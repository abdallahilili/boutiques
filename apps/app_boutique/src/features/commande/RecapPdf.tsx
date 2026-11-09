import { Document, Font, Page, StyleSheet, Text, View, pdf } from '@react-pdf/renderer'

Font.register({
  family: 'Amiri',
  fonts: [{ src: '/fonts/Amiri-Regular.ttf' }, { src: '/fonts/Amiri-Bold.ttf', fontWeight: 'bold' }],
})

const styles = StyleSheet.create({
  page: { padding: 36, fontFamily: 'Amiri', fontSize: 12 },
  titre: { fontSize: 20, fontWeight: 'bold', marginBottom: 4 },
  sous: { color: '#555', marginBottom: 18 },
  ligne: { flexDirection: 'row', justifyContent: 'space-between', borderBottomWidth: 1, borderBottomColor: '#ddd', paddingVertical: 6 },
  total: { marginTop: 14, fontSize: 16, fontWeight: 'bold', textAlign: 'right' },
})

export interface DonneesRecap {
  boutique: string
  numero: string
  date: string
  statut: string
  lignes: { libelle: string; quantite: number; total: string }[]
  fraisLivraison: string
  total: string
  libelles: { titre: string; statut: string; frais: string; total: string }
}

function RecapPdf({ d }: { d: DonneesRecap }) {
  return (
    <Document title={`${d.libelles.titre} ${d.numero}`}>
      <Page size="A4" style={styles.page}>
        <Text style={styles.titre}>{d.boutique}</Text>
        <Text style={styles.sous}>{d.libelles.titre} {d.numero} — {d.date} — {d.libelles.statut} : {d.statut}</Text>
        {d.lignes.map((l, i) => (
          <View key={i} style={styles.ligne}><Text>{l.quantite} × {l.libelle}</Text><Text>{l.total}</Text></View>
        ))}
        <View style={styles.ligne}><Text>{d.libelles.frais}</Text><Text>{d.fraisLivraison}</Text></View>
        <Text style={styles.total}>{d.libelles.total} : {d.total}</Text>
      </Page>
    </Document>
  )
}

/** Génère le récapitulatif à la demande (impression ou partage) : aucun PDF n'est stocké. */
export async function ouvrirRecap(donnees: DonneesRecap): Promise<void> {
  const blob = await pdf(<RecapPdf d={donnees} />).toBlob()
  window.open(URL.createObjectURL(blob), '_blank')
}
