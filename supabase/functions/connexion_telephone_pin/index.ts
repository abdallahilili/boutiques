// Connexion par numéro de téléphone + code à 4 chiffres (apps commerçante et boutique en ligne).
// Le code est converti côté serveur en secret d'authentification ; 5 échecs verrouillent l'identité
// 15 minutes (et 30 échecs par adresse IP, pour freiner l'énumération de numéros).
//
// POST { telephone, code, contexte?: "commercante" | "cliente", boutique_slug? }
//  → 200 { session, utilisateur_id, contexte }
//  → 401 identifiants_invalides | 403 compte_desactive | 429 compte_verrouille
import { adresseIp, ErreurHttp, json, lireJson, servir, texte } from "../_shared/http.ts";
import { cleTentative, type ContexteConnexion, emailTechnique, estCodePinValide, secretAuth } from "../_shared/code_pin.ts";
import { clientAnonyme, type Client, clientService, poivrePin } from "../_shared/supabase.ts";
import { estTelephoneValide, normaliserTelephone } from "../_shared/telephone.ts";

const MAX_ECHECS_IDENTITE = 5;
const MAX_ECHECS_IP = 30;
const DUREE_VERROU_SECONDES = 900;

async function resoudreContexte(
  service: Client,
  corps: Record<string, unknown>,
  telephone: string,
): Promise<ContexteConnexion> {
  if ((texte(corps, "contexte", 20) ?? "commercante") !== "cliente") return { type: "commercante", telephone };
  const slug = texte(corps, "boutique_slug", 60);
  if (!slug) throw new ErreurHttp(400, "donnees_invalides", "boutique_slug requis");
  const { data } = await service.from("boutiques").select("id").eq("slug", slug).maybeSingle();
  if (!data) throw new ErreurHttp(404, "boutique_introuvable");
  return { type: "cliente", telephone, boutiqueId: data.id as string };
}

async function verrouJusquAu(service: Client, cles: string[]): Promise<string | null> {
  for (const cle of cles) {
    const { data } = await service.rpc("verifier_verrou_connexion", { p_identifiant: cle });
    if (data) return data as string;
  }
  return null;
}

servir(async (req) => {
  const corps = await lireJson(req);
  const telephone = normaliserTelephone(texte(corps, "telephone", 30) ?? "");
  const code = typeof corps.code === "string" ? corps.code : "";
  if (!estTelephoneValide(telephone) || !estCodePinValide(code)) throw new ErreurHttp(400, "donnees_invalides");

  const service = clientService();
  const contexte = await resoudreContexte(service, corps, telephone);
  const cleIdentite = cleTentative(contexte);
  const cleIp = `ip:${adresseIp(req)}`;

  const verrou = await verrouJusquAu(service, [cleIdentite, cleIp]);
  if (verrou) throw new ErreurHttp(429, "compte_verrouille", "Trop de tentatives", { verrouille_jusqu_au: verrou });

  const email = emailTechnique(contexte);
  const { data, error } = await clientAnonyme().auth.signInWithPassword({
    email,
    password: await secretAuth(email, code, poivrePin()),
  });

  if (error || !data.session) {
    if (error && error.status !== undefined && error.status >= 500) throw new ErreurHttp(502, "authentification_indisponible");
    const verrouIdentite = await service.rpc("enregistrer_echec_connexion", {
      p_identifiant: cleIdentite,
      p_max: MAX_ECHECS_IDENTITE,
      p_duree_secondes: DUREE_VERROU_SECONDES,
    });
    await service.rpc("enregistrer_echec_connexion", {
      p_identifiant: cleIp,
      p_max: MAX_ECHECS_IP,
      p_duree_secondes: DUREE_VERROU_SECONDES,
    });
    if (verrouIdentite.data) {
      throw new ErreurHttp(429, "compte_verrouille", "Trop de tentatives", { verrouille_jusqu_au: verrouIdentite.data });
    }
    throw new ErreurHttp(401, "identifiants_invalides");
  }

  if (contexte.type === "commercante") {
    const { data: profil } = await service.from("profils").select("actif").eq("id", data.user.id).maybeSingle();
    if (!profil?.actif) throw new ErreurHttp(403, "compte_desactive");
  }

  await service.rpc("reinitialiser_tentatives_connexion", { p_identifiant: cleIdentite });
  const { access_token, refresh_token, expires_in, expires_at, token_type } = data.session;
  return json(200, {
    session: { access_token, refresh_token, expires_in, expires_at, token_type },
    utilisateur_id: data.user.id,
    contexte: contexte.type,
  });
});
