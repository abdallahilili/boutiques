import { useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { useAuth } from './AuthProvider'

export function LoginPage() {
  const { t } = useTranslation()
  const { seConnecter } = useAuth()
  const [email, setEmail] = useState('')
  const [motDePasse, setMotDePasse] = useState('')
  const [erreur, setErreur] = useState<string | null>(null)
  const [envoi, setEnvoi] = useState(false)

  async function soumettre(e: FormEvent) {
    e.preventDefault()
    setErreur(null)
    setEnvoi(true)
    try {
      await seConnecter(email.trim(), motDePasse)
    } catch {
      setErreur(t('auth.identifiants_invalides'))
    } finally {
      setEnvoi(false)
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center p-4">
      <form onSubmit={soumettre} className="carte w-full max-w-sm space-y-4">
        <h1 className="text-xl font-bold">{t('app.titre')}</h1>
        <h2 className="text-discret">{t('auth.titre')}</h2>
        <div>
          <label className="etiquette" htmlFor="email">{t('auth.email')}</label>
          <input id="email" className="input" type="email" autoComplete="username" required value={email}
            onChange={(e) => setEmail(e.target.value)} dir="ltr" />
        </div>
        <div>
          <label className="etiquette" htmlFor="mdp">{t('auth.mot_de_passe')}</label>
          <input id="mdp" className="input" type="password" autoComplete="current-password" required value={motDePasse}
            onChange={(e) => setMotDePasse(e.target.value)} dir="ltr" />
        </div>
        {erreur && <p role="alert" className="text-sm text-danger">{erreur}</p>}
        <button className="btn btn-primaire w-full" disabled={envoi}>{t('auth.connexion')}</button>
      </form>
    </main>
  )
}
