// Tâche quotidienne : alertes de stock (ruptures, seuils bas, lots proches de l'expiration) et impayés
// échus. Une synthèse par boutique et par jour, sans doublon. Protégée par x-cron-secret (CRON_SECRET).
import { ErreurHttp, json, servir } from "../_shared/http.ts";
import { pousserNotifications } from "../_shared/push.ts";
import { exigerSecretPartage } from "../_shared/secret.ts";
import { clientService } from "../_shared/supabase.ts";

servir(async (req) => {
  exigerSecretPartage(req);
  const service = clientService();

  const { data: stock, error } = await service.rpc("generer_alertes_stock");
  if (error) throw new ErreurHttp(500, "alertes_stock_impossibles", error.message);
  const { data: impayes, error: erreurImpayes } = await service.rpc("generer_alertes_impayes");
  if (erreurImpayes) throw new ErreurHttp(500, "alertes_impayes_impossibles", erreurImpayes.message);

  const ids = [
    ...((stock as { notification_ids: string[] }).notification_ids ?? []),
    ...((impayes as { notification_ids: string[] }).notification_ids ?? []),
  ];
  const push = await pousserNotifications(service, ids);
  return json(200, {
    alertes_stock: (stock as { nombre: number }).nombre,
    alertes_impayes: (impayes as { nombre: number }).nombre,
    push: { statut: push.statut, envoyes: push.envoyes },
  });
});
