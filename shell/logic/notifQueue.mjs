// Pure toast queue for notifications. No Qt imports, no I/O, no timers.

export function emptyQueue() {
  return { current: null, waiting: [] };
}

// A new notification never interrupts the one showing; it waits, newest first.
// An update to a known id (`replaces-id`) refreshes it where it already is.
export function receive(queue, notif) {
  if (!queue.current || queue.current.id === notif.id) {
    return { current: notif, waiting: queue.waiting };
  }
  if (queue.waiting.some((n) => n.id === notif.id)) {
    return {
      current: queue.current,
      waiting: queue.waiting.map((n) => (n.id === notif.id ? notif : n)),
    };
  }
  return { current: queue.current, waiting: [notif].concat(queue.waiting) };
}

// The shown one ended (timeout or ✕): the newest waiting takes its place.
export function advance(queue) {
  return {
    current: queue.waiting.length > 0 ? queue.waiting[0] : null,
    waiting: queue.waiting.slice(1),
  };
}

// The app closed a notification: drop it wherever it is.
export function close(queue, id) {
  if (queue.current?.id === id) return advance(queue);
  return {
    current: queue.current,
    waiting: queue.waiting.filter((n) => n.id !== id),
  };
}

// The shown one timed out: a critical waits as a pin (the `!`), newest first,
// until it is dismissed; a normal one is simply dropped.
export function collapse(queue, pinned, critical) {
  return {
    queue: advance(queue),
    pinned: critical && queue.current ? [queue.current].concat(pinned) : pinned,
  };
}

// A click on the `!`: the newest pin shows again; a toast that was showing
// waits at the front so it is not lost.
export function reopen(queue, pinned) {
  if (pinned.length === 0) return { queue, pinned };
  const waiting = queue.current
    ? [queue.current].concat(queue.waiting)
    : queue.waiting;
  return { queue: { current: pinned[0], waiting }, pinned: pinned.slice(1) };
}

// A waiting critical was dismissed (✕, an action) or closed by its app.
export function unpin(pinned, id) {
  return pinned.filter((n) => n.id !== id);
}

// Whether the queue head differs from the toast the reducer shows. `null`
// means no toast: shell-made notifications use negative ids, so -1 is taken.
export function headChanged(shownId, current) {
  return (current ? current.id : null) !== shownId;
}
