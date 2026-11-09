// Inscription d'une cliente sur la boutique en ligne (compte optionnel) : téléphone + code à 4 chiffres.
// L'identité Auth est propre à la boutique (un code ne peut pas être partagé avec un compte commerçante).
// Limitation de débit par IP et par téléphone ; la connexion se fait ensuite par connexion_telephone_pin.
//
// POST { boutique_slug, telephone, nom, code }  →  201 { utilisateur_id }
import { adresseIp, ErreurHttp, json, lireJson, servir, texte } from "../_shared/http.ts";
import { emailTechnique, estCodePinValide, secretAuth } from "../_shared/code_pin.ts";
import { clientService, poivrePin } from "../_shared/supabase.ts";
import { estTelephoneValide, normaliserTelephone } from "../_shared/telephone.ts";

servir(async (req) => {
  const corps = await lireJson(req);
  const slug = texte(corps, "boutique_slug", 60);
  const nom = texte(corps, "nom", 120);
  const telephone = normaliserTelephone(texte(corps, "telephone", 30) ?? "");
  const code = typeof corps.code === "string" ? corps.code : "";
  if (!slug || !nom || nom.length < 2 || !estTelephoneValide(telephone) || !estCodePinValide(code)) {
    throw new ErreurHttp(400, "donnees_invalides");
  }

  const service = clientService();
  const { data: boutique } = await service.from("boutiques").select("id, statut").eq("slug", slug).maybeSingle();
  if (!boutique || !["essai", "actif", "grace"].includes(boutique.statut as string)) {
    throw new ErreurHttp(404, "boutique_introuvable");
  }

  for (const [cle, max] of [[`inscription:ip:${adresseIp(req)}`, 20], [`inscription:tel:${boutique.id}:${telephone}`, 5]] as const) {
    const { error } = await service.rpc("limiter_requete", { p_cle: cle, p_max: max, p_fenetre_secondes: 3600 });
    if (error) throw new ErreurHttp(429, "trop_de_requetes");
  }

  const { data: existant } = await service.from("comptes_clientes_site").select("id")
    .eq("boutique_id", boutique.id).eq("telephone", telephone).maybeSingle();
  if (existant) throw new ErreurHttp(409, "compte_existant");

  const email = emailTechnique({ type: "cliente", telephone, boutiqueId: boutique.id as string });
  const { data: cree, error: erreurAuth } = await service.auth.admin.createUser({
    email,
    password: await secretAuth(email, code, poivrePin()),
    email_confirm: true,
    user_metadata: { telephone, contexte: "cliente" },
  });
  if (erreurAuth || !cree.user) throw new ErreurHttp(409, "compte_existant");

  const { error } = await service.from("comptes_clientes_site").insert({
    boutique_id: boutique.id,
    utilisateur_id: cree.user.id,
    nom,
    telephone,
  });
  if (error) {
    await service.auth.admin.deleteUser(cree.user.id);
    throw new ErreurHttp(409, "compte_existant");
  }
  return json(201, { utilisateur_id: cree.user.id });
});
