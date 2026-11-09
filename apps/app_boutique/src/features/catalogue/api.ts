import { supabase } from '@/lib/supabase'
import type { Views } from '@/types/database'

export type ProduitPublic = Views<'produits_publics'>
export type VariantePublique = Views<'variantes_publiques'>
export type ImagePublique = Views<'images_publiques'>
export type CategoriePublique = Views<'categories_publiques'>

export const TAILLE_PAGE = 12

export type Tri = 'defaut' | 'prix_asc' | 'prix_desc' | 'recent'

export interface FiltresCatalogue {
  categorieId?: string
  couleurId?: string
  modeleId?: string
  prixMin?: number
  prixMax?: number
  disponiblesSeulement?: boolean
  promoSeulement?: boolean
  recherche?: string
  tri: Tri
}

/** Retire les caractères qui ont un sens dans un filtre PostgREST (.or / ilike). */
export function motifRecherche(saisie: string): string {
  return `%${saisie.replace(/[%_,()*]/g, ' ').replace(/\s+/g, ' ').trim()}%`
}

/** Produits ayant au moins une variante de la couleur / du modèle demandé. */
async function idsProduits(boutiqueId: string, f: FiltresCatalogue): Promise<string[] | null> {
  if (!f.couleurId && !f.modeleId) return null
  let q = supabase.from('variantes_publiques').select('produit_id').eq('boutique_id', boutiqueId)
  if (f.couleurId) q = q.eq('couleur_id', f.couleurId)
  if (f.modeleId) q = q.eq('modele_id', f.modeleId)
  const { data, error } = await q
  if (error) throw new Error(error.message)
  return [...new Set((data ?? []).map((v) => v.produit_id as string))]
}

/**
 * Page de produits. Ordre par défaut : produits épinglés en tête (ordre d'épinglage),
 * puis catégories dans l'ordre choisi par la commerçante, puis ordre du produit.
 */
export async function chargerProduits(boutiqueId: string, f: FiltresCatalogue, page: number): Promise<ProduitPublic[]> {
  const ids = await idsProduits(boutiqueId, f)
  if (ids && ids.length === 0) return []

  let q = supabase.from('produits_publics').select('*').eq('boutique_id', boutiqueId)
  if (ids) q = q.in('id', ids)
  if (f.categorieId) q = q.eq('categorie_id', f.categorieId)
  if (f.prixMin !== undefined) q = q.gte('prix_min', f.prixMin)
  if (f.prixMax !== undefined) q = q.lte('prix_min', f.prixMax)
  if (f.disponiblesSeulement) q = q.eq('epuise', false)
  if (f.promoSeulement) q = q.eq('en_promo', true)
  if (f.recherche?.trim()) q = q.or(`nom_ar.ilike.${motifRecherche(f.recherche)},nom_fr.ilike.${motifRecherche(f.recherche)}`)

  if (f.tri === 'prix_asc') q = q.order('prix_min', { ascending: true })
  else if (f.tri === 'prix_desc') q = q.order('prix_min', { ascending: false })
  else if (f.tri === 'recent') q = q.order('cree_le', { ascending: false })
  else {
    q = q.order('epingle', { ascending: false })
      .order('ordre_epinglage', { ascending: true, nullsFirst: false })
      .order('categorie_ordre', { ascending: true, nullsFirst: false })
      .order('ordre', { ascending: true })
      .order('cree_le', { ascending: false })
  }
  const { data, error } = await q.range(page * TAILLE_PAGE, page * TAILLE_PAGE + TAILLE_PAGE - 1)
  if (error) throw new Error(error.message)
  return data as ProduitPublic[]
}

export async function suggestions(boutiqueId: string, saisie: string): Promise<ProduitPublic[]> {
  if (saisie.trim().length < 2) return []
  return chargerProduits(boutiqueId, { tri: 'defaut', recherche: saisie }, 0).then((p) => p.slice(0, 5))
}

export async function chargerCategories(boutiqueId: string): Promise<CategoriePublique[]> {
  const { data, error } = await supabase.from('categories_publiques').select('*').eq('boutique_id', boutiqueId).order('ordre')
  if (error) throw new Error(error.message)
  return data as CategoriePublique[]
}

export async function chargerProduit(boutiqueId: string, slug: string) {
  const { data: produit, error } = await supabase.from('produits_publics').select('*').eq('boutique_id', boutiqueId).eq('slug', slug).maybeSingle()
  if (error) throw new Error(error.message)
  if (!produit) return null
  const [variantes, images] = await Promise.all([
    supabase.from('variantes_publiques').select('*').eq('produit_id', produit.id as string),
    supabase.from('images_publiques').select('*').eq('produit_id', produit.id as string).order('principale', { ascending: false }).order('ordre'),
  ])
  if (variantes.error) throw new Error(variantes.error.message)
  if (images.error) throw new Error(images.error.message)
  return { produit: produit as ProduitPublic, variantes: variantes.data as VariantePublique[], images: images.data as ImagePublique[] }
}
