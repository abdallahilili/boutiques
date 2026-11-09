// Changement de son propre code à 4 chiffres (l'ancien code est revérifié, avec limitation des tentatives).
//
// POST { ancien_code, nouveau_code }
import { ErreurHttp, json, lireJson, servir } from "../_shared/http.ts";
import { cleTentative, emailTechnique, estCodePinValide, secretAuth } from "../_shared/code_pin.ts";
import { clientAnonyme, clientService, poivrePin, utilisateurCourant } from "../_shared/supabase.ts";

servir(async (req) => {
  const utilisateur = await utilisateurCourant(req);
  const corps = await lireJson(req);
  const ancien = typeof corps.ancien_code === "string" ? corps.ancien_code : "";
  const nouveau = typeof corps.nouveau_code === "string" ? corps.nouveau_code : "";
  if (!estCodePinValide(ancien) || !estCodePinValide(nouveau)) throw new ErreurHttp(400, "donnees_invalides");
  if (ancien === nouveau) throw new ErreurHttp(400, "code_identique");

  const service = clientService();
  const { data: profil } = await service.from("profils").select("telephone").eq("id", utilisateur.id).maybeSingle();
  if (!profil?.telephone) throw new ErreurHttp(400, "compte_sans_telephone");

  const contexte = { type: "commercante", telephone: profil.telephone as string } as const;
  const cle = cleTentative(contexte);
  const { data: verrou } = await service.rpc("verifier_verrou_connexion", { p_identifiant: cle });
  if (verrou) throw new ErreurHttp(429, "compte_verrouille", "Trop de tentatives", { verrouille_jusqu_au: verrou });

  const email = emailTechnique(contexte);
  const poivre = poivrePin();
  const { error } = await clientAnonyme().auth.signInWithPassword({ email, password: await secretAuth(email, ancien, poivre) });
  if (error) {
    const { data: verrouille } = await service.rpc("enregistrer_echec_connexion", { p_identifiant: cle, p_max: 5, p_duree_secondes: 900 });
    if (verrouille) throw new ErreurHttp(429, "compte_verrouille", "Trop de tentatives", { verrouille_jusqu_au: verrouille });
    throw new ErreurHttp(401, "identifiants_invalides");
  }

  const { error: erreurMaj } = await service.auth.admin.updateUserById(utilisateur.id, {
    password: await secretAuth(email, nouveau, poivre),
  });
  if (erreurMaj) throw new ErreurHttp(500, "changement_impossible");
  await service.rpc("reinitialiser_tentatives_connexion", { p_identifiant: cle });
  return json(200, { ok: true });
});
