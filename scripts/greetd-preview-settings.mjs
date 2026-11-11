// Read-only view of the staged SDDM palette and the saved wallpaper.
// Used by the visual preview only; it never reads credentials or auth config.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { previewTheme } from "../shell/logic/greetdVisual.mjs";

function read(path) {
  try {
    return readFileSync(path, "utf8");
  } catch (_error) {
    return "";
  }
}

function firstLine(text) {
  return String(text || "").split(/\r?\n/)[0].trim();
}

function fileUrl(path) {
  if (typeof path !== "string" || path[0] !== "/") return "";
  return "file://" +
    path.split("/").map((part, index) =>
      index === 0 ? "" : encodeURIComponent(part)
    )
      .join("/");
}

export function readPreviewSettings(stateHome) {
  const base = join(stateHome, "quickshell-notch");
  const target = firstLine(read(join(base, "sddm-target.txt")));
  const dataDir = target[0] === "/" ? target : join(base, "sddm");
  const theme = previewTheme(
    read(join(dataDir, "theme.conf")),
    read(join(dataDir, "theme.conf.user")),
  );
  const wallpaper = firstLine(read(join(base, "wallpaper.txt")));
  return { background: fileUrl(wallpaper), theme };
}
