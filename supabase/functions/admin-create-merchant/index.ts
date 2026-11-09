// Création d'une commerçante par l'éditeur (app_admin) : utilisateur Auth, profil, boutique,
// référentiels par défaut, abonnement d'essai et code initial à 4 chiffres.
// Le code n'est retourné qu'une fois, à l'administrateur, avec un lien WhatsApp pré-rempli.
//
// POST { telephone, nom_ar?, nom_fr?, whatsapp?, email?, ville?, notes?, langue?,
//        boutique: { nom_ar?, nom_fr?, slug?, type_activite?, devise? } }
import { ErreurHttp, json, lireJson, servir, texte } from "../_shared/http.ts";
import { emailTechnique, genererCodePin, secretAuth } from "../_shared/code_pin.ts";
import { exigerAdminPlateforme } from "../_shared/autorisations.ts";
import { clientService, poivrePin } from "../_shared/supabase.ts";
import { estTelephoneValide, normaliserTelephone } from "../_shared/telephone.ts";
import { lienWhatsapp, messageCodeInitial } from "../_shared/whatsapp.ts";

servir(async (req) => {
  const service = clientService();
  const admin = await exigerAdminPlateforme(req, service);
  const corps = await lireJson(req);

  const telephone = normaliserTelephone(texte(corps, "telephone", 30) ?? "");
  if (!estTelephoneValide(telephone)) throw new ErreurHttp(400, "donnees_invalides", "telephone invalide");
  const nomAr = texte(corps, "nom_ar", 120);
  const nomFr = texte(corps, "nom_fr", 120);
  if (!nomAr && !nomFr) throw new ErreurHttp(400, "donnees_invalides", "nom_ar ou nom_fr requis");

  const boutique = (corps.boutique ?? {}) as Record<string, unknown>;
  const boutiqueNomAr = texte(boutique, "nom_ar", 120);
  const boutiqueNomFr = texte(boutique, "nom_fr", 120);
  if (!boutiqueNomAr && !boutiqueNomFr) throw new ErreurHttp(400, "donnees_invalides", "nom de boutique requis");
  const langue = texte(corps, "langue", 2) ?? "ar";
  if (!["ar", "fr"].includes(langue)) throw new ErreurHttp(400, "donnees_invalides", "langue invalide");

  const { data: existant } = await service.from("profils").select("id").eq("telephone", telephone).maybeSingle();
  if (existant) throw new ErreurHttp(409, "telephone_deja_utilise");

  const code = genererCodePin();
  const email = emailTechnique({ type: "commercante", telephone });
  const { data: cree, error: erreurAuth } = await service.auth.admin.createUser({
    email,
    password: await secretAuth(email, code, poivrePin()),
    email_confirm: true,
    user_metadata: { telephone },
  });
  if (erreurAuth || !cree.user) throw new ErreurHttp(409, "creation_compte_impossible", erreurAuth?.message);

  // Création atomique côté base ; en cas d'échec, l'utilisateur Auth est supprimé (pas d'orphelin).
  const { data: resultat, error: erreurBase } = await service.rpc("creer_commercante_avec_boutique", {
    p_donnees: {
      utilisateur_id: cree.user.id,
      telephone,
      nom_ar: nomAr,
      nom_fr: nomFr,
      whatsapp: texte(corps, "whatsapp", 30) ? normaliserTelephone(texte(corps, "whatsapp", 30)!) : telephone,
      email: texte(corps, "email", 200),
      ville: texte(corps, "ville", 80),
      notes: texte(corps, "notes", 2000),
      langue,
      cree_par: admin.id,
      boutique: {
        nom_ar: boutiqueNomAr,
        nom_fr: boutiqueNomFr,
        slug: texte(boutique, "slug", 40),
        type_activite: texte(boutique, "type_activite", 80),
        devise: texte(boutique, "devise", 3)?.toUpperCase() ?? "MRU",
      },
    },
  });
  if (erreurBase) {
    await service.auth.admin.deleteUser(cree.user.id);
    throw new ErreurHttp(400, "creation_boutique_impossible", erreurBase.message);
  }

  await service.from("journal_audit").insert({
    boutique_id: resultat.boutique_id,
    utilisateur_id: admin.id,
    action: "creation_commercante",
    entite: "commercantes",
    entite_id: resultat.commercante_id,
    details: { telephone },
  });

  return json(201, {
    ...resultat,
    telephone,
    code_initial: code,
    lien_whatsapp: lienWhatsapp(telephone, messageCodeInitial(telephone, code)),
  });
});
