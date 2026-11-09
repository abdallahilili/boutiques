import { useQuery } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { formaterMontant } from '@/lib/format'
import { MessageErreur, TitrePage } from '@/components/ui'

interface Statistiques {
  boutiques: Partial<Record<'essai' | 'actif' | 'grace' | 'suspendu' | 'ferme', number>>
  mrr: number
  nouvelles_inscriptions_mois: number
  expirent_sous_7_jours: number
  commandes_en_ligne_30j: number
  evolution: { mois: string; boutiques: number; commandes: number }[]
}

function Carte({ libelle, valeur }: { libelle: string; valeur: string | number }) {
  return (
    <div className="carte">
      <div className="text-sm text-discret">{libelle}</div>
      <div className="mt-1 text-3xl font-bold">{valeur}</div>
    </div>
  )
}

/** Histogramme groupé en SVG : deux séries par mois, valeurs annotées. */
function Histogramme({ donnees, legendes }: { donnees: Statistiques['evolution']; legendes: [string, string] }) {
  const max = Math.max(1, ...donnees.flatMap((d) => [d.boutiques, d.commandes]))
  const largeur = 560
  const hauteur = 180
  const pas = largeur / Math.max(donnees.length, 1)
  const h = (v: number) => (v / max) * (hauteur - 30)
  return (
    <div>
      <svg role="img" aria-label={legendes.join(' / ')} viewBox={`0 0 ${largeur} ${hauteur + 20}`} className="w-full" style={{ direction: "ltr" }}>
        {donnees.map((d, i) => {
          const x = i * pas + pas / 2
          return (
            <g key={d.mois}>
              <rect x={x - 22} y={hauteur - h(d.boutiques)} width={20} height={h(d.boutiques)} rx={3} fill="var(--primaire)" />
              <rect x={x + 2} y={hauteur - h(d.commandes)} width={20} height={h(d.commandes)} rx={3} fill="var(--alerte)" />
              <text x={x - 12} y={hauteur - h(d.boutiques) - 4} textAnchor="middle" fontSize="10" fill="var(--texte)">{d.boutiques}</text>
              <text x={x + 12} y={hauteur - h(d.commandes) - 4} textAnchor="middle" fontSize="10" fill="var(--texte)">{d.commandes}</text>
              <text x={x} y={hauteur + 14} textAnchor="middle" fontSize="10" fill="var(--discret)">{d.mois}</text>
            </g>
          )
        })}
      </svg>
      <div className="mt-2 flex gap-4 text-xs text-discret">
        <span className="flex items-center gap-1"><i className="inline-block h-2 w-2 rounded-sm bg-primaire" />{legendes[0]}</span>
        <span className="flex items-center gap-1"><i className="inline-block h-2 w-2 rounded-sm bg-alerte" />{legendes[1]}</span>
      </div>
    </div>
  )
}

export function DashboardPage() {
  const { t, i18n } = useTranslation()
  const requete = useQuery({
    queryKey: ['admin_statistiques'],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('admin_statistiques')
      if (error) throw new Error(error.message)
      return data as unknown as Statistiques
    },
  })
  const s = requete.data
  return (
    <>
      <TitrePage titre={t('tableau_de_bord.titre')} />
      <MessageErreur erreur={requete.error} />
      {requete.isLoading && <p className="text-discret">{t('commun.chargement')}</p>}
      {s && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-3">
            <Carte libelle={t('tableau_de_bord.boutiques_actives')} valeur={s.boutiques.actif ?? 0} />
            <Carte libelle={t('tableau_de_bord.boutiques_essai')} valeur={s.boutiques.essai ?? 0} />
            <Carte libelle={t('tableau_de_bord.boutiques_suspendues')} valeur={(s.boutiques.suspendu ?? 0) + (s.boutiques.grace ?? 0)} />
            <Carte libelle={t('tableau_de_bord.mrr')} valeur={formaterMontant(s.mrr, 'MRU', i18n.language)} />
            <Carte libelle={t('tableau_de_bord.inscriptions_mois')} valeur={s.nouvelles_inscriptions_mois} />
            <Carte libelle={t('tableau_de_bord.expirent')} valeur={s.expirent_sous_7_jours} />
            <Carte libelle={t('tableau_de_bord.commandes')} valeur={s.commandes_en_ligne_30j} />
          </div>
          <div className="carte">
            <h2 className="mb-2 font-semibold">{t('tableau_de_bord.evolution')}</h2>
            <Histogramme donnees={s.evolution} legendes={[t('tableau_de_bord.serie_boutiques'), t('tableau_de_bord.serie_commandes')]} />
          </div>
        </div>
      )}
    </>
  )
}
