import { appliquerTheme, contraste, miseEnPage, variablesTheme } from './theme'

describe('variablesTheme', () => {
  it('convertit les couleurs, la police et le rayon en variables CSS', () => {
    const v = variablesTheme({ couleurs: { primaire: '#112233', fond: '#ffffff' }, police: 'serif', rayon: 'grand' })
    expect(v['--b-primaire']).toBe('#112233')
    expect(v['--b-fond']).toBe('#ffffff')
    expect(v['--b-police']).toContain('Georgia')
    expect(v['--b-rayon']).toBe('1.25rem')
  })

  it('ignore toute valeur invalide (pas d\'injection CSS)', () => {
    const v = variablesTheme({ couleurs: { primaire: 'red; background:url(x)', texte: '#12345' }, police: 'x; evil', rayon: 'énorme' })
    expect(v).toEqual({})
  })

  it('choisit un texte lisible sur le bouton principal', () => {
    expect(contraste('#000000')).toBe('#ffffff')
    expect(contraste('#fff200')).toBe('#111111')
    expect(variablesTheme({ couleurs: { primaire: '#ffffff' } })['--b-primaire-texte']).toBe('#111111')
  })

  it('aucune configuration : aucune variable', () => {
    expect(variablesTheme(null)).toEqual({})
  })
})

describe('miseEnPage', () => {
  it('la configuration de la commerçante prime sur le thème', () => {
    expect(miseEnPage({ entete: 'gauche', grille: 3, style_carte: 'ombre' }, { grille: 2 })).toEqual({ entete: 'gauche', grille: 2, styleCarte: 'ombre' })
  })
  it('valeurs par défaut sûres', () => {
    expect(miseEnPage(null, { entete: 'inconnu', grille: 7, style_carte: 'x' })).toEqual({ entete: 'centre', grille: 2, styleCarte: 'bordure' })
  })
})

describe('appliquerTheme', () => {
  it('pose puis retire les variables', () => {
    const racine = document.createElement('div')
    const retirer = appliquerTheme(racine, { '--b-primaire': '#112233' })
    expect(racine.style.getPropertyValue('--b-primaire')).toBe('#112233')
    retirer()
    expect(racine.style.getPropertyValue('--b-primaire')).toBe('')
  })
})
