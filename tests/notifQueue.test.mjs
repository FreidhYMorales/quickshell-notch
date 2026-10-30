import { test } from "node:test";
import assert from "node:assert/strict";
import {
  advance,
  close,
  collapse,
  emptyQueue,
  headChanged,
  receive,
  reopen,
  unpin,
} from "../shell/logic/notifQueue.mjs";

const notif = (id, summary = `n${id}`) => ({ id, summary });

test("receive: into an empty queue it shows at once with nothing waiting", () => {
  const q = receive(emptyQueue(), notif(1));
  assert.deepEqual(q, { current: notif(1), waiting: [] });
});

test("receive: a burst while one shows keeps it and queues newest first", () => {
  let q = receive(emptyQueue(), notif(1));
  for (const id of [2, 3, 4]) q = receive(q, notif(id));
  assert.deepEqual(q, {
    current: notif(1),
    waiting: [notif(4), notif(3), notif(2)],
  });
});

test("advance: ending the shown one brings the newest waiting", () => {
  let q = receive(emptyQueue(), notif(1));
  for (const id of [2, 3, 4]) q = receive(q, notif(id));
  assert.deepEqual(advance(q), {
    current: notif(4),
    waiting: [notif(3), notif(2)],
  });
});

test("advance: ending the last one leaves the queue empty", () => {
  const q = receive(emptyQueue(), notif(1));
  assert.deepEqual(advance(q), { current: null, waiting: [] });
});

test("receive: the same id as the shown one refreshes it in place", () => {
  let q = receive(emptyQueue(), notif(1));
  q = receive(q, notif(2));
  assert.deepEqual(receive(q, notif(1, "updated")), {
    current: notif(1, "updated"),
    waiting: [notif(2)],
  });
});

test("receive: the same id as a waiting one updates it where it waits", () => {
  let q = receive(emptyQueue(), notif(1));
  for (const id of [2, 3, 4]) q = receive(q, notif(id));
  assert.deepEqual(receive(q, notif(3, "updated")), {
    current: notif(1),
    waiting: [notif(4), notif(3, "updated"), notif(2)],
  });
});

test("close: the app closing the shown one brings the newest waiting", () => {
  let q = receive(emptyQueue(), notif(1));
  for (const id of [2, 3]) q = receive(q, notif(id));
  assert.deepEqual(close(q, 1), { current: notif(3), waiting: [notif(2)] });
});

test("close: the app closing a waiting one removes it", () => {
  let q = receive(emptyQueue(), notif(1));
  for (const id of [2, 3, 4]) q = receive(q, notif(id));
  assert.deepEqual(close(q, 3), {
    current: notif(1),
    waiting: [notif(4), notif(2)],
  });
});

test("collapse: a critical waits as a pin, newest first; a normal one is dropped", () => {
  const q = { current: notif(3), waiting: [notif(4)] };
  assert.deepEqual(collapse(q, [notif(1)], true), {
    queue: { current: notif(4), waiting: [] },
    pinned: [notif(3), notif(1)],
  });
  assert.deepEqual(collapse(q, [notif(1)], false), {
    queue: { current: notif(4), waiting: [] },
    pinned: [notif(1)],
  });
});

test("reopen: the newest pin shows again; a showing toast waits at the front", () => {
  const q = { current: notif(5), waiting: [notif(4)] };
  assert.deepEqual(reopen(q, [notif(3), notif(1)]), {
    queue: { current: notif(3), waiting: [notif(5), notif(4)] },
    pinned: [notif(1)],
  });
  assert.deepEqual(reopen(emptyQueue(), [notif(2)]), {
    queue: { current: notif(2), waiting: [] },
    pinned: [],
  });
  assert.deepEqual(reopen(q, []), { queue: q, pinned: [] });
});

test("unpin: a dismissed or closed critical leaves the pins, the rest stay", () => {
  const pinned = [notif(3), notif(2), notif(1)];
  assert.deepEqual(unpin(pinned, 2), [notif(3), notif(1)]);
  assert.deepEqual(unpin(pinned, 9), pinned);
  assert.deepEqual(unpin([notif(1)], 1), []);
});

test("headChanged: any id, negative ones included, differs from no toast", () => {
  assert.equal(headChanged(null, notif(-1)), true);
  assert.equal(headChanged(-1, notif(-1)), false);
  assert.equal(headChanged(3, null), true);
  assert.equal(headChanged(null, null), false);
});
