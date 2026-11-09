import type { ReactNode } from 'react'
import { useTranslation } from 'react-i18next'

const COULEURS: Record<string, string> = {
  actif: 'bg-succes/15 text-succes',
  active: 'bg-succes/15 text-succes',
  verifie: 'bg-succes/15 text-succes',
  essai: 'bg-primaire/15 text-primaire',
  en_attente: 'bg-alerte/15 text-alerte',
  grace: 'bg-alerte/15 text-alerte',
  suspendu: 'bg-danger/15 text-danger',
  expire: 'bg-danger/15 text-danger',
  desactivee: 'bg-danger/15 text-danger',
  erreur: 'bg-danger/15 text-danger',
}

/** Pastille de statut traduite (clé `statut.*`). */
export function Statut({ valeur }: { valeur: string }) {
  const { t } = useTranslation()
  return (
    <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${COULEURS[valeur] ?? 'bg-fond text-discret'}`}>
      {t(`statut.${valeur}`, { defaultValue: valeur })}
    </span>
  )
}

export function Champ({ etiquette, children }: { etiquette: string; children: ReactNode }) {
  return (
    <label className="block">
      <span className="etiquette">{etiquette}</span>
      {children}
    </label>
  )
}

export function TitrePage({ titre, children }: { titre: string; children?: ReactNode }) {
  return (
    <div className="mb-4 flex flex-wrap items-center justify-between gap-2">
      <h1 className="text-2xl font-bold">{titre}</h1>
      <div className="flex flex-wrap items-center gap-2">{children}</div>
    </div>
  )
}

export function MessageErreur({ erreur }: { erreur: Error | null }) {
  const { t } = useTranslation()
  return erreur ? <p role="alert" className="mb-3 text-sm text-danger">{t('commun.erreur')} ({erreur.message})</p> : null
}
