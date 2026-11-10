#!/usr/bin/env node
// Données de démonstration (fictives) pour tester les trois applications sur le projet Supabase configuré.
//
//   npm run seed:demo
//
// Crée 2 commerçantes avec leur boutique (code PIN 1234 pour les deux), un catalogue (catégories,
// produits, variantes), des réceptions de stock, des clientes, des fournisseurs, des ventes (caisse)
// et des commandes en ligne. Relançable : les comptes existants sont réutilisés, le catalogue d'une
// boutique déjà garnie n'est pas dupliqué.
//
// Lit supabase/functions/.env (ignoré par Git) : SUPABASE_URL, SUPABASE_ANON_KEY,
// SUPABASE_SERVICE_ROLE_KEY, PIN_SECRET. Ne jamais l'utiliser sur un projet de production réel.
import { createHmac, randomUUID } from 'node:crypto';
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
const env = { ...lireEnv(join(racine, 'supabase', 'functions', '.env')), ...process.env };
const url = (env.SUPABASE_URL ?? '').replace(/\/$/, '');
const cleService = env.SUPABASE_SERVICE_ROLE_KEY;
const cleAnon = env.SUPABASE_ANON_KEY;
const poivre = env.PIN_SECRET;
if (!url || !cleService || !cleAnon || !poivre) {
  console.error('SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY et PIN_SECRET sont requis (supabase/functions/.env).');
  process.exit(1);
}

const PIN = '1234';
const entetesService = { apikey: cleService, 'Content-Type': 'application/json' };
if (cleService.startsWith('eyJ')) entetesService.Authorization = `Bearer ${cleService}`;

async function appeler(chemin, { methode = 'GET', corps, entetes = entetesService, extra = {} } = {}) {
  const r = await fetch(`${url}${chemin}`, { method: methode, headers: { ...entetes, ...extra }, body: corps ? JSON.stringify(corps) : undefined });
  const texte = await r.text();
  let json = null;
  try { json = texte ? JSON.parse(texte) : null; } catch { /* non JSON */ }
  return { ok: r.ok, statut: r.status, json, texte };
}
const exiger = (r, quoi) => {
  if (!r.ok) throw new Error(`${quoi} (${r.statut}) : ${r.texte}`);
  return r.json;
};
const insererLot = async (table, lignes) => exiger(await appeler(`/rest/v1/${table}`, { methode: 'POST', corps: lignes, extra: { Prefer: 'return=representation' } }), `insertion ${table}`);
const lire = async (chemin) => exiger(await appeler(`/rest/v1/${chemin}`), `lecture ${chemin}`);

const secretAuth = (email, code) => createHmac('sha256', poivre).update(`${email}:${code}`).digest('hex');

// ---------------------------------------------------------------------------------------------
// Données fictives
// ---------------------------------------------------------------------------------------------
const COMMERCANTES = [
  {
    telephone: '22231000001', nom_ar: 'مريم بنت أحمد', nom_fr: 'Mariem Ahmed', ville: 'Nouakchott',
    boutique: { nom_ar: 'متجر الأناقة', nom_fr: 'Boutique Élégance', slug: 'elegance-demo', type_activite: 'Prêt-à-porter' },
    catalogue: 'mode',
  },
  {
    telephone: '22231000002', nom_ar: 'فاطمة سيدي', nom_fr: 'Fatimetou Sidi', ville: 'Nouadhibou',
    boutique: { nom_ar: 'بقالة السلام', nom_fr: 'Épicerie Salam', slug: 'salam-demo', type_activite: 'Alimentation' },
    catalogue: 'epicerie',
  },
];

