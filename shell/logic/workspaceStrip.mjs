// Pure rules for the workspaces notch (no Quickshell imports).
// Win = { address, cls, workspaceId, monitor, focus, mapped, hidden,
//         floating, hasParent, width, height }

/** isNormalWindow(win, { minFloatWidth, minFloatHeight }) -> bool */
export function isNormalWindow(win, rules) {
  if (!win.mapped || win.hidden || !win.cls || win.hasParent) return false;
  if (!win.floating) return true;
  return win.width >= rules.minFloatWidth && win.height >= rules.minFloatHeight;
}

/** lastFocusedClass(windows, wsId) -> class of the lowest focus there | null */
export function lastFocusedClass(windows, wsId) {
  let best = null;
  for (const w of windows) {
    if (w.workspaceId !== wsId) continue;
    if (
      best === null || w.focus < best.focus ||
      (w.focus === best.focus && w.address < best.address)
    ) best = w;
  }
  return best === null ? null : best.cls;
}

function onMonitor(windows, monitor) {
  const out = [];
  for (const w of windows) if (w.monitor === monitor) out.push(w);
  return out;
}

/** slotRange({ activeId, windows, monitor, minSlots }) -> [1..max(min, active, highest occupied)] */
export function slotRange(args) {
  let last = Math.max(args.minSlots, args.activeId);
  for (const w of onMonitor(args.windows, args.monitor)) {
    if (w.workspaceId > last) last = w.workspaceId;
  }
  const ids = [];
  for (let id = 1; id <= last; id++) ids.push(id);
  return ids;
}

/** specialName("special:music") -> "music" */
export function specialName(wsName) {
  return wsName.indexOf("special:") === 0 ? wsName.slice(8) : wsName;
}

/** appInitial("org.gnome.Nautilus", "?") -> "N" */
export function appInitial(cls, fallback, fullTitle = false) {
  if (!cls) return fallback;
  const name = fullTitle ? cls : cls.slice(cls.lastIndexOf(".") + 1);
  return name ? name.charAt(0).toUpperCase() : fallback;
}

/**
 * stripFor({ activeId, windows, monitor, minSlots, special, flash })
 *   -> { pinned, special, items: [{ id, kind, cls }] }
 * windows are already filtered with isNormalWindow. A non-empty `special`
 * pins the strip and replaces the slots. `flash` = { workspaceId, cls } puts
 * the newly opened app on the active slot.
 */
export function stripFor(args) {
  if (args.special) {
    return { pinned: true, special: specialName(args.special), items: [] };
  }
  if (args.view === "tray") {
    return { pinned: false, special: "", items: args.trayItems };
  }
  const windows = onMonitor(args.windows, args.monitor);
  const items = [];
  for (const id of slotRange(args)) {
    if (id === args.activeId) {
      const flashed = args.flash && args.flash.workspaceId === id;
      items.push({
        id,
        kind: "active",
        cls: flashed ? args.flash.cls : lastFocusedClass(windows, id),
      });
      continue;
    }
    const cls = lastFocusedClass(windows, id);
    items.push(
      cls === null
        ? { id, kind: "empty", cls: null }
        : { id, kind: "app", cls },
    );
  }
  return { pinned: false, special: "", items };
}

function normalByAddress(windows, rules) {
  const map = {};
  for (const w of windows) if (isNormalWindow(w, rules)) map[w.address] = w;
  return map;
}

/**
 * diffSnapshots(prev, next, monitor, rules)
 *   -> [{ kind: "workspace"|"open"|"move", workspaceId, cls?, from? }]
 * snapshot = { monitors: { [name]: { activeId } }, windows: [Win] }.
 * Only normal windows count; closes are silent; no previous snapshot -> [].
 * A move is reported to every monitor it leaves or enters.
 */
export function diffSnapshots(prev, next, monitor, rules) {
  if (!prev) return [];
  const events = [];
  const before = prev.monitors[monitor];
  const after = next.monitors[monitor];
  if (before && after && before.activeId !== after.activeId) {
    events.push({ kind: "workspace", workspaceId: after.activeId });
  }
  const old = normalByAddress(prev.windows, rules);
  for (const w of next.windows) {
    if (!isNormalWindow(w, rules)) continue;
    const p = old[w.address];
    if (!p) {
      if (w.monitor === monitor) {
        events.push({ kind: "open", workspaceId: w.workspaceId, cls: w.cls });
      }
    } else if (
      (p.workspaceId !== w.workspaceId || p.monitor !== w.monitor) &&
      (p.monitor === monitor || w.monitor === monitor)
    ) {
      events.push({
        kind: "move",
        workspaceId: w.workspaceId,
        cls: w.cls,
        from: p.workspaceId,
      });
    }
  }
  return events;
}

// Unknown focus order sorts after every real one.
const UNKNOWN_FOCUS = 1e9;
const str = (v) => (typeof v === "string" ? v : "");
const int = (v, fallback) => (Number.isFinite(v) ? v : fallback);

/**
 * windowFrom(client, { monitor, hasParent }) -> Win | null
 * Maps one `hyprctl clients -j` object (untrusted shape) to a Win; null when
 * it carries no address.
 */
export function windowFrom(client, extra) {
  if (!client || typeof client.address !== "string" || !client.address) {
    return null;
  }
  const size = Array.isArray(client.size) ? client.size : [];
  return {
    address: client.address,
    cls: str(client.class),
    workspaceId: int(client.workspace && client.workspace.id, 0),
    monitor: extra.monitor,
    focus: int(client.focusHistoryID, UNKNOWN_FOCUS),
    mapped: client.mapped === true,
    hidden: client.hidden === true,
    floating: client.floating === true,
    hasParent: extra.hasParent === true,
    width: int(size[0], 0),
    height: int(size[1], 0),
  };
}

/** parseActiveSpecial("special:magic,eDP-1") -> { name, monitor } | null */
export function parseActiveSpecial(data) {
  if (typeof data !== "string") return null;
  const at = data.lastIndexOf(",");
  if (at < 0 || at === data.length - 1) return null;
  return { name: data.slice(0, at), monitor: data.slice(at + 1) };
}

const SNAPSHOT_EVENTS = [
  "workspace",
  "workspacev2",
  "focusedmon",
  "focusedmonv2",
  "openwindow",
  "closewindow",
  "movewindow",
  "movewindowv2",
  "moveworkspace",
  "moveworkspacev2",
];

/** refreshesSnapshot(rawEventName) -> true when it should schedule a snapshot */
export function refreshesSnapshot(name) {
  return SNAPSHOT_EVENTS.indexOf(name) >= 0;
}
