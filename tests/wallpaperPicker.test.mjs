import { test   beginPreview,
  cancelPreview,
  catalogEntries,
  commitPreview,
  movePreview,
} from "node:test";
import assert from "node:assert/strict";
import {
  catalogEntries,
  beginPreview,
  movePreview,
  cancelPreview,
  commitPreview,
} from "../shell/logic/wallpaperPicker.mjs";

test("catalog keeps supported image and video paths in stable name order", () => {
  assert.deepEqual(
    catalogEntries(["/w/z.mp4", "/w/a.PNG", "/w/no.txt", "/w/b.webp"]),
    [
      { path: "/w/a.PNG", name: "a.PNG", video: false },
      { path: "/w/b.webp", name: "b.webp", video: false },
      { path: "/w/z.mp4", name: "z.mp4", video: true },
    ],
  );
});

test("empty catalog cannot produce a preview or commit", () => {
  const session = beginPreview([], "/w/old.png");
  assert.equal(session.index, -1);
  assert.equal(commitPreview(session), null);
  assert.equal(cancelPreview(session), "/w/old.png");
});

test("opening selects the current wallpaper without modifying it", () => {
  const entries = catalogEntries(["/w/a.png", "/w/b.png"]);
  const session = beginPreview(entries, "/w/b.png");
  assert.equal(session.index, 1);
  assert.equal(session.preview, "/w/b.png");
  assert.equal(session.original, "/w/b.png");
});

test("navigation wraps and changes preview only", () => {
  const entries = catalogEntries(["/w/a.png", "/w/b.png"]);
  const start = beginPreview(entries, "/w/a.png");
  const previous = movePreview(start, -1);
  assert.equal(previous.preview, "/w/b.png");
  assert.equal(previous.original, "/w/a.png");
  assert.equal(start.preview, "/w/a.png");
  assert.equal(movePreview(previous, 1).preview, "/w/a.png");
});

test("cancel restores original and commit returns selected path", () => {
  const entries = catalogEntries(["/w/a.png", "/w/b.png"]);
  const session = movePreview(beginPreview(entries, "/w/a.png"), 1);
  assert.equal(cancelPreview(session), "/w/a.png");
  assert.equal(commitPreview(session), "/w/b.png");
});

test("missing current wallpaper starts at first available entry", () => {
  const session = beginPreview(
    catalogEntries(["/w/b.png", "/w/a.png"]),
    "/w/old.png",
  );
  assert.equal(session.preview, "/w/a.png");
  assert.equal(cancelPreview(session), "/w/old.png");
});
