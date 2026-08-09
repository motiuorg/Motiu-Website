# ReFi BCN Website — Development Feedback

> **Live site:** https://refibcn.github.io/
> **Element/branding lab:** https://refibcn.github.io/lab/ (internal test surface — palette, type, motifs, primitives)
> **Repository:** https://github.com/refibcn/refibcn.github.io

---

> **📣 FEEDBACK PASS OPEN — week of 2026-08-10** (`BD-2026-048`, deferred from 260730; the Astro consolidation it was gated on has landed). Walk the live site section by section and file your requests below.
> **Context for prioritising:** the **landing page ships by 2026-08-17** (`BD-2026-062`, the Fito deadline). Landing-relevant asks filed by **~Wed 08-13** can make that cut; everything else is batched into iteration 5 — filed, not lost. The Aug 17 date wins over any individual request.

## How to Contribute

1. **Review the live site** at the link above (the `/lab/` page shows all the design elements in one place — now 15 pages on the atomic-design structure)
2. **Add your feedback** in the sections below — edit this file directly on GitHub (pencil icon)
3. **Tag your comments** with your name/handle
4. **Prioritize** if possible (🔴 Critical, 🟡 Important, 🟢 Nice to have)

---

## General Impressions

> What's your overall feeling about the site? First reactions welcome.

-
-
-

---

## Design Feedback

