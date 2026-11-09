// Clients Supabase : la clé service_role n'existe que dans ces fonctions, jamais côté client.
import { createClient, type SupabaseClient, type User } from "npm:@supabase/supabase-js@2";
import { ErreurHttp } from "./http.ts";

export type Client = SupabaseClient;

function variable(nom: string): string {
  const valeur = Deno.env.get(nom);
  if (!valeur) throw new Error(`Variable d'environnement manquante : ${nom}`);
  return valeur;
}

const optionsSansSession = { auth: { persistSession: false, autoRefreshToken: false } };

export function clientService(): Client {
  return createClient(variable("SUPABASE_URL"), variable("SUPABASE_SERVICE_ROLE_KEY"), optionsSansSession);
}

export function clientAnonyme(): Client {
  return createClient(variable("SUPABASE_URL"), variable("SUPABASE_ANON_KEY"), optionsSansSession);
}

/** Client agissant avec les droits (et la RLS) de l'appelant. */
export function clientUtilisateur(req: Request): Client {
  return createClient(variable("SUPABASE_URL"), variable("SUPABASE_ANON_KEY"), {
    ...optionsSansSession,
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
}

export function poivrePin(): string {
  return variable("PIN_SECRET");
}

export async function utilisateurCourant(req: Request): Promise<User> {
  if (!req.headers.get("Authorization")) throw new ErreurHttp(401, "non_authentifie");
  const { data, error } = await clientUtilisateur(req).auth.getUser();
  if (error || !data.user) throw new ErreurHttp(401, "non_authentifie");
  return data.user;
}
