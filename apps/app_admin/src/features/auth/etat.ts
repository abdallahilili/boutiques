export type RolePlateforme = 'super_admin' | 'support' | 'aucun'
export type NiveauAssurance = 'aal1' | 'aal2'

export type EtatAuth = 'chargement' | 'anonyme' | 'refuse' | 'mfa_enrolement' | 'mfa_verification' | 'ok'

export interface EntreeEtat {
  session: boolean
  role: RolePlateforme | null
  actif: boolean
  niveauActuel: NiveauAssurance | null
  niveauSuivant: NiveauAssurance | null
}

/**
 * Déduit l'étape d'accès à la console : session → rôle éditeur → 2FA TOTP (obligatoire).
 * Un compte sans rôle éditeur est refusé avant tout enrôlement 2FA.
 */
export function deduireEtat(e: EntreeEtat): EtatAuth {
  if (!e.session) return 'anonyme'
  if (e.role === null) return 'chargement'
  if (!e.actif || e.role === 'aucun') return 'refuse'
  if (e.niveauActuel === 'aal2') return 'ok'
  return e.niveauSuivant === 'aal2' ? 'mfa_verification' : 'mfa_enrolement'
}
