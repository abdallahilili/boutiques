import { useEffect, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'

interface Props {
  titre: string
  onFermer: () => void
  children: ReactNode
}

/** Fenêtre modale accessible (Échap pour fermer, clic sur le fond). */
export function Dialog({ titre, onFermer, children }: Props) {
  const { t } = useTranslation()
  useEffect(() => {
    const surTouche = (e: KeyboardEvent) => e.key === 'Escape' && onFermer()
    document.addEventListener('keydown', surTouche)
    return () => document.removeEventListener('keydown', surTouche)
  }, [onFermer])

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" onMouseDown={onFermer}>
      <div role="dialog" aria-modal="true" aria-label={titre} className="carte max-h-[90vh] w-full max-w-lg overflow-y-auto"
        onMouseDown={(e) => e.stopPropagation()}>
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-bold">{titre}</h2>
          <button className="btn" onClick={onFermer} aria-label={t('commun.fermer')}>✕</button>
        </div>
        {children}
      </div>
    </div>
  )
}
