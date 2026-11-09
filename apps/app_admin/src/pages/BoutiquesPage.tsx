import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { formaterDate, motifRecherche, nomLocalise } from '@/lib/format'
import { TAILLE_PAGE, useListe } from '@/lib/useListe'
import { DataTable } from '@/components/DataTable'
import { Dialog } from '@/components/Dialog'
import { MessageErreur, Statut, TitrePage } from '@/components/ui'
import type { Tables } from '@/types/database'

interface Quotas {
  produits: number
  utilisateurs: number
  commandes_30j: number
  limites: Record<string, number | boolean | null>
}

function FicheBoutique({ boutique, onFermer }: { boutique: Tables<'boutiques'>; onFermer: () => void }) {
  const { t, i18n } = useTranslation()
  const quotas = useQuery({
    queryKey: ['quotas', boutique.id],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('admin_quotas_boutique', { p_boutique: boutique.id })
      if (error) throw new Error(error.message)
      return data as unknown as Quotas
    },
  })
  const limite = (cle: string) => {
    const v = quotas.data?.limites[cle]
    return typeof v === 'number' ? v : t('boutiques.illimite')
  }
  return (
    <Dialog titre={`${t('boutiques.fiche')} — ${nomLocalise(boutique, i18n.language)}`} onFermer={onFermer}>
      <dl className="grid grid-cols-2 gap-2 text-sm">
        <dt className="text-discret">{t('boutiques.code_boutique')}</dt><dd dir="ltr">{boutique.code_boutique}</dd>
        <dt className="text-discret">{t('boutiques.sous_domaine')}</dt><dd dir="ltr">{boutique.slug}</dd>
        <dt className="text-discret">{t('commun.statut')}</dt><dd><Statut valeur={boutique.statut} /></dd>
        <dt className="text-discret">{t('commun.telephone')}</dt><dd dir="ltr">{boutique.telephone ?? '—'}</dd>
      </dl>
      <h3 className="mb-2 mt-4 font-semibold">{t('boutiques.quotas')}</h3>
      <MessageErreur erreur={quotas.error} />
      {quotas.data && (
        <ul className="space-y-1 text-sm">
          <li>{t('boutiques.produits')} : {quotas.data.produits} / {limite('produits')}</li>
          <li>{t('boutiques.utilisateurs')} : {quotas.data.utilisateurs} / {limite('utilisateurs')}</li>
          <li>{t('boutiques.commandes_30j')} : {quotas.data.commandes_30j}</li>
        </ul>
      )}
    </Dialog>
  )
}

export function BoutiquesPage() {
  const { t, i18n } = useTranslation()
  const queryClient = useQueryClient()
  const [recherche, setRecherche] = useState('')
  const [statut, setStatut] = useState('')
  const [fiche, setFiche] = useState<Tables<'boutiques'> | null>(null)

  const liste = useListe<Tables<'boutiques'>>(['boutiques', 'liste', recherche, statut], (a, b) => {
    let q = supabase.from('boutiques').select('*', { count: 'exact' }).order('cree_le', { ascending: false }).range(a, b)
    if (statut) q = q.eq('statut', statut as Tables<'boutiques'>['statut'])
    if (recherche) q = q.or(`nom_ar.ilike.${motifRecherche(recherche)},nom_fr.ilike.${motifRecherche(recherche)},slug.ilike.${motifRecherche(recherche)}`)
    return q
  })

  const changerStatut = useMutation({
    mutationFn: async ({ id, statut: nouveau }: { id: string; statut: Tables<'boutiques'>['statut'] }) => {
      const { error } = await supabase.from('boutiques').update({ statut: nouveau }).eq('id', id)
      if (error) throw new Error(error.message)
    },
    onSuccess: () => void queryClient.invalidateQueries({ queryKey: ['boutiques'] }),
  })

  return (
    <>
      <TitrePage titre={t('boutiques.titre')}>
        <input className="input w-56" placeholder={t('commun.rechercher')} value={recherche} onChange={(e) => { setRecherche(e.target.value); liste.setPage(0) }} />
        <select className="input w-44" value={statut} onChange={(e) => { setStatut(e.target.value); liste.setPage(0) }}>
          <option value="">{t('commun.tous')}</option>
          {['essai', 'actif', 'grace', 'suspendu', 'ferme'].map((s) => <option key={s} value={s}>{t(`statut.${s}`)}</option>)}
        </select>
      </TitrePage>
      <MessageErreur erreur={liste.erreur ?? (changerStatut.error as Error | null)} />
      <DataTable
        colonnes={[
          { cle: 'nom', titre: t('commun.boutique'), rendu: (b) => nomLocalise(b, i18n.language) },
          { cle: 'slug', titre: t('boutiques.sous_domaine'), rendu: (b) => <span dir="ltr">{b.slug}</span> },
          { cle: 'code', titre: t('boutiques.code_boutique'), rendu: (b) => <span dir="ltr">{b.code_boutique}</span> },
          { cle: 'statut', titre: t('commun.statut'), rendu: (b) => <Statut valeur={b.statut} /> },
          { cle: 'date', titre: t('commun.date'), rendu: (b) => formaterDate(b.cree_le, i18n.language) },
          {
            cle: 'actions', titre: t('commun.actions'), rendu: (b) => (
              <div className="flex gap-2">
                <button className="btn" onClick={() => setFiche(b)}>{t('boutiques.fiche')}</button>
                {b.statut === 'suspendu' || b.statut === 'ferme' ? (
                  <button className="btn" onClick={() => changerStatut.mutate({ id: b.id, statut: 'actif' })}>{t('boutiques.reactiver')}</button>
                ) : (
                  <button className="btn" onClick={() => window.confirm(t('boutiques.confirmation_suspension')) && changerStatut.mutate({ id: b.id, statut: 'suspendu' })}>
                    {t('boutiques.suspendre')}
                  </button>
                )}
              </div>
            ),
          },
        ]}
        lignes={liste.lignes} total={liste.total} page={liste.page} taillePage={TAILLE_PAGE} chargement={liste.chargement}
        onPage={liste.setPage} cleLigne={(b) => b.id}
      />
      {fiche && <FicheBoutique boutique={fiche} onFermer={() => setFiche(null)} />}
    </>
  )
}
