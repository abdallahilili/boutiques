-- =============================================================================
-- Journal d'audit (immuable), appareils (FCM + numérotation hors ligne),
-- notifications in-app, limitation des tentatives de connexion.
-- =============================================================================

create type public.plateforme_appareil as enum ('android', 'ios', 'web');

-- ---------------------------------------------------------------------------
-- Journal d'audit : ajout seul, alimenté par triggers et Edge Functions
-- (pas de clé étrangère : le journal survit à la suppression des entités).
-- ---------------------------------------------------------------------------
create table public.journal_audit (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid,
  utilisateur_id uuid,
  action text not null,
  entite text not null,
  entite_id uuid,
  avant jsonb,
  apres jsonb,
  details jsonb,
  date_action timestamptz not null default now()
);
create index journal_audit_boutique_idx on public.journal_audit (boutique_id, date_action desc);
create index journal_audit_entite_idx on public.journal_audit (entite, entite_id);
create index journal_audit_date_idx on public.journal_audit (date_action desc);

create trigger journal_audit_ajout_seul before update or delete on public.journal_audit
  for each row execute function prive.interdire_modification();
revoke insert, update, delete on public.journal_audit from authenticated;

alter table public.journal_audit enable row level security;
create policy lecture_journal_audit on public.journal_audit for select to authenticated
  using (
    prive.est_admin_plateforme()
    or (boutique_id is not null and boutique_id = any ((select prive.boutiques_avec_permission('parametres.gerer'))::uuid[]))
  );

-- Trigger générique d'audit (AFTER) : enregistre l'avant/après de la ligne et l'auteur.
create or replace function prive.trg_journaliser()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ligne jsonb := case tg_op when 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  v_boutique uuid := case tg_table_name
    when 'boutiques' then (v_ligne ->> 'id')::uuid
    else (v_ligne ->> 'boutique_id')::uuid
  end;
begin
  insert into public.journal_audit (boutique_id, utilisateur_id, action, entite, entite_id, avant, apres)
  values (
    v_boutique,
    auth.uid(),
    lower(tg_op),
    tg_table_name,
    (v_ligne ->> 'id')::uuid,
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end
  );
  return null;
end;
$$;

-- Audit des tables plateforme sensibles.
create trigger audit after insert or update or delete on public.boutiques
  for each row execute function prive.trg_journaliser();
create trigger audit after insert or update or delete on public.abonnements
  for each row execute function prive.trg_journaliser();
create trigger audit after insert or update or delete on public.paiements_abonnement
  for each row execute function prive.trg_journaliser();
create trigger audit after insert or update or delete on public.membres_boutique
  for each row execute function prive.trg_journaliser();
create trigger audit after insert or update or delete on public.plans
  for each row execute function prive.trg_journaliser();
create trigger audit after insert or update or delete on public.commercantes
  for each row execute function prive.trg_journaliser();
create trigger audit after update on public.profils
  for each row when (old.role_plateforme is distinct from new.role_plateforme or old.actif is distinct from new.actif)
  execute function prive.trg_journaliser();

-- ---------------------------------------------------------------------------
-- Appareils : jeton FCM (notifications) et identité de l'appareil pour la
-- réservation de plages de numéros hors ligne.
-- ---------------------------------------------------------------------------
create table public.appareils (
  id uuid primary key default gen_random_uuid(),
  utilisateur_id uuid not null references public.profils (id) on delete cascade,
  boutique_id uuid references public.boutiques (id) on delete cascade,
  jeton_fcm text unique,
  plateforme public.plateforme_appareil not null,
  nom text,
  derniere_activite timestamptz not null default now(),
  cree_le timestamptz not null default now()
);
create index appareils_utilisateur_idx on public.appareils (utilisateur_id);

alter table public.appareils enable row level security;
create policy lecture_appareils on public.appareils for select to authenticated
  using (utilisateur_id = auth.uid() or prive.est_admin_plateforme());
create policy insertion_appareils on public.appareils for insert to authenticated
  with check (
    utilisateur_id = auth.uid()
    and (boutique_id is null or boutique_id = any ((select prive.mes_boutiques())::uuid[]))
  );
create policy modification_appareils on public.appareils for update to authenticated
  using (utilisateur_id = auth.uid())
  with check (
    utilisateur_id = auth.uid()
    and (boutique_id is null or boutique_id = any ((select prive.mes_boutiques())::uuid[]))
  );
