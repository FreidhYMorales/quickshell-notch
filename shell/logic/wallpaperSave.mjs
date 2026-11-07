// Pure write queue for the two-file wallpaper state format.
// A snapshot is immutable while it is being written; later edits are queued.
export function initialSaveQueue() {
  return { pending: null, active: null, phase: "idle", saved: false };
}

export function enqueueSave(queue, fallback, perScreen) {
  const snapshot = { fallback, perScreen: Object.assign({}, perScreen) };
  return Object.assign({}, queue, { pending: snapshot, saved: false });
}

export function startSave(queue) {
  if (queue.phase !== "idle" || !queue.pending) return queue;
  return { pending: null, active: queue.pending, phase: "mkdir", saved: false };
}

export function advanceSave(queue, phase) {
  if (!queue.active) return queue;
  const expected = { mkdir: "default", default: "screens", screens: "idle" };
  if (queue.phase !== phase || !expected[phase]) return queue;
  if (phase === "screens") {
    return {
      pending: queue.pending,
      active: null,
      phase: "idle",
      saved: queue.pending === null,
    };
  }
  return Object.assign({}, queue, { phase: expected[phase] });
}

export function failSave(queue) {
  if (!queue.active) return queue;
  // A newer edit takes priority; otherwise retain the failed snapshot.
  return {
    pending: queue.pending ?? queue.active,
    active: null,
    phase: "idle",
    saved: false,
  };
}
