// Tâche quotidienne (planificateur ou `curl`) : abonnements (rappels J-7/J-3/J-1, grâce 7 jours, suspension)
// et expiration des devis périmés. Protégée par l'en-tête x-cron-secret (variable CRON_SECRET).
// Les notifications sont créées en base par la fonction SQL traiter_abonnements ; ici : livraison push FCM.
import { ErreurHttp, json, servir } from "../_shared/http.ts";
import { pousserNotifications } from "../_shared/push.ts";
import { exigerSecretPartage } from "../_shared/secret.ts";
import { clientService } from "../_shared/supabase.ts";

servir(async (req) => {
  exigerSecretPartage(req);
  const service = clientService();

  const { data, error } = await service.rpc("traiter_abonnements");
  if (error) throw new ErreurHttp(500, "traitement_abonnements_impossible", error.message);
  const resultat = data as { grace: number; suspendus: number; rappels: number; notification_ids: string[] };

  const { data: devis, error: erreurDevis } = await service.rpc("expirer_devis_perimes");
  if (erreurDevis) throw new ErreurHttp(500, "expiration_devis_impossible", erreurDevis.message);

  const push = await pousserNotifications(service, resultat.notification_ids ?? []);
  return json(200, {
    grace: resultat.grace,
    suspendus: resultat.suspendus,
    rappels: resultat.rappels,
    devis_expires: devis as number,
    push: { statut: push.statut, envoyes: push.envoyes },
  });
});
