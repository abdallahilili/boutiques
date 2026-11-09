import { useState, type FormEvent } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { invoquerFonction } from '@/lib/fonctions'
import { formaterDate, nomLocalise } from '@/lib/format'
import { TAILLE_PAGE, useListe } from '@/lib/useListe'
import { useBoutiques, usePlans } from '@/lib/useBoutiques'
import { DataTable } from '@/components/DataTable'
import { Champ, MessageErreur, TitrePage } from '@/components/ui'
import type { Tables } from '@/types/database'

type Cible = 'tous' | 'boutique' | 'plan'

export function NotificationsPage() {
  const { t, i18n } = useTranslation()
  const queryClient = useQueryClient()
  const { boutiques } = useBoutiques()
  const { plans } = usePlans()
  const [cible, setCible] = useState<Cible>('tous')
  const [cibleId, setCibleId] = useState('')
  const [v, setV] = useState({ titre_ar: '', titre_fr: '', corps_ar: '', corps_fr: '' })
  const [resultat, setResultat] = useState<string | null>(null)

  const envoi = useMutation({
    mutationFn: () => invoquerFonction<{ destinataires: number; push: { statut: string } }>('send-notification', {
      cible: { type: cible, id: cible === 'tous' ? undefined : cibleId }, ...v,
    }),
    onSuccess: (r) => {
      setResultat(`${t('notifications.envoyee', { n: r.destinataires })}${r.push.statut === 'non_configure' ? ` — ${t('notifications.push_non_configure')}` : ''}`)
      void queryClient.invalidateQueries({ queryKey: ['notifications'] })
    },
  })
  const soumettre = (e: FormEvent) => {
    e.preventDefault()
    setResultat(null)
    envoi.mutate()
  }

  const historique = useListe<Tables<'notifications'>>(['notifications'], (a, b) =>
    supabase.from('notifications').select('*', { count: 'exact' }).not('cree_par', 'is', null).order('cree_le', { ascending: false }).range(a, b))

  return (
    <>
      <TitrePage titre={t('notifications.titre')} />
      <form onSubmit={soumettre} className="carte mb-6 grid grid-cols-1 gap-3 md:grid-cols-2">
        <Champ etiquette={t('notifications.cible')}>
          <select className="input" value={cible} onChange={(e) => { setCible(e.target.value as Cible); setCibleId('') }}>
            <option value="tous">{t('notifications.cible_tous')}</option>
            <option value="boutique">{t('notifications.cible_boutique')}</option>
            <option value="plan">{t('notifications.cible_plan')}</option>
          </select>
        </Champ>
        {cible !== 'tous' && (
          <Champ etiquette={cible === 'boutique' ? t('commun.boutique') : t('commun.plan')}>
            <select className="input" required value={cibleId} onChange={(e) => setCibleId(e.target.value)}>
              <option value="" />
              {(cible === 'boutique' ? boutiques : plans).map((x) => <option key={x.id} value={x.id}>{nomLocalise(x, i18n.language)}</option>)}
            </select>
          </Champ>
        )}
        <Champ etiquette={t('notifications.titre_ar')}><input className="input" value={v.titre_ar} onChange={(e) => setV({ ...v, titre_ar: e.target.value })} /></Champ>
        <Champ etiquette={t('notifications.titre_fr')}><input className="input" value={v.titre_fr} onChange={(e) => setV({ ...v, titre_fr: e.target.value })} /></Champ>
        <Champ etiquette={t('notifications.corps_ar')}><textarea className="input" rows={3} value={v.corps_ar} onChange={(e) => setV({ ...v, corps_ar: e.target.value })} /></Champ>
        <Champ etiquette={t('notifications.corps_fr')}><textarea className="input" rows={3} value={v.corps_fr} onChange={(e) => setV({ ...v, corps_fr: e.target.value })} /></Champ>
        <div className="md:col-span-2">
          <MessageErreur erreur={envoi.error as Error | null} />
          {resultat && <p role="status" className="text-sm text-succes">{resultat}</p>}
        </div>
        <div className="flex justify-end md:col-span-2"><button className="btn btn-primaire" disabled={envoi.isPending}>{t('notifications.envoyer')}</button></div>
      </form>
      <h2 className="mb-2 font-semibold">{t('notifications.historique')}</h2>
      <MessageErreur erreur={historique.erreur} />
      <DataTable
        colonnes={[
          { cle: 'date', titre: t('commun.date'), rendu: (n) => formaterDate(n.cree_le, i18n.language, true) },
          { cle: 'titre', titre: t('notifications.titre'), rendu: (n) => (i18n.language === 'ar' ? n.titre_ar ?? n.titre_fr : n.titre_fr ?? n.titre_ar) },
          { cle: 'cible', titre: t('notifications.cible'), rendu: (n) => n.cible },
        ]}
        lignes={historique.lignes} total={historique.total} page={historique.page} taillePage={TAILLE_PAGE} chargement={historique.chargement}
        onPage={historique.setPage} cleLigne={(n) => n.id}
      />
    </>
  )
}
