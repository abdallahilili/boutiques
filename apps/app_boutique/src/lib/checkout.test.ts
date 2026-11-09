import { construireCommande, identifiantTentative, lienWhatsapp, oublierTentative, validerCommande, type FormulaireCommande } from './checkout'
import type { LignePanier } from './panier'

const lignes: LignePanier[] = [{ varianteId: 'v1', produitSlug: 'sac', quantite: 2, libelleAr: 'حقيبة', libelleFr: 'Sac', prix: 800, image: null }]
const formulaire: FormulaireCommande = {
  nom: 'Fatima', telephone: '36 00 00 77', adresse: 'Tevragh Zeina', ville: 'Nouakchott', zoneId: 'z1',
  modeLivraison: 'livraison', modePaiement: 'a_la_livraison', notes: '', miel: '',
}

describe('validerCommande', () => {
  it('accepte une commande complète', () => {
    expect(validerCommande(formulaire, lignes)).toEqual([])
  })
  it('exige nom, téléphone, adresse (livraison) et un panier non vide', () => {
    expect(validerCommande({ ...formulaire, nom: ' ', telephone: 'abc', adresse: '' }, [])).toEqual(['nom', 'telephone', 'adresse', 'panier_vide'])
  })
  it('l\'adresse n\'est pas requise pour un retrait en boutique', () => {
    expect(validerCommande({ ...formulaire, modeLivraison: 'retrait', adresse: '' }, lignes)).toEqual([])
  })
})

describe('construireCommande', () => {
  it('n\'envoie jamais de prix : seulement variante et quantité', () => {
    const corps = construireCommande('id-1', formulaire, lignes)
    expect(corps.lignes).toEqual([{ variante_id: 'v1', quantite: 2 }])
    expect(JSON.stringify(corps)).not.toContain('800')
  })
  it('retrait : ni adresse ni zone', () => {
    const corps = construireCommande('id-1', { ...formulaire, modeLivraison: 'retrait' }, lignes)
    expect(corps.adresse).toBeNull()
    expect(corps.zone_id).toBeNull()
  })
})

describe('identifiantTentative', () => {
  it('reste stable jusqu\'à confirmation (idempotence en cas de rejeu)', () => {
    oublierTentative()
    const a = identifiantTentative()
    expect(identifiantTentative()).toBe(a)
    oublierTentative()
    expect(identifiantTentative()).not.toBe(a)
  })
})

describe('lienWhatsapp', () => {
  it('construit le lien avec le message encodé', () => {
    expect(lienWhatsapp('+222 36 00 00 01', 'Bonjour & merci')).toBe('https://wa.me/22236000001?text=Bonjour%20%26%20merci')
  })
  it('aucun lien sans numéro valide', () => {
    expect(lienWhatsapp(null, 'x')).toBeNull()
  })
})
