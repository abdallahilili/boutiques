// Export des données d'une boutique en CSV (ouvrable dans Excel : UTF-8 avec BOM, séparateur « ; »).
// Réservé à la propriétaire (permission parametres.gerer) ; 3 exports par heure et par boutique.
//
// POST { boutique_id, tables?: string[] }
//  → 200 { boutique_id, genere_le, fichiers: [{ nom, table, lignes, tronque, contenu }] }
//
// Chaque table est lue page par page (1 000 lignes) et plafonnée à 20 000 lignes (`tronque: true` au-delà) :
// pour une sauvegarde complète d'un très gros catalogue, demander une extraction ciblée table par table.
import { ErreurHttp, json, lireJson, servir } from "../_shared/http.ts";
import { exigerPermission } from "../_shared/autorisations.ts";
import { versCsv } from "../_shared/csv.ts";
import { clientService } from "../_shared/supabase.ts";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const PAGE = 1000;
const PLAFOND = 20_000;

/** Tables exportables et colonne de tri stable. */
export const TABLES_EXPORTABLES: Record<string, string> = {
  categories: "cree_le",
  produits: "cree_le",
  variantes_produit: "cree_le",
  clients: "cree_le",
  fournisseurs: "cree_le",
  documents_vente: "cree_le",
  lignes_document_vente: "id",
  paiements: "cree_le",
  receptions_stock: "cree_le",
  lots_stock: "recu_le",
  mouvements_stock: "cree_le",
  depenses: "cree_le",
  commandes: "cree_le",
  lignes_commande: "id",
};

servir(async (req) => {
  const corps = await lireJson(req);
  const boutiqueId = String(corps.boutique_id ?? "");
  if (!UUID.test(boutiqueId)) throw new ErreurHttp(400, "donnees_invalides", "boutique_id invalide");
  const demandees = Array.isArray(corps.tables) ? corps.tables.map(String) : Object.keys(TABLES_EXPORTABLES);
  const inconnues = demandees.filter((t) => !(t in TABLES_EXPORTABLES));
  if (inconnues.length > 0) throw new ErreurHttp(400, "donnees_invalides", `tables inconnues : ${inconnues.join(", ")}`);
  const utilisateur = await exigerPermission(req, boutiqueId, "parametres.gerer");

  const service = clientService();
  const { error: erreurLimite } = await service.rpc("limiter_requete", { p_cle: `export:${boutiqueId}`, p_max: 3, p_fenetre_secondes: 3600 });
  if (erreurLimite) {
    if (erreurLimite.message.startsWith("trop_de_requetes")) throw new ErreurHttp(429, "trop_de_requetes", "3 exports par heure au maximum");
    throw new ErreurHttp(500, "limitation_indisponible");
  }

  const fichiers = [];
  for (const table of demandees) {
    const lignes: Record<string, unknown>[] = [];
    let tronque = false;
    for (let debut = 0; ; debut += PAGE) {
      const { data, error } = await service.from(table).select("*").eq("boutique_id", boutiqueId)
        .order(TABLES_EXPORTABLES[table]).range(debut, debut + PAGE - 1);
      if (error) throw new ErreurHttp(500, "export_impossible", `${table} : ${error.message}`);
      lignes.push(...((data ?? []) as Record<string, unknown>[]));
      if (!data || data.length < PAGE) break;
      if (lignes.length >= PLAFOND) {
        tronque = true;
        break;
      }
    }
    fichiers.push({ nom: `${table}.csv`, table, lignes: lignes.length, tronque, contenu: versCsv(lignes) });
  }

  await service.from("journal_audit").insert({
    boutique_id: boutiqueId,
    utilisateur_id: utilisateur.id,
    action: "export_donnees",
    entite: "boutiques",
    entite_id: boutiqueId,
    details: { tables: demandees },
  });
  return json(200, { boutique_id: boutiqueId, genere_le: new Date().toISOString(), fichiers });
});
