import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { previewTheme, visualSettings } from "../shell/logic/greetdVisual.mjs";
import { readPreviewSettings } from "../scripts/greetd-preview-settings.mjs";

test("real greeter settings use explicit wallpaper and validated shared theme", () => {
  assert.deepEqual(
    visualSettings(
      "[General]\naccent=#123456\nnormalNotchWidth=444\n",
      "/shared/my wall.png\n",
    ),
    {
      background: "file:///shared/my%20wall.png",
      accent: "#123456",
      foreground: "#e4e4e4",
      notchWidth: 444,
    },
  );
  assert.equal(visualSettings("", "relative.png").background, "");
  assert.equal(visualSettings("", "https://example.com/x").background, "");
});

test("real settings combine base and override using SDDM precedence", () => {
  const value = visualSettings(
    "[General]\nnotchMode=low\nlowBatteryNotchWidth=505\n",
    "",
    "[General]\nnormalNotchWidth=355\nlowBatteryNotchWidth=490\n",
  );
  assert.equal(value.notchWidth, 505);
});

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

test("preview merges the shipped SDDM presets with staged overrides", () => {
  const dir = mkdtempSync(join(tmpdir(), "greetd-presets-"));
  const target = join(dir, "quickshell-notch", "sddm");
  mkdirSync(target, { recursive: true });
  writeFileSync(
    join(target, "theme.conf"),
    "[General]\nnormalNotchWidth=355\nchargingNotchWidth=490\n",
  );
  writeFileSync(
    join(target, "theme.conf.user"),
    "[General]\nnotchMode=charging\n",
  );
  assert.equal(readPreviewSettings(dir).theme.notchWidth, 490);
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

test("greetd uses the same wallpaper dimming opacity as the SDDM theme", () => {
  const greeter = readFileSync(
    new URL("../greetd/preview/Main.qml", import.meta.url),
    "utf8",
  );
  const sddm = readFileSync(
    new URL("../sddm/notch/Main.qml", import.meta.url),
    "utf8",
  );
  assert.match(sddm, /color:\s*"#52000000"/i);
  assert.match(greeter, /color:\s*"#52000000"/i);
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
