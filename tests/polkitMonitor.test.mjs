import { test } from "node:test";
import assert from "node:assert/strict";
import { initialState, reduce } from "../shell/logic/centerState.mjs";

test("a polkit request without a valid monitor is cancelled", () => {
  const result = reduce(initialState(["A"]), {
    type: "PolkitRequest",
    flowId: "request-2",
    monitor: "missing",
  });
  assert.equal(result.state.global.polkit, null);
  assert.deepEqual(result.effects, [
    { type: "polkit.cancel", flowId: "request-2" },
  ]);
});
