import { deduireEtat, type EntreeEtat } from './etat'

const base: EntreeEtat = { session: true, role: 'super_admin', actif: true, niveauActuel: 'aal1', niveauSuivant: 'aal1' }

describe('deduireEtat', () => {
  it('sans session → anonyme', () => {
    expect(deduireEtat({ ...base, session: false })).toBe('anonyme')
  })
  it('profil en cours de chargement → chargement', () => {
    expect(deduireEtat({ ...base, role: null })).toBe('chargement')
  })
  it('compte sans rôle éditeur ou désactivé → refusé avant tout enrôlement 2FA', () => {
    expect(deduireEtat({ ...base, role: 'aucun' })).toBe('refuse')
    expect(deduireEtat({ ...base, actif: false })).toBe('refuse')
  })
  it('aucun facteur TOTP → enrôlement obligatoire', () => {
    expect(deduireEtat(base)).toBe('mfa_enrolement')
  })
  it('facteur TOTP enrôlé mais non vérifié → vérification', () => {
    expect(deduireEtat({ ...base, niveauSuivant: 'aal2' })).toBe('mfa_verification')
  })
  it('niveau aal2 atteint → accès accordé (super_admin et support)', () => {
    expect(deduireEtat({ ...base, niveauActuel: 'aal2', niveauSuivant: 'aal2' })).toBe('ok')
    expect(deduireEtat({ ...base, role: 'support', niveauActuel: 'aal2', niveauSuivant: 'aal2' })).toBe('ok')
  })
})
