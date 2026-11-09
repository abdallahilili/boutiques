// Réinitialisation du code à 4 chiffres d'un compte commerçante/employée.
// Autorisé pour l'équipe éditeur, ou pour la propriétaire (permission « employes.gerer »)
// sur une employée de sa boutique. Le nouveau code est retourné une seule fois.
//
// POST { utilisateur_id }
import { ErreurHttp, json, lireJson, servir, texte } from "../_shared/http.ts";
import { emailTechnique, genererCodePin, secretAuth } from "../_shared/code_pin.ts";
import { permissionsDans } from "../_shared/autorisations.ts";
import { clientService, poivrePin, utilisateurCourant } from "../_shared/supabase.ts";
import { lienWhatsapp, messageCodeInitial } from "../_shared/whatsapp.ts";

servir(async (req) => {
  const appelant = await utilisateurCourant(req);
  const corps = await lireJson(req);
  const cibleId = texte(corps, "utilisateur_id", 36) ?? "";
  const service = clientService();

  const { data: cible } = await service.from("profils").select("id, telephone, role_plateforme")
    .eq("id", cibleId).maybeSingle();
  if (!cible?.telephone || cible.role_plateforme !== "aucun") throw new ErreurHttp(404, "compte_introuvable");

  const { data: profilAppelant } = await service.from("profils").select("role_plateforme, actif")
    .eq("id", appelant.id).maybeSingle();
  const estEditeur = !!profilAppelant?.actif && profilAppelant.role_plateforme !== "aucun";

  if (!estEditeur) {
    const { data: roleProprietaire } = await service.from("roles").select("id")
      .is("boutique_id", null).eq("cle", "proprietaire").single();
    const { data: appartenances } = await service.from("membres_boutique").select("boutique_id, role_id")
      .eq("utilisateur_id", cible.id);
    let autorise = false;
    for (const m of appartenances ?? []) {
      if (m.role_id === roleProprietaire?.id) continue; // la propriétaire est réinitialisée par l'éditeur
      if ((await permissionsDans(req, m.boutique_id as string)).includes("employes.gerer")) autorise = true;
    }
    if (!autorise) throw new ErreurHttp(403, "acces_refuse");
  }

  const code = genererCodePin();
  const contexte = { type: "commercante", telephone: cible.telephone as string } as const;
  const email = emailTechnique(contexte);
  const { error } = await service.auth.admin.updateUserById(cible.id as string, {
    password: await secretAuth(email, code, poivrePin()),
  });
  if (error) throw new ErreurHttp(500, "reinitialisation_impossible");

  await service.rpc("reinitialiser_tentatives_connexion", { p_identifiant: `m:${cible.telephone}` });
  await service.from("journal_audit").insert({
    utilisateur_id: appelant.id,
    action: "reinitialisation_code",
    entite: "profils",
    entite_id: cible.id,
  });

  return json(200, {
    code: code,
    lien_whatsapp: lienWhatsapp(cible.telephone as string, messageCodeInitial(cible.telephone as string, code)),
  });
});
