import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import { PanierProvider } from '@/features/panier/PanierProvider'
import { CheckoutPage } from './CheckoutPage'

const rpc = vi.fn()
const fromZones = vi.fn()

vi.mock('@/lib/supabase', () => ({
  supabase: {
    rpc: (...a: unknown[]) => rpc(...a),
    from: () => ({ select: () => ({ eq: () => fromZones() }) }),
    storage: { from: () => ({ upload: vi.fn() }) },
  },
}))

vi.mock('@/features/boutique/BoutiqueProvider', () => ({
  useBoutique: () => ({
    boutique: {
      boutique_id: 'b1', slug: 'mon-sac', devise: 'MRU', nom_ar: 'متجر', nom_fr: 'Boutique', livraison_active: true, retrait_boutique_actif: true,
      paiement_livraison_actif: true, mobile_money_actif: false, commande_minimale: 0, infos_paiement: {},
    },
    mise: { entete: 'centre', grille: 2, styleCarte: 'bordure' },
    langues: ['ar', 'fr'],
  }),
}))

function rendre() {
  localStorage.setItem('panier.b1', JSON.stringify([{ varianteId: 'v1', produitSlug: 'sac', quantite: 2, libelleAr: 'حقيبة', libelleFr: 'Sac', prix: 800, image: null }]))
  return render(
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      <MemoryRouter initialEntries={['/commande']}>
        <PanierProvider>
          <Routes>
            <Route path="/commande" element={<CheckoutPage />} />
            <Route path="/commande/confirmation" element={<p>confirmation</p>} />
          </Routes>
        </PanierProvider>
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('CheckoutPage', () => {
  beforeEach(() => {
    rpc.mockReset()
    fromZones.mockResolvedValue({ data: [] })
    localStorage.clear()
    sessionStorage.clear()
  })

  it('refuse un formulaire incomplet sans appeler le serveur', async () => {
    rendre()
    await userEvent.click(screen.getByRole('button', { name: 'تأكيد الطلب' }))
    expect(await screen.findAllByRole('alert')).not.toHaveLength(0)
    expect(rpc).not.toHaveBeenCalled()
  })

  it('envoie la commande sans aucun prix, vide le panier et affiche la confirmation', async () => {
    rpc.mockResolvedValue({ data: { id: 'c1', numero: 'CMD-2026-0001', total: 1600, rejoue: false }, error: null })
    rendre()
    const champs = screen.getAllByRole('textbox')
    await userEvent.type(champs[0], 'Fatima')
    await userEvent.type(champs[1], '36 00 00 77')
    await userEvent.type(screen.getByLabelText('العنوان'), 'Tevragh Zeina')
    await userEvent.click(screen.getByRole('button', { name: 'تأكيد الطلب' }))

    await waitFor(() => expect(screen.getByText('confirmation')).toBeInTheDocument())
    expect(rpc).toHaveBeenCalledTimes(1)
    const [nom, args] = rpc.mock.calls[0] as [string, { p_slug: string; p_donnees: { lignes: unknown[] } }]
    expect(nom).toBe('passer_commande_en_ligne')
    expect(args.p_slug).toBe('mon-sac')
    expect(args.p_donnees.lignes).toEqual([{ variante_id: 'v1', quantite: 2 }])
    expect(JSON.stringify(args)).not.toContain('800')
    expect(JSON.parse(localStorage.getItem('panier.b1') ?? '[]')).toEqual([])
  })

  it('traduit une erreur de stock du serveur', async () => {
    rpc.mockResolvedValue({ data: null, error: { message: 'stock_insuffisant: Sac' } })
    rendre()
    const champs = screen.getAllByRole('textbox')
    await userEvent.type(champs[0], 'Fatima')
    await userEvent.type(champs[1], '36 00 00 77')
    await userEvent.type(screen.getByLabelText('العنوان'), 'Tevragh Zeina')
    await userEvent.click(screen.getByRole('button', { name: 'تأكيد الطلب' }))
    expect(await screen.findByText(/لم يعد أحد المنتجات متوفراً/)).toBeInTheDocument()
    expect(JSON.parse(localStorage.getItem('panier.b1') ?? '[]')).toHaveLength(1)
  })
})
