import { versCsv } from './csv'
import { motifRecherche, nomLocalise } from './format'

describe('versCsv', () => {
  it('sépare par « ; » et échappe guillemets, retours à la ligne et séparateurs', () => {
    expect(versCsv(['a', 'b'], [['x;y', 'dit "oui"'], [null, 3]])).toBe('a;b\r\n"x;y";"dit ""oui"""\r\n;3')
  })
})

describe('format', () => {
  it('nomLocalise : langue demandée puis repli', () => {
    expect(nomLocalise({ nom_ar: 'حقيبة', nom_fr: 'Sac' }, 'ar')).toBe('حقيبة')
    expect(nomLocalise({ nom_ar: null, nom_fr: 'Sac' }, 'ar')).toBe('Sac')
    expect(nomLocalise({}, 'fr')).toBe('—')
  })
  it('motifRecherche neutralise les caractères du filtre PostgREST', () => {
    expect(motifRecherche('a,b(c)%d')).toBe('%a b c d%')
  })
})
