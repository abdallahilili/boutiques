import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import { supabase } from '@/lib/supabase'
import { deduireEtat, type EtatAuth, type NiveauAssurance, type RolePlateforme } from './etat'

interface ContexteAuth {
  etat: EtatAuth
  role: RolePlateforme | null
  email: string | null
  seConnecter: (email: string, motDePasse: string) => Promise<void>
  rafraichir: () => Promise<void>
  deconnexion: () => Promise<void>
}

const Contexte = createContext<ContexteAuth | null>(null)

interface Instantane {
  session: boolean
  email: string | null
  role: RolePlateforme | null
  actif: boolean
  niveauActuel: NiveauAssurance | null
  niveauSuivant: NiveauAssurance | null
}

const VIDE: Instantane = { session: false, email: null, role: null, actif: false, niveauActuel: null, niveauSuivant: null }

async function lireInstantane(): Promise<Instantane> {
  const { data: { session } } = await supabase.auth.getSession()
  if (!session) return VIDE
  const [{ data: profil }, { data: niveaux }] = await Promise.all([
    supabase.from('profils').select('role_plateforme, actif').eq('id', session.user.id).maybeSingle(),
    supabase.auth.mfa.getAuthenticatorAssuranceLevel(),
  ])
  return {
    session: true,
    email: session.user.email ?? null,
    role: profil?.role_plateforme ?? 'aucun',
    actif: profil?.actif ?? false,
    niveauActuel: (niveaux?.currentLevel as NiveauAssurance | null | undefined) ?? null,
    niveauSuivant: (niveaux?.nextLevel as NiveauAssurance | null | undefined) ?? null,
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
      email: instantane?.email ?? null,
      rafraichir,
      seConnecter: async (email, motDePasse) => {
        const { error } = await supabase.auth.signInWithPassword({ email, password: motDePasse })
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
