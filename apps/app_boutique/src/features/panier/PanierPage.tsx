import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { lienWhatsapp } from '@/lib/checkout'
import { formaterMontant, urlImage } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'
import { Seo } from '@/features/layout/Seo'
import { usePanier } from './PanierProvider'

export function PanierPage() {
  const { t, i18n } = useTranslation()
  const { boutique } = useBoutique()
  const { lignes, sousTotal, changerQuantite, retirer } = usePanier()
  const montant = (n: number) => formaterMontant(n, boutique.devise, i18n.language)
  const libelle = (l: (typeof lignes)[number]) => (i18n.language === 'ar' ? l.libelleAr || l.libelleFr : l.libelleFr || l.libelleAr)
  const whatsapp = lienWhatsapp(boutique.whatsapp ?? boutique.telephone, lignes.map((l) => `${l.quantite} × ${libelle(l)}`).join('\n'))

  return (
    <>
      <Seo titre={t('panier.titre')} noindex />
      <h1 className="mb-4 text-2xl font-bold">{t('panier.titre')}</h1>
      {lignes.length === 0 ? (
        <div className="py-12 text-center">
          <p className="mb-4 text-discret">{t('panier.vide')}</p>
          <Link className="btn btn-primaire" to="/catalogue">{t('panier.continuer')}</Link>
        </div>
      ) : (
        <div className="grid gap-6 md:grid-cols-[1fr_20rem]">
          <ul className="space-y-3">
            {lignes.map((l) => (
              <li key={l.varianteId} className="carte flex gap-3">
                <div className="h-20 w-20 shrink-0 overflow-hidden rounded-boutique bg-fond">
                  {l.image && <img src={urlImage(l.image, 160)} alt="" loading="lazy" className="h-full w-full object-cover" />}
                </div>
                <div className="flex-1 space-y-2">
                  <Link to={`/produit/${l.produitSlug}`} className="font-medium">{libelle(l)}</Link>
                  <p className="text-sm text-discret">{montant(l.prix)}</p>
                  <div className="flex items-center gap-2">
                    <button className="btn px-3" aria-label="−" onClick={() => changerQuantite(l.varianteId, l.quantite - 1)}>−</button>
                    <span className="w-8 text-center" aria-live="polite">{l.quantite}</span>
                    <button className="btn px-3" aria-label="+" onClick={() => changerQuantite(l.varianteId, l.quantite + 1)}>+</button>
                    <button className="btn ms-auto" onClick={() => retirer(l.varianteId)}>{t('panier.retirer')}</button>
                  </div>
                </div>
                <p className="font-semibold">{montant(l.prix * l.quantite)}</p>
              </li>
            ))}
          </ul>
          <aside className="carte space-y-3 md:self-start">
            <p className="flex justify-between"><span>{t('panier.sous_total')}</span><strong>{montant(sousTotal)}</strong></p>
            <p className="flex justify-between text-sm text-discret"><span>{t('panier.livraison')}</span><span>{t('panier.livraison_calculee')}</span></p>
            <p className="text-xs text-discret">{t('panier.prix_verifie')}</p>
            <Link className="btn btn-primaire w-full" to="/commande">{t('panier.commander')}</Link>
            {whatsapp && <a className="btn w-full" href={whatsapp} target="_blank" rel="noreferrer">{t('panier.whatsapp')}</a>}
          </aside>
        </div>
      )}
    </>
  )
}
