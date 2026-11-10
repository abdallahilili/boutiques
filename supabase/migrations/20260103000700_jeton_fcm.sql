-- Enregistrement du jeton FCM d'un appareil : le jeton est unique ; s'il était rattaché à un autre appareil
-- (réinstallation, changement de compte sur le même téléphone), il est détaché avant d'être réattribué.
create or replace function public.enregistrer_jeton_fcm(p_appareil uuid, p_jeton text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'acces_refuse' using errcode = '42501';
  end if;
  if p_jeton is null or length(p_jeton) < 20 or length(p_jeton) > 4096 then
    raise exception 'parametres_invalides: jeton' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.appareils a where a.id = p_appareil and a.utilisateur_id = auth.uid()) then
    raise exception 'acces_refuse' using errcode = '42501';
  end if;
  update public.appareils set jeton_fcm = null where jeton_fcm = p_jeton and id <> p_appareil;
  update public.appareils set jeton_fcm = p_jeton, derniere_activite = now() where id = p_appareil;
end;
$$;
revoke all on function public.enregistrer_jeton_fcm(uuid, text) from public, anon;
grant execute on function public.enregistrer_jeton_fcm(uuid, text) to authenticated, service_role;
