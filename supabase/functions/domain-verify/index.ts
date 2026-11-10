// Vérifie le DNS du domaine personnalisé d'une boutique et, s'il est correct, le rattache à l'hébergeur
// de la boutique en ligne (API Vercel). Appelée par l'app mobile (permission site.gerer) ou la console éditeur.
//
// POST { boutique_id }
//  → 200 { statut_dns, statut_ssl, domaine, instructions: { type, nom, valeur }[] , trouve? }
//
// Variables : DOMAIN_CNAME_TARGET (ex. cname.vercel-dns.com), DOMAIN_A_TARGETS (IPv4 séparées par des virgules,
// facultatif), VERCEL_TOKEN, VERCEL_PROJECT_ID, VERCEL_TEAM_ID (facultatif). Sans les variables Vercel, le DNS est
// vérifié mais le rattachement n'est pas fait (le SSL reste « en attente » jusqu'au rattachement manuel).
import { ErreurHttp, json, lireJson, servir } from "../_shared/http.ts";
import { exigerPermission } from "../_shared/autorisations.ts";
import { type CiblesDns, evaluerDns, interrogerDns, normaliserDomaine } from "../_shared/dns.ts";
import { clientService, utilisateurCourant } from "../_shared/supabase.ts";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function cibles(): CiblesDns {
  const cname = Deno.env.get("DOMAIN_CNAME_TARGET") ?? undefined;
  const a = (Deno.env.get("DOMAIN_A_TARGETS") ?? "").split(",").map((x) => x.trim()).filter((x) => x);
  if (!cname && a.length === 0) throw new ErreurHttp(500, "dns_non_configure", "DOMAIN_CNAME_TARGET est requis");
  return { cname, a };
}

/** Rattache le domaine au projet d'hébergement ; retourne true si le certificat peut être émis. */
async function rattacherHebergeur(domaine: string): Promise<boolean | null> {
  const jeton = Deno.env.get("VERCEL_TOKEN");
  const projet = Deno.env.get("VERCEL_PROJECT_ID");
  if (!jeton || !projet) return null;
  const equipe = Deno.env.get("VERCEL_TEAM_ID");
  const adresse = `https://api.vercel.com/v10/projects/${projet}/domains${equipe ? `?teamId=${equipe}` : ""}`;
  const reponse = await fetch(adresse, {
    method: "POST",
    headers: { Authorization: `Bearer ${jeton}`, "Content-Type": "application/json" },
    body: JSON.stringify({ name: domaine }),
  });
  if (reponse.ok) return true;
  const corps = await reponse.json().catch(() => ({})) as { error?: { code?: string } };
  // Déjà rattaché : succès idempotent.
  if (corps.error?.code === "domain_already_in_use" || corps.error?.code === "domain_already_exists") return true;
  return false;
}

servir(async (req) => {
  const corps = await lireJson(req);
  const boutiqueId = String(corps.boutique_id ?? "");
  if (!UUID.test(boutiqueId)) throw new ErreurHttp(400, "donnees_invalides", "boutique_id invalide");
  const service = clientService();

  // Autorisation : membre avec site.gerer, ou équipe éditeur.
  try {
    await exigerPermission(req, boutiqueId, "site.gerer");
  } catch (e) {
    const utilisateur = await utilisateurCourant(req);
    const { data: profil } = await service.from("profils").select("role_plateforme, actif").eq("id", utilisateur.id).maybeSingle();
    if (!profil?.actif || !["super_admin", "support"].includes(String(profil.role_plateforme))) throw e;
  }

  const { data: ligne } = await service.from("domaines_boutique")
    .select("id, domaine_personnalise").eq("boutique_id", boutiqueId).eq("principal", true).maybeSingle();
  const domaine = ligne?.domaine_personnalise ? normaliserDomaine(String(ligne.domaine_personnalise)) : null;
  if (!ligne || !domaine) throw new ErreurHttp(404, "domaine_non_configure");

  const attendu = cibles();
  const instructions = [
    ...(attendu.cname ? [{ type: "CNAME", nom: domaine, valeur: attendu.cname }] : []),
    ...(attendu.a ?? []).map((valeur) => ({ type: "A", nom: domaine, valeur })),
  ];

  let verification;
  try {
    const [cname, a] = await Promise.all([interrogerDns(domaine, "CNAME"), interrogerDns(domaine, "A")]);
    verification = evaluerDns(cname, a, attendu);
  } catch {
    throw new ErreurHttp(502, "dns_indisponible", "Impossible de lire le DNS pour le moment, réessayez");
  }

  if (!verification.ok) {
    await service.from("domaines_boutique").update({ statut_dns: "erreur", statut_ssl: "non_configure" }).eq("id", ligne.id);
    return json(200, { domaine, statut_dns: "erreur", statut_ssl: "non_configure", instructions, trouve: verification.trouve });
  }

  const rattache = await rattacherHebergeur(domaine);
  const statutSsl = rattache === true ? "verifie" : rattache === false ? "erreur" : "en_attente";
  await service.from("domaines_boutique").update({ statut_dns: "verifie", statut_ssl: statutSsl }).eq("id", ligne.id);
  await service.from("journal_audit").insert({
    boutique_id: boutiqueId,
    action: "verification_domaine",
    entite: "domaines_boutique",
    entite_id: ligne.id,
    details: { domaine, statut_ssl: statutSsl },
  });
  return json(200, { domaine, statut_dns: "verifie", statut_ssl: statutSsl, instructions });
});
