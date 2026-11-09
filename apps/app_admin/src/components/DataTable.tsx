import type { ReactNode } from 'react'
import { useTranslation } from 'react-i18next'

export interface Colonne<T> {
  cle: string
  titre: string
  rendu: (ligne: T) => ReactNode
}

interface Props<T> {
  colonnes: Colonne<T>[]
  lignes: T[]
  total: number
  page: number
  taillePage: number
  chargement: boolean
  onPage: (page: number) => void
  cleLigne: (ligne: T) => string
}

/** Tableau paginé côté serveur (la pagination et les filtres sont appliqués par la requête). */
export function DataTable<T>({ colonnes, lignes, total, page, taillePage, chargement, onPage, cleLigne }: Props<T>) {
  const { t } = useTranslation()
  const pages = Math.max(1, Math.ceil(total / taillePage))
  return (
    <div className="carte overflow-x-auto p-0">
      <table className="table-donnees">
        <thead>
          <tr>{colonnes.map((c) => <th key={c.cle}>{c.titre}</th>)}</tr>
        </thead>
        <tbody>
          {lignes.map((ligne) => (
            <tr key={cleLigne(ligne)}>{colonnes.map((c) => <td key={c.cle}>{c.rendu(ligne)}</td>)}</tr>
          ))}
          {!chargement && lignes.length === 0 && (
            <tr><td colSpan={colonnes.length} className="py-8 text-center text-discret">{t('commun.aucun_resultat')}</td></tr>
          )}
        </tbody>
      </table>
      <div className="flex items-center justify-between gap-2 p-3 text-sm text-discret">
        <span>{chargement ? t('commun.chargement') : `${total} ${t('commun.total')}`}</span>
        <div className="flex items-center gap-2">
          <button className="btn" disabled={page <= 0} onClick={() => onPage(page - 1)}>{t('commun.precedent')}</button>
          <span>{page + 1} / {pages}</span>
          <button className="btn" disabled={page + 1 >= pages} onClick={() => onPage(page + 1)}>{t('commun.suivant')}</button>
        </div>
      </div>
    </div>
  )
}
