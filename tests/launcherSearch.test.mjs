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