const CATALOGUES = {
  mode: {
    categories: [
      { nom_ar: 'فساتين', nom_fr: 'Robes' },
      { nom_ar: 'ملاحف', nom_fr: 'Mlafa (voiles)' },
      { nom_ar: 'أحذية', nom_fr: 'Chaussures' },
      { nom_ar: 'إكسسوارات', nom_fr: 'Accessoires' },
    ],
    couleurs: [
      { nom_ar: 'أسود', nom_fr: 'Noir', code_hex: '#111111' },
      { nom_ar: 'أبيض', nom_fr: 'Blanc', code_hex: '#F5F5F5' },
      { nom_ar: 'أزرق', nom_fr: 'Bleu', code_hex: '#1E5AA8' },
      { nom_ar: 'أحمر', nom_fr: 'Rouge', code_hex: '#C62828' },
    ],
    tailles: [
      { nom_ar: 'S', nom_fr: 'S', type: 'taille' }, { nom_ar: 'M', nom_fr: 'M', type: 'taille' }, { nom_ar: 'L', nom_fr: 'L', type: 'taille' },
    ],
    produits: [
      { cat: 0, nom_ar: 'فستان صيفي', nom_fr: 'Robe d\'été', prix: 1800, cout: 1100, couleurs: [0, 1, 2], tailles: [0, 1, 2], epingle: true },
      { cat: 0, nom_ar: 'فستان سهرة', nom_fr: 'Robe de soirée', prix: 3500, cout: 2200, couleurs: [0, 3], tailles: [1, 2] },
      { cat: 1, nom_ar: 'ملحفة قطنية', nom_fr: 'Mlafa coton', prix: 900, cout: 550, couleurs: [1, 2, 3], tailles: [], epingle: true },
      { cat: 1, nom_ar: 'ملحفة حرير', nom_fr: 'Mlafa soie', prix: 2500, cout: 1600, couleurs: [0, 3], tailles: [] },
      { cat: 2, nom_ar: 'صندل جلد', nom_fr: 'Sandales cuir', prix: 1200, cout: 700, couleurs: [0, 1], tailles: [0, 1, 2] },
      { cat: 3, nom_ar: 'حقيبة يد', nom_fr: 'Sac à main', prix: 1500, cout: 900, couleurs: [0, 2, 3], tailles: [] },
      { cat: 3, nom_ar: 'وشاح', nom_fr: 'Foulard', prix: 400, cout: 220, couleurs: [1, 2, 3], tailles: [] },
    ],
  },
  epicerie: {
    categories: [
      { nom_ar: 'مواد غذائية', nom_fr: 'Épicerie sèche' },
      { nom_ar: 'مشروبات', nom_fr: 'Boissons' },
      { nom_ar: 'منظفات', nom_fr: 'Entretien' },
    ],
    couleurs: [],
    tailles: [],
    produits: [
      { cat: 0, nom_ar: 'أرز 1 كغ', nom_fr: 'Riz 1 kg', prix: 45, cout: 34, couleurs: [], tailles: [], epingle: true },
      { cat: 0, nom_ar: 'سكر 1 كغ', nom_fr: 'Sucre 1 kg', prix: 40, cout: 31, couleurs: [], tailles: [] },
      { cat: 0, nom_ar: 'زيت 1 لتر', nom_fr: 'Huile 1 L', prix: 70, cout: 55, couleurs: [], tailles: [] },
      { cat: 0, nom_ar: 'شاي أخضر', nom_fr: 'Thé vert', prix: 25, cout: 17, couleurs: [], tailles: [], epingle: true },
      { cat: 1, nom_ar: 'ماء 1.5 لتر', nom_fr: 'Eau 1,5 L', prix: 20, cout: 13, couleurs: [], tailles: [] },
      { cat: 1, nom_ar: 'عصير برتقال', nom_fr: 'Jus d\'orange', prix: 35, cout: 24, couleurs: [], tailles: [] },
      { cat: 2, nom_ar: 'مسحوق غسيل', nom_fr: 'Lessive', prix: 90, cout: 68, couleurs: [], tailles: [] },
    ],
  },
};

