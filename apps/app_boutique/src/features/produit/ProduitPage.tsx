import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { lienWhatsapp } from '@/lib/checkout'
import { descriptionLocalisee, formaterMontant, nomLocalise, urlImage } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'
import { chargerProduit, chargerProduits, type VariantePublique } from '@/features/catalogue/api'
import { GrilleProduits } from '@/features/catalogue/ProductCard'
import { Seo } from '@/features/layout/Seo'
import { usePanier } from '@/features/panier/PanierProvider'

type Langue = 'ar' | 'fr'
const nom = (v: VariantePublique, dimension: 'modele' | 'couleur' | 'taille', l: Langue) => {
  const ar = v[`${dimension}_nom_ar` as keyof VariantePublique] as string | null
  const fr = v[`${dimension}_nom_fr` as keyof VariantePublique] as string | null
  return (l === 'ar' ? ar ?? fr : fr ?? ar) ?? ''
}

interface Option { id: string; libelle: string; hex?: string }

function options(variantes: VariantePublique[], dimension: 'modele' | 'couleur' | 'taille', langue: Langue): Option[] {
  const vus = new Map<string, Option>()
  for (const v of variantes) {
    const id = v[`${dimension}_id` as keyof VariantePublique] as string | null
    if (id && !vus.has(id)) vus.set(id, { id, libelle: nom(v, dimension, langue), hex: dimension === 'couleur' ? (v.couleur_hex as string | null) ?? undefined : undefined })
  }
  return [...vus.values()]
}

