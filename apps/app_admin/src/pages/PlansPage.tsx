import { useState, type FormEvent } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { formaterMontant, nomLocalise } from '@/lib/format'
import { usePlans } from '@/lib/useBoutiques'
import { useAuth } from '@/features/auth/AuthProvider'
import { Dialog } from '@/components/Dialog'
import { Champ, MessageErreur, TitrePage } from '@/components/ui'
import type { Json, Tables, TablesInsert } from '@/types/database'

type Plan = Tables<'plans'>
const LIMITES_NOMBRE = ['utilisateurs', 'produits', 'stockage_mo', 'themes'] as const
const LIMITES_BOOLEEN = ['boutique_en_ligne', 'domaine_personnalise', 'rapports_avances'] as const

function nombreOuNull(saisie: string): number | null {
  return saisie.trim() === '' ? null : Number(saisie)
}

function FormulairePlan({ plan, onFini }: { plan: Plan | null; onFini: () => void }) {
  const { t } = useTranslation()
  const queryClient = useQueryClient()
  const limites = (plan?.limites ?? {}) as Record<string, number | boolean | null>
  const [v, setV] = useState({
    code: plan?.code ?? '', nom_ar: plan?.nom_ar ?? '', nom_fr: plan?.nom_fr ?? '',
    prix_mensuel: String(plan?.prix_mensuel ?? 0), prix_annuel: String(plan?.prix_annuel ?? 0),
    duree: plan?.duree_essai_jours ? String(plan.duree_essai_jours) : '', ordre: String(plan?.ordre ?? 0), actif: plan?.actif ?? true,
    ...Object.fromEntries(LIMITES_NOMBRE.map((k) => [k, limites[k] == null ? '' : String(limites[k])])),
    ...Object.fromEntries(LIMITES_BOOLEEN.map((k) => [k, limites[k] === true])),
  } as Record<string, string | boolean>)
  const texte = (k: string) => String(v[k])
  const maj = (k: string) => (e: { target: { value: string } }) => setV((x) => ({ ...x, [k]: e.target.value }))

  const sauver = useMutation({
    mutationFn: async () => {
      const limitesPlan: Record<string, number | boolean | null> = {}
      for (const k of LIMITES_NOMBRE) limitesPlan[k] = nombreOuNull(texte(k))
      for (const k of LIMITES_BOOLEEN) limitesPlan[k] = v[k] === true
      const valeurs: TablesInsert<'plans'> = {
        code: texte('code'), nom_ar: texte('nom_ar'), nom_fr: texte('nom_fr'),
        prix_mensuel: Number(v.prix_mensuel), prix_annuel: Number(v.prix_annuel),
        duree_essai_jours: nombreOuNull(texte('duree')), ordre: Number(v.ordre), actif: v.actif === true,
        limites: limitesPlan as Json,
      }
      const { error } = plan ? await supabase.from('plans').update(valeurs).eq('id', plan.id) : await supabase.from('plans').insert(valeurs)
      if (error) throw new Error(error.message)
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['plans'] })
      onFini()
    },
  })
  const soumettre = (e: FormEvent) => {
    e.preventDefault()
    sauver.mutate()
  }

  return (
    <form onSubmit={soumettre} className="grid grid-cols-2 gap-3">
      <Champ etiquette={t('commun.code')}><input className="input" dir="ltr" required pattern="[a-z0-9_]+" value={texte('code')} onChange={maj('code')} /></Champ>
      <Champ etiquette={t('commun.ordre')}><input className="input" type="number" value={texte('ordre')} onChange={maj('ordre')} /></Champ>
      <Champ etiquette={t('commun.nom_ar')}><input className="input" required value={texte('nom_ar')} onChange={maj('nom_ar')} /></Champ>
      <Champ etiquette={t('commun.nom_fr')}><input className="input" required value={texte('nom_fr')} onChange={maj('nom_fr')} /></Champ>
      <Champ etiquette={t('plans.prix_mensuel')}><input className="input" type="number" min="0" value={texte('prix_mensuel')} onChange={maj('prix_mensuel')} /></Champ>
      <Champ etiquette={t('plans.prix_annuel')}><input className="input" type="number" min="0" value={texte('prix_annuel')} onChange={maj('prix_annuel')} /></Champ>
      <Champ etiquette={t('plans.duree_essai')}><input className="input" type="number" min="1" value={texte('duree')} onChange={maj('duree')} /></Champ>
      <label className="flex items-center gap-2 pt-6"><input type="checkbox" checked={v.actif === true} onChange={(e) => setV((x) => ({ ...x, actif: e.target.checked }))} />{t('commun.actif')}</label>
      <h3 className="col-span-2 font-semibold">{t('plans.limites')} <span className="text-xs font-normal text-discret">({t('plans.vide_illimite')})</span></h3>
      {LIMITES_NOMBRE.map((k) => (
        <Champ key={k} etiquette={t(`plans.lim_${k === 'stockage_mo' ? 'stockage' : k}`)}>
          <input className="input" type="number" min="0" value={texte(k)} onChange={maj(k)} />
        </Champ>
      ))}
      {LIMITES_BOOLEEN.map((k) => (
        <label key={k} className="flex items-center gap-2">
          <input type="checkbox" checked={v[k] === true} onChange={(e) => setV((x) => ({ ...x, [k]: e.target.checked }))} />{t(`plans.lim_${k}`)}
        </label>
      ))}
      <MessageErreur erreur={sauver.error as Error | null} />
      <div className="col-span-2 flex justify-end"><button className="btn btn-primaire" disabled={sauver.isPending}>{t('commun.enregistrer')}</button></div>
    </form>
  )
}

export function PlansPage() {
  const { t, i18n } = useTranslation()
  const { role } = useAuth()
  const { plans, chargement } = usePlans()
  const [edition, setEdition] = useState<Plan | 'nouveau' | null>(null)
  const ecriture = role === 'super_admin'

  return (
    <>
      <TitrePage titre={t('plans.titre')}>
        {ecriture && <button className="btn btn-primaire" onClick={() => setEdition('nouveau')}>{t('plans.nouveau')}</button>}
      </TitrePage>
      {chargement && <p className="text-discret">{t('commun.chargement')}</p>}
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
        {plans.map((p) => (
          <div key={p.id} className="carte space-y-2">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold">{nomLocalise(p, i18n.language)}</h2>
              <span className="text-xs text-discret" dir="ltr">{p.code}{p.actif ? '' : ' · off'}</span>
            </div>
            <p>{formaterMontant(p.prix_mensuel, p.devise, i18n.language)} / {t('plans.prix_mensuel').toLowerCase()}</p>
            <p className="text-sm text-discret">{formaterMontant(p.prix_annuel, p.devise, i18n.language)} / {t('plans.prix_annuel').toLowerCase()}</p>
            <ul className="text-sm text-discret">
              {Object.entries(p.limites as Record<string, number | boolean | null>).map(([k, val]) => (
                <li key={k}>{k} : {val === null ? '∞' : String(val)}</li>
              ))}
            </ul>
            {ecriture && <button className="btn" onClick={() => setEdition(p)}>{t('commun.modifier')}</button>}
          </div>
        ))}
      </div>
      {edition && (
        <Dialog titre={edition === 'nouveau' ? t('plans.nouveau') : nomLocalise(edition, i18n.language)} onFermer={() => setEdition(null)}>
          <FormulairePlan plan={edition === 'nouveau' ? null : edition} onFini={() => setEdition(null)} />
        </Dialog>
      )}
    </>
  )
}
