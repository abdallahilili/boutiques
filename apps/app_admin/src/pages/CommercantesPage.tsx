import { useState, type FormEvent } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { ErreurFonction, invoquerFonction } from '@/lib/fonctions'
import { formaterDate, motifRecherche, nomLocalise } from '@/lib/format'
import { TAILLE_PAGE, useListe } from '@/lib/useListe'
import { useAuth } from '@/features/auth/AuthProvider'
import { DataTable } from '@/components/DataTable'
import { Dialog } from '@/components/Dialog'
import { Champ, MessageErreur, Statut, TitrePage } from '@/components/ui'
import type { Tables } from '@/types/database'

interface CodeAffiche {
  telephone: string
  code: string
  lien: string
}

function CodeInitial({ code, onFermer }: { code: CodeAffiche; onFermer: () => void }) {
  const { t } = useTranslation()
  return (
    <Dialog titre={t('commercantes.creee')} onFermer={onFermer}>
      <p className="mb-3 text-sm text-discret">{t('commercantes.code_info')}</p>
      <p className="etiquette">{t('commercantes.code_initial')}</p>
      <p className="mb-1 text-center text-4xl font-bold tracking-widest" dir="ltr">{code.code}</p>
      <p className="mb-4 text-center text-sm text-discret" dir="ltr">{code.telephone}</p>
      <div className="flex justify-end gap-2">
        <a className="btn btn-primaire" href={code.lien} target="_blank" rel="noreferrer">{t('commercantes.whatsapp_envoyer')}</a>
        <button className="btn" onClick={onFermer}>{t('commun.fermer')}</button>
      </div>
    </Dialog>
  )
}

function FormulaireCreation({ onFini }: { onFini: (code: CodeAffiche) => void }) {
  const { t } = useTranslation()
  const queryClient = useQueryClient()
  const [valeurs, setValeurs] = useState({ telephone: '', nom_ar: '', nom_fr: '', ville: '', whatsapp: '', notes: '', b_nom_ar: '', b_nom_fr: '', b_activite: '', b_slug: '' })
  const maj = (cle: keyof typeof valeurs) => (e: { target: { value: string } }) => setValeurs((v) => ({ ...v, [cle]: e.target.value }))

  const creation = useMutation({
    mutationFn: () => invoquerFonction<{ telephone: string; code_initial: string; lien_whatsapp: string }>('admin-create-merchant', {
      telephone: valeurs.telephone, nom_ar: valeurs.nom_ar, nom_fr: valeurs.nom_fr, ville: valeurs.ville, whatsapp: valeurs.whatsapp, notes: valeurs.notes,
      boutique: { nom_ar: valeurs.b_nom_ar, nom_fr: valeurs.b_nom_fr, type_activite: valeurs.b_activite, slug: valeurs.b_slug },
    }),
    onSuccess: (r) => {
      void queryClient.invalidateQueries({ queryKey: ['commercantes'] })
      void queryClient.invalidateQueries({ queryKey: ['boutiques'] })
      onFini({ telephone: r.telephone, code: r.code_initial, lien: r.lien_whatsapp })
    },
  })

  function soumettre(e: FormEvent) {
    e.preventDefault()
    creation.mutate()
  }
  const erreur = creation.error instanceof ErreurFonction && creation.error.code === 'telephone_deja_utilise'
    ? t('commercantes.telephone_utilise') : creation.error ? t('commun.erreur') : null

  return (
    <form onSubmit={soumettre} className="grid grid-cols-1 gap-3 sm:grid-cols-2">
      <Champ etiquette={t('commun.telephone')}><input className="input" dir="ltr" required value={valeurs.telephone} onChange={maj('telephone')} /></Champ>
      <Champ etiquette={t('commercantes.whatsapp')}><input className="input" dir="ltr" value={valeurs.whatsapp} onChange={maj('whatsapp')} /></Champ>
      <Champ etiquette={t('commun.nom_ar')}><input className="input" value={valeurs.nom_ar} onChange={maj('nom_ar')} /></Champ>
      <Champ etiquette={t('commun.nom_fr')}><input className="input" value={valeurs.nom_fr} onChange={maj('nom_fr')} /></Champ>
      <Champ etiquette={t('commercantes.boutique_nom_ar')}><input className="input" value={valeurs.b_nom_ar} onChange={maj('b_nom_ar')} /></Champ>
      <Champ etiquette={t('commercantes.boutique_nom_fr')}><input className="input" value={valeurs.b_nom_fr} onChange={maj('b_nom_fr')} /></Champ>
      <Champ etiquette={t('commercantes.type_activite')}><input className="input" value={valeurs.b_activite} onChange={maj('b_activite')} /></Champ>
      <Champ etiquette={t('commercantes.slug')}><input className="input" dir="ltr" pattern="[a-z0-9-]*" value={valeurs.b_slug} onChange={maj('b_slug')} /></Champ>
      <Champ etiquette={t('commun.ville')}><input className="input" value={valeurs.ville} onChange={maj('ville')} /></Champ>
      <Champ etiquette={t('commun.notes')}><input className="input" value={valeurs.notes} onChange={maj('notes')} /></Champ>
      {erreur && <p role="alert" className="text-sm text-danger sm:col-span-2">{erreur}</p>}
      <div className="flex justify-end sm:col-span-2">
        <button className="btn btn-primaire" disabled={creation.isPending}>{t('commun.creer')}</button>
      </div>
    </form>
  )
}

