import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react'
import { ajouter, changerQuantite, charger, nombreArticles, retirer, sauvegarder, sousTotal, type LignePanier } from '@/lib/panier'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'

interface ContextePanier {
  lignes: LignePanier[]
  articles: number
  sousTotal: number
  ajouter: (ligne: LignePanier) => void
  changerQuantite: (varianteId: string, quantite: number) => void
  retirer: (varianteId: string) => void
  vider: () => void
}

const Contexte = createContext<ContextePanier | null>(null)

/** Panier persistant (localStorage, une clé par boutique) : conservé hors ligne et entre les visites. */
export function PanierProvider({ children }: { children: ReactNode }) {
  const { boutique } = useBoutique()
  const [lignes, setLignes] = useState<LignePanier[]>(() => charger(boutique.boutique_id))

  const maj = useCallback((fn: (l: LignePanier[]) => LignePanier[]) => {
    setLignes((courantes) => {
      const suivantes = fn(courantes)
      sauvegarder(boutique.boutique_id, suivantes)
      return suivantes
    })
  }, [boutique.boutique_id])

  const valeur = useMemo<ContextePanier>(() => ({
    lignes,
    articles: nombreArticles(lignes),
    sousTotal: sousTotal(lignes),
    ajouter: (ligne) => maj((l) => ajouter(l, ligne)),
    changerQuantite: (id, q) => maj((l) => changerQuantite(l, id, q)),
    retirer: (id) => maj((l) => retirer(l, id)),
    vider: () => maj(() => []),
  }), [lignes, maj])

  return <Contexte.Provider value={valeur}>{children}</Contexte.Provider>
}

export function usePanier(): ContextePanier {
  const contexte = useContext(Contexte)
  if (!contexte) throw new Error('usePanier doit être utilisé dans PanierProvider')
  return contexte
}
