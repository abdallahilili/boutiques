import { useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'
import { connexionCliente, ErreurAuth } from './api'

export function LoginPage({ boutiqueSlug }: { boutiqueSlug: string }) {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [telephone, setTelephone] = useState('')
  const [code, setCode] = useState('')
  const [erreur, setErreur] = useState<string | null>(null)
  const [envoi, setEnvoi] = useState(false)

  async function soumettre(e: FormEvent) {
    e.preventDefault()
    setErreur(null)
    setEnvoi(true)
    try {
      await connexionCliente(boutiqueSlug, telephone.trim(), code)
      navigate('/')
    } catch (err) {
      setErreur(t(err instanceof ErreurAuth && err.code !== 'erreur' ? `auth.${err.code}` : 'commun.erreur'))
    } finally {
      setEnvoi(false)
    }
  }

  return (
    <main className="mx-auto max-w-sm p-4">
      <form onSubmit={soumettre} className="carte space-y-4">
        <h1 className="text-xl font-bold">{t('auth.connexion')}</h1>
        <div>
          <label className="etiquette" htmlFor="tel">{t('auth.telephone')}</label>
          <input id="tel" className="input" type="tel" inputMode="tel" autoComplete="username" required value={telephone}
            onChange={(e) => setTelephone(e.target.value)} dir="ltr" />
        </div>
        <div>
          <label className="etiquette" htmlFor="code">{t('auth.code')}</label>
          <input id="code" className="input text-center tracking-widest" type="password" inputMode="numeric"
            autoComplete="current-password" pattern="[0-9]{4}" maxLength={4} required value={code}
            onChange={(e) => setCode(e.target.value)} dir="ltr" />
        </div>
        {erreur && <p role="alert" className="text-sm text-danger">{erreur}</p>}
        <button className="btn btn-primaire w-full" disabled={envoi}>{t('auth.valider')}</button>
      </form>
    </main>
  )
}
