// Envoi push Firebase Cloud Messaging — STUB : la configuration Firebase sera faite plus tard.
// Tant que FCM_PROJECT_ID / FCM_SERVICE_ACCOUNT ne sont pas définis, rien n'est envoyé et le
// résultat l'indique ; les notifications in-app (table notifications) fonctionnent déjà.

export interface MessagePush {
  titre: string;
  corps: string;
  donnees?: Record<string, string>;
}

export interface ResultatPush {
  statut: "non_configure" | "envoye";
  envoyes: number;
}

export function fcmConfigure(): boolean {
  return Boolean(Deno.env.get("FCM_PROJECT_ID") && Deno.env.get("FCM_SERVICE_ACCOUNT"));
}

export function envoyerPush(jetons: string[], _message: MessagePush): Promise<ResultatPush> {
  if (!fcmConfigure() || jetons.length === 0) return Promise.resolve({ statut: "non_configure", envoyes: 0 });
  // TODO(firebase) : OAuth2 depuis FCM_SERVICE_ACCOUNT puis POST https://fcm.googleapis.com/v1/projects/{id}/messages:send
  return Promise.resolve({ statut: "non_configure", envoyes: 0 });
}
