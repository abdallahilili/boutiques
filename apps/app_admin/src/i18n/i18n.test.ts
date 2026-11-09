import i18n, { changerLangue } from './index'
import ar from './ar.json'
import fr from './fr.json'

function cles(objet: Record<string, unknown>, prefixe = ''): string[] {
  return Object.entries(objet).flatMap(([k, v]) =>
    typeof v === 'object' && v !== null ? cles(v as Record<string, unknown>, `${prefixe}${k}.`) : [`${prefixe}${k}`],
  )
}

describe('i18n', () => {
  it("l'arabe est la langue par défaut, en RTL", () => {
    expect(i18n.language).toBe('ar')
    expect(document.documentElement.dir).toBe('rtl')
  })
  it('la bascule en français passe en LTR', async () => {
    await changerLangue('fr')
    expect(document.documentElement.dir).toBe('ltr')
    expect(i18n.t('auth.connexion')).toBe('Se connecter')
    await changerLangue('ar')
  })
  it('ar et fr ont exactement les mêmes clés', () => {
    expect(cles(ar).sort()).toEqual(cles(fr).sort())
  })
})
