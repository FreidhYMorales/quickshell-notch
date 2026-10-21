import { test } from "node:test";
import assert from "node:assert/strict";
import { dspExpr } from "../shell/logic/hyprDsp.mjs";

test("valid name without args builds a bare call", () => {
  assert.equal(dspExpr("exit"), "hl.dsp.exit()");
  assert.equal(dspExpr("exit", []), "hl.dsp.exit()");
});

test("dotted names are accepted", () => {
  assert.equal(dspExpr("window.close"), "hl.dsp.window.close()");
});

test("string, number and boolean args are rendered as Lua literals", () => {
  assert.equal(
    dspExpr("exec_cmd", ["kitty", 3, true, -1.5]),
    'hl.dsp.exec_cmd("kitty", 3, true, -1.5)',
  );
});

test("table args render with validated keys", () => {
  assert.equal(
    dspExpr("focus", [{ workspace: 3, special: "scratch" }]),
    'hl.dsp.focus({workspace=3, special="scratch"})',
  );
});

test("invalid names return null", () => {
  for (
    const bad of [
      "",
      "Exit",
      "exit()",
      "exit; x",
      "a..b",
      ".a",
      "a.",
      "exit.x1",
      "exit ",
      undefined,
      null,
      5,
    ]
  ) {
    assert.equal(dspExpr(bad, []), null, `name ${JSON.stringify(bad)}`);
  }
});

test("injection in a name is rejected", () => {
  assert.equal(dspExpr('exit() --"); hl.dsp.exit() --', []), null);
});

test("injection in a string arg is escaped, not executed", () => {
  const out = dspExpr("exec_cmd", ['"); hl.dsp.exit() --']);
  assert.equal(out, 'hl.dsp.exec_cmd("\\"); hl.dsp.exit() --")');
});

test("backslashes, newlines and control chars are escaped", () => {
  assert.equal(dspExpr("x", ["a\\b"]), 'hl.dsp.x("a\\\\b")');
  assert.equal(dspExpr("x", ["a\nb\rc"]), 'hl.dsp.x("a\\nb\\rc")');
  assert.equal(dspExpr("x", ["a\u0000b"]), 'hl.dsp.x("a\\000b")');
  assert.equal(dspExpr("x", ["a\u0001b"]), 'hl.dsp.x("a\\001b")');
});

test("a control char followed by a digit cannot merge into the escape", () => {
  assert.equal(dspExpr("x", ["\u00001"]), 'hl.dsp.x("\\0001")');
});

test("injection through a table key is rejected", () => {
  assert.equal(dspExpr("focus", [{ "a=1}); hl.dsp.exit() --": 1 }]), null);
});

test("unsupported or invalid args return null", () => {
  assert.equal(dspExpr("x", [undefined]), null);
  assert.equal(dspExpr("x", [() => 1]), null);
  assert.equal(dspExpr("x", [NaN]), null);
  assert.equal(dspExpr("x", [Infinity]), null);
  assert.equal(dspExpr("x", [null]), null);
  assert.equal(dspExpr("x", "not-an-array"), null);
});

test("deeply nested tables are rejected", () => {
  assert.equal(dspExpr("x", [{ a: { b: { c: { d: { e: 1 } } } } }]), null);
});
