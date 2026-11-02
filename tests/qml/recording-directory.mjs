import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./run-tray.mjs";

test("recording creates its missing output directory before starting", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-recording-");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      "#!/usr/bin/python3\nimport signal,sys,time\nsignal.signal(signal.SIGINT, lambda *_: exit(0))\nif '-write-first-frame-ts' in sys.argv: open(sys.argv[sys.argv.index('-o') + 1] + '.ts', 'w').write('123 456\\n')\ntime.sleep(10)\n",
      { mode: 0o755 },
    );
    const destination = join(dir, "new", "recordings");
    const result = runTrayProbe("./recording-service.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: destination,
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.equal(statSync(destination).isDirectory(), true);
    assert.match(
      result.stdout + result.stderr,
      /recording service: started and stopped/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
