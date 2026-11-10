import { emailEquipe, normaliserTelephone } from './telephone'

describe('telephone', () => {
  it('ajoute l\'indicatif aux numéros locaux', () => {
    expect(normaliserTelephone('31 17 70 08')).toBe('22231177008')
  })
  it('accepte +, 00 et espaces', () => {
    expect(normaliserTelephone('+222 31177008')).toBe('22231177008')
    expect(normaliserTelephone('00222-31177008')).toBe('22231177008')
  })
  it('identifiant technique stable (même numéro, même identifiant)', () => {
    expect(emailEquipe('31177008')).toBe('22231177008@admin.invalid')
    expect(emailEquipe('+222 31177008')).toBe(emailEquipe('31177008'))
  })
})
