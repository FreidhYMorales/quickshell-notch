import { test } from "node:test";
import assert from "node:assert/strict";
import {
  appInitial,
  diffSnapshots,
  isNormalWindow,
  lastFocusedClass,
  parseActiveSpecial,
  refreshesSnapshot,
  slotRange,
  specialName,
  stripFor,
  windowFrom,
} from "../shell/logic/workspaceStrip.mjs";

const rules = { minFloatWidth: 300, minFloatHeight: 200 };
// win(address, cls, workspaceId, overrides) -> Win
const win = (address, cls, workspaceId, over) => {
  const w = {
    address,
    cls,
    workspaceId,
    monitor: "A",
    focus: 0,
    mapped: true,
    hidden: false,
    floating: false,
    hasParent: false,
    width: 800,
    height: 600,
  };
  for (const k of Object.keys(over || {})) w[k] = over[k];
  return w;
};

// Spec table: Window filtering.
for (
  const [name, over, expected, custom] of [
    ["tiled app", {}, true],
    ["big floating app", { floating: true }, true],
    [
      "floating at the minimum",
      { floating: true, width: 300, height: 200 },
      true,
    ],
    ["dialog with a parent", { hasParent: true }, false],
    ["small floating popup", { floating: true, width: 120, height: 40 }, false],
    ["floating too narrow", { floating: true, width: 299 }, false],
    ["floating too short", { floating: true, height: 199 }, false],
    ["small tiled window", { width: 100, height: 50 }, true],
    ["unmapped", { mapped: false }, false],
    ["hidden", { hidden: true }, false],
    ["no class", { cls: "" }, false],
    [
      "floating under custom rules",
      { floating: true, width: 150, height: 100 },
      true,
      { minFloatWidth: 100, minFloatHeight: 50 },
    ],
  ]
) {
  test(`isNormalWindow: ${name} -> ${expected}`, () => {
    assert.equal(
      isNormalWindow(win("0x1", "k", 1, over), custom || rules),
      expected,
    );
  });
}

test("lastFocusedClass: lowest focus, tie by address, null when empty", () => {
  const list = [
    win("0xb", "zeta", 3, { focus: 1 }),
    win("0xa", "alpha", 3, { focus: 1 }),
    win("0xc", "old", 3, { focus: 4 }),
    win("0xd", "foot", 4),
  ];
  assert.equal(lastFocusedClass(list, 3), "alpha");
  assert.equal(lastFocusedClass(list.slice().reverse(), 3), "alpha");
  assert.equal(lastFocusedClass(list, 4), "foot");
  assert.equal(lastFocusedClass(list, 9), null);
});

// Spec: Strip model, slot range per monitor.
for (
  const [name, active, ids, last] of [
    ["ids 2 and 4 -> 1-5", 2, [2, 4], 5],
    ["active 7 grows the range", 7, [], 7],
    ["occupied 9 grows the range", 2, [9], 9],
  ]
) {
  test(`slotRange: ${name}`, () => {
    const windows = ids.map((id) => win("0x" + id, "k", id));
    const got = slotRange({
      activeId: active,
      windows,
      monitor: "A",
      minSlots: 5,
    });
    assert.deepEqual(got, Array.from({ length: last }, (_, i) => i + 1));
  });
}

const strip = (over) => {
  const a = {
    activeId: 1,
    windows: [],
    monitor: "A",
    minSlots: 5,
    special: "",
  };
  for (const k of Object.keys(over || {})) a[k] = over[k];
  return stripFor(a);
};
const kinds = (s) => s.items.map((i) => i.kind);

// Spec table: symbol table (slotCount 5).
test("stripFor: empty strip, active 2", () => {
  const s = strip({ activeId: 2 });
  assert.deepEqual(kinds(s), ["empty", "active", "empty", "empty", "empty"]);
  assert.equal(s.pinned, false);
});

test("stripFor: occupied slot shows the last focused class", () => {
  const s = strip({
    windows: [
      win("0x1", "kitty", 3, { focus: 4 }),
      win("0x2", "ff", 3, { focus: 1 }),
    ],
  });
  assert.deepEqual(kinds(s), ["active", "empty", "app", "empty", "empty"]);
  assert.deepEqual(s.items[2], { id: 3, kind: "app", cls: "ff" });
});

