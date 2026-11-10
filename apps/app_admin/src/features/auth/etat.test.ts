import { deduireEtat, type EntreeEtat } from './etat'

const base: EntreeEtat = { session: true, role: 'super_admin', actif: true }

describe('deduireEtat', () => {
  it('sans session → anonyme', () => {
    expect(deduireEtat({ ...base, session: false })).toBe('anonyme')
  })
  it('profil en cours de chargement → chargement', () => {
    expect(deduireEtat({ ...base, role: null })).toBe('chargement')
  })
  it('compte sans rôle éditeur ou désactivé → refusé', () => {
    expect(deduireEtat({ ...base, role: 'aucun' })).toBe('refuse')
    expect(deduireEtat({ ...base, actif: false })).toBe('refuse')
  })
  it('super_admin et support actifs → accès accordé', () => {
    expect(deduireEtat(base)).toBe('ok')
    expect(deduireEtat({ ...base, role: 'support' })).toBe('ok')
  })
})
