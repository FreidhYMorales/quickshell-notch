import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

test("empty tray leaves the corner hidden and click-through", () => {
  const path = (name) => fileURLToPath(new URL(name, import.meta.url));
  const result = spawnSync("dbus-run-session", [
    `--config-file=${path("./test-bus.conf")}`,
    "--",
    "qs",
    "-p",
    path("./tray-empty.qml"),
  ], {
    encoding: "utf8",
    timeout: 10000,
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
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(
    result.stdout + result.stderr,
    /empty tray: corner stays hidden and click-through/,
  );
});
