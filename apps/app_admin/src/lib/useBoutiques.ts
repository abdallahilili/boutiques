import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { Tables } from '@/types/database'

export type BoutiqueResume = Pick<Tables<'boutiques'>, 'id' | 'nom_ar' | 'nom_fr' | 'slug' | 'statut' | 'devise' | 'commercante_id' | 'code_boutique'>

/** Toutes les boutiques (≈ 100 en V1) : sert de table de correspondance id → nom pour les autres écrans. */
export function useBoutiques() {
  const requete = useQuery({
    queryKey: ['boutiques', 'resume'],
    queryFn: async () => {
      const { data, error } = await supabase.from('boutiques')
        .select('id, nom_ar, nom_fr, slug, statut, devise, commercante_id, code_boutique').order('cree_le', { ascending: false })
      if (error) throw new Error(error.message)
      return data as BoutiqueResume[]
    },
  })
  const parId = new Map((requete.data ?? []).map((b) => [b.id, b]))
  return { boutiques: requete.data ?? [], parId, chargement: requete.isLoading }
}

export function usePlans() {
  const requete = useQuery({
    queryKey: ['plans'],
    queryFn: async () => {
      const { data, error } = await supabase.from('plans').select('*').order('ordre')
      if (error) throw new Error(error.message)
      return data
    },
  })
  const parId = new Map((requete.data ?? []).map((p) => [p.id, p]))
  return { plans: requete.data ?? [], parId, chargement: requete.isLoading }
}
