import { test } from "node:test";
import assert from "node:assert/strict";
import {
  fingerprintEnabled,
  serialiseSecurity,
} from "../shell/logic/lockSecurity.mjs";

const on = '{"fingerprintEnabled":true}';
const off = '{"fingerprintEnabled":false}';

test("the notch security state decides over the old shell's", () => {
  assert.equal(fingerprintEnabled(off, on), false);
  assert.equal(fingerprintEnabled(on, off), true);
});

test("without a notch state the old shell's state decides", () => {
  assert.equal(fingerprintEnabled(null, on), true);
  assert.equal(fingerprintEnabled("not json", on), true);
});

test("without any readable state the fingerprint stays off", () => {
  assert.equal(fingerprintEnabled(null, null), false);
  assert.equal(fingerprintEnabled("{}", "garbage"), false);
});

test("the saved switch keeps the old field name and reads back the same", () => {
  assert.equal(serialiseSecurity(false), off);
  assert.equal(serialiseSecurity(true), on);
  assert.equal(fingerprintEnabled(serialiseSecurity(false), on), false);
  assert.equal(fingerprintEnabled(serialiseSecurity(true), off), true);
});
