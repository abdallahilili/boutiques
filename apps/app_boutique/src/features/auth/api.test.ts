import { connexionCliente, ErreurAuth } from './api'

const invoke = vi.fn()
const setSession = vi.fn()

vi.mock('@/lib/supabase', () => ({
  supabase: { functions: { invoke: (...a: unknown[]) => invoke(...a) }, auth: { setSession: (...a: unknown[]) => setSession(...a), signOut: vi.fn() } },
}))

describe('connexionCliente', () => {
  beforeEach(() => {
    invoke.mockReset()
    setSession.mockReset()
  })

  it('envoie le contexte cliente et la boutique, puis installe la session', async () => {
    const session = { access_token: 'a', refresh_token: 'r' }
    invoke.mockResolvedValue({ data: { session }, error: null })
    setSession.mockResolvedValue({ error: null })
    await connexionCliente('mon-sac', '22236000001', '1234')
    expect(invoke).toHaveBeenCalledWith('connexion_telephone_pin', {
      body: { telephone: '22236000001', code: '1234', contexte: 'cliente', boutique_slug: 'mon-sac' },
    })
    expect(setSession).toHaveBeenCalledWith(session)
  })

  it.each([
    [401, 'identifiants_invalides'],
    [429, 'compte_verrouille'],
    [500, 'erreur'],
  ])('traduit le statut HTTP %i en %s', async (statut, code) => {
    invoke.mockResolvedValue({ data: null, error: { context: { status: statut } } })
    await expect(connexionCliente('x', '22236000001', '1234')).rejects.toEqual(expect.any(ErreurAuth))
    await expect(connexionCliente('x', '22236000001', '1234')).rejects.toMatchObject({ code })
    expect(setSession).not.toHaveBeenCalled()
  })
})
