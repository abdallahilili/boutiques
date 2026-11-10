import { assert, assertEquals } from "jsr:@std/assert@1";
import { base64url, corpsMessage, lireCompteService } from "./fcm.ts";
import { evaluerDns, normaliserDomaine } from "./dns.ts";
import { echapperCellule, versCsv } from "./csv.ts";
import { egalTempsConstant } from "./secret.ts";
import { texteLocalise } from "./push.ts";

Deno.test("base64url : sans remplissage ni caractères + /", () => {
  assertEquals(base64url("???>>>"), "Pz8_Pj4-");
  assertEquals(base64url(new Uint8Array([255, 254, 253])), "__79");
});

Deno.test("corpsMessage : données converties en chaînes, destinataire et notification", () => {
  const { message } = corpsMessage("jeton-1", { titre: "T", corps: "C", donnees: { n: 3 as unknown as string } });
  assertEquals(message.token, "jeton-1");
  assertEquals(message.notification, { title: "T", body: "C" });
  assertEquals(message.data, { n: "3" });
});

Deno.test("lireCompteService : JSON invalide ou incomplet refusé", () => {
  assertEquals(lireCompteService(undefined), null);
  assertEquals(lireCompteService("pas du json"), null);
  assertEquals(lireCompteService('{"client_email":"a@b.c"}'), null);
  assert(lireCompteService('{"client_email":"a@b.c","private_key":"k"}') !== null);
});

Deno.test("normaliserDomaine : retire schéma, chemin et point final", () => {
  assertEquals(normaliserDomaine(" HTTPS://Boutique.Exemple.com/page "), "boutique.exemple.com");
  assertEquals(normaliserDomaine("exemple.com."), "exemple.com");
});

Deno.test("evaluerDns : CNAME attendu, A accepté, sinon refus", () => {
  const cname = { Answer: [{ name: "b.exemple.com", type: 5, data: "cname.vercel-dns.com." }] };
  assertEquals(evaluerDns(cname, {}, { cname: "cname.vercel-dns.com" }), { ok: true, type: "CNAME", trouve: ["cname.vercel-dns.com"] });
  const a = { Answer: [{ name: "exemple.com", type: 1, data: "76.76.21.21" }] };
  assertEquals(evaluerDns({}, a, { cname: "cname.vercel-dns.com", a: ["76.76.21.21"] }).ok, true);
  const mauvais = { Answer: [{ name: "b.exemple.com", type: 5, data: "autre.hote.net." }] };
  const refus = evaluerDns(mauvais, {}, { cname: "cname.vercel-dns.com" });
  assertEquals(refus.ok, false);
  assertEquals(refus.trouve, ["autre.hote.net"]);
});

Deno.test("CSV : séparateur ;, guillemets doublés, BOM et protection contre les formules", () => {
  assertEquals(echapperCellule('a;b'), '"a;b"');
  assertEquals(echapperCellule('dit "oui"'), '"dit ""oui"""');
  assertEquals(echapperCellule("=SOMME(A1)"), "'=SOMME(A1)");
  assertEquals(echapperCellule(-5), "-5");
  assertEquals(echapperCellule(null), "");
  assertEquals(echapperCellule({ a: 1 }), '"{""a"":1}"');
  const csv = versCsv([{ nom: "Sac", prix: 10 }, { nom: "Foulard", prix: 5.5 }]);
  assert(csv.startsWith("﻿"));
  assertEquals(csv.slice(1), "nom;prix\r\nSac;10\r\nFoulard;5.5\r\n");
});

Deno.test("egalTempsConstant", () => {
  assertEquals(egalTempsConstant("secret-1234567890", "secret-1234567890"), true);
  assertEquals(egalTempsConstant("secret-1234567890", "secret-1234567891"), false);
  assertEquals(egalTempsConstant("court", "beaucoup-plus-long"), false);
});

Deno.test("texteLocalise : langue de l'utilisatrice avec repli", () => {
  assertEquals(texteLocalise("عربي", "Français", "ar"), "عربي");
  assertEquals(texteLocalise("عربي", "Français", "fr"), "Français");
  assertEquals(texteLocalise(null, "Français", "ar"), "Français");
  assertEquals(texteLocalise(null, null, "ar"), "");
});
