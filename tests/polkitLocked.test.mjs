import { test } from "node:test";
import assert from "node:assert/strict";
import { initialState, reduce } from "../shell/logic/centerState.mjs";

test("a polkit request arriving while locked is cancelled", () => {
  const locked =
    reduce(initialState(["A"]), { type: "Locked", on: true }).state;
  const result = reduce(locked, {
    type: "PolkitRequest",
    flowId: "request-1",
    monitor: "A",
  });
  assert.equal(result.state.global.polkit, null);
  assert.deepEqual(result.effects, [{
    type: "polkit.cancel",
    flowId: "request-1",
  }]);
});
