import { useState, type FormEvent } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { formaterDate, formaterMontant, nomLocalise } from '@/lib/format'
import { TAILLE_PAGE, useListe } from '@/lib/useListe'
import { useBoutiques, usePlans } from '@/lib/useBoutiques'
import { DataTable } from '@/components/DataTable'
import { Dialog } from '@/components/Dialog'
import { Champ, MessageErreur, Statut, TitrePage } from '@/components/ui'
import type { Tables } from '@/types/database'

type Paiement = Tables<'paiements_abonnement'>
const MODES: Paiement['mode'][] = ['especes', 'virement', 'mobile_money']

function nomFichierSur(nom: string): string {
  return nom.normalize('NFD').replace(/[^\w.-]+/g, '_')
}

function FormulairePaiement({ onFini }: { onFini: () => void }) {
  const { t, i18n } = useTranslation()
  const queryClient = useQueryClient()
  const { parId } = useBoutiques()
  const { parId: plansParId } = usePlans()
  const abonnements = useQuery({
    queryKey: ['abonnements', 'paiement'],
    queryFn: async () => {
      const { data, error } = await supabase.from('abonnements').select('*').neq('statut', 'annule').order('fin_le')
      if (error) throw new Error(error.message)
      return data
    },
  })
  const [v, setV] = useState({ abonnement: '', montant: '', mode: 'especes' as Paiement['mode'], reference: '', periode: '1' })
  const [fichier, setFichier] = useState<File | null>(null)

  const enregistrer = useMutation({
    mutationFn: async () => {
      const abonnement = abonnements.data?.find((a) => a.id === v.abonnement)
      if (!abonnement) throw new Error('abonnement')
      let chemin: string | undefined
      if (fichier) {
        chemin = `${abonnement.boutique_id}/abonnement/${crypto.randomUUID()}-${nomFichierSur(fichier.name)}`
        const { error } = await supabase.storage.from('payment-proofs').upload(chemin, fichier, { contentType: fichier.type })
        if (error) throw new Error(error.message)
      }
      const { error } = await supabase.rpc('enregistrer_paiement_abonnement', {
        p_abonnement_id: abonnement.id, p_montant: Number(v.montant), p_mode: v.mode,
        p_reference: v.reference || undefined, p_justificatif_url: chemin, p_periode_mois: Number(v.periode),
      })
      if (error) throw new Error(error.message)
    },
    onSuccess: () => {
      void queryClient.invalidateQueries()
      onFini()
    },
  })
  const soumettre = (e: FormEvent) => {
    e.preventDefault()
    enregistrer.mutate()
  }

  return (
    <form onSubmit={soumettre} className="grid grid-cols-2 gap-3">
      <div className="col-span-2">
        <Champ etiquette={t('paiements.abonnement')}>
          <select className="input" required value={v.abonnement} onChange={(e) => setV({ ...v, abonnement: e.target.value })}>
            <option value="" />
            {(abonnements.data ?? []).map((a) => {
              const b = parId.get(a.boutique_id)
              const p = plansParId.get(a.plan_id)
              return <option key={a.id} value={a.id}>{b ? nomLocalise(b, i18n.language) : a.boutique_id.slice(0, 8)} — {p ? nomLocalise(p, i18n.language) : ''} ({t(`statut.${a.statut}`)})</option>
            })}
          </select>
        </Champ>
      </div>
      <Champ etiquette={t('commun.montant')}><input className="input" type="number" min="1" required value={v.montant} onChange={(e) => setV({ ...v, montant: e.target.value })} /></Champ>
      <Champ etiquette={t('paiements.periode_mois')}><input className="input" type="number" min="1" max="36" required value={v.periode} onChange={(e) => setV({ ...v, periode: e.target.value })} /></Champ>
      <Champ etiquette={t('paiements.mode')}>
        <select className="input" value={v.mode} onChange={(e) => setV({ ...v, mode: e.target.value as Paiement['mode'] })}>
          {MODES.map((m) => <option key={m} value={m}>{t(`mode.${m}`)}</option>)}
        </select>
      </Champ>
      <Champ etiquette={t('paiements.reference')}><input className="input" dir="ltr" value={v.reference} onChange={(e) => setV({ ...v, reference: e.target.value })} /></Champ>
      <div className="col-span-2">
        <Champ etiquette={t('paiements.justificatif')}>
          <input className="input" type="file" accept="image/jpeg,image/png,image/webp,application/pdf" onChange={(e) => setFichier(e.target.files?.[0] ?? null)} />
        </Champ>
      </div>
      <div className="col-span-2"><MessageErreur erreur={enregistrer.error as Error | null} /></div>
      <div className="col-span-2 flex justify-end"><button className="btn btn-primaire" disabled={enregistrer.isPending}>{t('commun.valider')}</button></div>
    </form>
  )
}

