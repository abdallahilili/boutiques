import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import { supabase } from '@/lib/supabase'
import { emailEquipe } from '@/lib/telephone'
import { deduireEtat, type EtatAuth, type RolePlateforme } from './etat'

interface ContexteAuth {
  etat: EtatAuth
  role: RolePlateforme | null
  nom: string | null
  seConnecter: (telephone: string, motDePasse: string) => Promise<void>
  rafraichir: () => Promise<void>
  deconnexion: () => Promise<void>
}

const Contexte = createContext<ContexteAuth | null>(null)

interface Instantane {
  session: boolean
  nom: string | null
  role: RolePlateforme | null
  actif: boolean
}

const VIDE: Instantane = { session: false, nom: null, role: null, actif: false }

async function lireInstantane(): Promise<Instantane> {
  const { data: { session } } = await supabase.auth.getSession()
  if (!session) return VIDE
  const { data: profil } = await supabase.from('profils').select('nom_ar, nom_fr, telephone, role_plateforme, actif').eq('id', session.user.id).maybeSingle()
  return {
    session: true,
    nom: profil?.nom_fr ?? profil?.nom_ar ?? profil?.telephone ?? null,
    role: profil?.role_plateforme ?? 'aucun',
    actif: profil?.actif ?? false,
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [instantane, setInstantane] = useState<Instantane | null>(null)

  const rafraichir = useCallback(async () => setInstantane(await lireInstantane()), [])

  useEffect(() => {
    const { data } = supabase.auth.onAuthStateChange((evenement) => {
      if (evenement === 'SIGNED_OUT') setInstantane(VIDE)
      else if (evenement !== 'TOKEN_REFRESHED') setTimeout(() => void rafraichir(), 0)
    })
    return () => data.subscription.unsubscribe()
  }, [rafraichir])

  const valeur = useMemo<ContexteAuth>(
    () => ({
      etat: instantane ? deduireEtat(instantane) : 'chargement',
      role: instantane?.role ?? null,
      nom: instantane?.nom ?? null,
      rafraichir,
      seConnecter: async (telephone, motDePasse) => {
        const { error } = await supabase.auth.signInWithPassword({ email: emailEquipe(telephone), password: motDePasse })
        if (error) throw error
        await rafraichir()
      },
      deconnexion: async () => {
        await supabase.auth.signOut()
        setInstantane(VIDE)
      },
    }),
    [instantane, rafraichir],
  )

  return <Contexte.Provider value={valeur}>{children}</Contexte.Provider>
}

export function useAuth(): ContexteAuth {
  const contexte = useContext(Contexte)
  if (!contexte) throw new Error('useAuth doit être utilisé dans AuthProvider')
  return contexte
}
