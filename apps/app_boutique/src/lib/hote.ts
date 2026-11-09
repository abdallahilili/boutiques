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
