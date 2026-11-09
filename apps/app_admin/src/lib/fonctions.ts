import { supabase } from '@/lib/supabase'

export class ErreurFonction extends Error {
  constructor(
    public readonly code: string,
    public readonly statut: number,
  ) {
    super(code)
  }
}

/** Appelle une Edge Function et convertit les erreurs HTTP en `ErreurFonction` (code métier + statut). */
export async function invoquerFonction<T>(nom: string, corps: Record<string, unknown>): Promise<T> {
  const { data, error } = await supabase.functions.invoke<T>(nom, { body: corps })
  if (!error) return data as T
  const reponse = (error as { context?: Response }).context
  if (reponse) {
    const detail = (await reponse.json().catch(() => null)) as { erreur?: string } | null
    throw new ErreurFonction(detail?.erreur ?? 'erreur', reponse.status)
  }
  throw new ErreurFonction('reseau', 0)
}
