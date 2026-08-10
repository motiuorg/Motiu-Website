import { test } from "node:test";
import assert from "node:assert/strict";
import { loadTokens, getPalettes, mixHex } from "../scripts/lib/brand-tokens.mjs";

test("tokens parse from the canonical theme CSS (v4 relock values)", () => {
  const t = loadTokens();
  assert.equal(t.terracotta, "#D12B00"); // BD-2026-066
  assert.equal(t["pillar-neural-3"], "#0055FF"); // v4 — NOT the stale 05-31 lock
  assert.equal(t["pillar-tissue-4"], "#2C5A0D");
  assert.equal(t.umber, "#221a12");
  assert.equal(t.paper, "#fffffd");
});

test("rule is resolved from the color-mix (SVG has no color-mix)", () => {
  const t = loadTokens();
  // 65% umber #221a12 + 35% paper #fffffd
  assert.equal(t.rule, mixHex("#221a12", "#fffffd", 0.65));
  assert.equal(t.rule, "#6f6a64");
});

test("palettes resolve against tokens and refuse the stale JSON", () => {
  const p = getPalettes();
  assert.equal(p["terracotta-on-paper"].stroke, "#D12B00");
  assert.equal(p["rule-on-paper"].bg, "#fffffd");
  assert.equal(p.neural.ramp.length, 4);
  assert.equal(p.neural.ramp[2], "#0055FF");
  assert.ok(
    !Object.values(p).some((x) => x.stroke === "#C92637"),
    "pre-relock red must not appear in any palette",
  );
});
