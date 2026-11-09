import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import ar from './ar.json'
import fr from './fr.json'

export const LANGUES = ['ar', 'fr'] as const
export type Langue = (typeof LANGUES)[number]
const CLE_STOCKAGE = 'admin.langue'

/** Applique langue et sens d'écriture (RTL pour l'arabe) au document. */
export function appliquerDirection(langue: string): void {
  document.documentElement.lang = langue
  document.documentElement.dir = langue === 'ar' ? 'rtl' : 'ltr'
}

function langueInitiale(): Langue {
  try {
    const memorisee = localStorage.getItem(CLE_STOCKAGE)
    if (memorisee === 'ar' || memorisee === 'fr') return memorisee
  } catch {
    // stockage indisponible : on garde la langue par défaut
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
