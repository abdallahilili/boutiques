import { useEffect, useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { useAuth } from './AuthProvider'
import { demarrerEnrolement, facteurTotpVerifie, verifierCode, type Enrolement } from './mfa'

/** Deuxième facteur TOTP : enrôlement (QR code) à la première connexion, vérification ensuite. */
export function MfaPage() {
  const { t } = useTranslation()
  const { etat, rafraichir, deconnexion } = useAuth()
  const [facteurId, setFacteurId] = useState<string | null>(null)
  const [enrolement, setEnrolement] = useState<Enrolement | null>(null)
  const [code, setCode] = useState('')
  const [erreur, setErreur] = useState<string | null>(null)

  useEffect(() => {
    let actif = true
    async function preparer() {
      try {
        if (etat === 'mfa_enrolement') {
          const e = await demarrerEnrolement()
          if (actif) {
            setEnrolement(e)
            setFacteurId(e.facteurId)
          }
        } else {
          const id = await facteurTotpVerifie()
          if (actif) setFacteurId(id)
        }
      } catch {
        if (actif) setErreur(t('commun.erreur'))
      }
    }
    void preparer()
    return () => {
      actif = false
    }
  }, [etat, t])

  async function soumettre(e: FormEvent) {
    e.preventDefault()
    if (!facteurId) return
    setErreur(null)
    try {
      await verifierCode(facteurId, code.trim())
      await rafraichir()
    } catch {
      setErreur(t('auth.mfa_invalide'))
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center p-4">
      <form onSubmit={soumettre} className="carte w-full max-w-sm space-y-4">
        <h1 className="text-xl font-bold">{t('auth.mfa_titre')}</h1>
        {enrolement && (
          <div className="space-y-2 text-center">
            <p className="text-sm text-discret">{t('auth.mfa_enrolement')}</p>
            <img src={enrolement.qrCode} alt="QR code" className="mx-auto h-44 w-44 bg-white p-2" />
            <p className="text-xs text-discret">{t('auth.mfa_cle_manuelle')}</p>
            <code dir="ltr" className="block break-all text-xs">{enrolement.secret}</code>
          </div>
        )}
        <div>
          <label className="etiquette" htmlFor="code">{t('auth.mfa_code')}</label>
          <input id="code" className="input text-center tracking-widest" inputMode="numeric" autoComplete="one-time-code"
            pattern="[0-9]{6}" maxLength={6} required value={code} onChange={(e) => setCode(e.target.value)} dir="ltr" />
        </div>
        {erreur && <p role="alert" className="text-sm text-danger">{erreur}</p>}
        <button className="btn btn-primaire w-full" disabled={!facteurId}>{t('auth.mfa_verifier')}</button>
        <button type="button" className="btn w-full" onClick={() => void deconnexion()}>{t('commun.deconnexion')}</button>
      </form>
    </main>
  )
}
