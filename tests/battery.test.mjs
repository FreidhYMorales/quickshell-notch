import { test } from "node:test";
import assert from "node:assert/strict";
import {
  applyOverride,
  chargeStage,
  classify,
  criticalStep,
  edges,
  fromUPower,
  infoMilestone,
  parseSysfs,
} from "../shell/logic/battery.mjs";

const L = { low: 20, critical: 10 };
const C = { low: 20, high: 60 };
const bat = (x) =>
  Object.assign(
    {
      present: true,
      plugged: false,
      charging: false,
      full: false,
      percentage: 50,
    },
    x,
  );
const up = (state, fraction, onBattery) =>
  fromUPower({
    present: true,
    onBattery: onBattery !== false,
    state,
    fraction,
  });

// UPower reports the charge as a 0-1 fraction.
test("fromUPower rounds a 0-1 fraction to an integer percent", () => {
  assert.equal(up("discharging", 0.34).percentage, 34);
  assert.equal(up("discharging", 0.345).percentage, 35);
  assert.equal(up("discharging", 0.194).percentage, 19);
});

test("fromUPower clamps and tolerates bad fractions", () => {
  assert.deepEqual(
    [1.4, -0.2, NaN, undefined].map((f) => up("discharging", f).percentage),
    [100, 0, 0, 0],
  );
});

test("fromUPower derives plugged, charging and full", () => {
  assert.deepEqual(up("discharging", 0.5), bat({ percentage: 50 }));
  assert.deepEqual(
    up("charging", 0.5),
    bat({ plugged: true, charging: true }),
  );
  assert.deepEqual(
    up("full", 1),
    bat({ plugged: true, full: true, percentage: 100 }),
  );
  assert.equal(up("pending-charge", 0.9).plugged, true);
  assert.equal(up("unknown", 0.8, false).plugged, true);
  assert.equal(up("pending-discharge", 0.9).plugged, false);
  assert.equal(up("empty", 0).plugged, false);
});

test("fromUPower reports a missing battery", () => {
  const r = fromUPower({
    present: false,
    onBattery: false,
    state: "unknown",
    fraction: 0,
  });
  assert.equal(r.present, false);
  assert.equal(r.percentage, 0);
});

test("classify follows the spec table", () => {
  const rows = [
    [{ present: false, plugged: true, charging: true }, "none"],
    [{ plugged: true, charging: true, percentage: 72 }, "charging"],
    [{ plugged: true, full: true, percentage: 100 }, "full"],
    [{ percentage: 19 }, "low"],
    [{ percentage: 20 }, "none"],
    [{ percentage: 80 }, "none"],
    [{ plugged: true, charging: true, percentage: 5 }, "charging"],
    // Plugged but not charging (e.g. an 80% charge limit): show "plugged".
    [{ plugged: true, percentage: 80 }, "plugged"],
    [{ plugged: true, percentage: 10 }, "plugged"],
  ];
  assert.deepEqual(
    rows.map(([x]) => classify(bat(x), L)),
    rows.map(([, layer]) => layer),
  );
});

test("classify: plug replaces low, limits come from the caller", () => {
  assert.equal(classify(bat({ percentage: 18 }), L), "low");
  assert.equal(
    classify(bat({ plugged: true, charging: true, percentage: 18 }), L),
    "charging",
  );
  assert.equal(
    classify(bat({ percentage: 29 }), { low: 30, critical: 10 }),
    "low",
  );
});

test("chargeStage maps low, medium and high charge to stable bands", () => {
  assert.deepEqual([0, 19, 20, 59, 60, 80, 100].map((n) => chargeStage(n, C)), [
    "low",
    "low",
    "medium",
    "medium",
    "high",
    "high",
    "high",
  ]);
});

test("infoMilestone reports crossed bands in either direction", () => {
  assert.equal(
    infoMilestone(bat({ percentage: 19 }), bat({ percentage: 20 }), 80, C),
    20,
  );
  assert.equal(
    infoMilestone(bat({ percentage: 60 }), bat({ percentage: 59 }), 80, C),
    60,
  );
  assert.equal(
    infoMilestone(bat({ percentage: 59 }), bat({ percentage: 60 }), 80, C),
    60,
  );
  assert.equal(
    infoMilestone(bat({ percentage: 20 }), bat({ percentage: 21 }), 80, C),
    null,
  );
});

