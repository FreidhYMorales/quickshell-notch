import { test } from "node:test";
import assert from "node:assert/strict";
import { advance, emptyQueue, receive } from "../shell/logic/notifQueue.mjs";

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
