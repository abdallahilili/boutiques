// Génère les types TypeScript (apps web) et Dart (app mobile) depuis les migrations SQL.
// Les migrations sont appliquées dans PGlite puis le catalogue PostgreSQL est introspecté.
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';
import { construireBase } from './pglite/base.mjs';

const racine = join(dirname(fileURLToPath(import.meta.url)), '..');
const SORTIES_TS = ['apps/app_admin/src/types/database.ts', 'apps/app_boutique/src/types/database.ts'];
const SORTIE_DART = 'apps/app_commercante/lib/core/types/database_types.dart';
const ENTETE = 'Fichier généré par scripts/gen_types.mjs à partir de supabase/migrations — ne pas modifier à la main.';

const { db } = await construireBase({ seed: false });

const types = new Map(
  (await db.query(`select oid::int as oid, typname, typtype, typelem::int as elem, typcategory from pg_type`)).rows.map((t) => [t.oid, t]),
);

const colonnes = (await db.query(`
  select c.relname as objet, c.relkind, a.attname as col, a.atttypid::int as type_oid,
         a.attnotnull as non_nul, (a.atthasdef or a.attidentity <> '' or a.attgenerated <> '') as a_defaut
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  join pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
  where n.nspname = 'public' and c.relkind in ('r', 'v')
  order by c.relname, a.attnum`)).rows;

const enums = (await db.query(`
  select t.typname as nom, array_agg(e.enumlabel order by e.enumsortorder) as valeurs
  from pg_type t join pg_enum e on e.enumtypid = t.oid join pg_namespace n on n.oid = t.typnamespace
  where n.nspname = 'public' group by t.typname order by t.typname`)).rows;

const fonctions = (await db.query(`
  select p.proname as nom, p.pronargdefaults as nb_defauts, p.proargnames as noms,
         string_to_array(p.proargtypes::text, ' ') as types_args, p.prorettype::int as retour, p.proretset as ensemble
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f' and p.prorettype <> 'trigger'::regtype
  order by p.proname`)).rows;

// ---------------------------------------------------------------------------
// Regroupement
// ---------------------------------------------------------------------------
const objets = new Map();
for (const c of colonnes) {
  if (!objets.has(c.objet)) objets.set(c.objet, { genre: c.relkind === 'r' ? 'table' : 'vue', colonnes: [] });
  objets.get(c.objet).colonnes.push(c);
}
const noms = (genre) => [...objets].filter(([, o]) => o.genre === genre).map(([nom]) => nom);

// ---------------------------------------------------------------------------
// TypeScript
// ---------------------------------------------------------------------------
function typeTs(oid) {
  const t = types.get(oid);
  if (t.typtype === 'e') return `Database['public']['Enums']['${t.typname}']`;
  if (t.typcategory === 'A') return `${typeTs(t.elem)}[]`;
  if (['int2', 'int4', 'int8', 'float4', 'float8', 'numeric', 'oid'].includes(t.typname)) return 'number';
  if (t.typname === 'bool') return 'boolean';
  if (['json', 'jsonb'].includes(t.typname)) return 'Json';
  if (['uuid', 'text', 'varchar', 'bpchar', 'name', 'date', 'time', 'timetz', 'timestamp', 'timestamptz', 'interval', 'citext'].includes(t.typname)) return 'string';
  if (t.typname === 'void') return 'undefined';
  return 'unknown';
}

function tsObjet(nom, objet, indent) {
  const pad = ' '.repeat(indent);
  const ligne = (c, optionnel, nullable) =>
    `${pad}  ${c.col}${optionnel ? '?' : ''}: ${typeTs(c.type_oid)}${nullable ? ' | null' : ''}`;
  const bloc = (titre, fabrique) => `${pad}${titre}: {\n${objet.colonnes.map(fabrique).join('\n')}\n${pad}}`;
  const row = bloc('Row', (c) => ligne(c, false, objet.genre === 'vue' || !c.non_nul));
  if (objet.genre === 'vue') return `${pad.slice(2)}  ${nom}: {\n${row}\n${pad}Relationships: []\n${pad.slice(2)}  }`;
  const ins = bloc('Insert', (c) => ligne(c, c.a_defaut || !c.non_nul, !c.non_nul));
  const maj = bloc('Update', (c) => ligne(c, true, !c.non_nul));
  return `${pad.slice(2)}  ${nom}: {\n${row}\n${ins}\n${maj}\n${pad}Relationships: []\n${pad.slice(2)}  }`;
}

