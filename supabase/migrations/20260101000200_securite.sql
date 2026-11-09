-- =============================================================================
-- Sécurité : helpers RLS (schéma prive), boutique_est_active, quotas, politiques RLS
-- des tables plateforme, triggers de protection de colonnes.
-- Principe : isolement par appartenance (membres_boutique) ; écriture bloquée
-- quand la boutique est suspendue (lecture seule conservée).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Identité de l'appelant
-- ---------------------------------------------------------------------------

-- Vrai pour la clé service_role (Edge Functions) et pour une connexion directe à la base
-- (migrations, console SQL) où aucun JWT n'est présent.
create or replace function prive.est_service()
returns boolean
language sql
stable
as $$
  select coalesce(auth.role(), 'service_role') = 'service_role';
$$;

create or replace function prive.role_plateforme_courant()
returns public.role_plateforme
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.role_plateforme from public.profils p where p.id = auth.uid() and p.actif),
    'aucun'::public.role_plateforme
  );
$$;

create or replace function prive.est_admin_plateforme()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select prive.role_plateforme_courant() in ('super_admin', 'support');
$$;

create or replace function prive.est_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select prive.role_plateforme_courant() = 'super_admin';
$$;

-- ---------------------------------------------------------------------------
-- Appartenance et permissions
-- ---------------------------------------------------------------------------

-- Boutiques dont l'appelant est membre actif. Évalué une fois par requête via (select ...).
create or replace function prive.mes_boutiques()
returns uuid[]
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(array_agg(m.boutique_id), '{}'::uuid[])
  from public.membres_boutique m
  where m.utilisateur_id = auth.uid() and m.statut = 'actif';
$$;

-- Boutiques où l'appelant détient la permission donnée.
create or replace function prive.boutiques_avec_permission(p_cle text)
returns uuid[]
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(array_agg(m.boutique_id), '{}'::uuid[])
  from public.membres_boutique m
  join public.permissions_role pr on pr.role_id = m.role_id
  where m.utilisateur_id = auth.uid()
    and m.statut = 'actif'
    and pr.cle_permission = p_cle
    and pr.autorise;
$$;

create or replace function prive.a_permission(p_boutique uuid, p_cle text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_boutique = any (prive.boutiques_avec_permission(p_cle));
$$;

-- Vrai si l'appelant partage au moins une boutique active avec l'utilisateur donné.
create or replace function prive.partage_boutique(p_utilisateur uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.membres_boutique a
    join public.membres_boutique b on b.boutique_id = a.boutique_id
    where a.utilisateur_id = auth.uid() and a.statut = 'actif' and b.utilisateur_id = p_utilisateur
  );
$$;

-- Écriture autorisée tant que la boutique est en essai, active ou en période de grâce.
create or replace function public.boutique_est_active(p_boutique uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select b.statut in ('essai', 'actif', 'grace') from public.boutiques b where b.id = p_boutique),
    false
  );
