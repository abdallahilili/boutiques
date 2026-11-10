// Vérification DNS d'un domaine personnalisé (DNS-over-HTTPS) : le domaine doit pointer vers
// l'hébergeur de la boutique en ligne par un CNAME (ou, pour un domaine racine, un enregistrement A).

export interface ReponseDns {
  Status?: number;
  Answer?: { name: string; type: number; data: string }[];
}

export const TYPE_A = 1;
export const TYPE_CNAME = 5;

export function normaliserDomaine(saisie: string): string {
  return saisie.trim().toLowerCase().replace(/^https?:\/\//, "").replace(/\/.*$/, "").replace(/\.$/, "");
}

export function sansPointFinal(valeur: string): string {
  return valeur.trim().toLowerCase().replace(/\.$/, "");
}

export interface CiblesDns {
  /** Nom d'hôte attendu pour un CNAME (ex. cname.vercel-dns.com). */
  cname?: string;
  /** Adresses IPv4 acceptées pour un enregistrement A (domaine racine). */
  a?: string[];
}

export interface ResultatDns {
  ok: boolean;
  type: "CNAME" | "A" | null;
  trouve: string[];
}

/** Décide si les réponses DNS (CNAME puis A) correspondent aux cibles attendues. */
export function evaluerDns(cname: ReponseDns, a: ReponseDns, cibles: CiblesDns): ResultatDns {
  const cnames = (cname.Answer ?? []).filter((r) => r.type === TYPE_CNAME).map((r) => sansPointFinal(r.data));
  if (cibles.cname && cnames.includes(sansPointFinal(cibles.cname))) return { ok: true, type: "CNAME", trouve: cnames };
  const adresses = (a.Answer ?? []).filter((r) => r.type === TYPE_A).map((r) => r.data.trim());
  if (cibles.a?.length && adresses.some((x) => cibles.a!.includes(x))) return { ok: true, type: "A", trouve: adresses };
  return { ok: false, type: null, trouve: [...cnames, ...adresses] };
}

export async function interrogerDns(domaine: string, type: "CNAME" | "A"): Promise<ReponseDns> {
  const reponse = await fetch(
    `https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(domaine)}&type=${type}`,
    { headers: { Accept: "application/dns-json" } },
  );
  if (!reponse.ok) throw new Error(`DNS-over-HTTPS indisponible (${reponse.status})`);
  return await reponse.json() as ReponseDns;
}
