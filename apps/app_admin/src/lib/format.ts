/** Nom localisé avec repli sur l'autre langue (les deux colonnes nom_ar / nom_fr sont optionnelles). */
export function nomLocalise(ligne: { nom_ar?: string | null; nom_fr?: string | null }, langue: string): string {
  const [premier, second] = langue === 'ar' ? [ligne.nom_ar, ligne.nom_fr] : [ligne.nom_fr, ligne.nom_ar]
  return premier || second || '—'
}

/** Locales d'affichage : chiffres occidentaux (0-9) toujours, y compris en arabe (`nu-latn`). */
export const LOCALE_AFFICHAGE: Record<string, string> = { ar: 'ar-u-nu-latn', fr: 'fr-FR' }
const localeDe = (langue: string) => LOCALE_AFFICHAGE[langue] ?? LOCALE_AFFICHAGE.fr

export function formaterMontant(montant: number, devise: string, langue: string): string {
  try {
    return new Intl.NumberFormat(localeDe(langue), { style: 'currency', currency: devise, maximumFractionDigits: devise === 'MRU' ? 0 : 2 }).format(montant)
  } catch {
    return `${montant} ${devise}`
  }
}

export function formaterDate(valeur: string | null | undefined, langue: string, avecHeure = false): string {
  if (!valeur) return '—'
  return new Intl.DateTimeFormat(localeDe(langue), avecHeure ? { dateStyle: 'short', timeStyle: 'short' } : { dateStyle: 'medium' }).format(new Date(valeur))
}

/** Échappe une valeur pour un champ de recherche PostgREST `ilike` / `or`. */
export function motifRecherche(saisie: string): string {
  return `%${saisie.replace(/[%_,()]/g, ' ').replace(/\s+/g, ' ').trim()}%`
}