export function PaiementsPage() {
  const { t, i18n } = useTranslation()
  const { parId } = useBoutiques()
  const { parId: plansParId } = usePlans()
  const [creation, setCreation] = useState(false)

  const liste = useListe<Paiement>(['paiements_abonnement'], (a, b) =>
    supabase.from('paiements_abonnement').select('*', { count: 'exact' }).order('paye_le', { ascending: false }).range(a, b))

  const impayes = useQuery({
    queryKey: ['abonnements', 'impayes'],
    queryFn: async () => {
      const { data, error } = await supabase.from('abonnements').select('*').in('statut', ['grace', 'suspendu', 'expire']).order('fin_le').limit(10)
      if (error) throw new Error(error.message)
      return data
    },
  })

  async function ouvrirJustificatif(chemin: string) {
    const { data } = await supabase.storage.from('payment-proofs').createSignedUrl(chemin, 60)
    if (data?.signedUrl) window.open(data.signedUrl, '_blank')
  }

  async function recu(p: Paiement) {
    const [{ ouvrirRecu }, abonnement] = await Promise.all([
      import('@/features/paiements/RecuPdf'),
      supabase.from('abonnements').select('plan_id').eq('id', p.abonnement_id).maybeSingle(),
    ])
    const boutique = parId.get(p.boutique_id)
    const plan = abonnement.data ? plansParId.get(abonnement.data.plan_id) : undefined
    await ouvrirRecu({
      numero: p.id.slice(0, 8).toUpperCase(), date: formaterDate(p.paye_le, i18n.language),
      boutique: boutique ? `${boutique.nom_fr ?? ''} ${boutique.nom_ar ?? ''}`.trim() : '', plan: plan ? `${plan.nom_fr} / ${plan.nom_ar}` : '',
      montant: formaterMontant(p.montant, p.devise, i18n.language), mode: t(`mode.${p.mode}`), reference: p.reference, periodeMois: p.periode_mois,
      libelles: {
        titre: t('paiements.recu'), boutique: t('commun.boutique'), plan: t('commun.plan'), montant: t('commun.montant'), mode: t('paiements.mode'),
        reference: t('paiements.reference'), periode: t('paiements.periode_mois'), date: t('paiements.paye_le'),
      },
    })
  }

  return (
    <>
      <TitrePage titre={t('paiements.titre')}>
        <button className="btn btn-primaire" onClick={() => setCreation(true)}>{t('paiements.nouveau')}</button>
      </TitrePage>
      {(impayes.data?.length ?? 0) > 0 && (
        <div className="carte mb-4">
          <h2 className="mb-2 font-semibold">{t('paiements.impayes')}</h2>
          <ul className="space-y-1 text-sm">
            {impayes.data?.map((a) => {
              const b = parId.get(a.boutique_id)
              return <li key={a.id} className="flex items-center gap-2"><Statut valeur={a.statut} /> {b ? nomLocalise(b, i18n.language) : a.boutique_id.slice(0, 8)} · {formaterDate(a.fin_le, i18n.language)}</li>
            })}
          </ul>
        </div>
      )}
      <MessageErreur erreur={liste.erreur} />
      <DataTable
        colonnes={[
          { cle: 'boutique', titre: t('commun.boutique'), rendu: (p) => { const b = parId.get(p.boutique_id); return b ? nomLocalise(b, i18n.language) : p.boutique_id.slice(0, 8) } },
          { cle: 'montant', titre: t('commun.montant'), rendu: (p) => formaterMontant(p.montant, p.devise, i18n.language) },
          { cle: 'mode', titre: t('paiements.mode'), rendu: (p) => t(`mode.${p.mode}`) },
          { cle: 'ref', titre: t('paiements.reference'), rendu: (p) => <span dir="ltr">{p.reference ?? '—'}</span> },
          { cle: 'date', titre: t('paiements.paye_le'), rendu: (p) => formaterDate(p.paye_le, i18n.language) },
          {
            cle: 'actions', titre: t('commun.actions'), rendu: (p) => (
              <div className="flex gap-2">
                <button className="btn" onClick={() => void recu(p)}>{t('paiements.recu')}</button>
                {p.justificatif_url && <button className="btn" onClick={() => void ouvrirJustificatif(p.justificatif_url!)}>{t('paiements.justificatif')}</button>}
              </div>
            ),
          },
        ]}
        lignes={liste.lignes} total={liste.total} page={liste.page} taillePage={TAILLE_PAGE} chargement={liste.chargement}
        onPage={liste.setPage} cleLigne={(p) => p.id}
      />
      {creation && (
        <Dialog titre={t('paiements.nouveau')} onFermer={() => setCreation(false)}>
          <FormulairePaiement onFini={() => setCreation(false)} />
        </Dialog>
      )}
    </>
  )
}
