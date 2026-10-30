// Pure toast queue for notifications. No Qt imports, no I/O, no timers.

export function emptyQueue() {
  return { current: null, waiting: [] };
}

// A new notification never interrupts the one showing; it waits, newest first.
export function receive(queue, notif) {
  if (!queue.current) return { current: notif, waiting: queue.waiting };
  return { current: queue.current, waiting: [notif].concat(queue.waiting) };
}