export function ProduitPage() {
  const { slug = '' } = useParams()
  const { t, i18n } = useTranslation()
  const { boutique } = useBoutique()
  const { ajouter } = usePanier()
  const langue: Langue = i18n.language === 'ar' ? 'ar' : 'fr'
  const [choix, setChoix] = useState<Partial<Record<'modele' | 'couleur' | 'taille', string>>>({})
  const [image, setImage] = useState(0)
  const [zoom, setZoom] = useState(false)
  const [ajoute, setAjoute] = useState(false)

  const requete = useQuery({ queryKey: ['produit', boutique.boutique_id, slug], queryFn: () => chargerProduit(boutique.boutique_id, slug) })
  const categorieId = requete.data?.produit.categorie_id as string | null | undefined
  const similaires = useQuery({
    queryKey: ['similaires', boutique.boutique_id, categorieId],
    enabled: !!categorieId,
    queryFn: async () => (await chargerProduits(boutique.boutique_id, { tri: 'defaut', categorieId: categorieId ?? undefined }, 0)).filter((p) => p.slug !== slug).slice(0, 4),
  })

  const variantes = useMemo(() => requete.data?.variantes ?? [], [requete.data])
  const dimensions = useMemo(() => (['modele', 'couleur', 'taille'] as const).map((d) => ({ d, liste: options(variantes, d, langue) })).filter((x) => x.liste.length > 0), [variantes, langue])

  // Une dimension à option unique est sélectionnée d'office.
  const effectif = useMemo(() => {
    const r: Partial<Record<'modele' | 'couleur' | 'taille', string>> = { ...choix }
    for (const { d, liste } of dimensions) if (liste.length === 1) r[d] = liste[0].id
    return r
  }, [choix, dimensions])
  const variante = variantes.find((v) => dimensions.every(({ d }) => (v[`${d}_id` as keyof VariantePublique] as string | null) === (effectif[d] ?? null)))

  if (requete.isLoading) return <p className="text-discret">{t('commun.chargement')}</p>
  if (!requete.data) return <p className="py-12 text-center text-discret">{t('produit.introuvable')}</p>
  const { produit, images } = requete.data
  const titre = nomLocalise(produit, i18n.language)
  const galerie = [...(variante?.image_url ? [variante.image_url as string] : []), ...images.map((i) => i.url as string)]
  const principale = galerie[Math.min(image, Math.max(galerie.length - 1, 0))]
  const prix = variante ? (variante.prix as number) : (produit.prix_min as number)
  const prixNormal = variante ? (variante.prix_normal as number) : (produit.prix_normal_min as number)
  const enPromo = variante ? (variante.en_promo as boolean) : (produit.en_promo as boolean)
  const disponible = variante ? !(variante.epuisee as boolean) : false

  const libelle = (l: Langue) => [nomLocalise({ nom_ar: produit.nom_ar, nom_fr: produit.nom_fr }, l),
    ...(variante ? (['modele', 'couleur', 'taille'] as const).map((d) => nom(variante, d, l)).filter(Boolean) : [])].join(' - ')
  const lienProduit = `${window.location.origin}/produit/${slug}`
  const whatsapp = lienWhatsapp(boutique.whatsapp ?? boutique.telephone, `${t('produit.message_whatsapp', { produit: libelle(langue) })}\n${lienProduit}`)

  const ajouterAuPanier = () => {
    if (!variante) return
    ajouter({ varianteId: variante.id as string, produitSlug: slug, quantite: 1, libelleAr: libelle('ar'), libelleFr: libelle('fr'), prix: variante.prix as number, image: principale ?? null })
    setAjoute(true)
    setTimeout(() => setAjoute(false), 2000)
  }

  return (
    <>
      <Seo titre={titre} description={descriptionLocalisee(produit, i18n.language) || undefined} image={produit.image_url as string | null}
        jsonLd={{
          '@context': 'https://schema.org', '@type': 'Product', name: titre, image: urlImage(produit.image_url as string | null, 1200), description: descriptionLocalisee(produit, i18n.language),
          offers: { '@type': 'Offer', priceCurrency: boutique.devise, price: produit.prix_min, availability: produit.epuise ? 'https://schema.org/OutOfStock' : 'https://schema.org/InStock', url: lienProduit },
        }} />
      <div className="grid gap-6 md:grid-cols-2">
        <div>
          <button type="button" className="block aspect-square w-full overflow-hidden rounded-boutique bg-surface" onClick={() => setZoom(true)} aria-label={titre}>
            {principale && <img src={urlImage(principale, 800)} alt={titre} className="h-full w-full object-cover" />}
          </button>
          {galerie.length > 1 && (
            <div className="mt-2 flex gap-2 overflow-x-auto">
              {galerie.map((g, i) => (
                <button key={g + i} type="button" onClick={() => setImage(i)} aria-label={`${titre} ${i + 1}`} className={`h-16 w-16 shrink-0 overflow-hidden rounded-boutique border-2 ${i === image ? 'border-primaire' : 'border-bordure'}`}>
                  <img src={urlImage(g, 120)} alt="" loading="lazy" className="h-full w-full object-cover" />
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="space-y-4">
          <h1 className="text-2xl font-bold">{titre}</h1>
          <p className="text-2xl">
            <span className="font-bold text-primaire">{formaterMontant(prix ?? 0, boutique.devise, i18n.language)}</span>
            {enPromo && <s className="ms-3 text-base text-discret">{formaterMontant(prixNormal ?? 0, boutique.devise, i18n.language)}</s>}
          </p>

          {dimensions.map(({ d, liste }) => (
            <div key={d}>
              <p className="etiquette">{t(`produit.${d}`)}{effectif[d] && ` : ${liste.find((o) => o.id === effectif[d])?.libelle}`}</p>
              <div className="flex flex-wrap gap-2">
                {liste.map((o) => {
                  const selectionne = effectif[d] === o.id
                  const existe = variantes.some((v) => (v[`${d}_id` as keyof VariantePublique] as string | null) === o.id)
                  return d === 'couleur' ? (
                    <button key={o.id} type="button" title={o.libelle} aria-label={o.libelle} aria-pressed={selectionne} disabled={!existe}
                      onClick={() => setChoix({ ...choix, [d]: o.id })}
                      className={`h-9 w-9 rounded-full border-2 ${selectionne ? 'border-primaire ring-2 ring-primaire/40' : 'border-bordure'}`} style={{ backgroundColor: o.hex }} />
                  ) : (
                    <button key={o.id} type="button" aria-pressed={selectionne} onClick={() => setChoix({ ...choix, [d]: o.id })}
                      className={`btn ${selectionne ? 'btn-primaire' : ''}`}>{o.libelle}</button>
                  )
                })}
              </div>
            </div>
          ))}

          {variante ? (
            <p className={`text-sm ${disponible ? 'text-succes' : 'text-danger'}`}>
              {disponible ? (variante.stock_visible != null ? t('produit.stock_restant', { n: variante.stock_visible }) : t('produit.en_stock')) : t('produit.epuise')}
            </p>
          ) : dimensions.length > 0 && <p className="text-sm text-discret">{t('produit.indisponible_combinaison')}</p>}

          <div className="flex flex-wrap gap-2">
            <button className="btn btn-primaire flex-1" disabled={!variante || !disponible} onClick={ajouterAuPanier}>{ajoute ? t('produit.ajoute') : t('produit.ajouter')}</button>
            {whatsapp && <a className="btn flex-1" href={whatsapp} target="_blank" rel="noreferrer">{t('produit.whatsapp')}</a>}
          </div>
          {descriptionLocalisee(produit, i18n.language) && <p className="whitespace-pre-line text-sm text-discret">{descriptionLocalisee(produit, i18n.language)}</p>}
        </div>
      </div>

      {(similaires.data?.length ?? 0) > 0 && (
        <section className="mt-10">
          <h2 className="mb-3 text-xl font-bold">{t('produit.similaires')}</h2>
          <GrilleProduits produits={similaires.data ?? []} />
        </section>
      )}

      {zoom && principale && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4" onClick={() => setZoom(false)} role="dialog" aria-modal="true" aria-label={titre}>
          <img src={urlImage(principale, 1600)} alt={titre} className="max-h-full max-w-full object-contain" />
        </div>
      )}
    </>
  )
}
