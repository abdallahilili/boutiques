import { Link, Navigate, useLocation } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { formaterMontant } from '@/lib/format'
import { useBoutique } from '@/features/boutique/BoutiqueProvider'
import { Seo } from '@/features/layout/Seo'

export function ConfirmationPage() {
  const { t, i18n } = useTranslation()
  const { boutique } = useBoutique()
  const etat = useLocation().state as { numero: string; total: number; telephone: string } | null
  if (!etat) return <Navigate to="/" replace />
  const message = i18n.language === 'ar' ? boutique.message_confirmation_ar : boutique.message_confirmation_fr
  return (
    <>
      <Seo titre={t('commande.confirmation_titre')} noindex />
      <div className="mx-auto max-w-md space-y-4 py-10 text-center">
        <h1 className="text-2xl font-bold text-succes">{t('commande.confirmation_titre')}</h1>
        <div className="carte">
          <p className="text-sm text-discret">{t('commande.confirmation_numero')}</p>
          <p className="text-2xl font-bold" dir="ltr">{etat.numero}</p>
          <p className="mt-1">{formaterMontant(etat.total, boutique.devise, i18n.language)}</p>
        </div>
        <p className="text-sm text-discret">{message || t('commande.confirmation_texte')}</p>
        <Link className="btn btn-primaire" to="/suivi" state={{ numero: etat.numero, telephone: etat.telephone }}>{t('commande.suivre')}</Link>
      </div>
    </>
  )
}
