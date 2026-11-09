import { supabase } from '@/lib/supabase'

export type ErreurConnexion = 'identifiants_invalides' | 'compte_verrouille' | 'erreur'

export class ErreurAuth extends Error {
  constructor(public readonly code: ErreurConnexion) {
    super(code)
  }
}

interface ReponseConnexion {
  session: { access_token: string; refresh_token: string }
}

/**
 * Connexion cliente par téléphone + code à 4 chiffres : le code est converti en secret
 * côté serveur (Edge Function), la session obtenue est ensuite installée dans le client.
 */
export async function connexionCliente(boutiqueSlug: string, telephone: string, code: string): Promise<void> {
  const { data, error } = await supabase.functions.invoke<ReponseConnexion>('connexion_telephone_pin', {
    body: { telephone, code, contexte: 'cliente', boutique_slug: boutiqueSlug },
  })
  if (error || !data?.session) {
    const reponse = (error as { context?: Response } | null)?.context
    const statut = reponse?.status
    if (statut === 401) throw new ErreurAuth('identifiants_invalides')
    if (statut === 429) throw new ErreurAuth('compte_verrouille')
    throw new ErreurAuth('erreur')
  }
  const { error: erreurSession } = await supabase.auth.setSession(data.session)
  if (erreurSession) throw new ErreurAuth('erreur')
}

export async function deconnexionCliente(): Promise<void> {
  await supabase.auth.signOut()
}
