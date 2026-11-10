const INDICATIF = '222'

/** Chiffres uniquement, indicatif pays ajouté pour un numéro local (8 chiffres ou moins). */
export function normaliserTelephone(saisie: string): string {
  let chiffres = saisie.replace(/\D/g, '')
  if (chiffres.startsWith('00')) chiffres = chiffres.slice(2)
  return chiffres.length <= 8 ? INDICATIF + chiffres : chiffres
}

/** Identifiant Auth technique d'un membre de l'équipe : le téléphone sert de nom d'utilisateur. */
export function emailEquipe(telephone: string): string {
  return `${normaliserTelephone(telephone)}@admin.invalid`
}
