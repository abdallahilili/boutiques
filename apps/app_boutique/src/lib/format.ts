/** Nom localisé avec repli sur l'autre langue. */
export function nomLocalise(ligne: { nom_ar?: string | null; nom_fr?: string | null }, langue: string): string {
  const [premier, second] = langue === 'ar' ? [ligne.nom_ar, ligne.nom_fr] : [ligne.nom_fr, ligne.nom_ar]
  return premier || second || ''
}

export function titreLocalise(ligne: { titre_ar?: string | null; titre_fr?: string | null }, langue: string): string {
  return nomLocalise({ nom_ar: ligne.titre_ar, nom_fr: ligne.titre_fr }, langue)
}

export function contenuLocalise(ligne: { contenu_ar?: string | null; contenu_fr?: string | null }, langue: string): string {
  return nomLocalise({ nom_ar: ligne.contenu_ar, nom_fr: ligne.contenu_fr }, langue)
}

export function descriptionLocalisee(ligne: { description_ar?: string | null; description_fr?: string | null }, langue: string): string {
  return nomLocalise({ nom_ar: ligne.description_ar, nom_fr: ligne.description_fr }, langue)
}

/** Locales d'affichage : chiffres occidentaux (0-9) toujours, y compris en arabe (`nu-latn`). */
export const LOCALE_AFFICHAGE: Record<string, string> = { ar: 'ar-u-nu-latn', fr: 'fr-FR' }
const localeDe = (langue: string) => LOCALE_AFFICHAGE[langue] ?? LOCALE_AFFICHAGE.fr

/** Montant dans la devise de la boutique (MRU sans décimales). */
export function formaterMontant(montant: number, devise: string, langue: string): string {
  try {
    return new Intl.NumberFormat(localeDe(langue), {
      style: 'currency', currency: devise, maximumFractionDigits: devise === 'MRU' ? 0 : 2,
    }).format(montant)
  } catch {
    return `${montant} ${devise}`
  }
}

export function formaterDate(valeur: string, langue: string): string {
  return new Intl.DateTimeFormat(localeDe(langue), { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(valeur))
}

/**
 * URL d'image servie par les transformations Supabase Storage (redimensionnement, WebP).
 * Un chemin de bucket `product-images` ou `shop-assets` est transformé ; une URL absolue est conservée.
 */
export function urlImage(chemin: string | null | undefined, largeur = 600, bucket: 'product-images' | 'shop-assets' = 'product-images'): string | undefined {
  if (!chemin) return undefined
  if (/^https?:\/\//.test(chemin)) return chemin
  const base = (import.meta.env.VITE_SUPABASE_URL as string | undefined) ?? ''
  return `${base}/storage/v1/render/image/public/${bucket}/${chemin}?width=${largeur}&quality=75&format=webp`
}
