import { useState, type FormEvent } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { formaterDate, nomLocalise } from '@/lib/format'
import { TAILLE_PAGE, useListe } from '@/lib/useListe'
import { useBoutiques, usePlans } from '@/lib/useBoutiques'
import { DataTable } from '@/components/DataTable'
import { Dialog } from '@/components/Dialog'
import { Champ, MessageErreur, Statut, TitrePage } from '@/components/ui'
import type { Tables } from '@/types/database'

type Abonnement = Tables<'abonnements'>
const STATUTS: Abonnement['statut'][] = ['essai', 'actif', 'grace', 'suspendu', 'expire', 'annule']

function joursRestants(fin: string | null): number | null {
  return fin ? Math.ceil((new Date(fin).getTime() - Date.now()) / 86_400_000) : null
}

function FormulaireAbonnement({ abonnement, onFini }: { abonnement: Abonnement; onFini: () => void }) {
  const { t, i18n } = useTranslation()
  const queryClient = useQueryClient()
  const { plans } = usePlans()
  const [v, setV] = useState({
    plan_id: abonnement.plan_id, statut: abonnement.statut, fin_le: abonnement.fin_le ?? '',
    grace_jusqu_au: abonnement.grace_jusqu_au ?? '', remise: String(abonnement.remise), renouvellement_auto: abonnement.renouvellement_auto,
  })
  const sauver = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from('abonnements').update({
        plan_id: v.plan_id, statut: v.statut, fin_le: v.fin_le || null, grace_jusqu_au: v.grace_jusqu_au || null,
        remise: Number(v.remise), renouvellement_auto: v.renouvellement_auto,
      }).eq('id', abonnement.id)
      if (error) throw new Error(error.message)
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['abonnements'] })
      onFini()
    },
  })
  const soumettre = (e: FormEvent) => {
    e.preventDefault()
    sauver.mutate()
  }
  return (
    <form onSubmit={soumettre} className="grid grid-cols-2 gap-3">
      <Champ etiquette={t('commun.plan')}>
        <select className="input" value={v.plan_id} onChange={(e) => setV({ ...v, plan_id: e.target.value })}>
          {plans.map((p) => <option key={p.id} value={p.id}>{nomLocalise(p, i18n.language)}</option>)}
        </select>
      </Champ>
      <Champ etiquette={t('commun.statut')}>
        <select className="input" value={v.statut} onChange={(e) => setV({ ...v, statut: e.target.value as Abonnement['statut'] })}>
          {STATUTS.map((s) => <option key={s} value={s}>{t(`statut.${s}`)}</option>)}
        </select>
      </Champ>
      <Champ etiquette={t('abonnements.fin')}><input className="input" type="date" value={v.fin_le} onChange={(e) => setV({ ...v, fin_le: e.target.value })} /></Champ>
      <Champ etiquette={t('abonnements.grace')}><input className="input" type="date" value={v.grace_jusqu_au} onChange={(e) => setV({ ...v, grace_jusqu_au: e.target.value })} /></Champ>
      <Champ etiquette={t('abonnements.remise')}><input className="input" type="number" min="0" value={v.remise} onChange={(e) => setV({ ...v, remise: e.target.value })} /></Champ>
      <label className="flex items-center gap-2 pt-6">
        <input type="checkbox" checked={v.renouvellement_auto} onChange={(e) => setV({ ...v, renouvellement_auto: e.target.checked })} />{t('abonnements.renouvellement')}
      </label>
      <div className="col-span-2"><MessageErreur erreur={sauver.error as Error | null} /></div>
      <div className="col-span-2 flex justify-end"><button className="btn btn-primaire" disabled={sauver.isPending}>{t('commun.enregistrer')}</button></div>
    </form>
  )
}

export function AbonnementsPage() {
  const { t, i18n } = useTranslation()
  const { parId } = useBoutiques()
  const { parId: plansParId } = usePlans()
  const [statut, setStatut] = useState('')
  const [edition, setEdition] = useState<Abonnement | null>(null)

  const liste = useListe<Abonnement>(['abonnements', statut], (a, b) => {
    let q = supabase.from('abonnements').select('*', { count: 'exact' }).order('fin_le', { ascending: true, nullsFirst: false }).range(a, b)
    if (statut) q = q.eq('statut', statut as Abonnement['statut'])
    return q
  })

  return (
    <>
      <TitrePage titre={t('abonnements.titre')}>
        <select className="input w-44" value={statut} onChange={(e) => { setStatut(e.target.value); liste.setPage(0) }}>
          <option value="">{t('commun.tous')}</option>
          {STATUTS.map((s) => <option key={s} value={s}>{t(`statut.${s}`)}</option>)}
        </select>
      </TitrePage>
      <MessageErreur erreur={liste.erreur} />
      <DataTable
        colonnes={[
          { cle: 'boutique', titre: t('commun.boutique'), rendu: (a) => { const b = parId.get(a.boutique_id); return b ? nomLocalise(b, i18n.language) : a.boutique_id.slice(0, 8) } },
          { cle: 'plan', titre: t('commun.plan'), rendu: (a) => { const p = plansParId.get(a.plan_id); return p ? nomLocalise(p, i18n.language) : '—' } },
          { cle: 'statut', titre: t('commun.statut'), rendu: (a) => <Statut valeur={a.statut} /> },
          { cle: 'debut', titre: t('abonnements.debut'), rendu: (a) => formaterDate(a.debut_le, i18n.language) },
          {
            cle: 'fin', titre: t('abonnements.fin'), rendu: (a) => {
              const j = joursRestants(a.fin_le)
              const bientot = j !== null && j >= 0 && j <= 7 && ['essai', 'actif'].includes(a.statut)
              return <span className={bientot ? 'font-semibold text-alerte' : ''}>{formaterDate(a.fin_le, i18n.language)}{bientot && ` · ${t('abonnements.expire_bientot')}`}</span>
            },
          },
          { cle: 'actions', titre: t('commun.actions'), rendu: (a) => <button className="btn" onClick={() => setEdition(a)}>{t('commun.modifier')}</button> },
        ]}
        lignes={liste.lignes} total={liste.total} page={liste.page} taillePage={TAILLE_PAGE} chargement={liste.chargement}
        onPage={liste.setPage} cleLigne={(a) => a.id}
      />
      {edition && (
        <Dialog titre={t('abonnements.titre')} onFermer={() => setEdition(null)}>
          <FormulaireAbonnement abonnement={edition} onFini={() => setEdition(null)} />
        </Dialog>
      )}
    </>
  )
}
