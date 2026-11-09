import { useTranslation } from 'react-i18next'

export function DashboardPage() {
  const { t } = useTranslation()
  return <h1 className="text-2xl font-bold">{t('tableau_de_bord.titre')}</h1>
}