test("infoMilestone prefers the configured charge limit over a band crossing", () => {
  assert.equal(
    infoMilestone(
      bat({ plugged: true, charging: true, percentage: 79 }),
      bat({ plugged: true, percentage: 80 }),
      80,
      C,
    ),
    80,
  );
});

test("infoMilestone ignores missing batteries and absent charge limits", () => {
  assert.equal(
    infoMilestone(
      bat({ present: false, percentage: 19 }),
      bat({ present: false, percentage: 20 }),
      80,
      C,
    ),
    null,
  );
  assert.equal(
    infoMilestone(
      bat({ percentage: 79 }),
      bat({ plugged: true, percentage: 80 }),
      0,
      C,
    ),
    null,
  );
});

test("applyOverride keeps the input or replaces only given fields", () => {
  const input = bat({ percentage: 77 });
  assert.deepEqual(applyOverride(input, null), input);
  const out = applyOverride(input, { percentage: 18 });
  assert.deepEqual(out, bat({ percentage: 18 }));
  assert.equal(input.percentage, 77);
});

test("criticalStep fires once at <= critical", () => {
  let state = { armed: true };
  const fired = [11, 10, 9, 8].map((percentage) => {
    const r = criticalStep(state, bat({ percentage }), L);
    state = { armed: r.armed };
    return r.fire;
  });
  assert.deepEqual(fired, [false, true, false, false]);
  assert.equal(state.armed, false);
});

test("criticalStep re-arms on plug-in and fires again", () => {
  const plugged = criticalStep(
    { armed: false },
    bat({ plugged: true, percentage: 9 }),
    L,
  );
  assert.deepEqual(plugged, { fire: false, armed: true });
  assert.deepEqual(criticalStep(plugged, bat({ percentage: 10 }), L), {
    fire: true,
    armed: false,
  });
});

test("criticalStep never fires when plugged or without a battery", () => {
  assert.deepEqual(
    criticalStep({ armed: true }, bat({ plugged: true, percentage: 5 }), L),
    { fire: false, armed: true },
  );
  assert.deepEqual(
    criticalStep({ armed: true }, bat({ present: false, percentage: 3 }), L),
    { fire: false, armed: true },
  );
  assert.deepEqual(criticalStep({ armed: false }, bat({ percentage: 4 }), L), {
    fire: false,
    armed: false,
  });
});

test("edges detects plug, unplug and full transitions", () => {
  const none = { pluggedIn: false, unplugged: false, fullReached: false };
  assert.deepEqual(
    edges(bat(), bat({ plugged: true })),
    Object.assign({}, none, { pluggedIn: true }),
  );
  assert.deepEqual(
    edges(bat({ plugged: true }), bat()),
    Object.assign({}, none, { unplugged: true }),
  );
  assert.deepEqual(
    edges(
      bat({ plugged: true, charging: true }),
      bat({ plugged: true, full: true }),
    ),
    Object.assign({}, none, { fullReached: true }),
  );
  assert.deepEqual(edges(bat(), bat()), none);
});

// sysfs hands each attribute over as text, newline included.
const sysfs = (x) =>
  Object.assign(
    {
      cycles: "",
      energyNow: "",
      energyFull: "",
      energyFullDesign: "",
      endThreshold: "",
    },
    x,
  );

test("parseSysfs reads wear, capacity and the charge limit", () => {
  assert.deepEqual(
    parseSysfs(sysfs({
      cycles: "66\n",
      energyNow: "13840000\n",
      energyFull: "56370000\n",
      energyFullDesign: "57000000\n",
      endThreshold: "80\n",
    })),
    { health: 99, cycles: 66, energyNow: 13.8, energyFull: 56.4, limit: 80 },
  );
});

test("parseSysfs reads micro-Wh to one decimal", () => {
  const out = parseSysfs(
    sysfs({ energyNow: "56369999", energyFull: "57000000" }),
  );
  assert.equal(out.energyNow, 56.4);
  assert.equal(out.energyFull, 57);
});

test("parseSysfs turns missing or unreadable files into 0", () => {
  const zero = { health: 0, cycles: 0, energyNow: 0, energyFull: 0, limit: 0 };
  assert.deepEqual(parseSysfs(sysfs({})), zero);
  assert.deepEqual(
    parseSysfs(sysfs({
      cycles: "-3",
      energyNow: "NaN",
      energyFull: "0",
      energyFullDesign: "x",
      endThreshold: "x",
    })),
    zero,
  );
});