create policy suppression_appareils on public.appareils for delete to authenticated
  using (utilisateur_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Notifications in-app : une ligne par destinataire (le push FCM est envoyé par
-- l'Edge Function send-notification). `cible` décrit la diffusion d'origine.
-- ---------------------------------------------------------------------------
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid references public.boutiques (id) on delete cascade,
  utilisateur_id uuid not null references public.profils (id) on delete cascade,
  type text not null default 'annonce',
  titre_ar text,
  titre_fr text,
  corps_ar text,
  corps_fr text,
  cible text not null default 'utilisateur' check (cible in ('utilisateur', 'boutique', 'plan', 'tous')),
  donnees jsonb not null default '{}'::jsonb,
  lu_le timestamptz,
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  constraint notifications_titre_requis check (coalesce(titre_ar, titre_fr) is not null)
);
create index notifications_destinataire_idx on public.notifications (utilisateur_id, cree_le desc);
create index notifications_boutique_idx on public.notifications (boutique_id, cree_le desc);

alter table public.notifications enable row level security;
create policy lecture_notifications on public.notifications for select to authenticated
  using (utilisateur_id = auth.uid() or prive.est_admin_plateforme());
-- La destinataire ne peut que marquer comme lue (colonne lu_le, garantie par le trigger ci-dessous).
create policy modification_notifications on public.notifications for update to authenticated
  using (utilisateur_id = auth.uid()) with check (utilisateur_id = auth.uid());
create policy suppression_notifications on public.notifications for delete to authenticated
  using (utilisateur_id = auth.uid());

create or replace function prive.trg_notification_lecture_seule()
returns trigger
language plpgsql
as $$
begin
  if not prive.est_service() and (to_jsonb(new) - 'lu_le') is distinct from (to_jsonb(old) - 'lu_le') then
    raise exception 'colonne_protegee: seule la lecture (lu_le) est modifiable' using errcode = '42501';
  end if;
  return new;
end;
$$;
create trigger notification_lecture_seule before update on public.notifications
  for each row execute function prive.trg_notification_lecture_seule();

-- ---------------------------------------------------------------------------
-- Limitation des tentatives de connexion (code à 4 chiffres = secret faible).
-- Table interne : accessible uniquement via service_role (RPC ci-dessous).
-- ---------------------------------------------------------------------------
create table public.tentatives_connexion (
  identifiant text primary key,
  echecs integer not null default 0,
  verrouille_jusqu_au timestamptz,
  derniere_tentative_le timestamptz not null default now()
);

alter table public.tentatives_connexion enable row level security;
-- Politique explicite de refus : aucun client n'accède à cette table.
create policy refus_total_tentatives_connexion on public.tentatives_connexion
  for all to anon, authenticated using (false) with check (false);

-- Retourne la fin de verrouillage si l'identifiant est verrouillé, sinon null.
create or replace function public.verifier_verrou_connexion(p_identifiant text)
returns timestamptz
language sql
stable
security definer
set search_path = public
as $$
  select t.verrouille_jusqu_au
  from public.tentatives_connexion t
  where t.identifiant = p_identifiant and t.verrouille_jusqu_au > now();
$$;

-- Enregistre un échec de manière atomique ; verrouille après p_max échecs consécutifs.
-- Les échecs de plus d'une heure sont oubliés ; un verrou expiré remet le compteur à zéro.
create or replace function public.enregistrer_echec_connexion(
  p_identifiant text,
  p_max integer default 5,
  p_duree_secondes integer default 900
)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v public.tentatives_connexion;
begin
  insert into public.tentatives_connexion (identifiant, echecs, derniere_tentative_le)
  values (p_identifiant, 0, now())
  on conflict (identifiant) do nothing;

  select * into v from public.tentatives_connexion where identifiant = p_identifiant for update;

  if v.verrouille_jusqu_au is not null and v.verrouille_jusqu_au > now() then
    return v.verrouille_jusqu_au;
  end if;
  if v.verrouille_jusqu_au is not null or v.derniere_tentative_le < now() - interval '1 hour' then
    v.echecs := 0;
  end if;

  v.echecs := v.echecs + 1;
  v.verrouille_jusqu_au := case
    when v.echecs >= p_max then now() + make_interval(secs => p_duree_secondes)
  end;

  update public.tentatives_connexion
  set echecs = v.echecs, verrouille_jusqu_au = v.verrouille_jusqu_au, derniere_tentative_le = now()
  where identifiant = p_identifiant;
  return v.verrouille_jusqu_au;
end;
$$;

create or replace function public.reinitialiser_tentatives_connexion(p_identifiant text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.tentatives_connexion where identifiant = p_identifiant;
$$;

revoke all on function public.verifier_verrou_connexion(text) from public, anon, authenticated;
revoke all on function public.enregistrer_echec_connexion(text, integer, integer) from public, anon, authenticated;
revoke all on function public.reinitialiser_tentatives_connexion(text) from public, anon, authenticated;
grant execute on function public.verifier_verrou_connexion(text) to service_role;
grant execute on function public.enregistrer_echec_connexion(text, integer, integer) to service_role;
grant execute on function public.reinitialiser_tentatives_connexion(text) to service_role;
