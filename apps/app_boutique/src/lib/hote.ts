/**
 * Extrait le sous-domaine de la boutique depuis le nom d'hôte (`nom.plateforme.com` → `nom`).
 * Retourne null pour le domaine de base lui-même, un domaine inconnu ou un domaine personnalisé
 * (ces derniers sont résolus côté serveur par resoudre_boutique).
 */
export function sousDomaine(hote: string, domaineBase: string): string | null {
  const h = hote.toLowerCase()
  const base = domaineBase.toLowerCase()
  if (!h.endsWith(`.${base}`)) return null
  const etiquette = h.slice(0, -(base.length + 1))
  return etiquette && !etiquette.includes('.') && etiquette !== 'www' ? etiquette : null
}

/**
 * Nom d'hôte à résoudre côté serveur (resoudre_boutique) : le nom réel, sauf en développement
 * où `VITE_BOUTIQUE_SLUG` simule un sous-domaine quand l'URL est celle du domaine de base.
 */
export function hotePourResolution(hote: string, domaineBase: string, slugDev?: string): string {
  if (slugDev && (hote === domaineBase || hote === 'localhost' || hote === '127.0.0.1')) return `${slugDev}.${domaineBase}`
  return hote
}
