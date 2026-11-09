// Contrôles d'autorisation de l'appelant (en plus de la vérification du JWT par la plateforme).
import type { User } from "npm:@supabase/supabase-js@2";
import { ErreurHttp } from "./http.ts";
import { type Client, clientUtilisateur, utilisateurCourant } from "./supabase.ts";

export type RolePlateforme = "super_admin" | "support";

/** L'appelant doit être un membre actif de l'équipe éditeur (rôles autorisés au choix). */
export async function exigerAdminPlateforme(
  req: Request,
  service: Client,
  autorises: RolePlateforme[] = ["super_admin", "support"],
): Promise<User> {
  const utilisateur = await utilisateurCourant(req);
  const { data } = await service.from("profils").select("role_plateforme, actif").eq("id", utilisateur.id)
    .maybeSingle();
  if (!data?.actif || !autorises.includes(data.role_plateforme as RolePlateforme)) {
    throw new ErreurHttp(403, "acces_refuse", "Réservé à l'équipe éditeur");
  }
  return utilisateur;
}

/** Permissions de l'appelant dans une boutique (RPC exécutée avec son propre JWT). */
export async function permissionsDans(req: Request, boutiqueId: string): Promise<string[]> {
  const { data, error } = await clientUtilisateur(req).rpc("mes_permissions", { p_boutique: boutiqueId });
  if (error) throw new ErreurHttp(403, "acces_refuse");
  return (data as string[] | null) ?? [];
}

export async function exigerPermission(req: Request, boutiqueId: string, permission: string): Promise<User> {
  const utilisateur = await utilisateurCourant(req);
  if (!(await permissionsDans(req, boutiqueId)).includes(permission)) {
    throw new ErreurHttp(403, "acces_refuse", `Permission requise : ${permission}`);
  }
  return utilisateur;
}
