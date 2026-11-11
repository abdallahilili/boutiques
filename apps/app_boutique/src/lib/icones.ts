/**
 * Icônes de catégorie : la commerçante en choisit une dans l'application mobile quand la catégorie n'a pas
 * d'image (`categories.icone`). Les clés doivent rester identiques à `category_icons.dart` (app mobile).
 */
export const ICONES_CATEGORIE: Record<string, string> = {
  robe: '👗',
  vetements: '👔',
  chaussures: '👟',
  sac: '👜',
  bijoux: '💍',
  parfum: '🧴',
  beaute: '💄',
  montre: '⌚',
  enfants: '🧸',
  bebe: '🍼',
  maison: '🏠',
  meubles: '🛋️',
  cuisine: '🍳',
  alimentation: '🛒',
  fruits: '🍎',
  boissons: '🥤',
  boulangerie: '🍞',
  viande: '🥩',
  electronique: '📱',
  ordinateur: '💻',
  sport: '⚽',
  livres: '📚',
  papeterie: '✏️',
  outils: '🔧',
  jardin: '🌿',
  auto: '🚗',
  sante: '💊',
  cadeaux: '🎁',
  tissus: '🧵',
  animaux: '🐾',
  nettoyage: '🧼',
  autre: '🏷️',
}

/** Emoji de l'icône choisie, ou `undefined` si la clé est absente ou inconnue. */
export function iconeCategorie(cle: string | null | undefined): string | undefined {
  return cle ? ICONES_CATEGORIE[cle] : undefined
}
