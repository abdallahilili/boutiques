import { ajouter, changerQuantite, charger, nombreArticles, QUANTITE_MAX, retirer, sauvegarder, sousTotal, type LignePanier } from './panier'

const ligne = (id: string, quantite = 1, prix = 1000): LignePanier => ({
  varianteId: id, produitSlug: 'sac', quantite, libelleAr: 'حقيبة', libelleFr: 'Sac', prix, image: null,
})

describe('panier', () => {
  it('fusionne les ajouts de la même variante', () => {
    const lignes = ajouter(ajouter([], ligne('a', 1)), ligne('a', 2))
    expect(lignes).toHaveLength(1)
    expect(lignes[0].quantite).toBe(3)
  })

  it('borne les quantités (1 à 99, entières)', () => {
    expect(ajouter([], ligne('a', 500))[0].quantite).toBe(QUANTITE_MAX)
    expect(changerQuantite([ligne('a', 2)], 'a', 7.9)[0].quantite).toBe(7)
  })

  it('une quantité nulle retire la ligne', () => {
    expect(changerQuantite([ligne('a'), ligne('b')], 'a', 0).map((l) => l.varianteId)).toEqual(['b'])
    expect(retirer([ligne('a')], 'a')).toEqual([])
  })

  it('calcule sous-total et nombre d\'articles', () => {
    const lignes = [ligne('a', 2, 800), ligne('b', 1, 500)]
    expect(sousTotal(lignes)).toBe(2100)
    expect(nombreArticles(lignes)).toBe(3)
  })

  it('persiste par boutique et ignore les données corrompues', () => {
    sauvegarder('b1', [ligne('a', 2)])
    expect(charger('b1')).toHaveLength(1)
    expect(charger('b2')).toEqual([])
    localStorage.setItem('panier.b3', '{pas du json')
    expect(charger('b3')).toEqual([])
    localStorage.setItem('panier.b4', JSON.stringify([{ varianteId: 1 }, ligne('ok')]))
    expect(charger('b4').map((l) => l.varianteId)).toEqual(['ok'])
  })
})
