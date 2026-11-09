import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { versCsv, telechargerCsv } from '@/lib/csv'
import { formaterDate, nomLocalise } from '@/lib/format'
import { TAILLE_PAGE, useListe } from '@/lib/useListe'
import { useBoutiques } from '@/lib/useBoutiques'
import { DataTable } from '@/components/DataTable'
import { Dialog } from '@/components/Dialog'
import { MessageErreur, TitrePage } from '@/components/ui'
import type { Tables } from '@/types/database'

type Entree = Tables<'journal_audit'>

export function AuditPage() {
  const { t, i18n } = useTranslation()
  const { parId } = useBoutiques()
  const [entite, setEntite] = useState('')
  const [du, setDu] = useState('')
  const [au, setAu] = useState('')
  const [detail, setDetail] = useState<Entree | null>(null)

  const requete = (a: number, b: number) => {
    let q = supabase.from('journal_audit').select('*', { count: 'exact' }).order('date_action', { ascending: false }).range(a, b)
    if (entite) q = q.eq('entite', entite)
    if (du) q = q.gte('date_action', `${du}T00:00:00Z`)
    if (au) q = q.lte('date_action', `${au}T23:59:59Z`)
    return q
  }
  const liste = useListe<Entree>(['audit', entite, du, au], requete)
  const nomBoutique = (id: string | null) => { const b = id ? parId.get(id) : undefined; return b ? nomLocalise(b, i18n.language) : '—' }

  async function exporter() {
    const { data } = await requete(0, 4999)
    telechargerCsv('journal_audit.csv', versCsv(
      ['date', 'boutique', 'utilisateur', 'action', 'entite', 'entite_id'],
      (data ?? []).map((e) => [e.date_action, nomBoutique(e.boutique_id), e.utilisateur_id, e.action, e.entite, e.entite_id]),
    ))
  }

  return (
    <>
      <TitrePage titre={t('audit.titre')}>
        <input className="input w-44" placeholder={t('audit.filtre_entite')} value={entite} onChange={(e) => { setEntite(e.target.value.trim()); liste.setPage(0) }} />
        <input className="input w-40" type="date" aria-label={t('audit.du')} value={du} onChange={(e) => { setDu(e.target.value); liste.setPage(0) }} />
        <input className="input w-40" type="date" aria-label={t('audit.au')} value={au} onChange={(e) => { setAu(e.target.value); liste.setPage(0) }} />
        <button className="btn" onClick={() => void exporter()}>{t('commun.export_csv')}</button>
      </TitrePage>
      <MessageErreur erreur={liste.erreur} />
      <DataTable
        colonnes={[
          { cle: 'date', titre: t('commun.date'), rendu: (e) => formaterDate(e.date_action, i18n.language, true) },
          { cle: 'boutique', titre: t('commun.boutique'), rendu: (e) => nomBoutique(e.boutique_id) },
          { cle: 'action', titre: t('audit.action'), rendu: (e) => e.action },
          { cle: 'entite', titre: t('audit.entite'), rendu: (e) => <span dir="ltr">{e.entite}</span> },
          { cle: 'actions', titre: t('audit.details'), rendu: (e) => <button className="btn" onClick={() => setDetail(e)}>{t('audit.details')}</button> },
        ]}
        lignes={liste.lignes} total={liste.total} page={liste.page} taillePage={TAILLE_PAGE} chargement={liste.chargement}
        onPage={liste.setPage} cleLigne={(e) => e.id}
      />
      {detail && (
        <Dialog titre={`${detail.action} — ${detail.entite}`} onFermer={() => setDetail(null)}>
          <pre dir="ltr" className="max-h-96 overflow-auto rounded-lg bg-fond p-3 text-xs">{JSON.stringify({ avant: detail.avant, apres: detail.apres, details: detail.details, utilisateur: detail.utilisateur_id }, null, 2)}</pre>
        </Dialog>
      )}
    </>
  )
}
