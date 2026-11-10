#!/usr/bin/env node
// Visual simulation only: does not start greetd, PAM or a user session.
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { readPreviewSettings } from "./greetd-preview-settings.mjs";

const root = fileURLToPath(new URL("..", import.meta.url));
const qml = process.env.QML_RUNTIME || "/usr/lib/qt6/bin/qml";
if (!existsSync(qml)) {
  console.error("Qt 6 qml runtime is missing.");
  process.exit(1);
}

const state = process.env.XDG_STATE_HOME ||
  join(process.env.HOME, ".local/state");
const { background, theme } = readPreviewSettings(state);
const child = spawn(qml, [
  "-f",
  join(root, "greetd/preview/Main.qml"),
  "--",
  "notch-preview",
  background || "-",
  theme.accent,
  theme.foreground,
  String(theme.notchWidth),
], { stdio: "inherit" });

child.once("error", (error) => {
  console.error(`preview: ${error.message}`);
  process.exit(1);
});
child.once("exit", (code, signal) => {
  process.exit(code ?? (signal ? 1 : 0));
});
