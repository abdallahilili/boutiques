// Lien WhatsApp pré-rempli (envoi manuel en V1 ; l'API WhatsApp Business viendra en V2).

export function lienWhatsapp(telephone: string, message: string): string {
  return `https://wa.me/${telephone}?text=${encodeURIComponent(message)}`;
}

/** Message d'accueil bilingue contenant l'identifiant et le code initial. */
export function messageCodeInitial(telephone: string, code: string): string {
  return [
    `مرحباً! تم إنشاء حسابك. المعرّف: ${telephone} — الرمز السري: ${code}`,
    `Bonjour ! Votre compte est créé. Identifiant : ${telephone} — Code : ${code}`,
  ].join("\n");
}
