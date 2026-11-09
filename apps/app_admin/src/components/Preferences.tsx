import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { changerLangue, type Langue } from '@/i18n'

const CLE_THEME = 'admin.theme'

function themeInitial(): boolean {
  try {
    const memorise = localStorage.getItem(CLE_THEME)
    if (memorise) return memorise === 'sombre'
  } catch {
    // stockage indisponible
  }
  return window.matchMedia?.('(prefers-color-scheme: dark)').matches ?? false
}

/** Bascule de langue (AR/FR) et de thème (clair/sombre). */
export function Preferences() {
  const { t, i18n } = useTranslation()
  const [sombre, setSombre] = useState(themeInitial)

  useEffect(() => {
    document.documentElement.classList.toggle('dark', sombre)
    try {
      localStorage.setItem(CLE_THEME, sombre ? 'sombre' : 'clair')
    } catch {
      // préférence non mémorisée
    }
  }, [sombre])

  const autre: Langue = i18n.language === 'ar' ? 'fr' : 'ar'
  return (
    <div className="flex items-center gap-2">
      <button className="btn" onClick={() => void changerLangue(autre)} aria-label={t('commun.langue')}>
        {autre === 'ar' ? 'العربية' : 'Français'}
      </button>
      <button className="btn" onClick={() => setSombre((s) => !s)} aria-label={t('commun.theme')}>
        {sombre ? '☀' : '☾'}
      </button>
    </div>
  )
}
