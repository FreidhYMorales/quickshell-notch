import { test } from "node:test";
import assert from "node:assert/strict";
import { validateInstall } from "../shell/logic/webapp.mjs";

test("validateInstall: both fields are required", () => {
  assert.deepEqual(validateInstall("", "https://example.com"), {
    error: "nameMissing",
    name: "",
    url: "https://example.com",
  });
  assert.deepEqual(validateInstall("  Notch  ", "  "), {
    error: "urlMissing",
    name: "Notch",
    url: "",
  });
  assert.deepEqual(validateInstall("   ", "https://example.com"), {
    error: "nameMissing",
    name: "",
    url: "https://example.com",
  });
});

test("validateInstall: the name never carries a path", () => {
  // The helper builds the desktop file path from the name.
  for (const name of ["My/App", "My\\App", "../evil", ".hidden", "..", "."]) {
    assert.deepEqual(validateInstall(name, "https://example.com"), {
      error: "nameUnsafe",
      name,
      url: "https://example.com",
    });
  }
});

test("validateInstall: only http and https urls pass", () => {
  for (
    const url of [
      "ftp://example.com",
      "file:///etc/passwd",
      "javascript:alert(1)",
      "https://",
      "https:///path",
    ]
  ) {
    assert.deepEqual(validateInstall("Notch", url), {
      error: "urlInvalid",
      name: "Notch",
      url,
    });
  }
});

test("validateInstall: a bare host gets https and a full url is kept", () => {
  assert.deepEqual(validateInstall("Notch", "example.com"), {
    error: "",
    name: "Notch",
    url: "https://example.com",
  });
  assert.deepEqual(validateInstall("Notch Docs", "https://example.com/a?b=1"), {
    error: "",
    name: "Notch Docs",
    url: "https://example.com/a?b=1",
  });
  assert.deepEqual(validateInstall("Notch", "http://localhost:8080"), {
    error: "",
    name: "Notch",
    url: "http://localhost:8080",
  });
});
