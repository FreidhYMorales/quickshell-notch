import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const qml = readFileSync(
  new URL("../sddm/notch/Main.qml", import.meta.url),
  "utf8",
);

test("SDDM authenticates only after the exit morph finishes", () => {
  const submit = qml.slice(
    qml.indexOf("function submit()"),
    qml.indexOf("function previewExit()"),
  );
  assert.match(submit, /exitMorph\.restart\(\)/);
  assert.doesNotMatch(submit, /sddm\.login/);

  const morph = qml.slice(
    qml.indexOf("id: exitMorph"),
    qml.indexOf("Timer {", qml.indexOf("id: exitMorph")),
  );
  assert.match(morph, /onFinished:\s*\{[\s\S]*?sddm\.login\(/);
});

test("a failed or timed out login expands the greeter again", () => {
  assert.match(qml, /id:\s*authTimeout[\s\S]*?onTriggered:\s*root\.recover\(/);
  assert.match(
    qml,
    /function onLoginFailed\(\)\s*\{[\s\S]*?root\.recover\(/,
  );
  const recover = qml.slice(
    qml.indexOf("function recover"),
    qml.indexOf("function previewExit"),
  );
  assert.match(recover, /returnMorph\.restart\(\)/);
  assert.match(recover, /showLogin\(\)/);
});

test("test mode holds the notch frame and expands on its own", () => {
  assert.match(
    qml,
    /readonly property bool demoMode:\s*Qt\.application\.arguments\.indexOf\("--test-mode"\)/,
  );

  const morph = qml.slice(
    qml.indexOf("id: exitMorph"),
    qml.indexOf("NumberAnimation {", qml.indexOf("id: exitMorph")),
  );
  // Login must stay unreachable in test mode: there is no daemon to answer.
  const demoBranch = morph.indexOf("root.demoMode");
  assert.notEqual(demoBranch, -1);
  assert.ok(demoBranch < morph.indexOf("sddm.login("));
  assert.match(morph, /demoReturn\.restart\(\)/);

  assert.match(
    qml,
    /id:\s*demoReturn[\s\S]*?onTriggered:\s*root\.recover\(""\)/,
  );
});

test("the preview keybind expands with the same morph", () => {
  const reset = qml.slice(
    qml.indexOf("function resetPreview"),
    qml.indexOf("Timer {", qml.indexOf("function resetPreview")),
  );
  assert.match(reset, /returnMorph\.restart\(\)/);
  assert.doesNotMatch(reset, /reveal\s*=\s*1/);
});
