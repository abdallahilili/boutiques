// Fonctions appelées par un planificateur ou un webhook de base de données (pas par un utilisateur) :
// elles sont protégées par un secret partagé (en-tête x-cron-secret), comparé en temps constant.
import { ErreurHttp } from "./http.ts";

export function egalTempsConstant(a: string, b: string): boolean {
  const ea = new TextEncoder().encode(a);
  const eb = new TextEncoder().encode(b);
  let ecart = ea.length ^ eb.length;
  for (let i = 0; i < Math.max(ea.length, eb.length); i++) ecart |= (ea[i] ?? 0) ^ (eb[i] ?? 0);
  return ecart === 0;
}

/** Exige l'en-tête `x-cron-secret` égal à la variable d'environnement donnée (>= 16 caractères). */
export function exigerSecretPartage(req: Request, variable = "CRON_SECRET"): void {
  const attendu = Deno.env.get(variable) ?? "";
  if (attendu.length < 16) throw new ErreurHttp(500, "secret_non_configure", `${variable} (16 caractères minimum) est requis`);
  const recu = req.headers.get("x-cron-secret") ?? "";
  if (!egalTempsConstant(recu, attendu)) throw new ErreurHttp(401, "non_authentifie");
}
