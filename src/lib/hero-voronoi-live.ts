// hero-voronoi-live.ts — client-side companion to HeroVoronoi.astro.
//
// The astro component renders a frozen, baked Voronoi diagram for first
// paint (no JS required). This module re-generates it live once mounted so
// four content regions — the logo, the nav links, the hero copy, and the
// approach copy — are always fully inside a single cell, with no cell edge
// crossing them. Everything else in the diagram is free to move.
//
// Ported from the prototype validated in the org-os repo's hero-editor lab
// (projects/branding/preview/hero-editor/hero-editor.mjs, 2026-08-07
// containment session) — flat cells only, no nested subcells yet. Baseline
// geometry (sites/transform/corner radius) matches hero-default-preset.mjs
// there, which is also what the static fallback markup below is baked from.
import { Delaunay } from "d3";

type Point = [number, number];

const VB = { w: 1600, h: 1100 };
const CENTER: Point = [VB.w / 2, VB.h / 2];
/** Extend past the viewBox so clip edges sit off-screen. */
const VORONOI_PAD = { x: 450, y: 450 };
const CORNER_RADIUS = 25;
const STROKE_WIDTH = 4;
const TRANSFORM = {
  scale: 1,
  stretchX: 0.93,
  stretchY: 1,
  rotation: 0,
  offsetX: 34,
  offsetY: 185,
};
const BASE_SITES: Point[] = [
  [1095.4, -166.34],
  [142.58, -96.53],
  [1404.28, 555.1],
  [164.56, 319.34],
  [637.18, -302.36],
  [1297.51, -204.79],
  [420.05, 744.84],
  [1502.45, 551.27],
  [774.88, 89.72],
  [1577.6, 922.52],
];

function transformPoint([x, y]: Point): Point {
  const dx = (x - CENTER[0]) * TRANSFORM.scale * TRANSFORM.stretchX;
  const dy = (y - CENTER[1]) * TRANSFORM.scale * TRANSFORM.stretchY;
  const rad = (TRANSFORM.rotation * Math.PI) / 180;
  const cos = Math.cos(rad);
  const sin = Math.sin(rad);
  return [
    CENTER[0] + dx * cos - dy * sin + TRANSFORM.offsetX,
    CENTER[1] + dx * sin + dy * cos + TRANSFORM.offsetY,
  ];
}

function getEffectiveSites(): Point[] {
  return BASE_SITES.map(transformPoint);
}

function getParentVoronoiBounds(): [number, number, number, number] {
  return [
    -VORONOI_PAD.x,
    -VORONOI_PAD.y,
    VB.w + VORONOI_PAD.x,
    VB.h + VORONOI_PAD.y,
  ];
}

function polygonBBox(points: Point[]) {
  let minX = Infinity;
  let minY = Infinity;
  let maxX = -Infinity;
  let maxY = -Infinity;
  for (const [x, y] of points) {
    minX = Math.min(minX, x);
    maxX = Math.max(maxX, x);
    minY = Math.min(minY, y);
    maxY = Math.max(maxY, y);
  }
  return { minX, minY, maxX, maxY, w: maxX - minX, h: maxY - minY };
}

function roundPolygonPath(points: Point[], radius: number): string {
  const n = points.length;
  if (n < 3 || radius <= 0) {
    return "M" + points.map((p) => p[0] + "," + p[1]).join(" L") + " Z";
  }
  let d = "";
  for (let i = 0; i < n; i++) {
    const prev = points[(i - 1 + n) % n];
    const curr = points[i];
    const next = points[(i + 1) % n];
    const v1x = curr[0] - prev[0];
    const v1y = curr[1] - prev[1];
    const v2x = next[0] - curr[0];
    const v2y = next[1] - curr[1];
    const len1 = Math.hypot(v1x, v1y) || 1;
    const len2 = Math.hypot(v2x, v2y) || 1;
    const r = Math.min(radius, len1 * 0.45, len2 * 0.45);
    const p1x = curr[0] - (v1x / len1) * r;
    const p1y = curr[1] - (v1y / len1) * r;
    const p2x = curr[0] + (v2x / len2) * r;
    const p2y = curr[1] + (v2y / len2) * r;
    d += (i === 0 ? "M" : " L") + p1x + "," + p1y;
    d += " Q" + curr[0] + "," + curr[1] + " " + p2x + "," + p2y;
  }
  return d + " Z";
}

