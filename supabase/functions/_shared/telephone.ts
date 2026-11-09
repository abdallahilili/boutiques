// Normalisation des numéros de téléphone (identifiant de connexion).

export const INDICATIF_PAR_DEFAUT = Deno.env.get("PAYS_INDICATIF") ?? "222";

/** Chiffres uniquement, indicatif pays ajouté pour un numéro local (8 chiffres ou moins). */
export function normaliserTelephone(valeur: string, indicatif = INDICATIF_PAR_DEFAUT): string {
  let chiffres = valeur.replace(/[^0-9]/g, "");
  if (chiffres.startsWith("00")) chiffres = chiffres.slice(2);
  if (chiffres.length <= 8) chiffres = indicatif + chiffres;
  return chiffres;
}

export function estTelephoneValide(telephone: string): boolean {
  return /^[0-9]{8,15}$/.test(telephone);
}
