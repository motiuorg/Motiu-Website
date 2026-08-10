// tests/voronoi-core.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { computeCellPaths } from "../src/lib/voronoi-core.mjs";
import { HERO_VORONOI_DEFAULT } from "../public/lab-tools/hero-editor/hero-default-preset.mjs";

const VB = { w: 1600, h: 1100 };
const PAD = { x: 450, y: 450 };

test("preset transform matches the live module baseline", () => {
  assert.deepEqual(HERO_VORONOI_DEFAULT.transform, {
    scale: 1, stretchX: 0.93, stretchY: 1, rotation: 0, offsetX: 34, offsetY: 185,
  });
});

function numbersOf(d) {
  return (d.match(/-?\d+(\.\d+)?([eE][-+]?\d+)?/g) || []).map(Number);
}

test("computeCellPaths reproduces the baked hero fallback markup", () => {
  const astro = readFileSync(
    new URL("../src/components/HeroVoronoi.astro", import.meta.url), "utf8");
  const baked = [...astro.matchAll(/<path d="([^"]+)"/g)].map((m) => m[1]);
  assert.ok(baked.length === 10, `expected 10 baked paths, got ${baked.length}`);

  const paths = computeCellPaths({
    sites: HERO_VORONOI_DEFAULT.sites,
    transform: HERO_VORONOI_DEFAULT.transform,
    viewBox: VB,
    pad: PAD,
    cornerRadius: HERO_VORONOI_DEFAULT.cornerRadius,
  });
  assert.equal(paths.length, baked.length);
  for (let i = 0; i < paths.length; i++) {
    const got = numbersOf(paths[i]);
    const want = numbersOf(baked[i]);
    assert.equal(got.length, want.length, `path ${i}: coordinate count`);
    for (let j = 0; j < got.length; j++) {
      assert.ok(Math.abs(got[j] - want[j]) < 1e-6,
        `path ${i} coord ${j}: ${got[j]} vs ${want[j]}`);
    }
  }
});

test("no transform means identity", () => {
  const a = computeCellPaths({
    sites: HERO_VORONOI_DEFAULT.sites, transform: null,
    viewBox: VB, pad: PAD, cornerRadius: 25,
  });
  assert.equal(a.length, 10);
});
