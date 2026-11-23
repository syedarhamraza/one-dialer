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

test("t9Match folds accents and reads Cyrillic", () => {
  assert.deepEqual(t9Match("José", "5673"), [0, 4]);
  assert.deepEqual(t9Match("Jürgen Müller", "685537"), [7, 13]);
  assert.deepEqual(t9Match("Şule", "7853"), [0, 4]);
  assert.deepEqual(t9Match("Иван Петров", "4225"), [0, 4]);
  assert.deepEqual(t9Match("Иван Петров", "536"), [5, 8]);
});
