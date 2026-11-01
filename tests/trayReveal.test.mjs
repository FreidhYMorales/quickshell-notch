import { test } from "node:test";
import assert from "node:assert/strict";
import {
  initialReveal,
  isVisible,
  stepReveal,
} from "../shell/logic/reveal.mjs";

test("hovering the corner reveals the tray only when it has apps", () => {
  const ready = stepReveal(initialReveal(), { type: "Ready" }).state;
  const populated = stepReveal(ready, { type: "TrayHover", count: 1 });
  const empty = stepReveal(ready, { type: "TrayHover", count: 0 });

  assert.equal(isVisible(populated.state), true);
  assert.equal(isVisible(empty.state), false);
});
