import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import type { Session } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'
import { deconnexionCliente } from './api'

interface ContexteAuth {
  session: Session | null
  chargement: boolean
  deconnexion: () => Promise<void>
}

const Contexte = createContext<ContexteAuth | null>(null)

/** Session de la cliente connectée (compte optionnel : le checkout fonctionne sans compte). */
export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [chargement, setChargement] = useState(true)

  useEffect(() => {
    const { data } = supabase.auth.onAuthStateChange((_evenement, nouvelle) => {
      setSession(nouvelle)
      setChargement(false)
    })
    return () => data.subscription.unsubscribe()
  }, [])

  const valeur = useMemo(() => ({ session, chargement, deconnexion: deconnexionCliente }), [session, chargement])
  return <Contexte.Provider value={valeur}>{children}</Contexte.Provider>
}

export function useAuth(): ContexteAuth {
  const contexte = useContext(Contexte)
  if (!contexte) throw new Error('useAuth doit être utilisé dans AuthProvider')
  return contexte
}
