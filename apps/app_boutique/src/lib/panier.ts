/** Logique pure du panier (persistance locale par boutique, fusion des lignes identiques). */
export interface LignePanier {
  varianteId: string
  produitSlug: string
  quantite: number
  /** Copie d'affichage : les prix réels sont revérifiés par le serveur à la commande. */
  libelleAr: string
  libelleFr: string
  prix: number
  image: string | null
}

export const QUANTITE_MAX = 99

export function ajouter(lignes: LignePanier[], ligne: LignePanier): LignePanier[] {
  const existante = lignes.find((l) => l.varianteId === ligne.varianteId)
  if (!existante) return [...lignes, { ...ligne, quantite: borner(ligne.quantite) }]
  return lignes.map((l) => (l.varianteId === ligne.varianteId ? { ...l, ...ligne, quantite: borner(l.quantite + ligne.quantite) } : l))
}

export function changerQuantite(lignes: LignePanier[], varianteId: string, quantite: number): LignePanier[] {
  return quantite <= 0 ? retirer(lignes, varianteId) : lignes.map((l) => (l.varianteId === varianteId ? { ...l, quantite: borner(quantite) } : l))
}

export function retirer(lignes: LignePanier[], varianteId: string): LignePanier[] {
  return lignes.filter((l) => l.varianteId !== varianteId)
}

export function sousTotal(lignes: LignePanier[]): number {
  return lignes.reduce((somme, l) => somme + l.prix * l.quantite, 0)
}

export function nombreArticles(lignes: LignePanier[]): number {
  return lignes.reduce((somme, l) => somme + l.quantite, 0)
}

function borner(quantite: number): number {
  return Math.min(QUANTITE_MAX, Math.max(1, Math.floor(quantite)))
}

const cle = (boutiqueId: string) => `panier.${boutiqueId}`

export function charger(boutiqueId: string): LignePanier[] {
  try {
    const brut = localStorage.getItem(cle(boutiqueId))
    const donnees: unknown = brut ? JSON.parse(brut) : []
    return Array.isArray(donnees) ? donnees.filter(estLigne) : []
  } catch {
    return []
  }
}

export function sauvegarder(boutiqueId: string, lignes: LignePanier[]): void {
  try {
    localStorage.setItem(cle(boutiqueId), JSON.stringify(lignes))
  } catch {
    // stockage indisponible : le panier reste en mémoire
  }
}

function estLigne(valeur: unknown): valeur is LignePanier {
  const l = valeur as Partial<LignePanier> | null
  return !!l && typeof l.varianteId === 'string' && typeof l.quantite === 'number' && l.quantite > 0 && typeof l.prix === 'number'
}
