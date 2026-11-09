import { useState, type FormEvent } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase'
import { nomLocalise } from '@/lib/format'
import { TAILLE_PAGE, useListe } from '@/lib/useListe'
import { useBoutiques } from '@/lib/useBoutiques'
import { DataTable } from '@/components/DataTable'
import { Dialog } from '@/components/Dialog'
import { Champ, MessageErreur, Statut, TitrePage } from '@/components/ui'
import type { Tables } from '@/types/database'

type Domaine = Tables<'domaines_boutique'>
const STATUTS_DOMAINE: Domaine['statut_dns'][] = ['non_configure', 'en_attente', 'verifie', 'erreur']

function FormulaireSite({ domaine, onFini }: { domaine: Domaine; onFini: () => void }) {
  const { t, i18n } = useTranslation()
  const queryClient = useQueryClient()
  const themes = useQuery({
    queryKey: ['themes_site'],
    queryFn: async () => {
      const { data, error } = await supabase.from('themes_site').select('*').order('plan_minimum')
      if (error) throw new Error(error.message)
      return data
    },
  })
  const parametres = useQuery({
    queryKey: ['parametres_site', domaine.boutique_id],
    queryFn: async () => {
      const { data, error } = await supabase.from('parametres_site').select('theme_id, publie').eq('boutique_id', domaine.boutique_id).maybeSingle()
      if (error) throw new Error(error.message)
      return data
    },
  })
  const [v, setV] = useState({ sous_domaine: domaine.sous_domaine, dns: domaine.statut_dns, ssl: domaine.statut_ssl, theme: '', publie: true, init: false })
  if (parametres.data && !v.init) setV({ ...v, theme: parametres.data.theme_id ?? '', publie: parametres.data.publie, init: true })

  const sauver = useMutation({
    mutationFn: async () => {
      const a = await supabase.from('domaines_boutique').update({ sous_domaine: v.sous_domaine.toLowerCase(), statut_dns: v.dns, statut_ssl: v.ssl }).eq('id', domaine.id)
      if (a.error) throw new Error(a.error.message)
      const b = await supabase.from('parametres_site').update({ theme_id: v.theme || null, publie: v.publie }).eq('boutique_id', domaine.boutique_id)
      if (b.error) throw new Error(b.error.message)
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['domaines_boutique'] })
      onFini()
    },
  })
  const soumettre = (e: FormEvent) => {
    e.preventDefault()
    sauver.mutate()
  }

  return (
    <form onSubmit={soumettre} className="grid grid-cols-2 gap-3">
      <p className="col-span-2 rounded-lg bg-alerte/10 p-2 text-sm text-alerte">{t('sites.alerte_sous_domaine')}</p>
      <div className="col-span-2">
        <Champ etiquette={t('sites.sous_domaine')}><input className="input" dir="ltr" required pattern="[a-z0-9]([a-z0-9\-]{0,38}[a-z0-9])?" value={v.sous_domaine} onChange={(e) => setV({ ...v, sous_domaine: e.target.value })} /></Champ>
      </div>
      <Champ etiquette={t('sites.dns')}>
        <select className="input" value={v.dns} onChange={(e) => setV({ ...v, dns: e.target.value as Domaine['statut_dns'] })}>
          {STATUTS_DOMAINE.map((s) => <option key={s} value={s}>{t(`statut.${s}`)}</option>)}
        </select>
      </Champ>
      <Champ etiquette={t('sites.ssl')}>
        <select className="input" value={v.ssl} onChange={(e) => setV({ ...v, ssl: e.target.value as Domaine['statut_ssl'] })}>
          {STATUTS_DOMAINE.map((s) => <option key={s} value={s}>{t(`statut.${s}`)}</option>)}
        </select>
      </Champ>
      <Champ etiquette={t('sites.theme')}>
        <select className="input" value={v.theme} onChange={(e) => setV({ ...v, theme: e.target.value })}>
          <option value="" />
          {(themes.data ?? []).map((th) => <option key={th.id} value={th.id}>{nomLocalise(th, i18n.language)}</option>)}
        </select>
      </Champ>
      <label className="flex items-center gap-2 pt-6"><input type="checkbox" checked={v.publie} onChange={(e) => setV({ ...v, publie: e.target.checked })} />{t('sites.publie')}</label>
      <div className="col-span-2"><MessageErreur erreur={sauver.error as Error | null} /></div>
      <div className="col-span-2 flex justify-end"><button className="btn btn-primaire" disabled={sauver.isPending}>{t('commun.enregistrer')}</button></div>
    </form>
  )
}

export function SitesPage() {
  const { t, i18n } = useTranslation()
  const { parId } = useBoutiques()
  const [edition, setEdition] = useState<Domaine | null>(null)
  const liste = useListe<Domaine>(['domaines_boutique'], (a, b) =>
    supabase.from('domaines_boutique').select('*', { count: 'exact' }).order('cree_le', { ascending: false }).range(a, b))

  return (
    <>
      <TitrePage titre={t('sites.titre')} />
      <MessageErreur erreur={liste.erreur} />
      <DataTable
        colonnes={[
          { cle: 'boutique', titre: t('commun.boutique'), rendu: (d) => { const b = parId.get(d.boutique_id); return b ? nomLocalise(b, i18n.language) : d.boutique_id.slice(0, 8) } },
          { cle: 'sous', titre: t('sites.sous_domaine'), rendu: (d) => <span dir="ltr">{d.sous_domaine}</span> },
          { cle: 'perso', titre: t('sites.domaine_personnalise'), rendu: (d) => <span dir="ltr">{d.domaine_personnalise ?? '—'}</span> },
          { cle: 'dns', titre: t('sites.dns'), rendu: (d) => <Statut valeur={d.statut_dns} /> },
          { cle: 'ssl', titre: t('sites.ssl'), rendu: (d) => <Statut valeur={d.statut_ssl} /> },
          { cle: 'actions', titre: t('commun.actions'), rendu: (d) => <button className="btn" onClick={() => setEdition(d)}>{t('commun.modifier')}</button> },
        ]}
        lignes={liste.lignes} total={liste.total} page={liste.page} taillePage={TAILLE_PAGE} chargement={liste.chargement}
        onPage={liste.setPage} cleLigne={(d) => d.id}
      />
      {edition && (
        <Dialog titre={t('sites.modifier_sous_domaine')} onFermer={() => setEdition(null)}>
          <FormulaireSite domaine={edition} onFini={() => setEdition(null)} />
        </Dialog>
      )}
    </>
  )
}