// --- Content protection ----------------------------------------------------

interface ProtectedRegionDef {
  id: string;
  selectors: string[];
}

interface ProtectedRegion {
  id: string;
  corners: Point[];
  center: Point;
}

// Selectors point at the actual content, not layout wrappers — a plain
// block element (e.g. a <p> with no max-width of its own) can report a
// getBoundingClientRect() far wider than the text it renders, and
// #approach's own box spans a wide container regardless of how narrow the
// copy inside it is. measureInkRect() below sidesteps that by measuring
// rendered text extent instead of layout boxes.
const PROTECTED_REGIONS_DEF: ProtectedRegionDef[] = [
  { id: "logo", selectors: [".site-nav .brand"] },
  { id: "nav", selectors: [".site-nav nav ul"] },
  { id: "hero", selectors: [".hero__inner"] },
  { id: "approach", selectors: ["#approach"] },
];

/** Walking to individual text nodes (rather than ranging over a container
 * that may itself hold block-level children) avoids a Blink quirk where
 * Range.getClientRects() can throw in one phantom full-width rect for a
 * child's own block box alongside its real line-box rects. */
function collectInkRects(el: Element): DOMRect[] {
  const rects: DOMRect[] = [];
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, {
    acceptNode: (node) =>
      /\S/.test(node.nodeValue || "")
        ? NodeFilter.FILTER_ACCEPT
        : NodeFilter.FILTER_REJECT,
  });
  let node: Node | null;
  // eslint-disable-next-line no-cond-assign
  while ((node = walker.nextNode())) {
    const range = document.createRange();
    range.selectNodeContents(node);
    rects.push(...Array.from(range.getClientRects()));
  }
  return rects;
}

function measureInkRect(el: Element): DOMRect {
  const rects = collectInkRects(el);
  let minX = Infinity;
  let minY = Infinity;
  let maxX = -Infinity;
  let maxY = -Infinity;
  for (const r of rects) {
    if (!r.width || !r.height) continue;
    minX = Math.min(minX, r.left);
    minY = Math.min(minY, r.top);
    maxX = Math.max(maxX, r.right);
    maxY = Math.max(maxY, r.bottom);
  }
  if (minX === Infinity) return el.getBoundingClientRect();
  return new DOMRect(minX, minY, maxX - minX, maxY - minY);
}

function clientToSvg(
  svg: SVGSVGElement,
  clientX: number,
  clientY: number,
): Point {
  const pt = svg.createSVGPoint();
  pt.x = clientX;
  pt.y = clientY;
  const ctm = svg.getScreenCTM();
  if (!ctm) return [0, 0];
  const local = pt.matrixTransform(ctm.inverse());
  return [local.x, local.y];
}

function rectCorners(r: DOMRect): Point[] {
  return [
    [r.left, r.top],
    [r.right, r.top],
    [r.right, r.bottom],
    [r.left, r.bottom],
  ];
}

function measureProtectedRegions(svg: SVGSVGElement): ProtectedRegion[] {
  const regions: ProtectedRegion[] = [];
  for (const def of PROTECTED_REGIONS_DEF) {
    let corners: Point[] = [];
    for (const selector of def.selectors) {
      const el = document.querySelector(selector);
      if (!el) continue;
      const rect = measureInkRect(el);
      if (!rect.width || !rect.height) continue;
      corners = corners.concat(
        rectCorners(rect).map((p) => clientToSvg(svg, p[0], p[1])),
      );
    }
    if (!corners.length) continue;
    const box = polygonBBox(corners);
    regions.push({
      id: def.id,
      corners,
      center: [box.minX + box.w / 2, box.minY + box.h / 2],
    });
  }
  return regions;
}

/** Negative = `corner` is on `anchor`'s side of the anchor/other bisector. */
function bisectorSideScore(corner: Point, anchor: Point, other: Point): number {
  const mx = (anchor[0] + other[0]) / 2;
  const my = (anchor[1] + other[1]) / 2;
  const nx = other[0] - anchor[0];
  const ny = other[1] - anchor[1];
  return (corner[0] - mx) * nx + (corner[1] - my) * ny;
}

function regionClearsSite(
  region: ProtectedRegion,
  anchor: Point,
  other: Point,
  margin: number,
): boolean {
  for (const corner of region.corners) {
    if (bisectorSideScore(corner, anchor, other) > -margin) return false;
  }
  return true;
}

