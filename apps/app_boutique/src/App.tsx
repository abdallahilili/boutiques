import { Route, Routes } from 'react-router-dom'
import { Helmet } from 'react-helmet-async'
import { LoginPage } from '@/features/auth/LoginPage'
import { sousDomaine } from '@/lib/hote'

const DOMAINE_BASE = (import.meta.env.VITE_DOMAINE_BASE as string | undefined) ?? 'localhost'
const SLUG_DEV = import.meta.env.VITE_BOUTIQUE_SLUG as string | undefined

/** Boutique courante : sous-domaine de l'URL (ou variable de développement). */
export function slugCourant(): string {
  return sousDomaine(window.location.hostname, DOMAINE_BASE) ?? SLUG_DEV ?? ''
}

export function App() {
  const slug = slugCourant()
  return (
    <>
      <Helmet>
        <title>{slug}</title>
      </Helmet>
      <Routes>
        <Route path="/" element={<main className="p-8 text-center text-xl font-bold">{slug}</main>} />
        <Route path="/connexion" element={<LoginPage boutiqueSlug={slug} />} />
      </Routes>
    </>
  )
}
