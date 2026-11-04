import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const authority = `
import os, pwd, subprocess, sys
import dbus, dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
DBusGMainLoop(set_as_default=True)
os.environ['DBUS_SYSTEM_BUS_ADDRESS'] = os.environ['DBUS_SESSION_BUS_ADDRESS']
bus = dbus.SessionBus()
name = dbus.service.BusName('org.freedesktop.PolicyKit1', bus)
class Authority(dbus.service.Object):
    @dbus.service.method('org.freedesktop.PolicyKit1.Authority', in_signature='(sa{sv})so', out_signature='', sender_keyword='sender')
    def RegisterAuthenticationAgent(self, subject, locale, path, sender):
        print('PRIVATE_AGENT_REGISTERED', flush=True)
        def request():
            agent = bus.get_object(sender, path, introspect=False)
            identities = [('unix-user', {'uid': dbus.UInt32(pwd.getpwnam('nobody').pw_uid, variant_level=1)})]
            agent.BeginAuthentication('test.action', 'Private test request', '', {}, 'private-cookie', identities,
                dbus_interface='org.freedesktop.PolicyKit1.AuthenticationAgent', signature='sssa{ss}sa(sa{sv})',
                reply_handler=lambda: print('UNEXPECTED_SUCCESS', flush=True),
                error_handler=lambda e: print('PRIVATE_CANCELLED', str(e), flush=True))
            print('PRIVATE_REQUEST_SENT', flush=True)
            def when_active():
                if not os.path.exists(os.environ['NOTCH_ACTIVE_MARKER']): return True
                agent.CancelAuthentication('private-cookie', dbus_interface='org.freedesktop.PolicyKit1.AuthenticationAgent',
                    reply_handler=lambda: print('PRIVATE_EXTERNAL_CANCEL', flush=True),
                    error_handler=lambda e: print('PRIVATE_CANCEL_ERROR', str(e), flush=True))
                return False
            GLib.timeout_add(50, when_active)
            return False
        def when_focused():
            if not os.path.exists(os.environ['NOTCH_FOCUS_MARKER']): return True
            request()
            return False
        GLib.timeout_add(50, when_focused)
    @dbus.service.method('org.freedesktop.PolicyKit1.Authority', in_signature='(sa{sv})o', out_signature='')
    def UnregisterAuthenticationAgent(self, subject, path):
        pass
obj = Authority(bus, '/org/freedesktop/PolicyKit1/Authority')
child = subprocess.Popen(['qs', '-p', sys.argv[1]])
loop = GLib.MainLoop()
GLib.timeout_add(10000, lambda: (loop.quit(), False)[1])
loop.run()
sys.exit(child.wait(timeout=10))
`;
const qml = `import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
ShellRoot {
    id: root
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    Component.onCompleted: console.log("STORE_READY", center.store.state.global.locked)
    Process { id: marker; command: ["touch", Quickshell.env("NOTCH_FOCUS_MARKER")] }
    Process { id: activeMarker; command: ["touch", Quickshell.env("NOTCH_ACTIVE_MARKER")] }
    Timer {
        id: focusCheck; interval: 50; running: true; repeat: true
        onTriggered: if (Hyprland.focusedMonitor?.name) {
            console.log("FOCUS_READY", Hyprland.focusedMonitor.name);
            marker.running = true;
            focusCheck.stop();
        }
    }
    Timer {
        id: activeCheck; interval: 50; running: true; repeat: true
        onTriggered: {
            const monitor = Hyprland.focusedMonitor?.name;
            if (monitor && center.store.viewFor(monitor).mode === "polkit") {
                console.log("ACTIVE_VIEW polkit");
                activeMarker.running = true;
                activeCheck.stop();
            }
        }
    }
    Timer {
        interval: 7000; running: true
        onTriggered: {
            const monitor = Hyprland.focusedMonitor?.name;
            if (!monitor) return Qt.exit(2);
            const view = center.store.viewFor(monitor);
            console.log("ENDED_VIEW", view.mode);
        }
    }
    Timer { interval: 9000; running: true; onTriggered: Qt.quit() }
}`;

test("an externally cancelled real flow closes the notch", () => {
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
        NOTCH_SMOKE: "0",
        QT_QPA_PLATFORM: "wayland",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_FOCUS_MARKER: join(dir, "focused"),
        NOTCH_ACTIVE_MARKER: join(dir, "active"),
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /STORE_READY false/);
    assert.match(output, /PRIVATE_AGENT_REGISTERED/);
    assert.match(output, /FOCUS_READY (?!undefined)\S+/);
    assert.match(output, /PRIVATE_REQUEST_SENT/);
    assert.match(output, /ACTIVE_VIEW polkit/);
    assert.match(output, /PRIVATE_EXTERNAL_CANCEL/);
    assert.match(output, /ENDED_VIEW idle/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
