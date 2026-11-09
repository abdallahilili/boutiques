import type { LignePanier } from './panier'

export interface FormulaireCommande {
  nom: string
  telephone: string
  adresse: string
  ville: string
  zoneId: string
  modeLivraison: 'livraison' | 'retrait'
  modePaiement: 'a_la_livraison' | 'mobile_money'
  notes: string
  /** Champ piège anti-robot : doit rester vide. */
  miel: string
}

export type ErreurFormulaire = 'nom' | 'telephone' | 'adresse' | 'panier_vide'

/** Validation côté navigateur (le serveur revalide tout : prix, stock, options de la boutique). */
export function validerCommande(f: FormulaireCommande, lignes: LignePanier[]): ErreurFormulaire[] {
  const erreurs: ErreurFormulaire[] = []
  if (f.nom.trim().length < 2) erreurs.push('nom')
  if (!/^[0-9+\s().-]{8,20}$/.test(f.telephone.trim())) erreurs.push('telephone')
  if (f.modeLivraison === 'livraison' && f.adresse.trim() === '') erreurs.push('adresse')
  if (lignes.length === 0) erreurs.push('panier_vide')
  return erreurs
}

/** Corps de la RPC passer_commande_en_ligne : aucun prix n'est envoyé (le serveur décide). */
export function construireCommande(id: string, f: FormulaireCommande, lignes: LignePanier[]) {
  return {
    id,
    nom_client: f.nom.trim(),
    telephone: f.telephone.trim(),
    adresse: f.modeLivraison === 'livraison' ? f.adresse.trim() : null,
    ville: f.ville.trim() || null,
    zone_id: f.modeLivraison === 'livraison' && f.zoneId ? f.zoneId : null,
    mode_livraison: f.modeLivraison,
    mode_paiement: f.modePaiement,
    notes: f.notes.trim() || null,
    miel: f.miel,
    lignes: lignes.map((l) => ({ variante_id: l.varianteId, quantite: l.quantite })),
  }
}

const CLE_ID = 'commande.tentative'

/** Identifiant d'idempotence conservé tant que la commande n'est pas confirmée (un rejeu ne crée pas de doublon). */
export function identifiantTentative(): string {
  try {
    const existant = sessionStorage.getItem(CLE_ID)
    if (existant) return existant
    const nouveau = crypto.randomUUID()
    sessionStorage.setItem(CLE_ID, nouveau)
    return nouveau
  } catch {
    return crypto.randomUUID()
  }
}

export function oublierTentative(): void {
  try {
    sessionStorage.removeItem(CLE_ID)
  } catch {
    // rien à oublier
  }
}

/** Lien WhatsApp pré-rempli « Commander via WhatsApp » (pour un produit ou le panier). */
export function lienWhatsapp(numero: string | null | undefined, message: string): string | null {
  const chiffres = (numero ?? '').replace(/\D/g, '')
  return chiffres.length >= 8 ? `https://wa.me/${chiffres}?text=${encodeURIComponent(message)}` : null
}
