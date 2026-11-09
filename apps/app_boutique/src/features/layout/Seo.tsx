import { Helmet } from 'react-helmet-async'
import { useTranslation } from 'react-i18next'
import { nomLocalise, urlImage } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'

interface Props {
  titre?: string
  description?: string
  image?: string | null
  /** Données structurées schema.org (ex. Product). */
  jsonLd?: Record<string, unknown>
  noindex?: boolean
}

/** Balises meta, Open Graph et JSON-LD par page (React Helmet), dans la langue du visiteur. */
export function Seo({ titre, description, image, jsonLd, noindex }: Props) {
  const { i18n } = useTranslation()
  const { boutique } = useBoutique()
  const nom = nomLocalise(boutique, i18n.language)
  const referencement = (boutique.referencement ?? {}) as { description_ar?: string; description_fr?: string }
  const descriptionParDefaut = i18n.language === 'ar' ? referencement.description_ar : referencement.description_fr
  const titreComplet = titre ? `${titre} — ${nom}` : nom
  const texte = description ?? descriptionParDefaut ?? nom
  const visuel = urlImage(image, 1200) ?? urlImage(boutique.logo_url, 600, 'shop-assets')
  const favicon = urlImage(boutique.favicon_url, 64, 'shop-assets')

  return (
    <Helmet htmlAttributes={{ lang: i18n.language, dir: i18n.language === 'ar' ? 'rtl' : 'ltr' }}>
      <title>{titreComplet}</title>
      <meta name="description" content={texte} />
      {noindex && <meta name="robots" content="noindex" />}
      <meta property="og:site_name" content={nom} />
      <meta property="og:title" content={titreComplet} />
      <meta property="og:description" content={texte} />
      <meta property="og:type" content={jsonLd ? 'product' : 'website'} />
      {visuel && <meta property="og:image" content={visuel} />}
      <meta name="twitter:card" content={visuel ? 'summary_large_image' : 'summary'} />
      <meta name="theme-color" content={getComputedStyle(document.documentElement).getPropertyValue('--b-primaire').trim() || '#8a3b5c'} />
      {favicon && <link rel="icon" href={favicon} />}
      {jsonLd && <script type="application/ld+json">{JSON.stringify(jsonLd)}</script>}
    </Helmet>
  )
}
