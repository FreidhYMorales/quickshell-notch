import { test } from "node:test";
import assert from "node:assert/strict";
import { toastActions } from "../shell/logic/notifToast.mjs";

const action = (identifier, text) => ({ identifier, text });

test("toastActions: the default action goes to the body, the rest are buttons", () => {
  const actions = [
    action("default", "Open"),
    action("reply", "Reply"),
    action("later", "Later"),
  ];
  assert.deepEqual(toastActions(actions), {
    buttons: [action("reply", "Reply"), action("later", "Later")],
    bodyAction: action("default", "Open"),
  });
});

test("toastActions: no actions gives no buttons and no body action", () => {
  assert.deepEqual(toastActions([]), { buttons: [], bodyAction: null });
});
