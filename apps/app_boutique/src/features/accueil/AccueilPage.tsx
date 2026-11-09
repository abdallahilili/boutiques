import { useEffect, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { contenuLocalise, nomLocalise, titreLocalise, urlImage } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'
import { chargerCategories, chargerProduits, type FiltresCatalogue } from '@/features/catalogue/api'
import { GrilleProduits } from '@/features/catalogue/ProductCard'
import { Seo } from '@/features/layout/Seo'

type TypeSection = 'banniere' | 'categories_vedettes' | 'nouveautes' | 'promotions' | 'produits_populaires' | 'a_propos' | 'contact'
interface Section { id: string; type: TypeSection; titre_ar: string | null; titre_fr: string | null; contenu_ar: string | null; contenu_fr: string | null }

const SECTIONS_PAR_DEFAUT: Section[] = (['banniere', 'categories_vedettes', 'nouveautes', 'promotions'] as const)
  .map((type) => ({ id: type, type, titre_ar: null, titre_fr: null, contenu_ar: null, contenu_fr: null }))

function Banniere() {
  const { i18n } = useTranslation()
  const { boutique } = useBoutique()
  const [index, setIndex] = useState(0)
  const bannieres = useQuery({
    queryKey: ['bannieres', boutique.boutique_id],
    queryFn: async () => (await supabase.from('bannieres_site_publiques').select('*').eq('boutique_id', boutique.boutique_id).order('ordre')).data ?? [],
  })
  const liste = bannieres.data ?? []
  useEffect(() => {
    if (liste.length < 2 || window.matchMedia?.('(prefers-reduced-motion: reduce)').matches) return
    const id = setInterval(() => setIndex((i) => (i + 1) % liste.length), 5000)
    return () => clearInterval(id)
  }, [liste.length])
  if (liste.length === 0) return null
  const b = liste[index % liste.length]
  const contenu = <img src={urlImage(b.image_url, 1400, 'shop-assets')} alt={titreLocalise(b, i18n.language)} className="h-full w-full object-cover" />
  return (
    <div className="relative aspect-[16/7] overflow-hidden rounded-boutique bg-surface">
      {b.lien ? <a href={b.lien} className="block h-full">{contenu}</a> : contenu}
      {liste.length > 1 && (
        <div className="absolute inset-x-0 bottom-2 flex justify-center gap-1.5">
          {liste.map((x, i) => <button key={x.id as string} type="button" aria-label={String(i + 1)} onClick={() => setIndex(i)} className={`h-2 w-2 rounded-full ${i === index ? 'bg-white' : 'bg-white/50'}`} />)}
        </div>
      )}
    </div>
  )
}

function ProduitsSection({ titre, filtres }: { titre: string; filtres: FiltresCatalogue }) {
  const { boutique } = useBoutique()
  const { t } = useTranslation()
  const produits = useQuery({ queryKey: ['accueil', boutique.boutique_id, JSON.stringify(filtres)], queryFn: async () => (await chargerProduits(boutique.boutique_id, filtres, 0)).slice(0, 8) })
  if (!produits.data?.length) return null
  return (
    <section>
      <div className="mb-3 flex items-center justify-between"><h2 className="text-xl font-bold">{titre}</h2><Link to="/catalogue" className="text-sm text-primaire">{t('commun.voir_tout')}</Link></div>
      <GrilleProduits produits={produits.data} />
    </section>
  )
}

function CategoriesSection({ titre }: { titre: string }) {
  const { boutique } = useBoutique()
  const { i18n } = useTranslation()
  const categories = useQuery({ queryKey: ['categories', boutique.boutique_id], queryFn: () => chargerCategories(boutique.boutique_id) })
  if (!categories.data?.length) return null
  return (
    <section>
      <h2 className="mb-3 text-xl font-bold">{titre}</h2>
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {categories.data.filter((c) => !c.parent_id).map((c) => (
          <Link key={c.id as string} to={`/catalogue?categorie=${c.id}`} className="group overflow-hidden rounded-boutique border border-bordure bg-surface text-center">
            <div className="aspect-[4/3] bg-fond">{c.image_url && <img src={urlImage(c.image_url, 400, 'shop-assets')} alt="" loading="lazy" className="h-full w-full object-cover" />}</div>
            <p className="p-2 text-sm font-medium">{nomLocalise(c, i18n.language)}</p>
          </Link>
        ))}
      </div>
    </section>
  )
}

function Contact() {
  const { t, i18n } = useTranslation()
  const { boutique } = useBoutique()
  const horaires = Object.entries((boutique.horaires ?? {}) as Record<string, string>)
  return (
    <section className="carte space-y-1 text-sm">
      <h2 className="text-xl font-bold">{t('accueil.contact')}</h2>
      {boutique.adresse && <p>{boutique.adresse}{boutique.ville ? `, ${boutique.ville}` : ''}</p>}
      {boutique.telephone && <p dir="ltr">{boutique.telephone}</p>}
      {horaires.map(([jour, h]) => <p key={jour} className="text-discret">{jour} : {h}</p>)}
      {boutique.adresse && <a className="text-primaire" target="_blank" rel="noreferrer" href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${boutique.adresse} ${boutique.ville ?? ''} ${nomLocalise(boutique, i18n.language)}`)}`}>Maps</a>}
    </section>
  )
}

export function AccueilPage() {
  const { t, i18n } = useTranslation()
  const { boutique } = useBoutique()
  const sections = useQuery({
    queryKey: ['sections', boutique.boutique_id],
    queryFn: async () => ((await supabase.from('sections_site_publiques').select('*').eq('boutique_id', boutique.boutique_id).order('ordre')).data ?? []) as Section[],
  })
  const liste = sections.data && sections.data.length > 0 ? sections.data : SECTIONS_PAR_DEFAUT
  const titre = (s: Section, cle: string) => titreLocalise(s, i18n.language) || t(`accueil.${cle}`)

  return (
    <div className="space-y-8">
      <Seo />
      {liste.map((s) => {
        switch (s.type) {
          case 'banniere': return <Banniere key={s.id} />
          case 'categories_vedettes': return <CategoriesSection key={s.id} titre={titre(s, 'categories_vedettes')} />
          case 'nouveautes': return <ProduitsSection key={s.id} titre={titre(s, 'nouveautes')} filtres={{ tri: 'recent' }} />
          case 'promotions': return <ProduitsSection key={s.id} titre={titre(s, 'promotions')} filtres={{ tri: 'defaut', promoSeulement: true }} />
          case 'produits_populaires': return <ProduitsSection key={s.id} titre={titre(s, 'produits_populaires')} filtres={{ tri: 'defaut' }} />
          case 'a_propos': return <section key={s.id} className="carte"><h2 className="mb-2 text-xl font-bold">{titre(s, 'a_propos')}</h2><p className="whitespace-pre-line text-sm text-discret">{contenuLocalise(s, i18n.language)}</p></section>
          case 'contact': return <Contact key={s.id} />
        }
      })}
    </div>
  )
}