$$;
revoke all on function public.boutique_est_active(uuid) from public, anon;
grant execute on function public.boutique_est_active(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Quotas de plan : un dépassement bloque la création (pas la lecture ni la suppression)
-- ---------------------------------------------------------------------------

create or replace function prive.limite_plan(p_boutique uuid, p_cle text)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select nullif(p.limites ->> p_cle, '')::numeric
  from public.abonnements a
  join public.plans p on p.id = a.plan_id
  where a.boutique_id = p_boutique and a.statut in ('essai', 'actif', 'grace')
  limit 1;
$$;

create or replace function prive.verifier_quota(p_boutique uuid, p_cle text, p_courant bigint)
returns void
language plpgsql
stable
as $$
declare
  v_limite numeric := prive.limite_plan(p_boutique, p_cle);
begin
  if v_limite is not null and p_courant >= v_limite then
    raise exception 'quota_depasse: limite % atteinte (%)', p_cle, v_limite using errcode = 'P0001';
  end if;
end;
$$;

create or replace function prive.trg_quota_membres()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.statut <> 'desactive' then
    perform prive.verifier_quota(
      new.boutique_id, 'utilisateurs',
      (select count(*) from public.membres_boutique m where m.boutique_id = new.boutique_id and m.statut <> 'desactive')
    );
  end if;
  return new;
end;
$$;
create trigger quota_membres before insert on public.membres_boutique
  for each row execute function prive.trg_quota_membres();

-- ---------------------------------------------------------------------------
-- Fabrique de politiques RLS pour les tables métier portant `boutique_id`
-- ---------------------------------------------------------------------------
-- p_lecture : permission requise en lecture (null = tout membre actif).
-- p_ecriture : permission requise en écriture (null = aucune écriture cliente : RPC uniquement).
-- p_commandes : commandes d'écriture ouvertes parmi insert / update / delete.
create or replace function prive.creer_politiques_boutique(
  p_table regclass,
  p_lecture text,
  p_ecriture text default null,
  p_commandes text[] default array['insert', 'update', 'delete']
)
returns void
language plpgsql
as $$
declare
  v_nom text := (select c.relname from pg_class c where c.oid = p_table);
  v_lecture text;
  v_ecriture text;
  v_cmd text;
begin
  execute format('alter table %s enable row level security', p_table);

  v_lecture := case
    when p_lecture is null then 'boutique_id = any ((select prive.mes_boutiques())::uuid[])'
    else format('boutique_id = any ((select prive.boutiques_avec_permission(%L))::uuid[])', p_lecture)
  end;
  execute format('create policy %I on %s for select to authenticated using (%s)', 'lecture_' || v_nom, p_table, v_lecture);

  if p_ecriture is null then
    return;
  end if;

  v_ecriture := format(
    'public.boutique_est_active(boutique_id) and boutique_id = any ((select prive.boutiques_avec_permission(%L))::uuid[])',
    p_ecriture
  );
  foreach v_cmd in array p_commandes loop
    if v_cmd = 'insert' then
      execute format('create policy %I on %s for insert to authenticated with check (%s)', 'insertion_' || v_nom, p_table, v_ecriture);
    elsif v_cmd = 'update' then
      execute format('create policy %I on %s for update to authenticated using (%s) with check (%s)', 'modification_' || v_nom, p_table, v_ecriture, v_ecriture);
    elsif v_cmd = 'delete' then
      execute format('create policy %I on %s for delete to authenticated using (%s)', 'suppression_' || v_nom, p_table, v_ecriture);
    end if;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- RLS : profils
-- ---------------------------------------------------------------------------
alter table public.profils enable row level security;

create policy lecture_profils on public.profils for select to authenticated
  using (id = auth.uid() or prive.est_admin_plateforme() or prive.partage_boutique(id));
create policy modification_profil_personnel on public.profils for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy modification_profils_admin on public.profils for update to authenticated
  using (prive.est_admin_plateforme()) with check (prive.est_admin_plateforme());

-- Colonnes sensibles : seuls super_admin et service_role (Edge Functions) peuvent les modifier.
create or replace function prive.trg_proteger_profil()
returns trigger
language plpgsql
as $$
begin
  if not (prive.est_service() or prive.est_super_admin()) then
    if new.id is distinct from old.id
       or new.role_plateforme is distinct from old.role_plateforme
       or new.telephone is distinct from old.telephone
       or new.actif is distinct from old.actif then
      raise exception 'colonne_protegee: modification non autorisée du profil' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
create trigger proteger_profil before update on public.profils
  for each row execute function prive.trg_proteger_profil();

-- ---------------------------------------------------------------------------
-- RLS : commercantes (éditeur uniquement : contient les notes internes)
-- ---------------------------------------------------------------------------
alter table public.commercantes enable row level security;

create policy lecture_commercantes on public.commercantes for select to authenticated
  using (prive.est_admin_plateforme());
create policy insertion_commercantes on public.commercantes for insert to authenticated
  with check (prive.est_admin_plateforme());
create policy modification_commercantes on public.commercantes for update to authenticated
  using (prive.est_admin_plateforme()) with check (prive.est_admin_plateforme());
create policy suppression_commercantes on public.commercantes for delete to authenticated
  using (prive.est_super_admin());

-- ---------------------------------------------------------------------------
-- RLS : boutiques
-- ---------------------------------------------------------------------------
alter table public.boutiques enable row level security;

create policy lecture_boutiques on public.boutiques for select to authenticated
  using (id = any ((select prive.mes_boutiques())::uuid[]) or prive.est_admin_plateforme());
create policy modification_boutiques_membres on public.boutiques for update to authenticated
  using (public.boutique_est_active(id) and id = any ((select prive.boutiques_avec_permission('parametres.gerer'))::uuid[]))
  with check (id = any ((select prive.boutiques_avec_permission('parametres.gerer'))::uuid[]));
create policy modification_boutiques_admin on public.boutiques for update to authenticated
  using (prive.est_admin_plateforme()) with check (prive.est_admin_plateforme());
create policy suppression_boutiques on public.boutiques for delete to authenticated
  using (prive.est_super_admin());

-- Colonnes d'identité et de statut : modifiables par l'éditeur ou le service uniquement
-- (le sous-domaine attribué à la création n'est pas modifiable par la commerçante).
create or replace function prive.trg_proteger_boutique()
returns trigger
language plpgsql
as $$
begin
  if not (prive.est_service() or prive.est_admin_plateforme()) then
    if new.slug is distinct from old.slug
       or new.statut is distinct from old.statut
       or new.commercante_id is distinct from old.commercante_id
       or new.code_boutique is distinct from old.code_boutique then
      raise exception 'colonne_protegee: slug, statut, commercante et code boutique sont réservés à l''éditeur'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
create trigger proteger_boutique before update on public.boutiques
  for each row execute function prive.trg_proteger_boutique();

-- ---------------------------------------------------------------------------
-- RLS : permissions, roles, permissions_role (catalogue lisible, écriture super_admin)
-- ---------------------------------------------------------------------------
alter table public.permissions enable row level security;
create policy lecture_permissions on public.permissions for select to authenticated using (true);
create policy ecriture_permissions on public.permissions for all to authenticated
  using (prive.est_super_admin()) with check (prive.est_super_admin());

alter table public.roles enable row level security;
create policy lecture_roles on public.roles for select to authenticated
  using (boutique_id is null or boutique_id = any ((select prive.mes_boutiques())::uuid[]) or prive.est_admin_plateforme());
create policy ecriture_roles on public.roles for all to authenticated
  using (prive.est_super_admin()) with check (prive.est_super_admin());

alter table public.permissions_role enable row level security;
create policy lecture_permissions_role on public.permissions_role for select to authenticated using (true);
create policy ecriture_permissions_role on public.permissions_role for all to authenticated
  using (prive.est_super_admin()) with check (prive.est_super_admin());

-- ---------------------------------------------------------------------------
-- RLS : membres_boutique
-- ---------------------------------------------------------------------------
alter table public.membres_boutique enable row level security;

create policy lecture_membres_boutique on public.membres_boutique for select to authenticated
  using (boutique_id = any ((select prive.mes_boutiques())::uuid[]) or utilisateur_id = auth.uid() or prive.est_admin_plateforme());
create policy insertion_membres_admin on public.membres_boutique for insert to authenticated
  with check (prive.est_admin_plateforme());
create policy modification_membres on public.membres_boutique for update to authenticated
  using (public.boutique_est_active(boutique_id) and boutique_id = any ((select prive.boutiques_avec_permission('employes.gerer'))::uuid[]))
  with check (boutique_id = any ((select prive.boutiques_avec_permission('employes.gerer'))::uuid[]));
create policy modification_membres_admin on public.membres_boutique for update to authenticated
  using (prive.est_admin_plateforme()) with check (prive.est_admin_plateforme());
create policy suppression_membres on public.membres_boutique for delete to authenticated
  using (public.boutique_est_active(boutique_id) and boutique_id = any ((select prive.boutiques_avec_permission('employes.gerer'))::uuid[]));

-- La propriétaire ne peut être ni retirée, ni rétrogradée, ni désactivée par un membre ;
-- les identifiants (boutique, utilisatrice) sont immuables.
create or replace function prive.trg_proteger_membre()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_proprietaire uuid := (select r.id from public.roles r where r.boutique_id is null and r.cle = 'proprietaire');
  v_privilegie boolean := prive.est_service() or prive.est_admin_plateforme();
begin
  if tg_op = 'DELETE' then
    if old.role_id = v_proprietaire and not v_privilegie then
      raise exception 'proprietaire_protegee: la propriétaire ne peut pas être retirée' using errcode = '42501';
    end if;
    return old;
  end if;
  if new.boutique_id is distinct from old.boutique_id or new.utilisateur_id is distinct from old.utilisateur_id then
    raise exception 'colonne_protegee: boutique et utilisatrice sont immuables' using errcode = '42501';
  end if;
  if old.role_id = v_proprietaire and not v_privilegie
     and (new.role_id is distinct from old.role_id or new.statut <> 'actif') then
    raise exception 'proprietaire_protegee: la propriétaire ne peut pas être rétrogradée ni désactivée' using errcode = '42501';
  end if;
  if new.role_id = v_proprietaire and old.role_id is distinct from new.role_id and not v_privilegie then
    raise exception 'proprietaire_protegee: le rôle propriétaire est réservé à l''éditeur' using errcode = '42501';
  end if;
  return new;
end;
$$;
create trigger proteger_membre before update or delete on public.membres_boutique
  for each row execute function prive.trg_proteger_membre();

-- ---------------------------------------------------------------------------
-- RLS : plans, abonnements, paiements_abonnement
-- ---------------------------------------------------------------------------
alter table public.plans enable row level security;
create policy lecture_plans on public.plans for select to authenticated using (true);
create policy ecriture_plans on public.plans for all to authenticated
  using (prive.est_super_admin()) with check (prive.est_super_admin());

alter table public.abonnements enable row level security;
create policy lecture_abonnements on public.abonnements for select to authenticated
  using (boutique_id = any ((select prive.boutiques_avec_permission('abonnement.voir'))::uuid[]) or prive.est_admin_plateforme());
create policy insertion_abonnements on public.abonnements for insert to authenticated
  with check (prive.est_admin_plateforme());
create policy modification_abonnements on public.abonnements for update to authenticated
  using (prive.est_admin_plateforme()) with check (prive.est_admin_plateforme());
create policy suppression_abonnements on public.abonnements for delete to authenticated
  using (prive.est_super_admin());

-- Paiements d'abonnement : lecture seule côté clients ; écriture par enregistrer_paiement_abonnement().
alter table public.paiements_abonnement enable row level security;
create policy lecture_paiements_abonnement on public.paiements_abonnement for select to authenticated
  using (boutique_id = any ((select prive.boutiques_avec_permission('abonnement.voir'))::uuid[]) or prive.est_admin_plateforme());
