// scripts/verify-build.mjs
// Quick integrity checks on the static build output. Runs after `npm run build`.
// Single-page site (2026-09-07): the landing page now lives at /, and every
// other route is archived (underscore-prefixed in src/pages, so Astro doesn't
// route them). Only the root and the 404 error page are expected in dist.
import { existsSync } from "node:fs";
import { join } from "node:path";

const DIST = "dist";
const REQUIRED = [
  "index.html",
  "404.html",
];

let failed = false;
for (const path of REQUIRED) {
  const full = join(DIST, path);
  if (!existsSync(full)) {
    console.error(`MISSING: ${full}`);
    failed = true;
  } else {
    console.log(`OK:      ${full}`);
  }
}

process.exit(failed ? 1 : 0);