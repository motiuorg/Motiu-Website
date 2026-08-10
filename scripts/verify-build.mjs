// scripts/verify-build.mjs
// Quick integrity checks on the static build output. Runs after `npm run build`.
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const DIST = "dist";
const REQUIRED = [
  "index.html",
  "about/index.html",
  // These three are now redirect stubs pointing at knowledge.refibcn.cat
  // (BD-2026-060 / convergence 2026-08-10). Keep them in the REQUIRED list:
  // the routes must keep emitting, so the old URLs stay redirected rather
  // than 404ing. Do NOT "clean these up" — they assert the stubs render.
  "atlas/index.html",
  "commons/index.html",
  "commons-review/index.html",
  "contact/index.html",
  "what-we-do/index.html",
  "who-we-serve/index.html",
  "projects/index.html",
  "projects/regenerant-catalunya/index.html",
  "projects/regenerant-catalunya/article/index.html",
  "geo/catalunya-comarques.geojson",
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

// Sanity: cohort page must reference all 11 projects by id.
const cohort = readFileSync(join(DIST, "projects/regenerant-catalunya/index.html"), "utf8");
const expectedIds = [
  "regeneracio-xyz", "resilience-earth", "de-bat-a-bat", "chapter-2", "anigami", "mixite",
  "laurel-31", "la-marmita", "les-juntes", "la-suculenta", "la-granja-del-tilo",
];
for (const id of expectedIds) {
  // The program map embeds the cohort as JSON (e.g. {"id":"resilience-earth",...}).
  if (!cohort.includes(`"id":"${id}"`)) {
    console.error(`COHORT MISSING ID: ${id}`);
    failed = true;
  }
}
console.log(`COHORT IDs: ${expectedIds.length} expected, ${expectedIds.filter((id) => cohort.includes(id)).length} found`);

process.exit(failed ? 1 : 0);
