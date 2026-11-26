// Shared setup for the sleep lock probes: fake gdbus and systemd-inhibit on
// the PATH, so no real logind inhibitor is taken.
import { spawnSync } from "node:child_process";
import { chmodSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const signal =
  "/org/freedesktop/login1: org.freedesktop.login1.Manager.PrepareForSleep";

// Fake gdbus: announces sleep at once, and resume once `resume` exists.
// Fake systemd-inhibit: logs start and stop of the inhibitor.
export function fakeTools(dir, failFirstMonitor = false) {
  const log = join(dir, "events.log");
  writeFileSync(
    join(dir, "gdbus"),
    `#!/bin/bash
echo "gdbus $*" >> "${log}"
if [[ "$*" == *"monitor"* ]] && [[ "${failFirstMonitor}" == "true" ]] && [[ ! -e "${dir}/monitor-failed" ]]; then
  touch "${dir}/monitor-failed"
  exit 1
fi
if [[ "$*" == *"PreparingForSleep" ]]; then
  echo "(<false>,)"
  exit 0
fi
echo "Monitoring signals on object /org/freedesktop/login1 owned by org.freedesktop.login1"
echo "${signal} (true,)"
while [[ ! -e "${dir}/resume" ]]; do sleep 0.1; done
echo "${signal} (false,)"
sleep 30
`,
  );
  writeFileSync(
    join(dir, "systemd-inhibit"),
    `#!/bin/bash
echo "inhibit start $*" >> "${log}"
trap 'echo "inhibit stop $*" >> "${log}"; exit 0' TERM INT
while true; do sleep 0.1; done
`,
  );
  chmodSync(join(dir, "gdbus"), 0o755);
  chmodSync(join(dir, "systemd-inhibit"), 0o755);
  return log;
}

export function runProbe(dir, smoke) {
  return spawnSync("qs", [
    "-p",
    fileURLToPath(new URL("./sleep-lock.qml", import.meta.url)),
  ], {
    encoding: "utf8",
    timeout: 20000,
    env: Object.assign({}, process.env, {
      PATH: dir + ":" + process.env.PATH,
      NOTCH_SLEEP_DIR: dir,
      NOTCH_SMOKE: smoke ? "1" : "0",
      QT_QPA_PLATFORM: "wayland",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
        .href,
    }),
  });
}
