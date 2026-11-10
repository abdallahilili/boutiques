export type RolePlateforme = 'super_admin' | 'support' | 'aucun'

export type EtatAuth = 'chargement' | 'anonyme' | 'refuse' | 'ok'

export interface EntreeEtat {
  session: boolean
  role: RolePlateforme | null
  actif: boolean
}

/** Accès à la console : session ouverte et compte actif avec un rôle éditeur (super_admin ou support). */
export function deduireEtat(e: EntreeEtat): EtatAuth {
  if (!e.session) return 'anonyme'
  if (e.role === null) return 'chargement'
  return e.actif && e.role !== 'aucun' ? 'ok' : 'refuse'
}
