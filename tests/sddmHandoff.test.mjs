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
  assert.match(
    qml,
    /id:\s*authTimeout[\s\S]*?onTriggered:\s*root\.authenticationDelayed\(\)/,
  );
  assert.match(
    qml,
    /function onLoginFailed\(\)\s*\{[\s\S]*?root\.failLogin\(/,
  );
  assert.match(
    qml,
    /function finishLoginFailure\(\)[\s\S]*?returnMorph\.restart\(\)/,
  );
});

test("timeout keeps the attempt pending and prevents retry until a result", () => {
  const delayed = qml.slice(
    qml.indexOf("function authenticationDelayed()"),
    qml.indexOf("function failLogin()"),
  );
  assert.match(delayed, /if\s*\(!authenticating\)/);
  assert.doesNotMatch(delayed, /authenticating\s*=\s*false/);
  assert.match(delayed, /Authentication still in progress/);
  assert.match(delayed, /password\.text\s*=\s*""/);
  assert.match(delayed, /returnMorph\.restart\(\)/);
  assert.match(qml, /id:\s*password[\s\S]*?enabled:\s*!root\.authenticating/);
  const submit = qml.slice(
    qml.indexOf("function submit()"),
    qml.indexOf("function authenticationDelayed()"),
  );
  assert.match(submit, /if\s*\(exiting\s*\|\|\s*authenticating/);
});

test("late success stops the return animation and returns to the notch frame", () => {
  const success = qml.slice(
    qml.indexOf("function onLoginSucceeded()"),
    qml.indexOf("id: authTimeout"),
  );
  assert.match(success, /returnMorph\.stop\(\)/);
  assert.match(success, /root\.reveal\s*=\s*0/);
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
    /id:\s*demoReturn[\s\S]*?onTriggered:\s*root\.failLogin\(\)/,
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

test("confirmed login failure clears the password before the lock feedback", () => {
  const failure = qml.slice(
    qml.indexOf("function failLogin()"),
    qml.indexOf("function previewExit()"),
  );
  assert.ok(failure.indexOf('password.text = ""') >= 0);
  assert.ok(
    failure.indexOf('password.text = ""') <
      failure.indexOf("failureShake.restart()"),
  );
  assert.match(failure, /passwordError\s*=\s*true/);
  assert.match(failure, /Incorrect password/);
  assert.match(qml, /function onLoginFailed\(\)\s*\{\s*root\.failLogin\(\)/);
  assert.match(
    qml,
    /id:\s*failureShake[\s\S]*?onFinished:\s*root\.finishLoginFailure\(\)/,
  );
});

test("password error clears when the field regains focus", () => {
  const field = qml.slice(
    qml.indexOf("id: password"),
    qml.indexOf("id: submitArrow"),
  );
  assert.match(
    field,
    /onActiveFocusChanged[\s\S]*?root\.passwordError\s*=\s*false/,
  );
  assert.match(qml, /border\.color:\s*root\.passwordError/);
});
