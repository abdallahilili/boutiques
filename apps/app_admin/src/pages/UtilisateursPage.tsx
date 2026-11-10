import { useState, type FormEvent } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { ErreurFonction, invoquerFonction } from '@/lib/fonctions'
import { nomLocalise } from '@/lib/format'
import { TAILLE_PAGE, useListe } from '@/lib/useListe'
import { useAuth } from '@/features/auth/AuthProvider'
import { DataTable } from '@/components/DataTable'
import { Dialog } from '@/components/Dialog'
import { Champ, MessageErreur, Statut, TitrePage } from '@/components/ui'
import type { Tables } from '@/types/database'

type Profil = Tables<'profils'>

function FormulaireMembre({ onFini }: { onFini: () => void }) {
  const { t } = useTranslation()
  const queryClient = useQueryClient()
  const [v, setV] = useState({ telephone: '', nom_fr: '', nom_ar: '', role: 'support', mot_de_passe: '' })
  const creation = useMutation({
    mutationFn: () => invoquerFonction('admin-create-staff', v),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['equipe'] })
      onFini()
    },
  })
  const soumettre = (e: FormEvent) => {
    e.preventDefault()
    creation.mutate()
  }
  const erreur = creation.error instanceof ErreurFonction && creation.error.code === 'telephone_deja_utilise' ? t('utilisateurs.telephone_deja_utilise') : creation.error ? t('commun.erreur') : null
  return (
    <form onSubmit={soumettre} className="grid grid-cols-2 gap-3">
      <div className="col-span-2"><Champ etiquette={t('commun.telephone')}><input className="input" type="tel" dir="ltr" required value={v.telephone} onChange={(e) => setV({ ...v, telephone: e.target.value })} /></Champ></div>
      <Champ etiquette={t('commun.nom_ar')}><input className="input" value={v.nom_ar} onChange={(e) => setV({ ...v, nom_ar: e.target.value })} /></Champ>
      <Champ etiquette={t('commun.nom_fr')}><input className="input" value={v.nom_fr} onChange={(e) => setV({ ...v, nom_fr: e.target.value })} /></Champ>
      <Champ etiquette={t('utilisateurs.role')}>
        <select className="input" value={v.role} onChange={(e) => setV({ ...v, role: e.target.value })}>
          <option value="support">{t('statut.support')}</option>
          <option value="super_admin">{t('statut.super_admin')}</option>
        </select>
      </Champ>
      <Champ etiquette={t('utilisateurs.mot_de_passe')}><input className="input" type="password" dir="ltr" minLength={8} required value={v.mot_de_passe} onChange={(e) => setV({ ...v, mot_de_passe: e.target.value })} /></Champ>
      <p className="col-span-2 text-xs text-discret">{t('utilisateurs.mot_de_passe_aide')}</p>
      {erreur && <p role="alert" className="col-span-2 text-sm text-danger">{erreur}</p>}
      <div className="col-span-2 flex justify-end"><button className="btn btn-primaire" disabled={creation.isPending}>{t('commun.creer')}</button></div>
    </form>
  )
}

export function UtilisateursPage() {
  const { t, i18n } = useTranslation()
  const { role } = useAuth()
  const queryClient = useQueryClient()
  const [creation, setCreation] = useState(false)
  const ecriture = role === 'super_admin'

  const liste = useListe<Profil>(['equipe'], (a, b) =>
    supabase.from('profils').select('*', { count: 'exact' }).in('role_plateforme', ['super_admin', 'support']).order('cree_le').range(a, b))

  const modifier = useMutation({
    mutationFn: async ({ id, valeurs }: { id: string; valeurs: Partial<Pick<Profil, 'actif' | 'role_plateforme'>> }) => {
      const { error } = await supabase.from('profils').update(valeurs).eq('id', id)
      if (error) throw new Error(error.message)
    },
    onSuccess: () => void queryClient.invalidateQueries({ queryKey: ['equipe'] }),
  })

  return (
    <>
      <TitrePage titre={t('utilisateurs.titre')}>
        {ecriture ? <button className="btn btn-primaire" onClick={() => setCreation(true)}>{t('utilisateurs.nouveau')}</button> : <span className="text-sm text-discret">{t('utilisateurs.reserve_super_admin')}</span>}
      </TitrePage>
      <MessageErreur erreur={liste.erreur ?? (modifier.error as Error | null)} />
      <DataTable
        colonnes={[
          { cle: 'nom', titre: t('commun.nom_fr'), rendu: (p) => nomLocalise(p, i18n.language) },
          { cle: 'tel', titre: t('commun.telephone'), rendu: (p) => <span dir="ltr">{p.telephone}</span> },
          { cle: 'role', titre: t('utilisateurs.role'), rendu: (p) => <Statut valeur={p.role_plateforme} /> },
          { cle: 'actif', titre: t('commun.actif'), rendu: (p) => (p.actif ? t('commun.oui') : t('commun.non')) },
          {
            cle: 'actions', titre: t('commun.actions'), rendu: (p) => ecriture && (
              <div className="flex gap-2">
                <button className="btn" onClick={() => modifier.mutate({ id: p.id, valeurs: { actif: !p.actif } })}>{p.actif ? t('commercantes.desactiver') : t('commercantes.reactiver')}</button>
                <button className="btn" onClick={() => modifier.mutate({ id: p.id, valeurs: { role_plateforme: p.role_plateforme === 'support' ? 'super_admin' : 'support' } })}>
                  {p.role_plateforme === 'support' ? t('statut.super_admin') : t('statut.support')}
                </button>
              </div>
            ),
          },
        ]}
        lignes={liste.lignes} total={liste.total} page={liste.page} taillePage={TAILLE_PAGE} chargement={liste.chargement}
        onPage={liste.setPage} cleLigne={(p) => p.id}
      />
      {creation && (
        <Dialog titre={t('utilisateurs.nouveau')} onFermer={() => setCreation(false)}>
          <FormulaireMembre onFini={() => setCreation(false)} />
        </Dialog>
      )}
    </>
  )
}
