// Invitation d'une employée dans une boutique (app mobile, permission « employes.gerer »).
// Si le numéro n'a pas encore de compte, il est créé avec un code initial à 4 chiffres ;
// sinon la personne est simplement rattachée à la boutique (elle garde son code).
//
// POST { boutique_id, telephone, role: "manager" | "vendeuse" | "magasiniere", nom_ar?, nom_fr?, email? }
import { ErreurHttp, json, lireJson, servir, texte } from "../_shared/http.ts";
import { emailTechnique, genererCodePin, secretAuth } from "../_shared/code_pin.ts";
import { exigerPermission } from "../_shared/autorisations.ts";
import { clientService, poivrePin } from "../_shared/supabase.ts";
import { estTelephoneValide, normaliserTelephone } from "../_shared/telephone.ts";
import { lienWhatsapp, messageCodeInitial } from "../_shared/whatsapp.ts";

const ROLES_INVITABLES = ["manager", "vendeuse", "magasiniere"];
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

servir(async (req) => {
  const corps = await lireJson(req);
  const boutiqueId = texte(corps, "boutique_id", 36) ?? "";
  if (!UUID.test(boutiqueId)) throw new ErreurHttp(400, "donnees_invalides", "boutique_id invalide");
  const invitant = await exigerPermission(req, boutiqueId, "employes.gerer");

  const service = clientService();
  const { data: actif } = await service.rpc("boutique_est_active", { p_boutique: boutiqueId });
  if (!actif) throw new ErreurHttp(403, "boutique_suspendue");

  const role = texte(corps, "role", 20) ?? "";
  if (!ROLES_INVITABLES.includes(role)) throw new ErreurHttp(400, "donnees_invalides", "role invalide");
  const telephone = normaliserTelephone(texte(corps, "telephone", 30) ?? "");
  if (!estTelephoneValide(telephone)) throw new ErreurHttp(400, "donnees_invalides", "telephone invalide");

  const { data: profil } = await service.from("profils").select("id, role_plateforme").eq("telephone", telephone)
    .maybeSingle();

  if (profil) {
    if (profil.role_plateforme !== "aucun") throw new ErreurHttp(409, "compte_non_invitable");
    const { data: dejaMembre } = await service.from("membres_boutique").select("id")
      .eq("boutique_id", boutiqueId).eq("utilisateur_id", profil.id).maybeSingle();
    if (dejaMembre) throw new ErreurHttp(409, "deja_membre");
    const { data: membre, error } = await service.rpc("inviter_membre", {
      p_donnees: { boutique_id: boutiqueId, utilisateur_id: profil.id, role_cle: role, invite_par: invitant.id },
    });
    if (error) throw erreurInvitation(error.message);
    return json(201, { membre_id: membre, utilisateur_id: profil.id, nouveau_compte: false });
  }

  const nomAr = texte(corps, "nom_ar", 120);
  const nomFr = texte(corps, "nom_fr", 120);
  if (!nomAr && !nomFr) throw new ErreurHttp(400, "donnees_invalides", "nom_ar ou nom_fr requis");

  const code = genererCodePin();
  const email = emailTechnique({ type: "commercante", telephone });
  const { data: cree, error: erreurAuth } = await service.auth.admin.createUser({
    email,
    password: await secretAuth(email, code, poivrePin()),
    email_confirm: true,
    user_metadata: { telephone },
  });
  if (erreurAuth || !cree.user) throw new ErreurHttp(409, "creation_compte_impossible", erreurAuth?.message);

  const { data: membre, error } = await service.rpc("inviter_membre", {
    p_donnees: {
      boutique_id: boutiqueId,
      utilisateur_id: cree.user.id,
      role_cle: role,
      invite_par: invitant.id,
      profil: { telephone, nom_ar: nomAr, nom_fr: nomFr, email: texte(corps, "email", 200) },
    },
  });
  if (error) {
    await service.auth.admin.deleteUser(cree.user.id);
    throw erreurInvitation(error.message);
  }

  return json(201, {
    membre_id: membre,
    utilisateur_id: cree.user.id,
    nouveau_compte: true,
    code_initial: code,
    lien_whatsapp: lienWhatsapp(telephone, messageCodeInitial(telephone, code)),
  });
});

function erreurInvitation(message: string): ErreurHttp {
  return message.startsWith("quota_depasse")
    ? new ErreurHttp(403, "quota_depasse", message)
    : new ErreurHttp(400, "invitation_impossible", message);
}