const CLIENTES = [
  { nom_ar: 'عائشة محمد', nom_fr: 'Aïcha Mohamed', telephone: '22236111111', ville: 'Nouakchott' },
  { nom_ar: 'خديجة ولد', nom_fr: 'Khadija Ould', telephone: '22236222222', ville: 'Nouakchott' },
  { nom_ar: 'زينب عبد الله', nom_fr: 'Zeinebou Abdallahi', telephone: '22236333333', ville: 'Nouadhibou' },
  { nom_ar: 'منتو سالم', nom_fr: 'Mintou Salem', telephone: '22236444444', ville: 'Rosso' },
];
const FOURNISSEURS = [
  { nom_ar: 'مستورد النور', nom_fr: 'Importateur Nour', telephone: '22237111111' },
  { nom_ar: 'شركة الصحراء', nom_fr: 'Société Sahara', telephone: '22237222222' },
];

// ---------------------------------------------------------------------------------------------
// Création des comptes et boutiques
// ---------------------------------------------------------------------------------------------
async function boutiqueDe(telephone) {
  const profils = await lire(`profils?select=id&telephone=eq.${telephone}`);
  if (!profils.length) return null;
  const membres = await lire(`membres_boutique?select=boutique_id&utilisateur_id=eq.${profils[0].id}&limit=1`);
  return membres.length ? { utilisateur_id: profils[0].id, boutique_id: membres[0].boutique_id } : null;
}

async function creerCommercante(c) {
  const existante = await boutiqueDe(c.telephone);
  if (existante) {
    console.log(`  ${c.telephone} existe déjà : réutilisée`);
    return existante;
  }
  const email = `${c.telephone}@tel.invalid`;
  const creation = exiger(
    await appeler('/auth/v1/admin/users', { methode: 'POST', corps: { email, password: secretAuth(email, PIN), email_confirm: true, user_metadata: { telephone: c.telephone } } }),
    'création du compte Auth',
  );
  const r = await appeler('/rest/v1/rpc/creer_commercante_avec_boutique', {
    methode: 'POST',
    corps: { p_donnees: { utilisateur_id: creation.id, telephone: c.telephone, nom_ar: c.nom_ar, nom_fr: c.nom_fr, whatsapp: c.telephone, ville: c.ville, langue: 'ar', boutique: { ...c.boutique, devise: 'MRU' } } },
  });
  if (!r.ok) {
    await appeler(`/auth/v1/admin/users/${creation.id}`, { methode: 'DELETE' });
    throw new Error(`creer_commercante_avec_boutique (${r.statut}) : ${r.texte}`);
  }
  // Boutique « active » avec le plan Standard, pour dépasser les limites de l'essai (50 produits, 1 utilisateur).
  const plans = await lire('plans?select=id&code=eq.standard');
  if (plans.length) {
    exiger(await appeler(`/rest/v1/abonnements?boutique_id=eq.${r.json.boutique_id}`, {
      methode: 'PATCH', corps: { plan_id: plans[0].id, statut: 'actif', fin_le: new Date(Date.now() + 365 * 864e5).toISOString().slice(0, 10) },
    }), 'abonnement');
    exiger(await appeler(`/rest/v1/boutiques?id=eq.${r.json.boutique_id}`, { methode: 'PATCH', corps: { statut: 'actif' } }), 'statut boutique');
  }
  console.log(`  ${c.telephone} créée (boutique ${r.json.slug})`);
  return { utilisateur_id: creation.id, boutique_id: r.json.boutique_id };
}

async function ouvrirSession(c) {
  const email = `${c.telephone}@tel.invalid`;
  const r = await appeler('/auth/v1/token?grant_type=password', {
    methode: 'POST', entetes: { apikey: cleAnon, 'Content-Type': 'application/json' }, corps: { email, password: secretAuth(email, PIN) },
  });
  return exiger(r, 'connexion de la commerçante').access_token;
}
const rpcUtilisateur = async (jeton, nom, donnees) =>
  exiger(await appeler(`/rest/v1/rpc/${nom}`, {
    methode: 'POST', entetes: { apikey: cleAnon, Authorization: `Bearer ${jeton}`, 'Content-Type': 'application/json' }, corps: { p_donnees: donnees },
  }), nom);

