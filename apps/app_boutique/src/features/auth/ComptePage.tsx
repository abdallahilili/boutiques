import { useState, type FormEvent } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { formaterDate, formaterMontant } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'
import { Seo } from '@/features/layout/Seo'
import { connexionCliente, ErreurAuth, inscriptionCliente } from './api'
import { useAuth } from './AuthProvider'

function Formulaire({ inscription }: { inscription: boolean }) {
  const { t } = useTranslation()
  const { boutique } = useBoutique()
  const [nom, setNom] = useState('')
  const [telephone, setTelephone] = useState('')
  const [code, setCode] = useState('')
  const [erreur, setErreur] = useState<string | null>(null)
  const [envoi, setEnvoi] = useState(false)

  async function soumettre(e: FormEvent) {
    e.preventDefault()
    setErreur(null)
    setEnvoi(true)
    try {
      if (inscription) await inscriptionCliente(boutique.slug, nom.trim(), telephone.trim(), code)
      else await connexionCliente(boutique.slug, telephone.trim(), code)
    } catch (err) {
      const c = err instanceof ErreurAuth ? err.code : 'erreur'
      setErreur(t(c === 'identifiants_invalides' || c === 'compte_verrouille' ? `auth.${c}` : c === 'compte_existant' ? 'compte.compte_existant' : 'commun.erreur'))
    } finally {
      setEnvoi(false)
    }
  }

  return (
    <form onSubmit={soumettre} className="carte space-y-3">
      {inscription && <label className="block"><span className="etiquette">{t('compte.nom')}</span><input className="input" required minLength={2} autoComplete="name" value={nom} onChange={(e) => setNom(e.target.value)} /></label>}
      <label className="block"><span className="etiquette">{t('auth.telephone')}</span><input className="input" type="tel" inputMode="tel" autoComplete="username" required dir="ltr" value={telephone} onChange={(e) => setTelephone(e.target.value)} /></label>
      <label className="block"><span className="etiquette">{t('auth.code')}</span>
        <input className="input text-center tracking-widest" type="password" inputMode="numeric" autoComplete={inscription ? 'new-password' : 'current-password'} pattern="[0-9]{4}" maxLength={4} required dir="ltr" value={code} onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))} />
      </label>
      {erreur && <p role="alert" className="text-sm text-danger">{erreur}</p>}
      <button className="btn btn-primaire w-full" disabled={envoi}>{inscription ? t('compte.creer') : t('auth.valider')}</button>
    </form>
  )
}

function MesCommandes() {
  const { t, i18n } = useTranslation()
  const { boutique } = useBoutique()
  const { deconnexion } = useAuth()
  const commandes = useQuery({
    queryKey: ['mes-commandes', boutique.boutique_id],
    queryFn: async () => {
      const { data, error } = await supabase.from('commandes').select('id, numero, statut, total, cree_le').order('cree_le', { ascending: false }).limit(50)
      if (error) throw new Error(error.message)
      return data
    },
  })
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold">{t('compte.mes_commandes')}</h2>
        <button className="btn" onClick={() => void deconnexion()}>{t('auth.deconnexion')}</button>
      </div>
      {commandes.data?.length === 0 && <p className="text-discret">{t('compte.aucune_commande')}</p>}
      <ul className="space-y-2">
        {commandes.data?.map((c) => (
          <li key={c.id} className="carte flex flex-wrap items-center justify-between gap-2 text-sm">
            <Link to="/suivi" state={{ numero: c.numero }} className="font-semibold" dir="ltr">{c.numero}</Link>
            <span>{formaterDate(c.cree_le, i18n.language)}</span>
            <span>{t(`statut_commande.${c.statut}`)}</span>
            <strong>{formaterMontant(c.total, boutique.devise, i18n.language)}</strong>
          </li>
        ))}
      </ul>
    </div>
  )
}

export function ComptePage() {
  const { t } = useTranslation()
  const { session, chargement } = useAuth()
  const [inscription, setInscription] = useState(false)
  return (
    <div className="mx-auto max-w-md space-y-4">
      <Seo titre={t('compte.titre')} noindex />
      <h1 className="text-2xl font-bold">{t('compte.titre')}</h1>
      {chargement ? <p className="text-discret">{t('commun.chargement')}</p> : session ? <MesCommandes /> : (
        <>
          <p className="text-sm text-discret">{t('compte.optionnel')}</p>
          <div className="flex gap-2">
            <button className={`btn flex-1 ${!inscription ? 'btn-primaire' : ''}`} onClick={() => setInscription(false)}>{t('auth.connexion')}</button>
            <button className={`btn flex-1 ${inscription ? 'btn-primaire' : ''}`} onClick={() => setInscription(true)}>{t('compte.inscription')}</button>
          </div>
          <Formulaire key={String(inscription)} inscription={inscription} />
        </>
      )}
    </div>
  )
}
