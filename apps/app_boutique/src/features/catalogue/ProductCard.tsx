import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { formaterMontant, nomLocalise, urlImage } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'
import type { ProduitPublic } from './api'

const STYLES = {
  bordure: 'border border-bordure',
  ombre: 'shadow-md',
  minimal: '',
} as const

/** Carte produit : image différée (WebP via Supabase), prix promo, mention épuisé, mise en page du thème. */
export function ProductCard({ produit }: { produit: ProduitPublic }) {
  const { t, i18n } = useTranslation()
  const { boutique, mise } = useBoutique()
  const image = urlImage(produit.image_url, 400)
  return (
    <Link to={`/produit/${produit.slug}`} className={`group block overflow-hidden rounded-boutique bg-surface ${STYLES[mise.styleCarte]}`}>
      <div className="relative aspect-square bg-fond">
        {image && <img src={image} alt={nomLocalise(produit, i18n.language)} loading="lazy" decoding="async" className="h-full w-full object-cover transition group-hover:scale-105" />}
        {produit.en_promo && <span className="absolute start-2 top-2 rounded-full bg-secondaire px-2 py-0.5 text-xs font-semibold text-white">{t('produit.promo')}</span>}
        {produit.epuise && <span className="absolute inset-x-0 bottom-0 bg-black/60 py-1 text-center text-xs text-white">{t('produit.epuise')}</span>}
      </div>
      <div className="p-3">
        <h3 className="line-clamp-2 text-sm font-medium">{nomLocalise(produit, i18n.language)}</h3>
        <p className="mt-1 text-sm">
          <span className="font-semibold text-primaire">{formaterMontant(produit.prix_min ?? 0, boutique.devise, i18n.language)}</span>
          {produit.en_promo && produit.prix_normal_min != null && (
            <s className="ms-2 text-xs text-discret">{formaterMontant(produit.prix_normal_min, boutique.devise, i18n.language)}</s>
          )}
        </p>
      </div>
    </Link>
  )
}

export function GrilleProduits({ produits }: { produits: ProduitPublic[] }) {
  const { mise } = useBoutique()
  return (
    <div className={`grid grid-cols-2 gap-3 sm:grid-cols-3 ${mise.grille === 3 ? 'lg:grid-cols-4' : 'lg:grid-cols-3'}`}>
      {produits.map((p) => <ProductCard key={p.id as string} produit={p} />)}
    </div>
  )
}
