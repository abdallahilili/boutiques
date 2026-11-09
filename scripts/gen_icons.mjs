// Génère les icônes PWA (PNG) de la boutique en ligne : sac sur fond de la couleur par défaut du thème.
import { mkdirSync, writeFileSync } from 'node:fs';
import { deflateSync } from 'node:zlib';
import { join } from 'node:path';

const FOND = [0x8a, 0x3b, 0x5c];
const BLANC = [255, 255, 255];

function crc32(buf) {
  let c;
  const table = Array.from({ length: 256 }, (_, n) => {
    c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    return c >>> 0;
  });
  let crc = 0xffffffff;
  for (const b of buf) crc = table[(crc ^ b) & 0xff] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}

function bloc(type, data) {
  const corps = Buffer.concat([Buffer.from(type), data]);
  const longueur = Buffer.alloc(4);
  longueur.writeUInt32BE(data.length);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(corps));
  return Buffer.concat([longueur, corps, crc]);
}

/** Zone sûre « maskable » : le motif tient dans les 60 % centraux. */
function pixel(x, y) {
  const corps = x > 0.3 && x < 0.7 && y > 0.42 && y < 0.72;
  const dx = x - 0.5;
  const dy = y - 0.42;
  const distance = Math.hypot(dx, dy);
  const anse = y < 0.42 && distance > 0.12 && distance < 0.16;
  return corps || anse ? BLANC : FOND;
}

function png(taille) {
  const lignes = [];
  for (let y = 0; y < taille; y++) {
    const ligne = Buffer.alloc(1 + taille * 3);
    for (let x = 0; x < taille; x++) ligne.set(pixel(x / taille, y / taille), 1 + x * 3);
    lignes.push(ligne);
  }
  const entete = Buffer.alloc(13);
  entete.writeUInt32BE(taille, 0);
  entete.writeUInt32BE(taille, 4);
  entete.set([8, 2, 0, 0, 0], 8);
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    bloc('IHDR', entete),
    bloc('IDAT', deflateSync(Buffer.concat(lignes))),
    bloc('IEND', Buffer.alloc(0)),
  ]);
}

const dossier = join(import.meta.dirname, '..', 'apps', 'app_boutique', 'public', 'icons');
mkdirSync(dossier, { recursive: true });
for (const t of [192, 512]) writeFileSync(join(dossier, `icon-${t}.png`), png(t));
console.log('Icônes générées dans', dossier);
