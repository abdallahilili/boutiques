import { lazy, Suspense } from 'react'
import { Route, Routes } from 'react-router-dom'
import { ComptePage } from '@/features/auth/ComptePage'
import { AccueilPage } from '@/features/accueil/AccueilPage'
import { Layout } from '@/features/layout/Layout'
import { PanierPage } from '@/features/panier/PanierPage'

const CatalogPage = lazy(() => import('@/features/catalogue/CatalogPage').then((m) => ({ default: m.CatalogPage })))
const ProduitPage = lazy(() => import('@/features/produit/ProduitPage').then((m) => ({ default: m.ProduitPage })))
const CheckoutPage = lazy(() => import('@/features/commande/CheckoutPage').then((m) => ({ default: m.CheckoutPage })))
const ConfirmationPage = lazy(() => import('@/features/commande/ConfirmationPage').then((m) => ({ default: m.ConfirmationPage })))
const SuiviPage = lazy(() => import('@/features/commande/SuiviPage').then((m) => ({ default: m.SuiviPage })))
const PageStatique = lazy(() => import('@/features/pages/PageStatique').then((m) => ({ default: m.PageStatique })))

export function App() {
  return (
    <Suspense fallback={<p className="p-8 text-center text-discret">…</p>}>
      <Routes>
        <Route element={<Layout />}>
          <Route index element={<AccueilPage />} />
          <Route path="catalogue" element={<CatalogPage />} />
          <Route path="produit/:slug" element={<ProduitPage />} />
          <Route path="panier" element={<PanierPage />} />
          <Route path="commande" element={<CheckoutPage />} />
          <Route path="commande/confirmation" element={<ConfirmationPage />} />
          <Route path="suivi" element={<SuiviPage />} />
          <Route path="compte" element={<ComptePage />} />
          <Route path="page/:slug" element={<PageStatique />} />
        </Route>
      </Routes>
    </Suspense>
  )
}
