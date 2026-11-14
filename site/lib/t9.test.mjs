import assert from "node:assert/strict";
import test from "node:test";
import { t9Match } from "./t9.ts";

test("t9Match finds a word start, not the middle of a word", () => {
  assert.deepEqual(t9Match("Emma Clarke", "3662"), [0, 4]);
  assert.deepEqual(t9Match("Emma Clarke", "25"), [5, 7]);
  assert.equal(t9Match("Emma Clarke", "62"), null);
  assert.equal(t9Match("Emma Clarke", ""), null);
  assert.equal(t9Match("Emma", "36621"), null);
});
