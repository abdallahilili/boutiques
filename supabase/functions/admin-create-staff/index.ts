// Création d'un membre de l'équipe éditeur (super_admin uniquement) : le numéro de téléphone sert
// de nom d'utilisateur, avec un mot de passe choisi par le super_admin (8 caractères minimum).
// L'identifiant Auth technique est `<chiffres>@admin.invalid` (distinct de celui des commerçantes).
//
// POST { telephone, nom_fr?, nom_ar?, role: "support" | "super_admin", mot_de_passe }
import { ErreurHttp, json, lireJson, servir, texte } from "../_shared/http.ts";
import { exigerAdminPlateforme } from "../_shared/autorisations.ts";
import { clientService } from "../_shared/supabase.ts";
import { estTelephoneValide, normaliserTelephone } from "../_shared/telephone.ts";

servir(async (req) => {
  const service = clientService();
  const admin = await exigerAdminPlateforme(req, service, ["super_admin"]);
  const corps = await lireJson(req);

  const telephone = normaliserTelephone(texte(corps, "telephone", 30) ?? "");
  const role = texte(corps, "role", 20) ?? "";
  const motDePasse = typeof corps.mot_de_passe === "string" ? corps.mot_de_passe : "";
  const nomAr = texte(corps, "nom_ar", 120);
  const nomFr = texte(corps, "nom_fr", 120);
  if (!estTelephoneValide(telephone)) throw new ErreurHttp(400, "donnees_invalides", "telephone invalide");
  if (!["support", "super_admin"].includes(role)) throw new ErreurHttp(400, "donnees_invalides", "role invalide");
  if (!nomAr && !nomFr) throw new ErreurHttp(400, "donnees_invalides", "nom requis");
  if (motDePasse.length < 8) throw new ErreurHttp(400, "mot_de_passe_faible", "8 caractères minimum");

  const { data: existant } = await service.from("profils").select("id").eq("telephone", telephone).maybeSingle();
  if (existant) throw new ErreurHttp(409, "telephone_deja_utilise");

  const { data: cree, error } = await service.auth.admin.createUser({
    email: `${telephone}@admin.invalid`,
    password: motDePasse,
    email_confirm: true,
  });
  if (error || !cree.user) throw new ErreurHttp(409, "telephone_deja_utilise", error?.message);

  const { error: erreurProfil } = await service.from("profils").insert({
    id: cree.user.id,
    nom_ar: nomAr,
    nom_fr: nomFr,
    telephone,
    role_plateforme: role,
  });
  if (erreurProfil) {
    await service.auth.admin.deleteUser(cree.user.id);
    throw new ErreurHttp(400, "creation_impossible", erreurProfil.message);
  }
  await service.from("journal_audit").insert({
    utilisateur_id: admin.id,
    action: "creation_membre_equipe",
    entite: "profils",
    entite_id: cree.user.id,
    details: { role },
  });
  return json(201, { utilisateur_id: cree.user.id });
});
