import { assertEquals } from "jsr:@std/assert@1";
import { estTelephoneValide, normaliserTelephone } from "./telephone.ts";

Deno.test("normaliserTelephone ajoute l'indicatif aux numéros locaux", () => {
  assertEquals(normaliserTelephone("36 00 00 01", "222"), "22236000001");
});

Deno.test("normaliserTelephone gère +, 00 et espaces", () => {
  assertEquals(normaliserTelephone("+222 36 00 00 01", "222"), "22236000001");
  assertEquals(normaliserTelephone("00222-36000001", "222"), "22236000001");
});

Deno.test("estTelephoneValide", () => {
  assertEquals(estTelephoneValide("22236000001"), true);
  assertEquals(estTelephoneValide("123"), false);
  assertEquals(estTelephoneValide("abc"), false);
});
