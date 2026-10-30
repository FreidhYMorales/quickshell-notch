// Pure toast queue for notifications. No Qt imports, no I/O, no timers.

export function emptyQueue() {
  return { current: null, waiting: [] };
}

// A new notification never interrupts the one showing; it waits, newest first.
export function receive(queue, notif) {
  if (!queue.current) return { current: notif, waiting: queue.waiting };
  return { current: queue.current, waiting: [notif].concat(queue.waiting) };
}

// The shown one ended (timeout or ✕): the newest waiting takes its place.
export function advance(queue) {
  return {
    current: queue.waiting.length > 0 ? queue.waiting[0] : null,
    waiting: queue.waiting.slice(1),
  };
}
