// Rejoue les tests pgTAP de supabase/tests dans PGlite (sans Docker), avec un shim pgTAP.
// Usage : node test_db.mjs [filtre]
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { construireBase, dossierSupabase } from './pglite/base.mjs';

const filtre = process.argv[2];
const { db, migrations } = await construireBase();
console.log(`${migrations.length} migration(s) appliquée(s).`);
await db.exec(readFileSync(new URL('./pglite/pgtap_shim.sql', import.meta.url), 'utf8'));

const dossierTests = join(dossierSupabase, 'tests');
const fichiers = readdirSync(dossierTests).filter((f) => f.endsWith('.sql') && (!filtre || f.includes(filtre))).sort();

let echecs = 0;
let total = 0;
for (const fichier of fichiers) {
  console.log(`\n# ${fichier}`);
  let resultats;
  try {
    // pgTAP est fourni par le shim : on retire uniquement l'activation de l'extension.
    const sql = readFileSync(join(dossierTests, fichier), 'utf8').replace(/^create extension if not exists pgtap.*$/gm, '');
    resultats = await db.exec(sql);
  } catch (e) {
    console.log(`not ok - erreur SQL : ${e.message}`);
    echecs++;
    await db.exec('rollback').catch(() => {});
    continue;
  }
  for (const r of resultats) {
    for (const ligne of r.rows) {
      const texte = Object.values(ligne)[0];
      if (typeof texte !== 'string' || !/^(ok|not ok|1\.\.|#)/.test(texte)) continue;
      console.log(texte);
      if (texte.startsWith('not ok') || texte.startsWith('# Looks like')) echecs++;
      if (/^(ok|not ok)/.test(texte)) total++;
    }
  }
}
console.log(`\n${total} test(s), ${echecs} échec(s).`);
process.exit(echecs ? 1 : 0);