export function CommercantesPage() {
  const { t, i18n } = useTranslation()
  const { role } = useAuth()
  const queryClient = useQueryClient()
  const [recherche, setRecherche] = useState('')
  const [statut, setStatut] = useState('')
  const [creation, setCreation] = useState(false)
  const [code, setCode] = useState<CodeAffiche | null>(null)

  const liste = useListe<Tables<'commercantes'>>(['commercantes', recherche, statut], (a, b) => {
    let q = supabase.from('commercantes').select('*', { count: 'exact' }).order('cree_le', { ascending: false }).range(a, b)
    if (statut) q = q.eq('statut', statut as Tables<'commercantes'>['statut'])
    if (recherche) q = q.or(`nom_ar.ilike.${motifRecherche(recherche)},nom_fr.ilike.${motifRecherche(recherche)},telephone.ilike.${motifRecherche(recherche)}`)
    return q
  })

  const basculer = useMutation({
    mutationFn: async (c: Tables<'commercantes'>) => {
      const desactiver = c.statut === 'active'
      const { error } = await supabase.from('commercantes').update({ statut: desactiver ? 'desactivee' : 'active' }).eq('id', c.id)
      if (error) throw new Error(error.message)
      const { error: erreurProfil } = await supabase.from('profils').update({ actif: !desactiver }).eq('id', c.utilisateur_id)
      if (erreurProfil) throw new Error(erreurProfil.message)
    },
    onSuccess: () => void queryClient.invalidateQueries({ queryKey: ['commercantes'] }),
  })

  const reinitialiser = useMutation({
    mutationFn: async (c: Tables<'commercantes'>) => {
      const r = await invoquerFonction<{ code: string; lien_whatsapp: string }>('reset-pin', { utilisateur_id: c.utilisateur_id })
      return { telephone: c.telephone, code: r.code, lien: r.lien_whatsapp }
    },
    onSuccess: setCode,
  })

  return (
    <>
      <TitrePage titre={t('commercantes.titre')}>
        <input className="input w-56" placeholder={t('commun.rechercher')} value={recherche} onChange={(e) => { setRecherche(e.target.value); liste.setPage(0) }} />
        <select className="input w-40" value={statut} onChange={(e) => { setStatut(e.target.value); liste.setPage(0) }}>
          <option value="">{t('commun.tous')}</option>
          <option value="active">{t('statut.active')}</option>
          <option value="desactivee">{t('statut.desactivee')}</option>
        </select>
        <button className="btn btn-primaire" onClick={() => setCreation(true)}>{t('commercantes.nouvelle')}</button>
      </TitrePage>
      <MessageErreur erreur={liste.erreur ?? (basculer.error as Error | null) ?? (reinitialiser.error as Error | null)} />
      <DataTable
        colonnes={[
          { cle: 'nom', titre: t('commun.nom_fr'), rendu: (c) => nomLocalise(c, i18n.language) },
          { cle: 'tel', titre: t('commun.telephone'), rendu: (c) => <span dir="ltr">{c.telephone}</span> },
          { cle: 'ville', titre: t('commun.ville'), rendu: (c) => c.ville ?? '—' },
          { cle: 'statut', titre: t('commun.statut'), rendu: (c) => <Statut valeur={c.statut} /> },
          { cle: 'date', titre: t('commun.date'), rendu: (c) => formaterDate(c.cree_le, i18n.language) },
          {
            cle: 'actions', titre: t('commun.actions'), rendu: (c) => (
              <div className="flex gap-2">
                <button className="btn" onClick={() => reinitialiser.mutate(c)}>{t('commercantes.reinitialiser_code')}</button>
                {role === 'super_admin' && (
                  <button className="btn" onClick={() => window.confirm(t('commercantes.confirmation_desactivation')) && basculer.mutate(c)}>
                    {c.statut === 'active' ? t('commercantes.desactiver') : t('commercantes.reactiver')}
                  </button>
                )}
              </div>
            ),
          },
        ]}
        lignes={liste.lignes} total={liste.total} page={liste.page} taillePage={TAILLE_PAGE} chargement={liste.chargement}
        onPage={liste.setPage} cleLigne={(c) => c.id}
      />
      {creation && (
        <Dialog titre={t('commercantes.nouvelle')} onFermer={() => setCreation(false)}>
          <FormulaireCreation onFini={(c) => { setCreation(false); setCode(c) }} />
        </Dialog>
      )}
      {code && <CodeInitial code={code} onFermer={() => setCode(null)} />}
    </>
  )
}