> Current theme = "editorial-organic", **2026-08-07 relock (Andrea's design-system push)**: Geist headings
> + body (Averia Serif Libre = display-only for hero titles/pull quotes) · IBM Plex Mono labels ·
> straight edges · **terracotta primary `#D12B00`** · pillar palette v4 sourced from the `/lab/colors`
> Color Library (neural = cyan/water, tissue = lime/land, flow = orange/finance) · warm neutrals on
> `--umber` · live content-protected **Voronoi hero** (the network-cells motif, `BD-2026-043`).
> The whole palette/type can still be swapped in one line (`src/styles/theme.css`).

-
-
-

---

## Content Feedback

> Landing copy follows Andrea's prepared structure (pillars as the three capabilities).
> **The name is Motiu** (`BD-2026-049`, 2026-08-04) — "Motiu" alone in public, "co-op" only selectively
> (`BD-2026-050`). The site chrome already carries it; the meta layer follows via `src/data/site.yaml`.

-
-
-

---

## Navigation & UX

> How does it feel to move around? Known open point: the landing tells the full story while the nav
> still points to separate deeper pages (/what-we-do, /who-we-serve…) with overlapping content.

-
-
-

---

## Content Ideas

> What pages/sections should we add? (Atlas = maps, Commons = knowledge base are scaffolds for now.)

-
-
-

---

## Feature Requests

> What's missing? What would make this better?

-
-
-

---

## Bugs & Issues

> Anything broken? Display issues? Errors?

| Issue | Browser/Device | Reporter |
|-------|---------------|----------|
| | | |
| | | |

---

## Questions for Discussion

- [x] **Primary action colour** — ~~embrace red as primary, or keep a warm amber/coral?~~ → **Red** (`#C92637`), decided 2026-07-04 (see Decisions Made).
- [x] **Body font** — ~~Geist vs Inter?~~ → **Geist**, decided 2026-07-04 (see Decisions Made).
- [x] **Landing vs deeper pages** — ~~single-page with anchors, or keep separate pages?~~ → **Keep separate pages, differentiate by content** (iteration 4, editorial deepening). Each deeper page now carries what the landing can't — About gets team cards + proof + partners; What we do gets deliverables + engagement process; Who we serve gets fit-signals; case studies get stat callouts + prev/next.
- [ ] **Custom domain** — `motiu.cat` + one international TLD decided (`BD-2026-051`, 2026-08-04) but **not yet purchased**; conflict check (handles · registry · trademark) unowned → 08-11 sync.
- [x] **Group name** — ~~survey pending~~ → **Motiu** (`BD-2026-049`, 2026-08-04); propagating via `site.yaml`.
- [ ]

---

## Decisions Made

| Decision | Date | Context |
|----------|------|---------|
| Organic / interconnected visual direction (cells · mycelium · rivers) | 2026-06-02 | ops sync |
| One consolidated Astro surface, BIS editorial base + hidden `/lab` | 2026-06-11 | ops sync |
| "Bioregional Commons" as the maps+knowledge surface label (provisional) | 2026-06-11 | ops sync |
| Editorial-BIS structure + organic atmosphere; dual-theme one-line swap | 2026-06-10 | build session |
| Landing adopts Andrea's prepared structure + Averia titles | 2026-06-11 | build session |
| Naming stays OPEN / ReFi BCN — publishing not gated on rebrand | 2026-06-30 | team decision |
| Published to GitHub Pages under the refibcn account (`gh-pages` branch) | 2026-07-01 | this repo |
| ~~**Primary action colour = red** `#C92637` (flow step 3 of Andrea's 2026-05-31 lock; paper foreground, AA 5.23:1)~~ → **SUPERSEDED 2026-08-07: primary = terracotta `#D12B00`** (`BD-2026-066`), picked independently of the pillars — the brand mark isn't a capability colour. Fixes the flow-primary AA failure (3.20:1 → 5.17:1 on paper; hover 7.06:1). Guardrails unchanged: `--danger` → dark brick `#7A2618`, `--warning` → flow-light | 2026-08-07 | Andrea, design-system push |
| ~~**Body font = Geist** (Andrea's direction). Display stays Averia Serif Libre~~ → **EXTENDED 2026-08-07: headings h1–h6 = Geist too** (`BD-2026-068`); Averia demotes to display-only (hero titles/pull quotes via `.display`, guarded h4+); eyebrows/labels stay IBM Plex Mono. Type base 16px → 20px, new 5-step copy scale | 2026-08-07 | Andrea, design-system push |
| **Pillar palette v4 relock** (`BD-2026-067`): ramps sourced from the `/lab/colors` Color Library — neural = cyan (water) · tissue = lime (land) · flow = orange (finance). Neutrals re-anchored (`--ink` → `--umber #221a12`, `--paper #fffffd`, derived `--rule`). Supersedes the 2026-05-31 lock. `--lib-*` data-viz set NOT yet migrated | 2026-08-07 | Andrea, design-system push |
| 2026-05-31 palette lock adopted in both organic themes (4-step ramps, new 9-colour data-viz library); aurora pillar fields recreated in pure CSS (watermarked mesh refs NOT shipped) | 2026-07-04 | iteration-3 session |
| **Iteration 4 — editorial deepening.** Keep separate pages, differentiate by content. New shared components: `StatBand`, `ProcessStrip`, `TeamCard`, `CTABand`, `PageHero`. Every deeper page rebuilt; landing gets a stat band + numbered section eyebrows; sleekness pass (card/button hover, scroll-reveal, nav Contact button) | 2026-07-05 | iteration-4 session |
| **Bioregional Commons + Atlas surfaces added.** `/atlas` full-page Catalunya program map (BIS absorption); `/commons` public knowledge surface — engine live but **content review-gated, zero objects published by design** (fail-closed `publishableKb` filter + public-dist canary); staticrypt-gated internal `/commons-review` surface; bespoke `/projects/regenerant-catalunya/` program page (inset map + network breakdown) | 2026-07-21 | commons/atlas build |
| **KB application — one engine, two lenses** (replaces the review-tool UX; supersedes Obsidian Publish + Quartz as the knowledge surface). `kb.mjs connections()` resolves `related_concepts` → objects + backlinks + provenance siblings (scoping = the public leak guard). Internal `/commons-review` rebuilt as a **hash-routed app** (sidebar schema-tree + filters, reader with typed per-schema layouts, References/Referenced-by/Same-source, prev-next, keyboard nav, deep links, graph wired to routing) — still one self-contained env-gated staticrypt-ready file. Public `/commons` → schema-grouped browse + status meter; `/commons/[schema]/[slug]` typed pages + scoped connections (zero published today). 16 tests pass; leak guard + typed ordering covered | 2026-07-22 | KB-app session |

---

## Next Steps (proposed — next iteration)

- [x] Adopt Andrea's 2026-05-31 palette lock — done 2026-07-04 (red primary per decision)
- [x] Wire in Andrea's real project illustrations (optimized for web) — done 2026-07-01 (iteration 2)
- [x] Recreate the grainy-aurora pillar backgrounds in CSS — done 2026-07-04 (`Aurora.astro`, pure CSS)
- [x] Fold Andrea's live Voronoi tissue editor into `/lab` — done 2026-07-01 (`/lab-tools/`)
- [x] Housekeeping: centralize the org name into one token · OG/meta tags · 404 page — done 2026-07-01
- [x] Phase 1b: wire the Catalunya maps into `/atlas` — done 2026-07-21 (full-page program map)
- [ ] Body font follow-up: Geist Mono for eyebrows/labels? (IBM Plex Mono kept for now)
- [ ] Commons: flip the review gate to publish reviewed knowledge objects (currently zero by design)

---

## Meeting Notes

### [Date]

**Present:**

**Notes:**

**Actions:**

---

*Add your name to contributors when you provide feedback!*

**Contributors:**