test("stripFor: active wins over an occupying window", () => {
  const s = strip({ activeId: 4, windows: [win("0x1", "foot", 4)] });
  assert.deepEqual(kinds(s), ["empty", "empty", "empty", "active", "empty"]);
  assert.equal(s.items[3].cls, "foot");
});

test("stripFor: the active slot carries its last focused app", () => {
  const s = strip({
    activeId: 3,
    windows: [
      win("0x1", "kitty", 3, { focus: 4 }),
      win("0x2", "ff", 3, { focus: 1 }),
    ],
  });
  assert.deepEqual(s.items[2], { id: 3, kind: "active", cls: "ff" });
});

test("stripFor: a newly opened app wins over the active slot's app", () => {
  const s = strip({
    windows: [win("0x1", "foot", 1)],
    flash: { workspaceId: 1, cls: "kitty" },
  });
  assert.equal(s.items[0].cls, "kitty");
});

test("stripFor: an empty active slot carries no app", () => {
  const s = strip({ activeId: 2 });
  assert.deepEqual(s.items[1], { id: 2, kind: "active", cls: null });
});

test("stripFor: per-monitor isolation", () => {
  const onB = [win("0x1", "foot", 3, { monitor: "B" })];
  const a = strip({ windows: onB });
  const b = strip({ windows: onB, monitor: "B", activeId: 3 });
  assert.deepEqual(kinds(a), ["active", "empty", "empty", "empty", "empty"]);
  assert.deepEqual(kinds(b), ["empty", "empty", "active", "empty", "empty"]);
  assert.equal(strip({ activeId: 7 }).items.length, 7);
});

test("stripFor: flash only lands on the active slot's workspace", () => {
  const hit = strip({ flash: { workspaceId: 1, cls: "kitty" } });
  const miss = strip({ flash: { workspaceId: 3, cls: "kitty" } });
  assert.equal(hit.items[0].cls, "kitty");
  assert.equal(miss.items[0].cls, null);
});

// Spec: special pin.
test("stripFor: special pins the strip and drops the slots", () => {
  assert.deepEqual(strip({ special: "special:magic" }), {
    pinned: true,
    special: "magic",
    items: [],
  });
});

test("specialName and appInitial", () => {
  assert.equal(specialName("special:music"), "music");
  assert.equal(specialName("special:a:b"), "a:b");
  assert.equal(appInitial("unknownapp", "?"), "U");
  assert.equal(appInitial("org.gnome.Nautilus", "?"), "N");
  assert.equal(appInitial("", "?"), "?");
  assert.equal(appInitial(null, "?"), "?");
});

// Spec: reveal triggers (event table). Snapshots: monitor A active 1.
const snap = (active, windows, b) => {
  const monitors = { A: { activeId: active } };
  if (b) monitors.B = { activeId: b };
  return { monitors, windows };
};
const w1 = win("0x1", "kitty", 1);
const diff = (prev, next, mon) => diffSnapshots(prev, next, mon || "A", rules);
const popup = { floating: true, width: 100, height: 30 };

test("diffSnapshots: nothing without a previous or a change", () => {
  assert.deepEqual(diff(null, snap(1, [w1])), []);
  assert.deepEqual(diff(snap(1, [w1]), snap(1, [w1])), []);
  assert.deepEqual(diff(snap(1, [w1]), snap(1, [])), []); // close is silent
});

test("diffSnapshots: workspace change is per monitor", () => {
  assert.deepEqual(diff(snap(1, [w1]), snap(3, [w1])), [
    { kind: "workspace", workspaceId: 3 },
  ]);
  const [prev, next] = [snap(1, [], 4), snap(1, [], 5)];
  assert.deepEqual(diff(prev, next), []);
  assert.deepEqual(diff(prev, next, "B"), [{
    kind: "workspace",
    workspaceId: 5,
  }]);
});

test("diffSnapshots: open counts normal windows only", () => {
  const added = win("0x2", "firefox", 2);
  assert.deepEqual(diff(snap(1, [w1]), snap(1, [w1, added])), [
    { kind: "open", workspaceId: 2, cls: "firefox" },
  ]);
  const ignored = [
    win("0x3", "zenity", 1, { hasParent: true }),
    win("0x4", "menu", 1, popup),
    win("0x5", "far", 3, { monitor: "B" }),
  ];
  assert.deepEqual(diff(snap(1, [w1]), snap(1, [w1].concat(ignored), 3)), []);
});

