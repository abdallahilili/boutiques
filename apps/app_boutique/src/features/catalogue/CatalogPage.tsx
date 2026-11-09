import { useEffect, useState } from 'react'
import { useInfiniteQuery, useQuery } from '@tanstack/react-query'
import { Link, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { nomLocalise } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'
import { Seo } from '@/features/layout/Seo'
import { chargerCategories, chargerProduits, suggestions, TAILLE_PAGE, type FiltresCatalogue, type Tri } from './api'
import { GrilleProduits } from './ProductCard'

function useDebounce<T>(valeur: T, delai = 250): T {
  const [v, setV] = useState(valeur)
  useEffect(() => {
    const id = setTimeout(() => setV(valeur), delai)
    return () => clearTimeout(id)
  }, [valeur, delai])
  return v
}

function lireFiltres(p: URLSearchParams): FiltresCatalogue {
  const nombre = (cle: string) => (p.get(cle) ? Number(p.get(cle)) : undefined)
  return {
    categorieId: p.get('categorie') ?? undefined, couleurId: p.get('couleur') ?? undefined, modeleId: p.get('modele') ?? undefined,
    prixMin: nombre('min'), prixMax: nombre('max'), disponiblesSeulement: p.get('dispo') === '1', recherche: p.get('q') ?? undefined,
    tri: (p.get('tri') as Tri | null) ?? 'defaut',
  }
}

export function CatalogPage() {
  const { t, i18n } = useTranslation()
  const { boutique } = useBoutique()
  const [params, setParams] = useSearchParams()
  const filtres = lireFiltres(params)
  const [saisie, setSaisie] = useState(filtres.recherche ?? '')
  const saisieDiffere = useDebounce(saisie)

  const maj = (cle: string, valeur: string | null) => {
    const suivants = new URLSearchParams(params)
    if (valeur) suivants.set(cle, valeur)
    else suivants.delete(cle)
    setParams(suivants, { replace: true })
  }
  useEffect(() => {
    if ((params.get('q') ?? '') !== saisieDiffere) {
      const suivants = new URLSearchParams(params)
      if (saisieDiffere) suivants.set('q', saisieDiffere)
      else suivants.delete('q')
      setParams(suivants, { replace: true })
    }
  }, [saisieDiffere, params, setParams])

  const categories = useQuery({ queryKey: ['categories', boutique.boutique_id], queryFn: () => chargerCategories(boutique.boutique_id) })
  const couleurs = useQuery({
    queryKey: ['couleurs', boutique.boutique_id],
    queryFn: async () => (await supabase.from('couleurs_publiques').select('*').eq('boutique_id', boutique.boutique_id).order('ordre')).data ?? [],
  })
  const modeles = useQuery({
    queryKey: ['modeles', boutique.boutique_id],
    queryFn: async () => (await supabase.from('modeles_publics').select('*').eq('boutique_id', boutique.boutique_id)).data ?? [],
  })
  const propositions = useQuery({
    queryKey: ['suggestions', boutique.boutique_id, saisieDiffere],
    queryFn: () => suggestions(boutique.boutique_id, saisieDiffere),
    enabled: saisieDiffere.trim().length >= 2 && saisieDiffere !== filtres.recherche,
  })

  const produits = useInfiniteQuery({
    queryKey: ['produits', boutique.boutique_id, params.toString()],
    initialPageParam: 0,
    queryFn: ({ pageParam }) => chargerProduits(boutique.boutique_id, filtres, pageParam),
    getNextPageParam: (derniere, toutes) => (derniere.length === TAILLE_PAGE ? toutes.length : undefined),
  })
  const liste = produits.data?.pages.flat() ?? []
  const nbFiltres = ['categorie', 'couleur', 'modele', 'min', 'max', 'dispo', 'q'].filter((c) => params.get(c)).length

  return (
    <>
      <Seo titre={t('catalogue.titre')} />
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <h1 className="me-auto text-2xl font-bold">{t('catalogue.titre')}</h1>
        <div className="relative w-full sm:w-72">
          <input className="input" type="search" placeholder={t('commun.rechercher')} value={saisie} onChange={(e) => setSaisie(e.target.value)} />
          {(propositions.data?.length ?? 0) > 0 && (
            <ul className="absolute z-20 mt-1 w-full overflow-hidden rounded-boutique border border-bordure bg-fond shadow-lg">
              {propositions.data?.map((p) => (
                <li key={p.id as string}><Link className="block px-3 py-2 text-sm hover:bg-surface" to={`/produit/${p.slug}`}>{nomLocalise(p, i18n.language)}</Link></li>
              ))}
            </ul>
          )}
        </div>
        <select className="input w-auto" value={filtres.tri} onChange={(e) => maj('tri', e.target.value === 'defaut' ? null : e.target.value)} aria-label={t('catalogue.tri')}>
          <option value="defaut">{t('catalogue.tri_defaut')}</option>
          <option value="prix_asc">{t('catalogue.tri_prix_asc')}</option>
          <option value="prix_desc">{t('catalogue.tri_prix_desc')}</option>
          <option value="recent">{t('catalogue.tri_recent')}</option>
        </select>
      </div>

      <div className="grid gap-4 md:grid-cols-[14rem_1fr]">
        <aside className="carte space-y-3 text-sm md:self-start" aria-label={t('catalogue.filtres')}>
          <div>
            <p className="etiquette">{t('catalogue.categorie')}</p>
            <select className="input" value={filtres.categorieId ?? ''} onChange={(e) => maj('categorie', e.target.value || null)}>
              <option value="">{t('catalogue.toutes')}</option>
              {categories.data?.map((c) => <option key={c.id as string} value={c.id as string}>{nomLocalise(c, i18n.language)}</option>)}
            </select>
          </div>
          {(couleurs.data?.length ?? 0) > 0 && (
            <div>
              <p className="etiquette">{t('catalogue.couleur')}</p>
              <div className="flex flex-wrap gap-2">
                {couleurs.data?.map((c) => (
                  <button key={c.id as string} type="button" title={nomLocalise(c, i18n.language)} aria-label={nomLocalise(c, i18n.language)} aria-pressed={filtres.couleurId === c.id}
                    onClick={() => maj('couleur', filtres.couleurId === c.id ? null : (c.id as string))}
                    className={`h-7 w-7 rounded-full border-2 ${filtres.couleurId === c.id ? 'border-primaire ring-2 ring-primaire/40' : 'border-bordure'}`}
                    style={{ backgroundColor: c.code_hex as string }} />
                ))}
              </div>
            </div>
          )}
          {(modeles.data?.length ?? 0) > 0 && (
            <div>
              <p className="etiquette">{t('catalogue.modele')}</p>
              <select className="input" value={filtres.modeleId ?? ''} onChange={(e) => maj('modele', e.target.value || null)}>
                <option value="">{t('catalogue.toutes')}</option>
                {modeles.data?.map((m) => <option key={m.id as string} value={m.id as string}>{nomLocalise(m, i18n.language)}</option>)}
              </select>
            </div>
          )}
          <div className="grid grid-cols-2 gap-2">
            <label><span className="etiquette">{t('catalogue.prix_min')}</span><input className="input" type="number" min="0" value={params.get('min') ?? ''} onChange={(e) => maj('min', e.target.value)} /></label>
            <label><span className="etiquette">{t('catalogue.prix_max')}</span><input className="input" type="number" min="0" value={params.get('max') ?? ''} onChange={(e) => maj('max', e.target.value)} /></label>
          </div>
          <label className="flex items-center gap-2"><input type="checkbox" checked={!!filtres.disponiblesSeulement} onChange={(e) => maj('dispo', e.target.checked ? '1' : null)} />{t('catalogue.disponibles')}</label>
          {nbFiltres > 0 && <button className="btn w-full" onClick={() => { setSaisie(''); setParams({}, { replace: true }) }}>{t('catalogue.effacer')}</button>}
        </aside>

        <section>
          {produits.isLoading && <p className="text-discret">{t('commun.chargement')}</p>}
          {produits.error && <p role="alert" className="text-danger">{t('commun.erreur')}</p>}
          {!produits.isLoading && liste.length === 0 && <p className="py-12 text-center text-discret">{t('catalogue.aucun')}</p>}
          <GrilleProduits produits={liste} />
          {produits.hasNextPage && (
            <div className="mt-6 text-center">
              <button className="btn" disabled={produits.isFetchingNextPage} onClick={() => void produits.fetchNextPage()}>{t('commun.voir_plus')}</button>
            </div>
          )}
        </section>
      </div>
    </>
  )
}
