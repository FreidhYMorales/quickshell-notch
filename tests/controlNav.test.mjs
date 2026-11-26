import { test } from "node:test";
import assert from "node:assert/strict";
import {
  back,
  closeOnLeave,
  commandView,
  initialView,
  openSubpage,
  panelHeight,
  toggleCommand,
} from "../shell/logic/controlNav.mjs";

test("initialView opens the control center at the root", () => {
  assert.equal(initialView(), "root");
});

test("openSubpage shows the notifications view and back returns to the root", () => {
  assert.equal(openSubpage(), "notifications");
  assert.equal(back(), "root");
});

test("closeOnLeave collapses at once on the root and waits on a subpage", () => {
  assert.equal(closeOnLeave("root"), "now");
  assert.equal(closeOnLeave("notifications"), "wait");
});

test("commandView maps the control center IPC commands and ignores unknown ones", () => {
  assert.equal(commandView("open"), "root");
  assert.equal(commandView("notifications"), "notifications");
  assert.equal(commandView("toggle"), null);
});

test("a control center command closes its active view or opens the requested one", () => {
  assert.deepEqual(toggleCommand(false, "root", "root"), {
    open: true,
    view: "root",
  });
  assert.deepEqual(toggleCommand(true, "root", "root"), {
    open: false,
    view: "root",
  });
  assert.deepEqual(toggleCommand(true, "root", "notifications"), {
    open: true,
    view: "notifications",
  });
  assert.deepEqual(toggleCommand(true, "notifications", "notifications"), {
    open: false,
    view: "notifications",
  });
});

test("panelHeight never shrinks below the root around a subpage", () => {
  assert.equal(panelHeight("root", 289, 228), 289);
  assert.equal(panelHeight("notifications", 289, 228), 289);
  assert.equal(panelHeight("notifications", 217, 228), 228);
});
