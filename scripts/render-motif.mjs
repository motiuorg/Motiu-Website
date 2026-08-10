#!/usr/bin/env node
// render-motif.mjs — preset JSON → SVG (+ optional PNG). The headless half of
// the Voronoi motif pipeline; the manual half is public/lab-tools/hero-lab.html.
// Usage:
//   node scripts/render-motif.mjs --preset brand/presets/<name>.json
//     [--out brand/renders/<target>/round-1] [--png] [--smoke]
// Never deploys anything. brand/ is outside src/ and public/, so nothing here
// reaches the built site.
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { computeCellPaths } from "../src/lib/voronoi-core.mjs";
import { loadTokens, getPalettes } from "./lib/brand-tokens.mjs";
import { FORMATS, validatePreset, generateSites } from "./lib/preset.mjs";

export function renderSvg(preset, palettes) {
  const { w, h } = FORMATS[preset.format];
  const pal = palettes[preset.palette];
  const sites =
    preset.sites ?? generateSites(preset.field, { w, h }, preset.padRatio);
  const paths = computeCellPaths({
    sites,
    transform: preset.transform,
    viewBox: { w, h },
    pad: { x: preset.padRatio * w, y: preset.padRatio * h },
    cornerRadius: preset.cornerRadius,
  });
  const cells = paths
    .map((d, i) => {
      const fill =
        preset.fill === "ramp"
          ? `fill="${pal.ramp[i % pal.ramp.length]}" fill-opacity="${preset.fillOpacity}"`
          : `fill="none"`;
      return `  <path d="${d}" ${fill} stroke="${pal.stroke}" stroke-width="${preset.stroke}" stroke-linejoin="round" stroke-linecap="round"/>`;
    })
    .join("\n");
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}">
  <rect width="${w}" height="${h}" fill="${pal.bg}"/>
${cells}
</svg>
`;
}

const CHROME_PATHS = [
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
];

export async function renderPng(svgPath, pngPath, { w, h }) {
  const chrome = CHROME_PATHS.find((p) => existsSync(p));
  if (!chrome) {
    console.warn("png: SKIPPED — no Chrome/Chromium found (SVG still written)");
    return false;
  }
  const { default: puppeteer } = await import("puppeteer-core");
  const browser = await puppeteer.launch({ executablePath: chrome });
  try {
    const page = await browser.newPage();
    await page.setViewport({ width: w, height: h, deviceScaleFactor: 2 });
    await page.goto("file://" + svgPath);
    await page.screenshot({ path: pngPath, clip: { x: 0, y: 0, width: w, height: h } });
  } finally {
    await browser.close();
  }
  return true;
}

async function main() {
  const args = process.argv.slice(2);
  const get = (flag) => {
    const i = args.indexOf(flag);
    return i >= 0 ? args[i + 1] : null;
  };
  const presetPath = get("--preset");
  if (!presetPath) {
    console.error("usage: render-motif --preset <file.json> [--out <dir>] [--png] [--smoke]");
    process.exit(1);
  }
  const palettes = getPalettes(loadTokens());
  const preset = validatePreset(
    JSON.parse(readFileSync(presetPath, "utf8")),
    palettes,
  );
  const outDir = get("--out") ?? "brand/renders/_scratch";
  mkdirSync(outDir, { recursive: true });
  const svg = renderSvg(preset, palettes);
  const svgPath = join(process.cwd(), outDir, basename(presetPath, ".json") + ".svg");
  writeFileSync(svgPath, svg);
  const cellCount = (svg.match(/<path /g) || []).length;
  console.log(`svg: ${svgPath} (${cellCount} cells, ${preset.format}, ${preset.palette})`);
  if (args.includes("--smoke")) {
    const expected = preset.sites ? preset.sites.length : preset.field.count;
    if (cellCount !== expected) {
      console.error(`smoke: FAIL — ${cellCount} cells, expected ${expected}`);
      process.exit(1);
    }
    console.log("smoke: OK");
  }
  if (args.includes("--png")) {
    const ok = await renderPng(svgPath, svgPath.replace(/\.svg$/, ".png"), FORMATS[preset.format]);
    if (ok) console.log(`png: ${svgPath.replace(/\.svg$/, ".png")}`);
  }
}

// Robust against spaces/URL-escaping in the path (this repo lives under
// ".../03 Libraries/..."), unlike a raw "file://" + process.argv[1] compare.
if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((e) => {
    console.error(e.message);
    process.exit(1);
  });
}
