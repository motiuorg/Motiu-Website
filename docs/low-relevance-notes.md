# Low-relevance & hidden items — for future review

Working notes on things that are intentionally (or incidentally) hidden or de-emphasized.
Updated 2026-09-03. Nothing here blocks launch; everything here is a "what if" for a later pass.

## Hidden surfaces that still exist (invisible infra)

- **`/atlas` and `/commons` redirect stubs** — both emit a redirect to
  `https://knowledge.refibcn.cat`. Kept deliberately so old URLs don't 404 and the
  "Bioregional Intelligence" project card (href `/atlas/`) keeps working. `scripts/verify-build.mjs`
  asserts they keep rendering. If/when the knowledge surface moves to a motiu-owned domain,
  update the stub targets.
- **`knowledge.refibcn.cat` (external)** — the actual Knowledge surface. No longer linked from
  the nav or footer; the canonical place to redirect the stubs to once it's rebranded/moved.
- **`/lab` + `/lab-tools` internal design surfaces** — noindexed and unlinked (test tooling,
  not content). They still contain old specimen URLs (`refibcn.cat`, `refibcn.github.io`) in
  demo copy — harmless, but scrub if these ever become public.

## Removed content, kept in git history

- **Regenerant Catalunya funders list** (Regen Coordination, Celo Public Goods, Gitcoin,
  Ethereum Foundation): emptied; the section renders conditionally and is hidden. The
  attribution facts live in git history if ever needed for grant reporting.
- **ReFi DAO / Regen Coordination and org-os**: removed from all visible content (2026-09-03
  positioning pass). Old project URLs (`/projects/refi-dao-regen-coordination/`,
  `/projects/org-os/`) now 404 — the old pages exist only in git history.
- **Web3 vocabulary** (Safe, Gitcoin, multi-sig, on-chain, GG24): scrubbed from rendered copy.
  Code comments in `src/` (e.g. `HeroVoronoi.*`, `hero-voronoi-live.ts`, `content.config.ts`
  `karma` field) still reference the old world — invisible, kept as provenance.

## Visual/brand leftovers

- **`public/assets/og-image.png`, `favicons.png`, `favicon.svg`** — still shipped from the
  ReFi-era brand. The motiu m-mark presets exist in `brand/presets/`; regenerate these assets
  before any external launch.
- **RC Maps project card image** uses `/assets/ecosystem_map.png` as a placeholder — replace
  with a real screenshot of https://motiuorg.github.io/Regenerant-Catalunya-Maps/.
- **"179+" figure** on the RC Maps card is live data from the maps database (grew 177→179
  between builds) — fine with "+", revisit if it grows a lot.

## Other sites / operational

- **The maps site footer** (`motiuorg.github.io/Regenerant-Catalunya-Maps/`) still lists
  "ReFi BCN" as a partner — separate repo (`motiuorg/Regenerant-Catalunya-Maps`), decide
  later whether to rebrand that footer too.
- **`hello@motiu.org`** is the published contact but no mailbox/forwarding is known to exist
  yet — set up forwarding (or a mailbox) at the email provider before publishing widely.
- **`/home/gq/Motiu/rc2`** is an untracked working copy of the maps-site repo inside this
  repo's directory — workspace artifact, never commit it here.
- **Stats "2 local networks facilitated end-to-end"** replaced the removed "global networks
  federated" stat — a soft proxy; swap for a stronger verifiable number when one exists.