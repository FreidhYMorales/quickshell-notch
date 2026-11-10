import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

test("SDDM session selector starts on the remembered session", () => {
  const qml = readFileSync(
    new URL("../sddm/notch/Main.qml", import.meta.url),
    "utf8",
  );
  assert.match(
    qml,
    /currentIndex:\s*sessionModel\.lastIndex\s*>=\s*0\s*\?\s*sessionModel\.lastIndex\s*:\s*0/,
  );
  assert.match(qml, /sddm\.login\([\s\S]*?sessions\.currentIndex\)/);
});
