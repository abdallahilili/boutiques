import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import ar from './ar.json'
import fr from './fr.json'

export const LANGUES = ['ar', 'fr'] as const
export type Langue = (typeof LANGUES)[number]
const CLE_STOCKAGE = 'boutique.langue'

export function estLangue(valeur: unknown): valeur is Langue {
  return valeur === 'ar' || valeur === 'fr'
}

/** Applique langue et sens d'écriture (RTL pour l'arabe) au document. */
export function appliquerDirection(langue: string): void {
  document.documentElement.lang = langue
  document.documentElement.dir = langue === 'ar' ? 'rtl' : 'ltr'
}

function langueInitiale(): Langue {
  try {
    const memorisee = localStorage.getItem(CLE_STOCKAGE)
    if (estLangue(memorisee)) return memorisee
  } catch {
    // stockage indisponible : langue par défaut
  }
  return 'ar'
}

export async function changerLangue(langue: Langue): Promise<void> {
  await i18n.changeLanguage(langue)
  try {
    localStorage.setItem(CLE_STOCKAGE, langue)
  } catch {
    // préférence non mémorisée
  }
}

void i18n.use(initReactI18next).init({
  resources: { ar: { translation: ar }, fr: { translation: fr } },
  lng: langueInitiale(),
  fallbackLng: 'ar',
  interpolation: { escapeValue: false },
})
i18n.on('languageChanged', appliquerDirection)
appliquerDirection(i18n.language)

export default i18n
