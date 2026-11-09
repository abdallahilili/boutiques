import { hotePourResolution, sousDomaine } from './hote'

describe('sousDomaine', () => {
  it('extrait le sous-domaine', () => {
    expect(sousDomaine('mon-sac.plateforme.com', 'plateforme.com')).toBe('mon-sac')
    expect(sousDomaine('Mon-Sac.Plateforme.com', 'plateforme.com')).toBe('mon-sac')
  })
  it('ignore le domaine de base, www et les sous-niveaux', () => {
    expect(sousDomaine('plateforme.com', 'plateforme.com')).toBeNull()
    expect(sousDomaine('www.plateforme.com', 'plateforme.com')).toBeNull()
    expect(sousDomaine('a.b.plateforme.com', 'plateforme.com')).toBeNull()
  })
  it('ignore un domaine personnalisé', () => {
    expect(sousDomaine('www.maboutique.mr', 'plateforme.com')).toBeNull()
  })
  it('gère localhost en développement', () => {
    expect(sousDomaine('mon-sac.localhost', 'localhost')).toBe('mon-sac')
  })
})

describe('hotePourResolution', () => {
  it('utilise le slug de développement sur le domaine de base', () => {
    expect(hotePourResolution('localhost', 'localhost', 'mon-sac')).toBe('mon-sac.localhost')
    expect(hotePourResolution('127.0.0.1', 'localhost', 'mon-sac')).toBe('mon-sac.localhost')
  })
  it('conserve le nom réel sinon (sous-domaine ou domaine personnalisé)', () => {
    expect(hotePourResolution('a.plateforme.com', 'plateforme.com', 'x')).toBe('a.plateforme.com')
    expect(hotePourResolution('www.maboutique.mr', 'plateforme.com')).toBe('www.maboutique.mr')
  })
})
