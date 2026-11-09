import { createContext, useContext, useEffect, useMemo, type ReactNode } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { hotePourResolution } from '@/lib/hote'
import { appliquerTheme, miseEnPage, variablesTheme, type ConfigTheme, type MiseEnPage } from '@/lib/theme'
import { changerLangue, estLangue } from '@/i18n'
import type { Views } from '@/types/database'

export type Boutique = Views<'parametres_boutique_publics'> & { boutique_id: string; slug: string; devise: string }

interface Contexte {
  boutique: Boutique
  mise: MiseEnPage
  /** Langues proposées au visiteur (au moins une). */
  langues: ('ar' | 'fr')[]
}

const ContexteBoutique = createContext<Contexte | null>(null)

const DOMAINE_BASE = (import.meta.env.VITE_DOMAINE_BASE as string | undefined) ?? 'localhost'
const SLUG_DEV = import.meta.env.VITE_BOUTIQUE_SLUG as string | undefined

type Resolution = { etat: 'introuvable' } | { etat: 'indisponible' } | { etat: 'ok'; boutique: Boutique }

async function resoudre(): Promise<Resolution> {
  const hote = hotePourResolution(window.location.hostname, DOMAINE_BASE, SLUG_DEV)
  const { data, error } = await supabase.rpc('resoudre_boutique', { p_hote: hote })
  if (error) throw new Error(error.message)
  const resolution = data as { boutique_id: string; slug: string; disponible: boolean } | null
  if (!resolution) return { etat: 'introuvable' }
  if (!resolution.disponible) return { etat: 'indisponible' }
  const { data: boutique, error: erreurParametres } = await supabase.from('parametres_boutique_publics').select('*').eq('boutique_id', resolution.boutique_id).maybeSingle()
  if (erreurParametres) throw new Error(erreurParametres.message)
  return boutique ? { etat: 'ok', boutique: boutique as Boutique } : { etat: 'indisponible' }
}

function PageMessage({ titre, texte }: { titre: string; texte: string }) {
  return (
    <main className="mx-auto flex min-h-screen max-w-md flex-col items-center justify-center gap-2 p-6 text-center">
      <h1 className="text-2xl font-bold">{titre}</h1>
      <p className="text-discret">{texte}</p>
    </main>
  )
}

/** Résout la boutique depuis le domaine, applique son thème (variables CSS) puis affiche l'application. */
export function BoutiqueProvider({ children }: { children: ReactNode }) {
  const { t } = useTranslation()
  const requete = useQuery({ queryKey: ['resolution-boutique'], queryFn: resoudre, staleTime: 5 * 60_000 })
  const boutique = requete.data?.etat === 'ok' ? requete.data.boutique : null

  const valeur = useMemo<Contexte | null>(() => {
    if (!boutique) return null
    const langues = (boutique.langues_activees ?? ['ar', 'fr']).filter(estLangue)
    return {
      boutique,
      mise: miseEnPage(boutique.theme_schema as Partial<ConfigTheme> | null, boutique.config_theme as ConfigTheme | null),
      langues: langues.length ? langues : ['ar'],
    }
  }, [boutique])

  useEffect(() => {
    if (!boutique) return
    return appliquerTheme(document.documentElement, variablesTheme(boutique.config_theme as ConfigTheme | null))
  }, [boutique])

  // Langue : préférence du visiteur, sinon langue de la boutique ; jamais une langue désactivée.
  useEffect(() => {
    if (!valeur) return
    const courante = document.documentElement.lang
    if (!valeur.langues.includes(courante as 'ar' | 'fr')) void changerLangue(valeur.langues.includes('ar') ? 'ar' : valeur.langues[0])
  }, [valeur])

  if (requete.isLoading) return <p className="p-8 text-center text-discret">{t('commun.chargement')}</p>
  if (requete.error) return <PageMessage titre={t('commun.erreur')} texte={(requete.error as Error).message} />
  if (requete.data?.etat === 'introuvable') return <PageMessage titre={t('boutique.introuvable_titre')} texte={t('boutique.introuvable_texte')} />
  if (!valeur) return <PageMessage titre={t('boutique.indisponible_titre')} texte={t('boutique.indisponible_texte')} />
  return <ContexteBoutique.Provider value={valeur}>{children}</ContexteBoutique.Provider>
}

export function useBoutique(): Contexte {
  const contexte = useContext(ContexteBoutique)
  if (!contexte) throw new Error('useBoutique doit être utilisé dans BoutiqueProvider')
  return contexte
}
