// Utilitaires HTTP communs aux Edge Functions : CORS, erreurs typées, réponses JSON.

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

/** Erreur métier convertie en réponse JSON `{ erreur, message, ...extra }`. */
export class ErreurHttp extends Error {
  constructor(
    public readonly statut: number,
    public readonly code: string,
    message?: string,
    public readonly extra: Record<string, unknown> = {},
  ) {
    super(message ?? code);
  }
}

export function json(statut: number, corps: unknown): Response {
  return new Response(JSON.stringify(corps), {
    status: statut,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}

/** Démarre le serveur : gère OPTIONS, transforme les `ErreurHttp` en réponses, masque les erreurs internes. */
export function servir(gestionnaire: (req: Request) => Promise<Response>): void {
  Deno.serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
    try {
      if (req.method !== "POST") throw new ErreurHttp(405, "methode_non_autorisee");
      return await gestionnaire(req);
    } catch (e) {
      if (e instanceof ErreurHttp) return json(e.statut, { erreur: e.code, message: e.message, ...e.extra });
      console.error(e);
      return json(500, { erreur: "erreur_interne" });
    }
  });
}

export async function lireJson(req: Request): Promise<Record<string, unknown>> {
  try {
    const corps = await req.json();
    if (corps === null || typeof corps !== "object" || Array.isArray(corps)) throw new Error("objet attendu");
    return corps as Record<string, unknown>;
  } catch {
    throw new ErreurHttp(400, "json_invalide");
  }
}

/** Lit une chaîne optionnelle (rognée, bornée) ; `null` si absente ou vide. */
export function texte(corps: Record<string, unknown>, cle: string, max = 200): string | null {
  const valeur = corps[cle];
  if (valeur === undefined || valeur === null) return null;
  if (typeof valeur !== "string") throw new ErreurHttp(400, "donnees_invalides", `${cle} doit être un texte`);
  const propre = valeur.trim();
  if (propre.length > max) throw new ErreurHttp(400, "donnees_invalides", `${cle} trop long`);
  return propre === "" ? null : propre;
}

export function adresseIp(req: Request): string {
  return req.headers.get("x-forwarded-for")?.split(",")[0].trim() || "inconnue";
}
