// Webhook de base de données (INSERT sur public.commandes) : envoie le push FCM de la nouvelle commande.
// Les notifications in-app sont déjà créées par le trigger SQL ; cette fonction ne fait que les pousser.
// Protégée par x-cron-secret = WEBHOOK_SECRET. Corps : payload du webhook Supabase ({ record: { id } })
// ou { commande_id }.
import { ErreurHttp, json, lireJson, servir } from "../_shared/http.ts";
import { pousserNotifications } from "../_shared/push.ts";
import { exigerSecretPartage } from "../_shared/secret.ts";
import { clientService } from "../_shared/supabase.ts";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

servir(async (req) => {
  exigerSecretPartage(req, "WEBHOOK_SECRET");
  const corps = await lireJson(req);
  const enregistrement = (corps.record ?? {}) as { id?: unknown };
  const commandeId = String(corps.commande_id ?? enregistrement.id ?? "");
  if (!UUID.test(commandeId)) throw new ErreurHttp(400, "donnees_invalides", "commande_id invalide");

  const service = clientService();
  const { data, error } = await service.from("notifications").select("id")
    .eq("type", "commande").eq("donnees->>commande_id", commandeId);
  if (error) throw new ErreurHttp(500, "lecture_notifications_impossible");
  const push = await pousserNotifications(service, (data ?? []).map((n) => n.id as string));
  return json(200, { notifications: (data ?? []).length, push: { statut: push.statut, envoyes: push.envoyes } });
});
