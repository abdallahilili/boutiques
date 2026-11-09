/**
 * Thème de la boutique : `parametres_site.config_theme` + `themes_site.schema_config` convertis en
 * variables CSS (aucun code par boutique). Toute valeur est validée avant d'être injectée dans le DOM.
 */
export interface ConfigTheme {
  couleurs?: { primaire?: string; secondaire?: string; fond?: string; texte?: string }
  police?: string
  rayon?: string
  style_carte?: string
  entete?: string
  grille?: number
}

export interface MiseEnPage {
  entete: 'centre' | 'gauche'
  grille: 2 | 3
  styleCarte: 'bordure' | 'ombre' | 'minimal'
}

const HEX = /^#[0-9a-fA-F]{6}$/

const POLICES: Record<string, string> = {
  systeme: '"Segoe UI", Tahoma, "Noto Sans Arabic", system-ui, sans-serif',
  serif: 'Georgia, "Times New Roman", Amiri, serif',
  naskh: 'Amiri, "Traditional Arabic", Georgia, serif',
  arrondie: '"Trebuchet MS", "Segoe UI", Tahoma, system-ui, sans-serif',
}

const RAYONS: Record<string, string> = { aucun: '0', petit: '0.375rem', moyen: '0.75rem', grand: '1.25rem', pilule: '999px' }

/** Variables CSS à appliquer sur :root (valeurs inconnues ou invalides ignorées). */
export function variablesTheme(config: ConfigTheme | null | undefined): Record<string, string> {
  const variables: Record<string, string> = {}
  const c = config?.couleurs
  if (c?.primaire && HEX.test(c.primaire)) variables['--b-primaire'] = c.primaire
  if (c?.secondaire && HEX.test(c.secondaire)) variables['--b-secondaire'] = c.secondaire
  if (c?.fond && HEX.test(c.fond)) variables['--b-fond'] = c.fond
  if (c?.texte && HEX.test(c.texte)) variables['--b-texte'] = c.texte
  if (c?.primaire && HEX.test(c.primaire)) variables['--b-primaire-texte'] = contraste(c.primaire)
  if (config?.police && POLICES[config.police]) variables['--b-police'] = POLICES[config.police]
  if (config?.rayon && RAYONS[config.rayon] !== undefined) variables['--b-rayon'] = RAYONS[config.rayon]
  return variables
}

/** Blanc ou noir selon la luminance relative du fond (lisibilité du texte sur le bouton principal). */
export function contraste(hex: string): '#ffffff' | '#111111' {
  const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255).map((v) => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4))
  return 0.2126 * r + 0.7152 * g + 0.0722 * b > 0.4 ? '#111111' : '#ffffff'
}

/** Mise en page : le choix de la commerçante (config_theme) prime sur les valeurs par défaut du thème. */
export function miseEnPage(schema: Partial<ConfigTheme> | null | undefined, config: ConfigTheme | null | undefined): MiseEnPage {
  const entete = config?.entete ?? schema?.entete
  const grille = config?.grille ?? schema?.grille
  const carte = config?.style_carte ?? schema?.style_carte
  return {
    entete: entete === 'gauche' ? 'gauche' : 'centre',
    grille: grille === 3 ? 3 : 2,
    styleCarte: carte === 'ombre' || carte === 'minimal' ? carte : 'bordure',
  }
}

export function appliquerTheme(racine: HTMLElement, variables: Record<string, string>): () => void {
  const posees = Object.keys(variables)
  for (const [nom, valeur] of Object.entries(variables)) racine.style.setProperty(nom, valeur)
  return () => posees.forEach((nom) => racine.style.removeProperty(nom))
}
