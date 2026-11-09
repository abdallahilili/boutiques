import { assert, assertEquals, assertNotEquals } from "jsr:@std/assert@1";
import { cleTentative, emailTechnique, estCodePinValide, genererCodePin, secretAuth } from "./code_pin.ts";

Deno.test("genererCodePin produit toujours 4 chiffres", () => {
  for (let i = 0; i < 500; i++) assert(estCodePinValide(genererCodePin()));
});

Deno.test("estCodePinValide refuse les formats invalides", () => {
  for (const code of ["", "123", "12345", "12a4", " 123", "１２３４"]) assertEquals(estCodePinValide(code), false);
  assertEquals(estCodePinValide("0042"), true);
});

Deno.test("secretAuth est déterministe, dépend du code, de l'identité et du poivre", async () => {
  const poivre = "poivre-de-test-suffisamment-long";
  const a = await secretAuth("22236000001@tel.invalid", "1234", poivre);
  assertEquals(a, await secretAuth("22236000001@tel.invalid", "1234", poivre));
  assertEquals(a.length, 64);
  assertNotEquals(a, await secretAuth("22236000001@tel.invalid", "1235", poivre));
  assertNotEquals(a, await secretAuth("22236000002@tel.invalid", "1234", poivre));
  assertNotEquals(a, await secretAuth("22236000001@tel.invalid", "1234", poivre + "x"));
});

Deno.test("secretAuth refuse un poivre trop court", async () => {
  let erreur = false;
  try {
    await secretAuth("a@b", "1234", "court");
  } catch {
    erreur = true;
  }
  assert(erreur);
});

Deno.test("identités commerçante et cliente sont distinctes", () => {
  const commercante = { type: "commercante", telephone: "22236000001" } as const;
  const cliente = { type: "cliente", telephone: "22236000001", boutiqueId: "b1" } as const;
  assertNotEquals(emailTechnique(commercante, "tel.invalid"), emailTechnique(cliente, "tel.invalid"));
  assertNotEquals(cleTentative(commercante), cleTentative(cliente));
});
