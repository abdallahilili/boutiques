// Construit une base PGlite avec l'environnement Supabase émulé, les migrations et (option) le seed.
import { PGlite } from '@electric-sql/pglite';
import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const racine = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
export const dossierSupabase = join(racine, 'supabase');

export async function construireBase({ seed = true, jusqua = process.env.MIGRATIONS_JUSQUA } = {}) {
  const db = new PGlite();
  await db.exec(readFileSync(join(dossierSupabase, '..', 'scripts', 'pglite', 'supabase_stub.sql'), 'utf8'));

  const dossierMigrations = join(dossierSupabase, 'migrations');
  // `jusqua` (préfixe de version) permet de reconstruire un état intermédiaire du schéma.
  const migrations = readdirSync(dossierMigrations)
    .filter((f) => f.endsWith('.sql') && (!jusqua || f.slice(0, jusqua.length) <= jusqua))
    .sort();
  for (const fichier of migrations) {
    try {
      await db.exec(readFileSync(join(dossierMigrations, fichier), 'utf8'));
    } catch (e) {
      throw new Error(`Migration ${fichier} : ${e.message}`);
    }
  }

  const fichierSeed = join(dossierSupabase, 'seed.sql');
  if (seed && existsSync(fichierSeed)) {
    try {
      await db.exec(readFileSync(fichierSeed, 'utf8'));
    } catch (e) {
      throw new Error(`seed.sql : ${e.message}`);
    }
  }
  return { db, migrations };
}
