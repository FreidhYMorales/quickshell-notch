import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const path = (name) => fileURLToPath(new URL(name, import.meta.url));
const script = `
python3 "$1" &
fixture=$!
trap 'kill "$fixture" 2>/dev/null; wait "$fixture" 2>/dev/null' EXIT
qs -p "$2"
`;

export function runTrayProbe(probe) {
  return spawnSync("dbus-run-session", [
    `--config-file=${path("./test-bus.conf")}`,
    "--",
    "sh",
    "-c",
    script,
    "tray-surface",
    path("./fake_tray_item.py"),
    path(probe),
  ], {
    encoding: "utf8",
    timeout: 15000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      QT_QPA_PLATFORM: "wayland",
      NO_COLOR: "1",
      NOTCH_TEST_SURFACE: new URL(
        "../../shell/notches/workspaces/WorkspacesSurface.qml",
        import.meta.url,
      ).href,
    }),
  });
}
