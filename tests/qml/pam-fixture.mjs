// Shared setup for the lock auth probes: a throwaway PAM directory so the
// real PamContext conversation runs without the user's real password.
import { chmodSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

export const testPassword = "correct-horse";

// password: pam_exec accepts only `testPassword`.
// fingerprint: each entry is one scan, "ok" (pam_permit) or "fail" (pam_deny),
// consumed in order by a counter file.
export function pamDir(fingerprintScans = []) {
  const dir = mkdtempSync(join(tmpdir(), "notch-lock-pam-"));
  const check = join(dir, "check-password.sh");
  writeFileSync(
    check,
    `#!/bin/bash\nIFS= read -r -d '' pw\n[[ "$pw" == "${testPassword}" ]]\n`,
  );
  chmodSync(check, 0o755);
  writeFileSync(
    join(dir, "password"),
    `auth required pam_exec.so expose_authtok quiet ${check}\naccount required pam_permit.so\n`,
  );
  const scans = join(dir, "scans");
  writeFileSync(scans, fingerprintScans.join("\n") + "\n");
  const scan = join(dir, "scan.sh");
  writeFileSync(
    scan,
    `#!/bin/bash\nfirst=$(head -n1 "${scans}")\ntail -n +2 "${scans}" > "${scans}.next" && mv "${scans}.next" "${scans}"\n[[ "$first" == "ok" ]]\n`,
  );
  chmodSync(scan, 0o755);
  writeFileSync(
    join(dir, "fingerprint"),
    `auth required pam_exec.so quiet ${scan}\naccount required pam_permit.so\n`,
  );
  return dir;
}

export function runProbe(name, env) {
  return spawnSync("qs", [
    "-p",
    fileURLToPath(new URL(`./${name}.qml`, import.meta.url)),
  ], {
    encoding: "utf8",
    timeout: 15000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      NOTCH_LOCK_URL: new URL("../../shell/lock", import.meta.url).href,
      QT_QPA_PLATFORM: "wayland",
      QS_DISABLE_CRASH_HANDLER: "1",
      NO_COLOR: "1",
    }, env),
  });
}