function tsFonction(f) {
  const total = f.types_args.filter(Boolean).length;
  const args = f.types_args.filter(Boolean).map((oid, i) => {
    const nom = f.noms?.[i] ?? `arg${i}`;
    const optionnel = i >= total - f.nb_defauts;
    return `        ${nom}${optionnel ? '?' : ''}: ${typeTs(Number(oid))}`;
  });
  const retour = typeTs(f.retour) + (f.ensemble ? '[]' : '');
  const corpsArgs = args.length ? `{\n${args.join('\n')}\n      }` : 'Record<PropertyKey, never>';
  return `      ${f.nom}: {\n        Args: ${corpsArgs}\n        Returns: ${retour}\n      }`;
}

const ts = `// ${ENTETE}
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  public: {
    Tables: {
${noms('table').map((n) => tsObjet(n, objets.get(n), 8)).join('\n')}
    }
    Views: {
${noms('vue').map((n) => tsObjet(n, objets.get(n), 8)).join('\n')}
    }
    Functions: {
${fonctions.map(tsFonction).join('\n')}
    }
    Enums: {
${enums.map((e) => `      ${e.nom}: ${e.valeurs.map((v) => `'${v}'`).join(' | ')}`).join('\n')}
    }
    CompositeTypes: Record<string, never>
  }
}

type Public = Database['public']
export type Tables<T extends keyof Public['Tables']> = Public['Tables'][T]['Row']
export type TablesInsert<T extends keyof Public['Tables']> = Public['Tables'][T]['Insert']
export type TablesUpdate<T extends keyof Public['Tables']> = Public['Tables'][T]['Update']
export type Views<T extends keyof Public['Views']> = Public['Views'][T]['Row']
export type Enums<T extends keyof Public['Enums']> = Public['Enums'][T]
`;

// ---------------------------------------------------------------------------
// Dart
// ---------------------------------------------------------------------------
const camel = (s) => s.replace(/_([a-z0-9])/g, (_, c) => c.toUpperCase());
const pascal = (s) => camel(s).replace(/^./, (c) => c.toUpperCase());
const RESERVES_DART = new Set(['class', 'default', 'enum', 'new', 'null', 'switch', 'this', 'true', 'false', 'var', 'void', 'with', 'in', 'is', 'as', 'do', 'if', 'else', 'for', 'while', 'case', 'try', 'catch', 'final', 'const', 'type', 'rethrow']);
const champDart = (col) => (RESERVES_DART.has(camel(col)) ? `${camel(col)}_` : camel(col));

function typeDart(oid) {
  const t = types.get(oid);
  if (t.typtype === 'e') return pascal(t.typname);
  if (t.typcategory === 'A') return `List<${typeDart(t.elem)}>`;
  if (['int2', 'int4', 'int8', 'oid'].includes(t.typname)) return 'int';
  if (['float4', 'float8', 'numeric'].includes(t.typname)) return 'double';
  if (t.typname === 'bool') return 'bool';
  if (['json', 'jsonb'].includes(t.typname)) return 'dynamic';
  if (['date', 'timestamp', 'timestamptz'].includes(t.typname)) return 'DateTime';
  return 'String';
}

function lectureDart(oid, expr) {
  const t = types.get(oid);
  if (t.typtype === 'e') return `${pascal(t.typname)}.depuisJson(${expr} as String)`;
  if (t.typcategory === 'A') return `(${expr} as List).map((e) => ${lectureDart(t.elem, 'e')}).toList()`;
  const dart = typeDart(oid);
  if (dart === 'double') return `(${expr} as num).toDouble()`;
  if (dart === 'DateTime') return `DateTime.parse(${expr} as String)`;
  if (dart === 'dynamic') return expr;
  return `${expr} as ${dart}`;
}

