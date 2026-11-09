import { NavLink, Outlet } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuth } from '@/features/auth/AuthProvider'
import { Preferences } from './Preferences'

const LIENS = [
  { vers: '/', cle: 'nav.tableau_de_bord' },
  { vers: '/commercantes', cle: 'nav.commercantes' },
  { vers: '/boutiques', cle: 'nav.boutiques' },
  { vers: '/plans', cle: 'nav.plans' },
  { vers: '/abonnements', cle: 'nav.abonnements' },
  { vers: '/paiements', cle: 'nav.paiements' },
  { vers: '/sites', cle: 'nav.sites' },
  { vers: '/utilisateurs', cle: 'nav.utilisateurs' },
  { vers: '/audit', cle: 'nav.audit' },
  { vers: '/notifications', cle: 'nav.notifications' },
] as const

export function Layout() {
  const { t } = useTranslation()
  const { email, deconnexion } = useAuth()
  return (
    <div className="flex min-h-screen flex-col md:flex-row">
      <aside className="border-bordure bg-surface md:w-60 md:border-e">
        <div className="p-4 text-lg font-bold">{t('app.titre')}</div>
        <nav className="flex gap-1 overflow-x-auto px-2 pb-2 md:flex-col">
          {LIENS.map((l) => (
            <NavLink key={l.vers} to={l.vers} end
              className={({ isActive }) => `rounded-lg px-3 py-2 text-sm ${isActive ? 'bg-primaire text-primaire-texte' : 'hover:bg-fond'}`}>
              {t(l.cle)}
            </NavLink>
          ))}
        </nav>
      </aside>
      <div className="flex-1">
        <header className="flex items-center justify-between gap-2 border-b border-bordure bg-surface p-3">
          <span className="text-sm text-discret" dir="ltr">{email}</span>
          <div className="flex items-center gap-2">
            <Preferences />
            <button className="btn" onClick={() => void deconnexion()}>{t('commun.deconnexion')}</button>
          </div>
        </header>
        <main className="p-4"><Outlet /></main>
      </div>
    </div>
  )
}