test("diffSnapshots: moves, including to special", () => {
  for (const to of [4, -99]) {
    assert.deepEqual(diff(snap(1, [w1]), snap(1, [win("0x1", "kitty", to)])), [
      { kind: "move", workspaceId: to, cls: "kitty", from: 1 },
    ]);
  }
});

test("diffSnapshots: a cross-monitor move reaches both monitors", () => {
  const away = win("0x1", "kitty", 3, { monitor: "B" });
  const move = { kind: "move", workspaceId: 3, cls: "kitty", from: 1 };
  assert.deepEqual(diff(snap(1, [w1], 3), snap(1, [away], 3)), [move]);
  assert.deepEqual(diff(snap(1, [w1], 3), snap(1, [away], 3), "B"), [move]);
});

test("diffSnapshots: events come out in order", () => {
  const next = snap(3, [win("0x1", "kitty", 2), win("0x2", "foot", 3)]);
  assert.deepEqual(diff(snap(1, [w1]), next), [
    { kind: "workspace", workspaceId: 3 },
    { kind: "move", workspaceId: 2, cls: "kitty", from: 1 },
    { kind: "open", workspaceId: 3, cls: "foot" },
  ]);
});

// Hyprland IPC adapters.
const ipc = {
  address: "0x1",
  class: "kitty",
  workspace: { id: 3, name: "3" },
  floating: true,
  mapped: true,
  hidden: false,
  size: [640, 480],
  focusHistoryID: 2,
};

test("windowFrom: maps a client object to a Win", () => {
  assert.deepEqual(windowFrom(ipc, { monitor: "A", hasParent: true }), {
    address: "0x1",
    cls: "kitty",
    workspaceId: 3,
    monitor: "A",
    focus: 2,
    mapped: true,
    hidden: false,
    floating: true,
    hasParent: true,
    width: 640,
    height: 480,
  });
});

test("windowFrom: missing or garbage fields never throw", () => {
  assert.equal(windowFrom(null, { monitor: "A", hasParent: false }), null);
  assert.equal(windowFrom({}, { monitor: "A", hasParent: false }), null);
  const w = windowFrom({ address: "0x2" }, { monitor: "A", hasParent: false });
  assert.equal(w.cls, "");
  assert.equal(w.mapped, false);
  assert.equal(w.workspaceId, 0);
  assert.equal(w.width, 0);
  assert.equal(w.focus > 1000, true); // unknown focus sorts last
  const odd = windowFrom(
    { address: "0x3", class: 7, size: "big", workspace: { id: "x" } },
    { monitor: "A", hasParent: false },
  );
  assert.equal(odd.cls, "");
  assert.equal(odd.width, 0);
  assert.equal(odd.workspaceId, 0);
});

test("windowFrom: a special workspace id stays negative", () => {
  const w = windowFrom(
    Object.assign({}, ipc, { workspace: { id: -98, name: "special:m" } }),
    { monitor: "A", hasParent: false },
  );
  assert.equal(w.workspaceId, -98);
});

for (
  const [data, expected] of [
    ["special:magic,eDP-1", { name: "special:magic", monitor: "eDP-1" }],
    [",eDP-1", { name: "", monitor: "eDP-1" }],
    ["special:a,b,DP-2", { name: "special:a,b", monitor: "DP-2" }],
    ["nocomma", null],
    ["special:x,", null],
    ["", null],
    [undefined, null],
  ]
) {
  test(`parseActiveSpecial: ${JSON.stringify(data)}`, () => {
    assert.deepEqual(parseActiveSpecial(data), expected);
  });
}

for (
  const [name, expected] of [
    ["workspace", true],
    ["workspacev2", true],
    ["focusedmon", true],
    ["openwindow", true],
    ["closewindow", true],
    ["movewindowv2", true],
    ["moveworkspacev2", true],
    ["activespecial", false],
    ["activewindow", false],
    ["urgent", false],
    ["", false],
    [undefined, false],
  ]
) {
  test(`refreshesSnapshot: ${name}`, () => {
    assert.equal(refreshesSnapshot(name), expected);
  });
}
