import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { previewTheme } from "../shell/logic/greetdVisual.mjs";
import { readPreviewSettings } from "../scripts/greetd-preview-settings.mjs";

test("uses the SDDM notch presets and synced palette", () => {
  const defaults =
    "[General]\nnormalNotchWidth=300\nchargingNotchWidth=420\nlowBatteryNotchWidth=420\n";
  const override =
    "[General]\nnotchMode=charging\naccent=#b3c5ff\nforeground=#e3e2e9\n";
  assert.deepEqual(previewTheme(defaults, override), {
    notchWidth: 420,
    accent: "#b3c5ff",
    foreground: "#e3e2e9",
  });
});

test("preview reads the staged palette and saved wallpaper", () => {
  const dir = mkdtempSync(join(tmpdir(), "greetd-settings-"));
  const state = join(dir, "state");
  const target = join(dir, "shared");
  mkdirSync(join(state, "quickshell-notch"), { recursive: true });
  mkdirSync(target);
  writeFileSync(join(state, "quickshell-notch", "sddm-target.txt"), target);
  writeFileSync(
    join(state, "quickshell-notch", "wallpaper.txt"),
    "/home/example/my wallpaper.gif",
  );
  writeFileSync(
    join(target, "theme.conf.user"),
    "[General]\naccent=#123456\nforeground=#abcdef\n",
  );
  const settings = readPreviewSettings(state);
  assert.equal(settings.background, "file:///home/example/my%20wallpaper.gif");
  assert.equal(settings.theme.accent, "#123456");
  assert.equal(settings.theme.foreground, "#abcdef");
});

test("the preview masks the morph with the shared concave notch geometry", () => {
  const source = readFileSync(
    new URL("../greetd/preview/Main.qml", import.meta.url),
    "utf8",
  );
  assert.match(source, /import .*earGeometry\.mjs.* as EarGeometry/);
  assert.match(source, /path:\s*EarGeometry\.notchPath\(/);
  assert.match(source, /maskSource:\s*morphMaskTexture/);
  assert.match(
    source,
    /root\.notchWidth\s*\+\s*\(root\.width\s*-\s*root\.notchWidth\)/,
  );
});

test("invalid values use safe defaults and do not parse other sections", () => {
  const settings =
    "[Other]\naccent=#ff0000\n[General]\nnormalNotchWidth=nope\naccent=bad\n";
  assert.deepEqual(previewTheme(settings, ""), {
    notchWidth: 300,
    accent: "#c6c6c6",
    foreground: "#e4e4e4",
  });
});
