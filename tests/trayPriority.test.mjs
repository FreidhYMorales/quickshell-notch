import { test } from "node:test";
import assert from "node:assert/strict";
import {
  initialReveal,
  isVisible,
  stepReveal,
} from "../shell/logic/reveal.mjs";

test("workspace activity does not hide the hovered tray", () => {
  const ready = stepReveal(initialReveal(), { type: "Ready" }).state;
  const tray = stepReveal(ready, { type: "TrayHover", count: 1 }).state;
  const switched = stepReveal(tray, { type: "Trigger" }).state;
  const opened = stepReveal(tray, {
    type: "Trigger",
    flash: { workspaceId: 1, cls: "Steam" },
  }).state;

  assert.equal(
    isVisible(stepReveal(switched, { type: "Timeout" }).state),
    true,
  );
  assert.equal(isVisible(stepReveal(opened, { type: "Timeout" }).state), true);
});
