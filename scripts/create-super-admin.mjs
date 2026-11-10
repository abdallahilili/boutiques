#!/usr/bin/env node
// Crée (ou promeut) le premier super-admin de la console éditeur, sans passer par le dashboard ni le SQL.
//
//   npm run admin:create -- 31177008 "MotDePasse" "Nom complet"
//
// Variables lues dans supabase/functions/.env (ignoré par Git) ou dans l'environnement :
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (clé secrète du projet : jamais loguée ni envoyée à une app)
// Connexion sur app_admin : numéro de téléphone (nom d'utilisateur) + mot de passe (8 caractères minimum).
// Relancer le script avec un compte existant remplace son mot de passe et le promeut super-admin.
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const racine = join(dirname(fileURLToPath(import.meta.url)), '..');

function lireEnv(fichier) {
  const env = {};
  if (!existsSync(fichier)) return env;
  for (const ligne of readFileSync(fichier, 'utf8').split(/\r?\n/)) {
    const m = ligne.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/);
    if (m && !ligne.trim().startsWith('#')) env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
  return env;
}

function normaliserTelephone(saisie) {
  let chiffres = String(saisie ?? '').replace(/\D/g, '');
  if (chiffres.startsWith('00')) chiffres = chiffres.slice(2);
  return chiffres.length <= 8 ? `222${chiffres}` : chiffres;
}

const [, , telephoneBrut, motDePasse, nom = 'Éditeur'] = process.argv;
const telephone = normaliserTelephone(telephoneBrut);
if (!/^[0-9]{8,15}$/.test(telephone) || !motDePasse) {
  console.error('Usage : npm run admin:create -- <téléphone> <mot_de_passe_8+_caractères> ["Nom complet"]');
  process.exit(1);
}
if (motDePasse.length < 8) {
  console.error('Le mot de passe doit contenir au moins 8 caractères.');
  process.exit(1);
}

const env = { ...lireEnv(join(racine, 'supabase', 'functions', '.env')), ...process.env };
const url = (env.SUPABASE_URL ?? '').replace(/\/$/, '');
const cle = env.SUPABASE_SERVICE_ROLE_KEY ?? env.SUPABASE_SECRET_KEY;
if (!url || !cle) {
  console.error('SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont requis (supabase/functions/.env).');
  process.exit(1);
}

// Les clés « sb_secret_… » ne sont pas des JWT : elles vont uniquement dans `apikey`.
const entetes = { apikey: cle, 'Content-Type': 'application/json' };
if (cle.startsWith('eyJ')) entetes.Authorization = `Bearer ${cle}`;

async function appeler(methode, chemin, corps, extra = {}) {
  const reponse = await fetch(`${url}${chemin}`, { method: methode, headers: { ...entetes, ...extra }, body: corps ? JSON.stringify(corps) : undefined });
  const texte = await reponse.text();
  let json = null;
  try { json = texte ? JSON.parse(texte) : null; } catch { /* réponse non JSON */ }
  return { ok: reponse.ok, statut: reponse.status, json, texte };
}

// Même identifiant technique que la console et la fonction admin-create-staff.
const adresse = `${telephone}@admin.invalid`;
let utilisateurId;
const creation = await appeler('POST', '/auth/v1/admin/users', { email: adresse, password: motDePasse, email_confirm: true });
if (creation.ok) {
  utilisateurId = creation.json.id;
  console.log(`Super-admin créé : ${telephone}`);
} else if (creation.statut === 422 || /already|exists|registered/i.test(creation.texte)) {
  const liste = await appeler('GET', '/auth/v1/admin/users?page=1&per_page=1000');
  utilisateurId = liste.json?.users?.find((u) => u.email?.toLowerCase() === adresse)?.id;
  if (!utilisateurId) {
    console.error('Utilisateur existant introuvable :', liste.texte);
    process.exit(1);
  }
  const maj = await appeler('PUT', `/auth/v1/admin/users/${utilisateurId}`, { password: motDePasse });
  if (!maj.ok) {
    console.error(`Mot de passe non modifié (${maj.statut}) :`, maj.texte);
    process.exit(1);
  }
  console.log(`Compte existant ${telephone} : mot de passe remplacé, promu super-admin.`);
} else {
  console.error(`Création impossible (${creation.statut}) :`, creation.texte);
  process.exit(1);
}

const profil = await appeler(
  'POST',
  '/rest/v1/profils?on_conflict=id',
  { id: utilisateurId, nom_fr: nom, telephone, role_plateforme: 'super_admin', actif: true },
  { Prefer: 'resolution=merge-duplicates,return=minimal' },
);
if (!profil.ok) {
  console.error(`Profil non enregistré (${profil.statut}) — les migrations sont-elles appliquées (npm run db:push) ?`, profil.texte);
  process.exit(1);
}
console.log(`Super-admin prêt. Connectez-vous sur app_admin avec le numéro ${telephone} et ce mot de passe.`);
