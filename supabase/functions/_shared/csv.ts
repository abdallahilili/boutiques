// Export CSV compatible Excel : séparateur « ; », UTF-8 avec BOM, guillemets doublés,
// protection contre l'injection de formules (cellules commençant par = + - @).

export function echapperCellule(valeur: unknown): string {
  if (valeur === null || valeur === undefined) return "";
  let texte = typeof valeur === "object" ? JSON.stringify(valeur) : String(valeur);
  if (/^[=+\-@\t\r]/.test(texte) && typeof valeur !== "number") texte = `'${texte}`;
  return /[";\n\r]/.test(texte) ? `"${texte.replaceAll('"', '""')}"` : texte;
}

export function versCsv(lignes: Record<string, unknown>[], colonnes?: string[]): string {
  const cles = colonnes ?? [...new Set(lignes.flatMap((l) => Object.keys(l)))];
  const entete = cles.map(echapperCellule).join(";");
  const corps = lignes.map((l) => cles.map((c) => echapperCellule(l[c])).join(";"));
  return "﻿" + [entete, ...corps].join("\r\n") + "\r\n";
}
