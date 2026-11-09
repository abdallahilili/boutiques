import { lazy, Suspense } from 'react'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuth } from '@/features/auth/AuthProvider'
import { LoginPage } from '@/features/auth/LoginPage'
import { MfaPage } from '@/features/auth/MfaPage'
import { Layout } from '@/components/Layout'
import { DashboardPage } from '@/pages/DashboardPage'
const CommercantesPage = lazy(() => import('@/pages/CommercantesPage').then((m) => ({ default: m.CommercantesPage })))
const BoutiquesPage = lazy(() => import('@/pages/BoutiquesPage').then((m) => ({ default: m.BoutiquesPage })))
const PlansPage = lazy(() => import('@/pages/PlansPage').then((m) => ({ default: m.PlansPage })))
const AbonnementsPage = lazy(() => import('@/pages/AbonnementsPage').then((m) => ({ default: m.AbonnementsPage })))
const PaiementsPage = lazy(() => import('@/pages/PaiementsPage').then((m) => ({ default: m.PaiementsPage })))
const SitesPage = lazy(() => import('@/pages/SitesPage').then((m) => ({ default: m.SitesPage })))
const UtilisateursPage = lazy(() => import('@/pages/UtilisateursPage').then((m) => ({ default: m.UtilisateursPage })))
const AuditPage = lazy(() => import('@/pages/AuditPage').then((m) => ({ default: m.AuditPage })))
const NotificationsPage = lazy(() => import('@/pages/NotificationsPage').then((m) => ({ default: m.NotificationsPage })))

export function App() {
  const { t } = useTranslation()
  const { etat, deconnexion } = useAuth()

  switch (etat) {
    case 'chargement':
      return <p className="p-8 text-center text-discret">{t('commun.chargement')}</p>
    case 'anonyme':
      return <LoginPage />
    case 'refuse':
      return (
        <main className="flex min-h-screen flex-col items-center justify-center gap-4 p-4">
          <p role="alert" className="text-danger">{t('auth.acces_refuse')}</p>
          <button className="btn" onClick={() => void deconnexion()}>{t('commun.deconnexion')}</button>
        </main>
      )
    case 'mfa_enrolement':
    case 'mfa_verification':
      return <MfaPage />
    case 'ok':
      return (
        <BrowserRouter>
          <Routes>
            <Route element={<Suspense fallback={<p className="p-8 text-center text-discret">{t('commun.chargement')}</p>}><Layout /></Suspense>}>
              <Route index element={<DashboardPage />} />
              <Route path="commercantes" element={<CommercantesPage />} />
              <Route path="boutiques" element={<BoutiquesPage />} />
              <Route path="plans" element={<PlansPage />} />
              <Route path="abonnements" element={<AbonnementsPage />} />
              <Route path="paiements" element={<PaiementsPage />} />
              <Route path="sites" element={<SitesPage />} />
              <Route path="utilisateurs" element={<UtilisateursPage />} />
              <Route path="audit" element={<AuditPage />} />
              <Route path="notifications" element={<NotificationsPage />} />
            </Route>
          </Routes>
        </BrowserRouter>
      )
  }
}
