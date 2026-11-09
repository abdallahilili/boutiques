// Code à 4 chiffres : génération, validation et conversion en secret d'authentification.
// Le code n'est jamais stocké : Auth ne conserve que HMAC-SHA256(poivre, email_technique:code).
// Sans le poivre (variable PIN_SECRET de l'Edge Function), les 10 000 codes ne sont pas rejouables hors ligne.

export type ContexteConnexion =
  | { type: "commercante"; telephone: string }
  | { type: "cliente"; telephone: string; boutiqueId: string };

export function estCodePinValide(code: string): boolean {
  return /^[0-9]{4}$/.test(code);
}

/** Code aléatoire uniforme (tirage avec rejet pour éviter le biais du modulo). */
export function genererCodePin(): string {
  const limite = 4_294_960_000; // plus grand multiple de 10 000 inférieur à 2^32
  const tirage = new Uint32Array(1);
  do {
    crypto.getRandomValues(tirage);
  } while (tirage[0] >= limite);
  return String(tirage[0] % 10_000).padStart(4, "0");
}

/** Email technique de l'identité Auth : le numéro de téléphone n'est pas un email réel. */
export function emailTechnique(
  contexte: ContexteConnexion,
  domaine = Deno.env.get("PHONE_EMAIL_DOMAIN") ?? "tel.invalid",
): string {
  return contexte.type === "commercante"
    ? `${contexte.telephone}@${domaine}`
    : `c.${contexte.boutiqueId}.${contexte.telephone}@${domaine}`;
}

/** Clé de limitation des tentatives (une par identité, jamais partagée entre rôles). */
export function cleTentative(contexte: ContexteConnexion): string {
  return contexte.type === "commercante"
    ? `m:${contexte.telephone}`
    : `c:${contexte.boutiqueId}:${contexte.telephone}`;
}

export async function secretAuth(email: string, code: string, poivre: string): Promise<string> {
  if (poivre.length < 16) throw new Error("PIN_SECRET trop court (16 caractères minimum)");
  const cle = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(poivre),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", cle, new TextEncoder().encode(`${email}:${code}`));
  return Array.from(new Uint8Array(signature), (o) => o.toString(16).padStart(2, "0")).join("");
}