// ---------------------------------------------------------------------------------------------
// Remplissage d'une boutique
// ---------------------------------------------------------------------------------------------
async function garnir(c, ids) {
  const B = ids.boutique_id;
  const deja = await lire(`produits?select=id&boutique_id=eq.${B}&limit=1`);
  if (deja.length) {
    console.log('  catalogue déjà présent : ignoré');
    return;
  }
  const cat = CATALOGUES[c.catalogue];
  const parBoutique = (lignes) => lignes.map((l) => ({ ...l, boutique_id: B, cree_par: ids.utilisateur_id }));

  const categories = await insererLot('categories', parBoutique(cat.categories.map((x, i) => ({ ...x, ordre: i }))));
  const couleurs = cat.couleurs.length ? await insererLot('couleurs', parBoutique(cat.couleurs.map((x, i) => ({ ...x, ordre: i })))) : [];
  const tailles = cat.tailles.length ? await insererLot('tailles', parBoutique(cat.tailles.map((x, i) => ({ ...x, ordre: i })))) : [];
  const clients = await insererLot('clients', parBoutique(CLIENTES.map((x) => ({ ...x, whatsapp: x.telephone }))));
  const fournisseurs = await insererLot('fournisseurs', parBoutique(FOURNISSEURS));
  await insererLot('zones_livraison', [
    { boutique_id: B, nom_ar: 'نواكشوط', nom_fr: 'Nouakchott', frais: 100 },
    { boutique_id: B, nom_ar: 'خارج العاصمة', nom_fr: 'Hors capitale', frais: 300 },
  ]).catch((e) => console.log('  zones de livraison ignorées :', e.message.slice(0, 120)));

  const slugify = (s) => s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  const produits = await insererLot('produits', parBoutique(cat.produits.map((p, i) => ({
    categorie_id: categories[p.cat].id, nom_ar: p.nom_ar, nom_fr: p.nom_fr, slug: `${slugify(p.nom_fr)}-${i + 1}`,
    description_fr: `${p.nom_fr} — article de démonstration.`, description_ar: `${p.nom_ar} — منتج تجريبي.`,
    epingle: Boolean(p.epingle), ordre_epinglage: p.epingle ? i + 1 : null, ordre: i,
  }))));

  const variantesAInserer = [];
  const metaVariantes = [];
  cat.produits.forEach((p, i) => {
    const cs = p.couleurs.length ? p.couleurs : [null];
    const ts = p.tailles.length ? p.tailles : [null];
    for (const ci of cs) for (const ti of ts) {
      variantesAInserer.push({
        produit_id: produits[i].id, couleur_id: ci === null ? null : couleurs[ci].id, taille_id: ti === null ? null : tailles[ti].id,
        prix_vente: p.prix, stock_minimum: 3, code_barres: null,
      });
      metaVariantes.push(p);
    }
  });
  const variantes = await insererLot('variantes_produit', parBoutique(variantesAInserer));
  console.log(`  ${categories.length} catégories, ${produits.length} produits, ${variantes.length} variantes, ${clients.length} clientes`);

  // Stock : une réception par fournisseur (coût figé par lot), via la fonction transactionnelle.
  const jeton = await ouvrirSession(c);
  const moitie = Math.ceil(variantes.length / 2);
  for (const [k, tranche] of [variantes.slice(0, moitie), variantes.slice(moitie)].entries()) {
    if (!tranche.length) continue;
    await rpcUtilisateur(jeton, 'recevoir_stock', {
      id: randomUUID(), boutique_id: B, fournisseur_id: fournisseurs[k % fournisseurs.length].id, reference: `BL-DEMO-${k + 1}`,
      lignes: tranche.map((v) => ({ variante_id: v.id, quantite: 8 + Math.floor(Math.random() * 25), cout_unitaire: metaVariantes[variantes.indexOf(v)].cout })),
    });
  }
  console.log('  stock reçu (2 réceptions)');

  // Ventes en caisse : espèces / mobile money, quelques-unes à crédit pour une cliente.
  const modes = await lire(`modes_paiement?select=id,type&boutique_id=eq.${B}&actif=eq.true`);
  const especes = modes.find((m) => m.type === 'especes');
  const mobile = modes.find((m) => m.type === 'mobile_money') ?? especes;
  const rSession = await appeler('/rest/v1/rpc/ouvrir_session_caisse', {
    methode: 'POST', entetes: { apikey: cleAnon, Authorization: `Bearer ${jeton}`, 'Content-Type': 'application/json' },
    corps: { p_boutique_id: B, p_id: randomUUID(), p_fond: 500 },
  });
  const session = rSession.ok ? rSession.json : null;
  if (!session) console.log(`  session de caisse ignorée : ${rSession.texte.slice(0, 120)}`);
  const choisir = () => variantes[Math.floor(Math.random() * variantes.length)];
  let ventes = 0;
  for (let i = 0; i < 10; i++) {
    const lignes = [choisir(), choisir()].filter((v, j, a) => a.indexOf(v) === j).map((v) => ({ id: randomUUID(), variante_id: v.id, quantite: 1 + (i % 3) }));
    const total = lignes.reduce((s, l) => s + l.quantite * variantes.find((v) => v.id === l.variante_id).prix_vente, 0);
    const credit = i % 5 === 4;
    try {
      await rpcUtilisateur(jeton, 'enregistrer_vente', {
        id: randomUUID(), boutique_id: B, type: credit ? 'facture' : 'ticket', canal: 'caisse',
        client_id: credit || i % 2 === 0 ? clients[i % clients.length].id : null, session_caisse_id: session?.id ?? null, lignes,
        paiements: credit ? [{ id: randomUUID(), mode_paiement_id: especes.id, montant: Math.round(total / 3) }] : [{ id: randomUUID(), mode_paiement_id: i % 2 ? mobile.id : especes.id, montant: total }],
      });
      ventes++;
    } catch (e) {
      console.log(`  vente ${i + 1} ignorée : ${e.message.slice(0, 140)}`);
    }
  }
  console.log(`  ${ventes} ventes enregistrées`);

  // Commandes en ligne (comme un visiteur de la boutique, avec la clé publique).
  let commandes = 0;
  for (let i = 0; i < 4; i++) {
    const v = choisir();
    const r = await appeler('/rest/v1/rpc/passer_commande_en_ligne', {
      methode: 'POST', entetes: { apikey: cleAnon, 'Content-Type': 'application/json' },
      corps: { p_slug: c.boutique.slug, p_donnees: { id: randomUUID(), nom_client: CLIENTES[i].nom_fr, telephone: CLIENTES[i].telephone, adresse: 'Tevragh Zeina', ville: CLIENTES[i].ville, mode_livraison: i % 2 ? 'retrait' : 'livraison', mode_paiement: 'a_la_livraison', miel: '', lignes: [{ variante_id: v.id, quantite: 1 + (i % 2) }] } },
    });
    if (r.ok) commandes++; else console.log(`  commande ${i + 1} ignorée : ${r.texte.slice(0, 140)}`);
  }
  console.log(`  ${commandes} commandes en ligne passées`);
}

console.log(`Projet : ${url}`);
for (const c of COMMERCANTES) {
  console.log(`\n${c.boutique.nom_fr} (${c.telephone})`);
  const ids = await creerCommercante(c);
  await garnir(c, ids);
}
console.log(`\nTerminé. Connexion commerçante (app mobile / boutique) : téléphone ${COMMERCANTES.map((c) => c.telephone.slice(3)).join(' ou ')} + code ${PIN}.`);
console.log(`Vitrine : <slug>.<domaine> avec les slugs ${COMMERCANTES.map((c) => c.boutique.slug).join(', ')}.`);
