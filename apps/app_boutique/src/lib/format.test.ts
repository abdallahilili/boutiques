import { urlImage } from './format'

describe('urlImage', () => {
  afterEach(() => vi.unstubAllEnvs())

  it('sert le fichier public tel quel par défaut (compatible tous plans Supabase)', () => {
    vi.stubEnv('VITE_SUPABASE_URL', 'https://projet.supabase.co')
    expect(urlImage('b1/p1/photo.jpg', 400)).toBe('https://projet.supabase.co/storage/v1/object/public/product-images/b1/p1/photo.jpg')
    expect(urlImage('b1/logo.png', 160, 'shop-assets')).toBe('https://projet.supabase.co/storage/v1/object/public/shop-assets/b1/logo.png')
  })

  it('utilise les transformations d\'image quand elles sont activées', () => {
    vi.stubEnv('VITE_SUPABASE_URL', 'https://projet.supabase.co')
    vi.stubEnv('VITE_IMAGE_TRANSFORMS', 'true')
    expect(urlImage('b1/p1/photo.jpg', 400)).toBe('https://projet.supabase.co/storage/v1/render/image/public/product-images/b1/p1/photo.jpg?width=400&quality=75&format=webp')
  })

  it('garde une URL absolue et ignore un chemin vide', () => {
    expect(urlImage('https://exemple.com/a.png')).toBe('https://exemple.com/a.png')
    expect(urlImage(null)).toBeUndefined()
  })
})
