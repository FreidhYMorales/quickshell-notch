import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const theme = readFileSync(
  new URL("../sddm/notch/Main.qml", import.meta.url),
  "utf8",
);

test("SDDM embeds an initially hidden, explicitly toggled virtual keyboard", () => {
  assert.match(theme, /property bool keyboardRequested: false/);
  assert.match(theme, /InputPanel\s*\{/);
  assert.match(theme, /visible: root\.keyboardRequested && root\.loginVisible/);
  assert.match(theme, /ToolTip\.text: "Teclado virtual"/);
  assert.match(theme, /Qt\.inputMethod\.show\(\)/);
  assert.match(theme, /Qt\.inputMethod\.hide\(\)/);
});

test("keyboard color filter maps brightness to the synced palette", () => {
  const shader = readFileSync(
    new URL("../sddm/notch/shaders/keyboard.frag", import.meta.url),
    "utf8",
  );
  assert.match(shader, /mix\(darkColor\.rgb, lightColor\.rgb, luminance\)/);
  assert.match(theme, /fragmentShader: "shaders\/keyboard\.frag\.qsb"/);
  assert.match(theme, /property color lightColor: root\.foreground/);
  assert.match(
    theme,
    /property color darkColor: Qt\.darker\(root\.accent, 4\)/,
  );
});

test("keyboard filter rounds the panel edges", () => {
  const shader = readFileSync(
    new URL("../sddm/notch/shaders/keyboard.frag", import.meta.url),
    "utf8",
  );
  assert.match(shader, /uniform buf[\s\S]*vec2 panelSize/);
  assert.match(shader, /smoothstep/);
  assert.match(
    theme,
    /property size panelSize: Qt\.size\(virtualKeyboard\.width, virtualKeyboard\.height\)/,
  );
  assert.match(theme, /property real cornerRadius: 16/);
});