/**
 * Returns a clone of `sites` with one site per region snapped to that
 * region's centroid, and every non-anchor site pushed clear of any bisector
 * that would otherwise cut into a protected rect. Never moves an anchor —
 * two protected regions whose fixed centroids can't be separated by a
 * straight bisector just stay imperfect rather than being silently "fixed."
 */
function applyContentProtection(
  sites: Point[],
  regions: ProtectedRegion[],
): Point[] {
  const result: Point[] = sites.map((p) => [p[0], p[1]]);
  const margin = 8;
  const claimed = new Set<number>();
  const anchors: { siteIndex: number; region: ProtectedRegion }[] = [];

  for (const region of regions) {
    let best = -1;
    let bestDist = Infinity;
    for (let i = 0; i < result.length; i++) {
      if (claimed.has(i)) continue;
      const dx = result[i][0] - region.center[0];
      const dy = result[i][1] - region.center[1];
      const d = dx * dx + dy * dy;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    if (best < 0) continue;
    claimed.add(best);
    result[best] = [region.center[0], region.center[1]];
    anchors.push({ siteIndex: best, region });
  }

  const anchorIndexSet = new Set(anchors.map((a) => a.siteIndex));
  const maxIter = 60;
  for (let iter = 0; iter < maxIter; iter++) {
    let moved = false;
    for (const { siteIndex: anchorIdx, region } of anchors) {
      const anchor = result[anchorIdx];
      for (let si = 0; si < result.length; si++) {
        if (si === anchorIdx || anchorIndexSet.has(si)) continue;
        const other = result[si];
        if (regionClearsSite(region, anchor, other, margin)) continue;
        const dx = other[0] - region.center[0];
        const dy = other[1] - region.center[1];
        const len = Math.hypot(dx, dy) || 1;
        result[si] = [other[0] + (dx / len) * 16, other[1] + (dy / len) * 16];
        moved = true;
      }
    }
    if (!moved) break;
  }

  return result;
}

// --- Render ------------------------------------------------------------

const SVG_NS = "http://www.w3.org/2000/svg";

export function initHeroVoronoiLive(): void {
  const svg = document.querySelector<SVGSVGElement>("[data-hero-voronoi-svg]");
  const cellsEl = document.querySelector<SVGGElement>(
    "[data-hero-voronoi-cells]",
  );
  if (!svg || !cellsEl) return;

  function render() {
    const effectiveSites = getEffectiveSites();
    const regions = measureProtectedRegions(svg!);
    const renderSites = regions.length
      ? applyContentProtection(effectiveSites, regions)
      : effectiveSites;

    const delaunay = Delaunay.from(renderSites);
    const voronoi = delaunay.voronoi(getParentVoronoiBounds());
    const frag = document.createDocumentFragment();
    for (let i = 0; i < renderSites.length; i++) {
      const poly = voronoi.cellPolygon(i) as Point[] | null;
      if (!poly) continue;
      const pathEl = document.createElementNS(SVG_NS, "path");
      pathEl.setAttribute("d", roundPolygonPath(poly, CORNER_RADIUS));
      // Set presentation attributes directly rather than relying on the
      // component's scoped <style> — Astro scopes styles by stamping a
      // data-astro-cid-* attribute onto elements present in the template at
      // build time, which paths created here at runtime never get. Without
      // this they fall back to SVG defaults (filled black, full opacity),
      // which is exactly the dark overlay + starburst artifacts this
      // produced before the fix.
      pathEl.setAttribute("fill", "none");
      pathEl.setAttribute("stroke", "var(--rule, var(--text-muted))");
      pathEl.setAttribute("stroke-width", String(STROKE_WIDTH));
      pathEl.setAttribute("stroke-linejoin", "round");
      pathEl.setAttribute("stroke-linecap", "round");
      pathEl.setAttribute("vector-effect", "non-scaling-stroke");
      frag.appendChild(pathEl);
    }
    cellsEl!.replaceChildren(frag);
  }

  let queued = false;
  function scheduleRender() {
    if (queued) return;
    queued = true;
    requestAnimationFrame(() => {
      queued = false;
      render();
    });
  }

  render();
  window.addEventListener("resize", scheduleRender);
  window.addEventListener("load", scheduleRender);
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(scheduleRender);
  }
}
