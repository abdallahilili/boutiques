import { useState, type FormEvent } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { construireCommande, identifiantTentative, oublierTentative, validerCommande, type ErreurFormulaire, type FormulaireCommande } from '@/lib/checkout'
import { formaterMontant, nomLocalise } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'
import { Seo } from '@/features/layout/Seo'
import { usePanier } from '@/features/panier/PanierProvider'

interface ReponseCommande { id: string; numero: string; total: number; rejoue: boolean }

function messageServeur(message: string): string {
  if (message.startsWith('stock_insuffisant') || message.startsWith('produit_indisponible')) return 'commande.erreur_stock'
  if (message.startsWith('trop_de_requetes')) return 'commande.erreur_trop_de_requetes'
  if (message.startsWith('boutique_indisponible')) return 'commande.erreur_indisponible'
  return 'commun.erreur'
}

/** Checkout en un seul écran, sans compte. Le serveur revérifie prix, stock et options de la boutique. */
export function CheckoutPage() {
  const { t, i18n } = useTranslation()
  const navigate = useNavigate()
  const { boutique } = useBoutique()
  const { lignes, sousTotal, vider } = usePanier()
  const [f, setF] = useState<FormulaireCommande>({
    nom: '', telephone: '', adresse: '', ville: '', zoneId: '', modeLivraison: boutique.livraison_active ? 'livraison' : 'retrait',
    modePaiement: boutique.paiement_livraison_actif ? 'a_la_livraison' : 'mobile_money', notes: '', miel: '',
  })
  const [preuve, setPreuve] = useState<File | null>(null)
  const [erreurs, setErreurs] = useState<ErreurFormulaire[]>([])
  const [erreurServeur, setErreurServeur] = useState<string | null>(null)
  const [envoi, setEnvoi] = useState(false)

  const zones = useQuery({
    queryKey: ['zones', boutique.boutique_id],
    queryFn: async () => (await supabase.from('zones_livraison_publiques').select('*').eq('boutique_id', boutique.boutique_id)).data ?? [],
  })
  const zone = zones.data?.find((z) => z.id === f.zoneId)
  const frais = f.modeLivraison === 'livraison' ? Number(zone?.frais ?? 0) : 0
  const montant = (n: number) => formaterMontant(n, boutique.devise, i18n.language)
  const instructions = (boutique.infos_paiement ?? {}) as { instructions_ar?: string; instructions_fr?: string }
  const minimum = Number(boutique.commande_minimale ?? 0)
  const maj = <K extends keyof FormulaireCommande>(cle: K, valeur: FormulaireCommande[K]) => setF((x) => ({ ...x, [cle]: valeur }))

  async function soumettre(e: FormEvent) {
    e.preventDefault()
    setErreurServeur(null)
    const invalides = validerCommande(f, lignes)
    setErreurs(invalides)
    if (invalides.length > 0 || sousTotal < minimum) return
    setEnvoi(true)
    try {
      const { data, error } = await supabase.rpc('passer_commande_en_ligne', { p_slug: boutique.slug, p_donnees: construireCommande(identifiantTentative(), f, lignes) })
      if (error) throw new Error(error.message)
      const commande = data as unknown as ReponseCommande

      if (preuve && f.modePaiement === 'mobile_money') {
        const chemin = `${boutique.boutique_id}/commandes/${commande.id}/${crypto.randomUUID()}.${preuve.name.split('.').pop()?.toLowerCase().replace(/[^a-z0-9]/g, '') || 'jpg'}`
        const { error: erreurDepot } = await supabase.storage.from('payment-proofs').upload(chemin, preuve, { contentType: preuve.type })
        if (!erreurDepot) await supabase.rpc('joindre_justificatif_commande', { p_slug: boutique.slug, p_commande_id: commande.id, p_telephone: f.telephone, p_chemin: chemin })
      }

      oublierTentative()
      vider()
      navigate('/commande/confirmation', { state: { numero: commande.numero, total: commande.total, telephone: f.telephone }, replace: true })
    } catch (err) {
      setErreurServeur(messageServeur((err as Error).message))
    } finally {
      setEnvoi(false)
    }
  }

  const champErreur = (cle: ErreurFormulaire) => erreurs.includes(cle) && <p role="alert" className="mt-1 text-xs text-danger">{t(`commande.erreur_${cle}`)}</p>

  return (
    <>
      <Seo titre={t('commande.titre')} noindex />
      <h1 className="mb-4 text-2xl font-bold">{t('commande.titre')}</h1>
      <form onSubmit={soumettre} noValidate className="grid gap-6 md:grid-cols-[1fr_20rem]">
        <div className="space-y-4">
          <label className="block"><span className="etiquette">{t('commande.nom')}</span><input className="input" autoComplete="name" value={f.nom} onChange={(e) => maj('nom', e.target.value)} />{champErreur('nom')}</label>
          <label className="block"><span className="etiquette">{t('commande.telephone')}</span><input className="input" type="tel" inputMode="tel" autoComplete="tel" dir="ltr" value={f.telephone} onChange={(e) => maj('telephone', e.target.value)} />{champErreur('telephone')}</label>

          <fieldset>
            <legend className="etiquette">{t('commande.mode_livraison')}</legend>
            <div className="flex gap-2">
              {boutique.livraison_active && <button type="button" aria-pressed={f.modeLivraison === 'livraison'} className={`btn flex-1 ${f.modeLivraison === 'livraison' ? 'btn-primaire' : ''}`} onClick={() => maj('modeLivraison', 'livraison')}>{t('commande.livraison')}</button>}
              {boutique.retrait_boutique_actif && <button type="button" aria-pressed={f.modeLivraison === 'retrait'} className={`btn flex-1 ${f.modeLivraison === 'retrait' ? 'btn-primaire' : ''}`} onClick={() => maj('modeLivraison', 'retrait')}>{t('commande.retrait')}</button>}
            </div>
          </fieldset>

          {f.modeLivraison === 'livraison' && (
            <>
              {(zones.data?.length ?? 0) > 0 && (
                <label className="block"><span className="etiquette">{t('commande.zone')}</span>
                  <select className="input" value={f.zoneId} onChange={(e) => maj('zoneId', e.target.value)}>
                    <option value="" />
                    {zones.data?.map((z) => <option key={z.id as string} value={z.id as string}>{nomLocalise(z, i18n.language)} — {montant(Number(z.frais))}</option>)}
                  </select>
                </label>
              )}
              <label className="block"><span className="etiquette">{t('commande.ville')}</span><input className="input" value={f.ville} onChange={(e) => maj('ville', e.target.value)} /></label>
              <label className="block"><span className="etiquette">{t('commande.adresse')}</span><textarea className="input" rows={2} autoComplete="street-address" value={f.adresse} onChange={(e) => maj('adresse', e.target.value)} />{champErreur('adresse')}</label>
            </>
          )}

          <fieldset>
            <legend className="etiquette">{t('commande.mode_paiement')}</legend>
            <div className="flex flex-wrap gap-2">
              {boutique.paiement_livraison_actif && <button type="button" aria-pressed={f.modePaiement === 'a_la_livraison'} className={`btn flex-1 ${f.modePaiement === 'a_la_livraison' ? 'btn-primaire' : ''}`} onClick={() => maj('modePaiement', 'a_la_livraison')}>{t('commande.a_la_livraison')}</button>}
              {boutique.mobile_money_actif && <button type="button" aria-pressed={f.modePaiement === 'mobile_money'} className={`btn flex-1 ${f.modePaiement === 'mobile_money' ? 'btn-primaire' : ''}`} onClick={() => maj('modePaiement', 'mobile_money')}>{t('commande.mobile_money')}</button>}
            </div>
          </fieldset>
          {f.modePaiement === 'mobile_money' && (
            <div className="carte space-y-2 text-sm">
              <p className="font-medium">{t('commande.instructions_paiement')}</p>
              <p className="whitespace-pre-line text-discret">{(i18n.language === 'ar' ? instructions.instructions_ar : instructions.instructions_fr) ?? ''}</p>
              <label className="block"><span className="etiquette">{t('commande.preuve')}</span>
                <input className="input" type="file" accept="image/jpeg,image/png,image/webp" onChange={(e) => setPreuve(e.target.files?.[0] ?? null)} />
              </label>
            </div>
          )}

          <label className="block"><span className="etiquette">{t('commande.notes')}</span><textarea className="input" rows={2} value={f.notes} onChange={(e) => maj('notes', e.target.value)} /></label>
          {/* Champ piège : invisible pour les humaines, rempli par les robots. */}
          <input tabIndex={-1} autoComplete="off" aria-hidden="true" className="absolute -start-[9999px] h-0 w-0 opacity-0" value={f.miel} onChange={(e) => maj('miel', e.target.value)} />
        </div>

        <aside className="carte space-y-2 md:self-start">
          <h2 className="font-semibold">{t('commande.recapitulatif')}</h2>
          {champErreur('panier_vide')}
          <ul className="space-y-1 text-sm">
            {lignes.map((l) => <li key={l.varianteId} className="flex justify-between gap-2"><span>{l.quantite} × {i18n.language === 'ar' ? l.libelleAr || l.libelleFr : l.libelleFr || l.libelleAr}</span><span>{montant(l.prix * l.quantite)}</span></li>)}
          </ul>
          <hr className="border-bordure" />
          <p className="flex justify-between text-sm"><span>{t('panier.sous_total')}</span><span>{montant(sousTotal)}</span></p>
          <p className="flex justify-between text-sm"><span>{t('commande.frais')}</span><span>{montant(frais)}</span></p>
          <p className="flex justify-between font-bold"><span>{t('commande.total')}</span><span>{montant(sousTotal + frais)}</span></p>
          {sousTotal < minimum && <p role="alert" className="text-xs text-danger">{t('commande.minimum', { montant: montant(minimum) })}</p>}
          {erreurServeur && <p role="alert" className="text-sm text-danger">{t(erreurServeur)}</p>}
          <button className="btn btn-primaire w-full" disabled={envoi}>{t('commande.confirmer')}</button>
        </aside>
      </form>
    </>
  )
}
