import { Document, Font, Page, StyleSheet, Text, View, pdf } from '@react-pdf/renderer'

Font.register({
  family: 'Amiri',
  fonts: [{ src: '/fonts/Amiri-Regular.ttf' }, { src: '/fonts/Amiri-Bold.ttf', fontWeight: 'bold' }],
})

const styles = StyleSheet.create({
  page: { padding: 40, fontFamily: 'Amiri', fontSize: 12 },
  titre: { fontSize: 20, fontWeight: 'bold', textAlign: 'center', marginBottom: 4 },
  sous: { textAlign: 'center', color: '#555', marginBottom: 24 },
  ligne: { flexDirection: 'row', justifyContent: 'space-between', borderBottomWidth: 1, borderBottomColor: '#ddd', paddingVertical: 8 },
  etiquette: { color: '#555' },
  total: { marginTop: 20, fontSize: 18, fontWeight: 'bold', textAlign: 'center' },
})

export interface DonneesRecu {
  numero: string
  date: string
  boutique: string
  plan: string
  montant: string
  mode: string
  reference: string | null
  periodeMois: number
  libelles: { titre: string; boutique: string; plan: string; montant: string; mode: string; reference: string; periode: string; date: string }
}

function RecuPdf({ d }: { d: DonneesRecu }) {
  const l = d.libelles
  const ligne = (etiquette: string, valeur: string) => (
    <View style={styles.ligne}><Text style={styles.etiquette}>{etiquette}</Text><Text>{valeur}</Text></View>
  )
  return (
    <Document title={`${l.titre} ${d.numero}`}>
      <Page size="A5" style={styles.page}>
        <Text style={styles.titre}>{l.titre}</Text>
        <Text style={styles.sous}>N° {d.numero}</Text>
        {ligne(l.date, d.date)}
        {ligne(l.boutique, d.boutique)}
        {ligne(l.plan, d.plan)}
        {ligne(l.periode, String(d.periodeMois))}
        {ligne(l.mode, d.mode)}
        {d.reference && ligne(l.reference, d.reference)}
        <Text style={styles.total}>{d.montant}</Text>
      </Page>
    </Document>
  )
}

/** Génère le reçu à la demande (aucun PDF n'est stocké) et l'ouvre dans un nouvel onglet. */
export async function ouvrirRecu(donnees: DonneesRecu): Promise<void> {
  const blob = await pdf(<RecuPdf d={donnees} />).toBlob()
  window.open(URL.createObjectURL(blob), '_blank')
}
