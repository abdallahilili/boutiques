function echapper(valeur: unknown): string {
  const texte = valeur === null || valeur === undefined ? '' : String(valeur)
  return /[",;\n\r]/.test(texte) ? `"${texte.replace(/"/g, '""')}"` : texte
}

/** Sérialise des lignes en CSV (séparateur « ; » pour l'ouverture directe dans Excel en locale FR/AR). */
export function versCsv(entetes: string[], lignes: unknown[][]): string {
  return [entetes, ...lignes].map((ligne) => ligne.map(echapper).join(';')).join('\r\n')
}

export function telechargerCsv(nomFichier: string, contenu: string): void {
  const blob = new Blob(['﻿' + contenu], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const lien = document.createElement('a')
  lien.href = url
  lien.download = nomFichier
  lien.click()
  URL.revokeObjectURL(url)
}
