// Pure toast queue for notifications. No Qt imports, no I/O, no timers.

export function emptyQueue() {
  return { current: null, waiting: [] };
}

export function receive(queue, notif) {
  return { current: notif, waiting: queue.waiting };
}
