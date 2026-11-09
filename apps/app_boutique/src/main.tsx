import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { HelmetProvider } from 'react-helmet-async'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import './i18n'
import './index.css'
import { App } from './App'
import { AuthProvider } from './features/auth/AuthProvider'
import { BoutiqueProvider } from './features/boutique/BoutiqueProvider'
import { PanierProvider } from './features/panier/PanierProvider'

const queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 30_000, retry: 1 } } })

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <HelmetProvider>
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <BoutiqueProvider>
            <AuthProvider>
              <PanierProvider>
                <App />
              </PanierProvider>
            </AuthProvider>
          </BoutiqueProvider>
        </BrowserRouter>
      </QueryClientProvider>
    </HelmetProvider>
  </StrictMode>,
)
