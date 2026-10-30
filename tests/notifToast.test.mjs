import { test } from "node:test";
import assert from "node:assert/strict";
import {
  toastActions,
  toastIcon,
  toastIconInfo,
} from "../shell/logic/notifToast.mjs";

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

// Fake theme lookup: only "firefox" exists; a miss gives "".
const lookup = (name) => (name === "firefox" ? "/icons/firefox.svg" : "");

test("toastIcon: a known icon name resolves through the theme", () => {
  assert.equal(
    toastIcon({ image: "", appIcon: "firefox" }, lookup),
    "/icons/firefox.svg",
  );
  assert.equal(
    toastIcon({ image: "image://icon/firefox", appIcon: "" }, lookup),
    "/icons/firefox.svg",
  );
});

test("toastIcon: an unknown icon name gives nothing, never a broken image", () => {
  assert.equal(toastIcon({ image: "discord", appIcon: "discord" }, lookup), "");
  assert.equal(
    toastIcon({ image: "image://icon/discord", appIcon: "" }, lookup),
    "",
  );
});

test("toastIcon: a real image (path or URL) wins over the app icon", () => {
  const shot = { image: "/tmp/shot.png", appIcon: "firefox" };
  assert.equal(toastIcon(shot, lookup), "/tmp/shot.png");
  const data = { image: "image://qsimage/42", appIcon: "firefox" };
  assert.equal(toastIcon(data, lookup), "image://qsimage/42");
});

test("toastIcon: an unknown image falls back to a known app icon", () => {
  assert.equal(
    toastIcon({ image: "nope", appIcon: "firefox" }, lookup),
    "/icons/firefox.svg",
  );
});

test("toastIconInfo: theme icons are marked for tinting", () => {
  assert.deepEqual(
    toastIconInfo({ image: "", appIcon: "firefox" }, lookup),
    { source: "/icons/firefox.svg", themed: true },
  );
  assert.deepEqual(
    toastIconInfo({ image: "image://icon/firefox", appIcon: "" }, lookup),
    { source: "/icons/firefox.svg", themed: true },
  );
});

test("toastIconInfo: real pictures and the fallback are never tinted", () => {
  assert.deepEqual(
    toastIconInfo({ image: "/tmp/shot.png", appIcon: "firefox" }, lookup),
    { source: "/tmp/shot.png", themed: false },
  );
  assert.deepEqual(
    toastIconInfo({ image: "", appIcon: "discord" }, lookup),
    { source: "", themed: false },
  );
});
