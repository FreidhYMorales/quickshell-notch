import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const authority = `
import os, subprocess, sys
import dbus, dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
DBusGMainLoop(set_as_default=True)
os.environ['DBUS_SYSTEM_BUS_ADDRESS'] = os.environ['DBUS_SESSION_BUS_ADDRESS']
bus = dbus.SessionBus()
name = dbus.service.BusName('org.freedesktop.PolicyKit1', bus)
class Authority(dbus.service.Object):
    @dbus.service.method('org.freedesktop.PolicyKit1.Authority', in_signature='(sa{sv})so', out_signature='')
    def RegisterAuthenticationAgent(self, subject, locale, path):
        print('PRIVATE_AGENT_REGISTERED', flush=True)
    @dbus.service.method('org.freedesktop.PolicyKit1.Authority', in_signature='(sa{sv})o', out_signature='')
    def UnregisterAuthenticationAgent(self, subject, path):
        pass
obj = Authority(bus, '/org/freedesktop/PolicyKit1/Authority')
child = subprocess.Popen(['qs', '-p', sys.argv[1]])
loop = GLib.MainLoop()
GLib.timeout_add(2000, lambda: (loop.quit(), False)[1])
loop.run()
sys.exit(child.wait(timeout=10))
`;
const qml = `import QtQuick
import Quickshell
ShellRoot {
    id: root
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    Component.onCompleted: console.log("STORE_READY", center.store.state.global.locked)
    Timer { interval: 1500; running: true; onTriggered: Qt.quit() }
}`;

test("smoke mode never registers the polkit agent", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-polkit-"));
  try {
    const probe = join(dir, "probe.qml");
    writeFileSync(probe, qml);
    const bus = fileURLToPath(new URL("./test-bus.conf", import.meta.url));
    const result = spawnSync("dbus-run-session", [
      `--config-file=${bus}`,
      "--",
      "python3",
      "-c",
      authority,
      probe,
    ], {
      encoding: "utf8",
      timeout: 15000,
      env: Object.assign({}, process.env, {
        NOTCH_SMOKE: "1",
        QT_QPA_PLATFORM: "offscreen",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /STORE_READY false/);
    assert.doesNotMatch(output, /PRIVATE_AGENT_REGISTERED/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
