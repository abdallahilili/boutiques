// Livraison push des notifications déjà enregistrées en base (table notifications) : chaque
// destinataire reçoit le message dans sa langue (profil), sur tous ses appareils enregistrés.
import { envoyerPush, type ResultatPush } from "./fcm.ts";
import type { Client } from "./supabase.ts";

interface LigneNotification {
  utilisateur_id: string;
  type: string;
  titre_ar: string | null;
  titre_fr: string | null;
  corps_ar: string | null;
  corps_fr: string | null;
  donnees: Record<string, unknown> | null;
}

/** Choisit le texte dans la langue de l'utilisatrice, avec repli sur l'autre langue. */
export function texteLocalise(ar: string | null, fr: string | null, langue: string): string {
  return (langue === "fr" ? fr ?? ar : ar ?? fr) ?? "";
}

export async function pousserNotifications(service: Client, ids: string[]): Promise<ResultatPush> {
  const total: ResultatPush = { statut: "non_configure", envoyes: 0, invalides: [] };
  if (ids.length === 0) return total;
  const lignes: LigneNotification[] = [];
  for (let i = 0; i < ids.length; i += 200) {
    const { data } = await service.from("notifications")
      .select("utilisateur_id, type, titre_ar, titre_fr, corps_ar, corps_fr, donnees").in("id", ids.slice(i, i + 200));
    lignes.push(...((data ?? []) as LigneNotification[]));
  }
  if (lignes.length === 0) return total;

  const utilisateurs = [...new Set(lignes.map((l) => l.utilisateur_id))];
  const { data: appareils } = await service.from("appareils").select("utilisateur_id, jeton_fcm")
    .in("utilisateur_id", utilisateurs).not("jeton_fcm", "is", null);
  const { data: profils } = await service.from("profils").select("id, langue").in("id", utilisateurs);
  const jetonsParUtilisateur = new Map<string, string[]>();
  for (const a of appareils ?? []) {
    const liste = jetonsParUtilisateur.get(a.utilisateur_id as string) ?? [];
    liste.push(a.jeton_fcm as string);
    jetonsParUtilisateur.set(a.utilisateur_id as string, liste);
  }
  const langues = new Map((profils ?? []).map((p) => [p.id as string, (p.langue as string | null) ?? "ar"]));

  for (const ligne of lignes) {
    const jetons = jetonsParUtilisateur.get(ligne.utilisateur_id) ?? [];
    if (jetons.length === 0) continue;
    const langue = langues.get(ligne.utilisateur_id) ?? "ar";
    const donnees: Record<string, string> = { type: ligne.type };
    for (const [cle, valeur] of Object.entries(ligne.donnees ?? {})) donnees[cle] = String(valeur);
    const resultat = await envoyerPush(jetons, {
      titre: texteLocalise(ligne.titre_ar, ligne.titre_fr, langue),
      corps: texteLocalise(ligne.corps_ar, ligne.corps_fr, langue),
      donnees,
    });
    if (resultat.statut === "envoye") total.statut = "envoye";
    total.envoyes += resultat.envoyes;
    total.invalides.push(...resultat.invalides);
  }
  await supprimerJetonsInvalides(service, total.invalides);
  return total;
}

export async function supprimerJetonsInvalides(service: Client, jetons: string[]): Promise<void> {
  if (jetons.length === 0) return;
  await service.from("appareils").delete().in("jeton_fcm", [...new Set(jetons)]);
}
