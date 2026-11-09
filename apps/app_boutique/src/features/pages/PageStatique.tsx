import { useQuery } from '@tanstack/react-query'
import { useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { contenuLocalise, titreLocalise } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'
import { Seo } from '@/features/layout/Seo'

/** Pages statiques (à propos, livraison, retours, conditions) : texte brut, jamais de HTML injecté. */
export function PageStatique() {
  const { slug = '' } = useParams()
  const { t, i18n } = useTranslation()
  const { boutique } = useBoutique()
  const page = useQuery({
    queryKey: ['page', boutique.boutique_id, slug],
    queryFn: async () => (await supabase.from('pages_site_publiques').select('*').eq('boutique_id', boutique.boutique_id).eq('slug', slug).maybeSingle()).data,
  })
  if (page.isLoading) return <p className="text-discret">{t('commun.chargement')}</p>
  if (!page.data) return <p className="py-12 text-center text-discret">{t('produit.introuvable')}</p>
  const titre = titreLocalise(page.data, i18n.language)
  return (
    <article className="mx-auto max-w-2xl space-y-3">
      <Seo titre={titre} description={contenuLocalise(page.data, i18n.language).slice(0, 160)} />
      <h1 className="text-2xl font-bold">{titre}</h1>
      <p className="whitespace-pre-line text-discret">{contenuLocalise(page.data, i18n.language)}</p>
    </article>
  )
}
