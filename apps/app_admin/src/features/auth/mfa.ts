import { supabase } from '@/lib/supabase'

export interface Enrolement {
  facteurId: string
  qrCode: string
  secret: string
}

/** Identifiant du facteur TOTP vérifié, s'il existe. */
export async function facteurTotpVerifie(): Promise<string | null> {
  const { data, error } = await supabase.auth.mfa.listFactors()
  if (error) throw error
  return data.totp[0]?.id ?? null
}

/** Démarre l'enrôlement TOTP (les tentatives non terminées sont purgées avant). */
export async function demarrerEnrolement(): Promise<Enrolement> {
  const { data: facteurs, error: erreurListe } = await supabase.auth.mfa.listFactors()
  if (erreurListe) throw erreurListe
  for (const f of facteurs.all.filter((f) => f.factor_type === 'totp' && f.status === 'unverified')) {
    await supabase.auth.mfa.unenroll({ factorId: f.id })
  }
  const { data, error } = await supabase.auth.mfa.enroll({ factorType: 'totp' })
  if (error) throw error
  return { facteurId: data.id, qrCode: data.totp.qr_code, secret: data.totp.secret }
}

export async function verifierCode(facteurId: string, code: string): Promise<void> {
  const { error } = await supabase.auth.mfa.challengeAndVerify({ factorId: facteurId, code })
  if (error) throw error
}
