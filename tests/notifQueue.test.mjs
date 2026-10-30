import { test } from "node:test";
import assert from "node:assert/strict";
import { emptyQueue, receive } from "../shell/logic/notifQueue.mjs";

const notif = (id, summary = `n${id}`) => ({ id, summary });

test("receive: into an empty queue it shows at once with nothing waiting", () => {
  const q = receive(emptyQueue(), notif(1));
  assert.deepEqual(q, { current: notif(1), waiting: [] });
});
