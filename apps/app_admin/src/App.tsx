import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuth } from '@/features/auth/AuthProvider'
import { LoginPage } from '@/features/auth/LoginPage'
import { MfaPage } from '@/features/auth/MfaPage'
import { Layout } from '@/components/Layout'
import { DashboardPage } from '@/pages/DashboardPage'

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
            <Route element={<Layout />}>
              <Route index element={<DashboardPage />} />
            </Route>
          </Routes>
        </BrowserRouter>
      )
  }
}
