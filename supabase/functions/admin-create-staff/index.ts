// Création d'un membre de l'équipe éditeur (super_admin uniquement) : email + mot de passe initial.
// L'enrôlement du 2FA TOTP est imposé à sa première connexion sur app_admin.
//
// POST { email, nom_fr?, nom_ar?, role: "support" | "super_admin", mot_de_passe }
import { ErreurHttp, json, lireJson, servir, texte } from "../_shared/http.ts";
import { exigerAdminPlateforme } from "../_shared/autorisations.ts";
import { clientService } from "../_shared/supabase.ts";

servir(async (req) => {
  const service = clientService();
  const admin = await exigerAdminPlateforme(req, service, ["super_admin"]);
  const corps = await lireJson(req);

  const email = texte(corps, "email", 200)?.toLowerCase() ?? "";
  const role = texte(corps, "role", 20) ?? "";
  const motDePasse = typeof corps.mot_de_passe === "string" ? corps.mot_de_passe : "";
  const nomAr = texte(corps, "nom_ar", 120);
  const nomFr = texte(corps, "nom_fr", 120);
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new ErreurHttp(400, "donnees_invalides", "email invalide");
  if (!["support", "super_admin"].includes(role)) throw new ErreurHttp(400, "donnees_invalides", "role invalide");
  if (!nomAr && !nomFr) throw new ErreurHttp(400, "donnees_invalides", "nom requis");
  if (motDePasse.length < 12) throw new ErreurHttp(400, "mot_de_passe_faible", "12 caractères minimum");

  const { data: cree, error } = await service.auth.admin.createUser({ email, password: motDePasse, email_confirm: true });
  if (error || !cree.user) throw new ErreurHttp(409, "email_deja_utilise", error?.message);

  const { error: erreurProfil } = await service.from("profils").insert({
    id: cree.user.id,
    nom_ar: nomAr,
    nom_fr: nomFr,
    email,
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
