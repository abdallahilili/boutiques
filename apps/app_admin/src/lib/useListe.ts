import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'

export const TAILLE_PAGE = 20

interface Resultat<T> {
  data: T[] | null
  count: number | null
  error: { message: string } | null
}

/**
 * Liste paginée côté serveur. `charger(debut, fin)` exécute la requête filtrée avec `.range(debut, fin)`
 * et `{ count: 'exact' }`. `cle` doit contenir les filtres pour relancer la requête à chaque changement.
 */
export function useListe<T>(cle: unknown[], charger: (debut: number, fin: number) => PromiseLike<Resultat<T>>) {
  const [page, setPage] = useState(0)
  const requete = useQuery({
    queryKey: [...cle, page],
    placeholderData: keepPreviousData,
    queryFn: async () => {
      const { data, count, error } = await charger(page * TAILLE_PAGE, page * TAILLE_PAGE + TAILLE_PAGE - 1)
      if (error) throw new Error(error.message)
      return { lignes: data ?? [], total: count ?? 0 }
    },
  })
  return {
    lignes: requete.data?.lignes ?? [],
    total: requete.data?.total ?? 0,
    page,
    setPage,
    chargement: requete.isFetching,
    erreur: requete.error as Error | null,
    recharger: requete.refetch,
  }
}
