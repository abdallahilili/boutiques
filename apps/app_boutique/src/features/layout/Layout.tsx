import { Link, NavLink, Outlet } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { changerLangue } from '@/i18n'
import { nomLocalise, urlImage } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'
import { usePanier } from '@/features/panier/PanierProvider'
import { Seo } from './Seo'

/** En-tête (disposition centrée ou à gauche selon le thème), pied de page et bascule de langue. */
export function Layout() {
  const { t, i18n } = useTranslation()
  const { boutique, mise, langues } = useBoutique()
  const { articles } = usePanier()
  const logo = urlImage(boutique.logo_url, 160, 'shop-assets')
  const autre = i18n.language === 'ar' ? 'fr' : 'ar'
  const lienClasse = ({ isActive }: { isActive: boolean }) => `px-2 py-1 text-sm ${isActive ? 'font-semibold text-primaire' : 'text-discret hover:text-texte'}`

  return (
    <div className="flex min-h-screen flex-col">
      <Seo />
      <header className="sticky top-0 z-30 border-b border-bordure bg-fond/95 backdrop-blur">
        <div className={`mx-auto flex max-w-6xl flex-wrap items-center gap-x-4 gap-y-1 p-3 ${mise.entete === 'centre' ? 'justify-center' : 'justify-between'}`}>
          <Link to="/" className="flex items-center gap-2 text-lg font-bold">
            {logo && <img src={logo} alt="" className="h-9 w-9 rounded-boutique object-cover" />}
            {nomLocalise(boutique, i18n.language)}
          </Link>
          <nav className="flex flex-wrap items-center gap-1">
            <NavLink to="/" end className={lienClasse}>{t('nav.accueil')}</NavLink>
            <NavLink to="/catalogue" className={lienClasse}>{t('nav.catalogue')}</NavLink>
            <NavLink to="/suivi" className={lienClasse}>{t('nav.suivi')}</NavLink>
            <NavLink to="/compte" className={lienClasse}>{t('nav.compte')}</NavLink>
            <NavLink to="/panier" className={lienClasse}>{t('nav.panier')}{articles > 0 && <span className="ms-1 rounded-full bg-primaire px-1.5 text-xs text-primaire-texte">{articles}</span>}</NavLink>
            {langues.length > 1 && (
              <button className="px-2 py-1 text-sm text-discret" onClick={() => void changerLangue(autre)} aria-label={t('commun.langue')}>
                {autre === 'ar' ? 'العربية' : 'Français'}
              </button>
            )}
          </nav>
        </div>
      </header>
      <main className="mx-auto w-full max-w-6xl flex-1 p-3 sm:p-4"><Outlet /></main>
      <footer className="border-t border-bordure p-4 text-center text-sm text-discret">
        <p>{nomLocalise(boutique, i18n.language)}{boutique.adresse ? ` · ${boutique.adresse}` : ''}</p>
        {boutique.telephone && <p dir="ltr">{boutique.telephone}</p>}
      </footer>
    </div>
  )
}
