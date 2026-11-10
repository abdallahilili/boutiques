// Envoi push Firebase Cloud Messaging (API HTTP v1).
// Variables : FCM_SERVICE_ACCOUNT (JSON du compte de service Firebase, en secret d'Edge Function) et
// FCM_PROJECT_ID (facultatif : déduit du compte de service). Sans elles, rien n'est envoyé et le résultat
// l'indique ; les notifications in-app (table notifications) fonctionnent indépendamment.

export interface MessagePush {
  titre: string;
  corps: string;
  /** Données applicatives (toutes les valeurs doivent être des chaînes pour FCM). */
  donnees?: Record<string, string>;
}

export interface ResultatPush {
  statut: "non_configure" | "envoye";
  envoyes: number;
  /** Jetons refusés comme inexistants ou expirés : à supprimer de la table appareils. */
  invalides: string[];
}

interface CompteService {
  client_email: string;
  private_key: string;
  token_uri?: string;
  project_id?: string;
}

const PORTEE = "https://www.googleapis.com/auth/firebase.messaging";

export function lireCompteService(brut: string | undefined | null): CompteService | null {
  if (!brut) return null;
  try {
    const compte = JSON.parse(brut) as CompteService;
    return compte.client_email && compte.private_key ? compte : null;
  } catch {
    return null;
  }
}

export function fcmConfigure(): boolean {
  return lireCompteService(Deno.env.get("FCM_SERVICE_ACCOUNT")) !== null;
}

export function base64url(octets: Uint8Array | string): string {
  const donnees = typeof octets === "string" ? new TextEncoder().encode(octets) : octets;
  let binaire = "";
  for (const o of donnees) binaire += String.fromCharCode(o);
  return btoa(binaire).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

/** Corps JSON d'un message FCM v1 adressé à un appareil (données converties en chaînes). */
export function corpsMessage(jeton: string, message: MessagePush): { message: Record<string, unknown> } {
  const donnees: Record<string, string> = {};
  for (const [cle, valeur] of Object.entries(message.donnees ?? {})) donnees[cle] = String(valeur);
  return {
    message: {
      token: jeton,
      notification: { title: message.titre, body: message.corps },
      data: donnees,
      android: { priority: "HIGH", notification: { channel_id: "boutiques_default" } },
      apns: { payload: { aps: { sound: "default" } } },
    },
  };
}

function pemVersDer(pem: string): Uint8Array<ArrayBuffer> {
  const corps = pem.replace(/-----[A-Z ]+-----/g, "").replace(/\s+/g, "");
  return Uint8Array.from(atob(corps), (c) => c.charCodeAt(0));
}

async function signerJwt(compte: CompteService): Promise<string> {
  const maintenant = Math.floor(Date.now() / 1000);
  const entete = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const revendications = base64url(JSON.stringify({
    iss: compte.client_email,
    scope: PORTEE,
    aud: compte.token_uri ?? "https://oauth2.googleapis.com/token",
    iat: maintenant,
    exp: maintenant + 3600,
  }));
  const cle = await crypto.subtle.importKey(
    "pkcs8",
    pemVersDer(compte.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cle, new TextEncoder().encode(`${entete}.${revendications}`));
  return `${entete}.${revendications}.${base64url(new Uint8Array(signature))}`;
}

let jetonAcces: { valeur: string; expire: number } | null = null;

async function obtenirJetonAcces(compte: CompteService): Promise<string> {
  if (jetonAcces && jetonAcces.expire > Date.now() + 60_000) return jetonAcces.valeur;
  const reponse = await fetch(compte.token_uri ?? "https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: await signerJwt(compte),
    }),
  });
  if (!reponse.ok) throw new Error(`FCM : échec OAuth2 (${reponse.status})`);
  const corps = await reponse.json() as { access_token: string; expires_in: number };
  jetonAcces = { valeur: corps.access_token, expire: Date.now() + corps.expires_in * 1000 };
  return corps.access_token;
}

export async function envoyerPush(jetons: string[], message: MessagePush): Promise<ResultatPush> {
  const compte = lireCompteService(Deno.env.get("FCM_SERVICE_ACCOUNT"));
  const uniques = [...new Set(jetons.filter((j) => j))];
  if (!compte || uniques.length === 0) return { statut: "non_configure", envoyes: 0, invalides: [] };
  const projet = Deno.env.get("FCM_PROJECT_ID") ?? compte.project_id;
  if (!projet) return { statut: "non_configure", envoyes: 0, invalides: [] };

  const acces = await obtenirJetonAcces(compte);
  let envoyes = 0;
  const invalides: string[] = [];
  // Par lots de 20 requêtes parallèles (l'API v1 n'accepte qu'un destinataire par appel).
  for (let i = 0; i < uniques.length; i += 20) {
    await Promise.all(uniques.slice(i, i + 20).map(async (jeton) => {
      const reponse = await fetch(`https://fcm.googleapis.com/v1/projects/${projet}/messages:send`, {
        method: "POST",
        headers: { "Authorization": `Bearer ${acces}`, "Content-Type": "application/json" },
        body: JSON.stringify(corpsMessage(jeton, message)),
      });
      if (reponse.ok) {
        envoyes++;
      } else if (reponse.status === 404 || reponse.status === 400) {
        const erreur = await reponse.text();
        if (/UNREGISTERED|NOT_FOUND|INVALID_ARGUMENT/.test(erreur)) invalides.push(jeton);
      } else {
        await reponse.body?.cancel();
      }
    }));
  }
  return { statut: "envoye", envoyes, invalides };
}
