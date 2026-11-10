import { useState, type FormEvent } from 'react'
import { useLocation } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { lienWhatsapp } from '@/lib/checkout'
import { formaterDate, formaterMontant, nomLocalise } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'
import { Seo } from '@/features/layout/Seo'

interface Suivi {
  numero: string
  statut: string
  statut_paiement: string
  total: number
  frais_livraison: number
  cree_le: string
  lignes: { libelle_ar: string | null; libelle_fr: string | null; quantite: number; total: number }[]
  historique: { statut: string; date_statut: string }[]
  boutique: { telephone: string | null; whatsapp: string | null }
}

/** Suivi sans compte : téléphone seul (liste des commandes) ou téléphone + numéro de commande (facultatif). */
export function SuiviPage() {
  const { t, i18n } = useTranslation()
  const { boutique } = useBoutique()
  const prefill = (useLocation().state ?? {}) as { numero?: string; telephone?: string }
  const [numero, setNumero] = useState(prefill.numero ?? '')
  const [telephone, setTelephone] = useState(prefill.telephone ?? '')
  const [suivis, setSuivis] = useState<Suivi[]>([])
  const [erreur, setErreur] = useState<string | null>(null)
  const [chargement, setChargement] = useState(false)
  const montant = (n: number) => formaterMontant(n, boutique.devise, i18n.language)

  async function chercher(e: FormEvent) {
    e.preventDefault()
    setErreur(null)
    setSuivis([])
    setChargement(true)
    const reponse = numero.trim()
      ? await supabase.rpc('suivre_commande', { p_slug: boutique.slug, p_numero: numero, p_telephone: telephone })
      : await supabase.rpc('suivre_commandes_par_telephone', { p_slug: boutique.slug, p_telephone: telephone })
    setChargement(false)
    if (reponse.error) {
      setErreur(reponse.error.message.startsWith('commande_introuvable') ? t('suivi.introuvable') : t('commun.erreur'))
      return
    }
    const liste = (Array.isArray(reponse.data) ? reponse.data : [reponse.data]) as unknown as Suivi[]
    if (liste.length === 0) setErreur(t('suivi.introuvable'))
    else setSuivis(liste)
  }

  async function recap(suivi: Suivi) {
    const { ouvrirRecap } = await import('./RecapPdf')
    await ouvrirRecap({
      boutique: nomLocalise(boutique, i18n.language), numero: suivi.numero, date: formaterDate(suivi.cree_le, i18n.language), statut: t(`statut_commande.${suivi.statut}`),
      lignes: suivi.lignes.map((l) => ({ libelle: (i18n.language === 'ar' ? l.libelle_ar ?? l.libelle_fr : l.libelle_fr ?? l.libelle_ar) ?? '', quantite: l.quantite, total: montant(l.total) })),
      fraisLivraison: montant(suivi.frais_livraison), total: montant(suivi.total),
      libelles: { titre: t('commande.recapitulatif_pdf'), statut: t('suivi.paiement'), frais: t('commande.frais'), total: t('commande.total') },
    })
  }

  return (
    <>
      <Seo titre={t('suivi.titre')} noindex />
      <h1 className="mb-4 text-2xl font-bold">{t('suivi.titre')}</h1>
      <form onSubmit={chercher} className="carte mb-6 grid gap-3 sm:grid-cols-[1fr_1fr_auto] sm:items-end">
        <label><span className="etiquette">{t('suivi.telephone')}</span><input className="input" type="tel" dir="ltr" required value={telephone} onChange={(e) => setTelephone(e.target.value)} /></label>
        <label><span className="etiquette">{t('suivi.numero')} <span className="text-discret">({t('suivi.facultatif')})</span></span><input className="input" dir="ltr" value={numero} onChange={(e) => setNumero(e.target.value)} /></label>
        <button className="btn btn-primaire" disabled={chargement}>{t('suivi.chercher')}</button>
      </form>
      {erreur && <p role="alert" className="text-danger">{erreur}</p>}
      {suivis.map((suivi) => (
        <div key={suivi.numero} className="carte mb-4 space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <h2 className="text-lg font-bold" dir="ltr">{suivi.numero}</h2>
            <span className="rounded-full bg-primaire px-3 py-1 text-sm text-primaire-texte">{t(`statut_commande.${suivi.statut}`)}</span>
          </div>
          <ol className="space-y-1 border-s-2 border-bordure ps-4 text-sm">
            {suivi.historique.map((h, i) => <li key={i}><strong>{t(`statut_commande.${h.statut}`)}</strong> <span className="text-discret">{formaterDate(h.date_statut, i18n.language)}</span></li>)}
          </ol>
          <ul className="space-y-1 text-sm">
            {suivi.lignes.map((l, i) => <li key={i} className="flex justify-between gap-2"><span>{l.quantite} × {(i18n.language === 'ar' ? l.libelle_ar ?? l.libelle_fr : l.libelle_fr ?? l.libelle_ar) ?? ''}</span><span>{montant(l.total)}</span></li>)}
          </ul>
          <p className="flex justify-between font-bold"><span>{t('commande.total')}</span><span>{montant(suivi.total)}</span></p>
          <p className="text-sm text-discret">{t('suivi.paiement')} : {t(`statut_paiement.${suivi.statut_paiement}`)}</p>
          <div className="flex flex-wrap gap-2">
            {lienWhatsapp(suivi.boutique.whatsapp ?? suivi.boutique.telephone, suivi.numero) && <a className="btn" href={lienWhatsapp(suivi.boutique.whatsapp ?? suivi.boutique.telephone, suivi.numero) ?? undefined} target="_blank" rel="noreferrer">{t('suivi.contact')}</a>}
            <button className="btn" onClick={() => void recap(suivi)}>{t('commande.recapitulatif_pdf')}</button>
          </div>
        </div>
      ))}
    </>
  )
}
