import { test } from "node:test";
import assert from "node:assert/strict";
import { enqueue, take } from "../shell/logic/requestQueue.mjs";

test("the queue keeps every request, in order, until a monitor is known", () => {
  const empty = [];
  let queue = enqueue(empty, { kind: "expanded" });
  queue = enqueue(queue, { kind: "controlcenter", view: "notifications" });
  queue = enqueue(queue, { kind: "expanded" });
  assert.deepEqual(empty, []);
  assert.deepEqual(take(queue, ""), { ready: [], rest: queue });
  assert.deepEqual(take(queue, "eDP-1"), {
    ready: [
      { kind: "expanded" },
      { kind: "controlcenter", view: "notifications" },
      { kind: "expanded" },
    ],
    rest: [],
  });
});
