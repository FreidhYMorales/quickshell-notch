import { test } from "node:test";
import assert from "node:assert/strict";
import { validateInstall } from "../shell/logic/webapp.mjs";

test("control characters in the name cannot inject desktop entry keys", () => {
  for (const name of ["Notch\nTerminal=true", "Notch\tX"]) {
    assert.deepEqual(validateInstall(name, "https://example.com"), {
      error: "nameUnsafe",
      name,
      url: "https://example.com",
    });
  }
});

test("URL whitespace cannot inject or split desktop entry arguments", () => {
  for (
    const url of [
      "https://example.com\nExec=/bin/sh -c id",
      "http://a b",
      "https://example.com\tx",
    ]
  ) {
    assert.deepEqual(validateInstall("Notch", url), {
      error: "urlInvalid",
      name: "Notch",
      url,
    });
  }
});