function ecritureDart(oid, expr, nullable) {
  const t = types.get(oid);
  const acces = nullable ? '?.' : '.';
  if (t.typtype === 'e') return `${expr}${acces}valeur`;
  if (t.typcategory === 'A') return `${expr}${acces}map((e) => ${ecritureDart(t.elem, 'e', false)}).toList()`;
  if (typeDart(oid) === 'DateTime') return `${expr}${acces}toIso8601String()`;
  return expr;
}

function classeDart(nom, objet) {
  const cols = objet.colonnes;
  const nullable = (c) => objet.genre === 'vue' || !c.non_nul;
  const champs = cols.map((c) => `  final ${typeDart(c.type_oid)}${nullable(c) && typeDart(c.type_oid) !== 'dynamic' ? '?' : ''} ${champDart(c.col)};`);
  const ctor = cols.map((c) => `    ${nullable(c) ? '' : 'required '}this.${champDart(c.col)},`);
  const depuis = cols.map((c) => {
    const brut = `json['${c.col}']`;
    const lecture = lectureDart(c.type_oid, brut);
    return `      ${champDart(c.col)}: ${nullable(c) ? `${brut} == null ? null : ${lecture}` : lecture},`;
  });
  const vers = cols.map((c) => {
    return `        '${c.col}': ${ecritureDart(c.type_oid, champDart(c.col), nullable(c))},`;
  });
  return `/// ${objet.genre === 'vue' ? 'Vue' : 'Table'} \`${nom}\`.
class ${pascal(nom)}Row {
  const ${pascal(nom)}Row({
${ctor.join('\n')}
  });

${champs.join('\n')}

  factory ${pascal(nom)}Row.depuisJson(Map<String, dynamic> json) => ${pascal(nom)}Row(
${depuis.join('\n')}
    );

  Map<String, dynamic> versJson() => {
${vers.join('\n')}
      };
}
`;
}

function enumDart(e) {
  const membre = (v) => (RESERVES_DART.has(camel(v)) ? `${camel(v)}_` : camel(v));
  return `enum ${pascal(e.nom)} {
${e.valeurs.map((v) => `  ${membre(v)}('${v}')`).join(',\n')};

  const ${pascal(e.nom)}(this.valeur);
  final String valeur;

  static ${pascal(e.nom)} depuisJson(String valeur) => values.firstWhere((e) => e.valeur == valeur);
}
`;
}

const dart = `// ${ENTETE}
// ignore_for_file: constant_identifier_names, public_member_api_docs, lines_longer_than_80_chars, prefer_if_null_operators, prefer_null_aware_operators

${enums.map(enumDart).join('\n')}
/// Noms des tables et vues.
abstract final class Tables {
${[...objets.keys()].map((n) => `  static const ${camel(n)} = '${n}';`).join('\n')}
}

/// Noms des fonctions SQL (RPC).
abstract final class Rpc {
${fonctions.map((f) => `  static const ${camel(f.nom)} = '${f.nom}';`).join('\n')}
}

${[...objets].map(([nom, objet]) => classeDart(nom, objet)).join('\n')}`;

// ---------------------------------------------------------------------------
// Écriture
// ---------------------------------------------------------------------------
function ecrire(chemin, contenu) {
  const complet = join(racine, chemin);
  mkdirSync(dirname(complet), { recursive: true });
  writeFileSync(complet, contenu, 'utf8');
  console.log(`→ ${chemin}`);
  return complet;
}

for (const sortie of SORTIES_TS) ecrire(sortie, ts);
const cheminDart = ecrire(SORTIE_DART, dart);
try {
  execSync(`dart format "${cheminDart}"`, { stdio: 'ignore' });
} catch {
  // dart absent : le fichier reste valide, simplement non formaté.
}
console.log(`${noms('table').length} table(s), ${noms('vue').length} vue(s), ${fonctions.length} fonction(s), ${enums.length} enum(s).`);
