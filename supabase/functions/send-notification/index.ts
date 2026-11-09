// Envoi ciblé d'une notification par l'éditeur : in-app (table notifications) + push FCM (stub).
//
// POST { cible: { type: "boutique" | "plan" | "tous" | "utilisateur", id? },
//        titre_ar?, titre_fr?, corps_ar?, corps_fr?, type? }
import { ErreurHttp, json, lireJson, servir, texte } from "../_shared/http.ts";
import { exigerAdminPlateforme } from "../_shared/autorisations.ts";
import { envoyerPush } from "../_shared/fcm.ts";
import { clientService } from "../_shared/supabase.ts";

const CIBLES = ["boutique", "plan", "tous", "utilisateur"] as const;
type TypeCible = (typeof CIBLES)[number];
const STATUTS_ACTIFS = ["essai", "actif", "grace"];

servir(async (req) => {
  const service = clientService();
  const admin = await exigerAdminPlateforme(req, service);
  const corps = await lireJson(req);

  const cible = (corps.cible ?? {}) as { type?: string; id?: string };
  if (!CIBLES.includes(cible.type as TypeCible)) throw new ErreurHttp(400, "donnees_invalides", "cible invalide");
  if (cible.type !== "tous" && !cible.id) throw new ErreurHttp(400, "donnees_invalides", "cible.id requis");
  const titreAr = texte(corps, "titre_ar", 160);
  const titreFr = texte(corps, "titre_fr", 160);
  if (!titreAr && !titreFr) throw new ErreurHttp(400, "donnees_invalides", "titre requis");
  const corpsAr = texte(corps, "corps_ar", 1000);
  const corpsFr = texte(corps, "corps_fr", 1000);

  // Destinataires : membres actifs des boutiques visées.
  let utilisateurs: { boutique_id: string | null; utilisateur_id: string }[] = [];
  if (cible.type === "utilisateur") {
    utilisateurs = [{ boutique_id: null, utilisateur_id: cible.id! }];
  } else {
    let requete = service.from("membres_boutique").select("boutique_id, utilisateur_id, boutiques!inner(statut)")
      .eq("statut", "actif").in("boutiques.statut", STATUTS_ACTIFS);
    if (cible.type === "boutique") requete = requete.eq("boutique_id", cible.id!);
    if (cible.type === "plan") {
      const { data: abonnements } = await service.from("abonnements").select("boutique_id")
        .eq("plan_id", cible.id!).in("statut", STATUTS_ACTIFS);
      requete = requete.in("boutique_id", (abonnements ?? []).map((a) => a.boutique_id as string));
    }
    const { data, error } = await requete;
    if (error) throw new ErreurHttp(500, "lecture_destinataires_impossible");
    utilisateurs = (data ?? []) as typeof utilisateurs;
  }
  if (utilisateurs.length === 0) return json(200, { destinataires: 0, push: { statut: "non_configure", envoyes: 0 } });

  const lignes = utilisateurs.map((u) => ({
    boutique_id: u.boutique_id,
    utilisateur_id: u.utilisateur_id,
    type: texte(corps, "type", 40) ?? "annonce",
    titre_ar: titreAr,
    titre_fr: titreFr,
    corps_ar: corpsAr,
    corps_fr: corpsFr,
    cible: cible.type,
    cree_par: admin.id,
  }));
  for (let i = 0; i < lignes.length; i += 500) {
    const { error } = await service.from("notifications").insert(lignes.slice(i, i + 500));
    if (error) throw new ErreurHttp(500, "enregistrement_impossible", error.message);
  }

  const { data: appareils } = await service.from("appareils").select("jeton_fcm")
    .in("utilisateur_id", utilisateurs.map((u) => u.utilisateur_id)).not("jeton_fcm", "is", null);
  const push = await envoyerPush(
    (appareils ?? []).map((a) => a.jeton_fcm as string),
    { titre: titreFr ?? titreAr ?? "", corps: corpsFr ?? corpsAr ?? "" },
  );
  return json(200, { destinataires: utilisateurs.length, push });
});
