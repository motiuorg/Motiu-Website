#!/usr/bin/env node
// capture-og-hero.mjs — screenshot the live hero (voronoi + heading + pillar
// badges + tagline) for use as the site's og:image / twitter:image, with the
// fixed nav hidden so only the hero itself is captured. Reuses the
// Chrome-launch pattern from render-motif.mjs's renderPng().
//
// Usage:
//   node scripts/capture-og-hero.mjs [--url <url>] [--out <file.png>]
//     [--width <px>] [--height <px>]
//
// Defaults match the current og:image:width/height fallbacks in
// Layout.astro (1920x1078) so no yaml changes are needed if you keep them.
import { writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, isAbsolute, join } from "node:path";
import { fileURLToPath } from "node:url";

const CHROME_PATHS = [
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
];

async function main() {
  const args = process.argv.slice(2);
  const get = (flag, fallback) => {
    const i = args.indexOf(flag);
    return i >= 0 ? args[i + 1] : fallback;
  };
  const url = get("--url", "https://motiu.org");
  const outArg = get("--out", "public/assets/og-hero.png");
  const width = Number(get("--width", "1920"));
  const height = Number(get("--height", "1078"));
  const outPath = isAbsolute(outArg) ? outArg : join(process.cwd(), outArg);

  const chrome = CHROME_PATHS.find((p) => existsSync(p));
  if (!chrome) {
    console.error("capture-og-hero: no Chrome/Chromium found — install one of:", CHROME_PATHS);
    process.exit(1);
  }
  const { default: puppeteer } = await import("puppeteer-core");
  const browser = await puppeteer.launch({ executablePath: chrome });
  try {
    const page = await browser.newPage();
    await page.setViewport({ width, height, deviceScaleFactor: 1 });
    await page.goto(url, { waitUntil: "networkidle0" });
    await page.evaluate(() => document.fonts.ready);
    // Hide the fixed nav so it never overlaps the hero, and give the
    // Voronoi hydration + headline-rotation scripts a moment to settle.
    await page.evaluate(() => {
      const nav = document.querySelector(".landing-nav");
      if (nav) nav.style.display = "none";
    });
    await new Promise((r) => setTimeout(r, 400));
    mkdirSync(dirname(outPath), { recursive: true });
    await page.screenshot({
      path: outPath,
      clip: { x: 0, y: 0, width, height },
    });
    console.log(`capture-og-hero: wrote ${outPath} (${width}x${height})`);
  } finally {
    await browser.close();
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((e) => {
    console.error(e.message);
    process.exit(1);
  });
}
