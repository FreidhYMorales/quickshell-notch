import { test } from "node:test";
import assert from "node:assert/strict";
import { rankApps } from "../shell/logic/launcherSearch.mjs";

const app = (id, name, genericName = "", keywords = []) => ({
  id,
  name,
  genericName,
  keywords,
});

test("rankApps: an empty query lists every app alphabetically, ignoring case", () => {
  const apps = [
    app("zed", "Zed"),
    app("firefox", "firefox"),
    app("blender", "Blender"),
    app("files", "Files"),
  ];
  assert.deepEqual(
    rankApps(apps, "").map((a) => a.id),
    ["blender", "files", "firefox", "zed"],
  );
});

test("rankApps: name prefix first, then word starts, then any in-order match", () => {
  const apps = [
    app("calc", "Calculator"),
    app("profile", "Profile Editor"),
    app("font", "Font Viewer"),
    app("firmware", "GNOME Firmware"),
    app("firefox", "Firefox"),
    app("files", "Files"),
  ];
  assert.deepEqual(
    rankApps(apps, "fi").map((a) => a.id),
    ["files", "firefox", "firmware", "font", "profile"],
  );
});

test("rankApps: ignores case; generic name and keywords match after any name match", () => {
  const apps = [
    app("firefox", "Firefox", "Web Browser"),
    app("files", "Files", "File Manager", ["folder"]),
    app("chromium", "Chromium", "", ["Internet", "WWW", "web"]),
    app("wireless", "Wireless Bench"),
    app("webcam", "webcam viewer"),
  ];
  assert.deepEqual(
    rankApps(apps, "WEB").map((a) => a.id),
    ["webcam", "wireless", "chromium", "firefox"],
  );
});
