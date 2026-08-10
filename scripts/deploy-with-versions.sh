#!/usr/bin/env bash
# deploy-with-versions.sh — THE deploy script for refibcn.github.io.
#
# Builds the current site PLUS frozen iteration snapshots (from git tags) into
# one dist/, then force-pushes to gh-pages. Because every deploy force-pushes,
# snapshots MUST be rebuilt on every deploy — which this script does. Deploy
# only via this script from now on; a bare `dist` push wipes /versions/.
#
#   Live site:      /                (current main)
#   Snapshots:      /versions/<name>/  (rebuilt from tags, noindex'd)
#   Compare index:  /versions/
#
# Requires: KB_DIR pointing at the org-os data/kb/ store (older iterations'
# kb.mjs has no missing-dir fallback and their build fails without it).
#
# DO NOT DELETE THE KB_DIR GUARD (convergence 2026-08-10 / BD-2026-060). The
# CURRENT site no longer needs it — its KB engine was removed and /commons,
# /atlas, /commons-review are now redirect stubs to knowledge.refibcn.cat. But
# each snapshot below builds in a worktree checked out at its own tag, and those
# tags still carry their own src/lib/kb.mjs + commons.astro. Drop KB_DIR and
# every snapshot build fails, which fails the whole deploy.
#
# ONE SNAPSHOT PER VERSION LINE, not a growing archive. The website has three
# lines — converged (live at root) · andrea · luiz — and each keeps exactly one
# entry, its latest. When Andrea pushes again, re-point `iteration/andrea-v2`
# (or add the new tag and swap the line below); do not accumulate andrea-v2,
# andrea-v3, … The hub is for deciding what to keep from which, not for history
# — git tags are the history.
#
# Add/remove snapshots by editing VERSIONS ("url-name:git-ref").
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${KB_DIR:?Set KB_DIR to the org-os data/kb/ path (absolute)}"

VERSIONS=(
  "luiz-i4:iteration/luiz-4"
  "andrea-v2:iteration/andrea-v2"
)

cd "$REPO_ROOT"
echo "==> building current site"
npm run build

mkdir -p dist/versions

for pair in "${VERSIONS[@]}"; do
  name="${pair%%:*}"; ref="${pair#*:}"
  echo "==> snapshot $name  ($ref)"
  wt="$(mktemp -d "/tmp/refibcn-snap-$name.XXXX")"
  git worktree add --detach --force "$wt" "$ref" >/dev/null
  ln -s "$REPO_ROOT/node_modules" "$wt/node_modules"
  (cd "$wt" && npm run build)
  python3 - "$name" "$wt/dist" <<'PY'
import re, sys, pathlib
name, root = sys.argv[1], sys.argv[2]
pre = f"/versions/{name}"
ATTR = re.compile(r'\b(href|src|srcset|content|action|poster)="/(?!/|versions/)')
URLF = re.compile(r'url\(/(?!/|versions/)')
QSTR = re.compile(r'''(["'])/(assets|_astro|lab-tools|data|favicon)(?=[/."'])''')
HEAD = re.compile(r'(<head[^>]*>)', re.I)
for p in pathlib.Path(root).rglob("*"):
    if p.suffix not in {".html", ".css", ".js", ".mjs"}:
        continue
    s = p.read_text(encoding="utf-8", errors="surrogateescape")
    s = ATTR.sub(lambda m: f'{m.group(1)}="{pre}/', s)
    s = URLF.sub(f"url({pre}/", s)
    s = QSTR.sub(lambda m: f"{m.group(1)}{pre}/{m.group(2)}", s)
    if p.suffix == ".html":
        s = HEAD.sub(lambda m: m.group(1) + '<meta name="robots" content="noindex">', s, count=1)
    p.write_text(s, encoding="utf-8", errors="surrogateescape")
print(f"rewrote root-absolute refs -> {pre}/")
PY
  # leak check: any root-absolute local refs left that escaped the rewrite?
  leaks=$(grep -rEoh '(href|src)="/(assets|_astro|lab-tools)/' "$wt/dist" --include='*.html' | sort -u | head -5 || true)
  [ -n "$leaks" ] && { echo "!! unrewritten refs in $name:"; echo "$leaks"; exit 1; }
  rm -rf "dist/versions/$name"
  cp -R "$wt/dist" "dist/versions/$name"
  git worktree remove --force "$wt"
done

echo "==> versions index (development instances hub)"
cat > dist/versions/index.html <<'HTML'
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex"><title>motiu · development instances</title>
<style>
  :root{--umber:#221a12;--paper:#fffffd;--bone:#faf8f4;--rule:#6b6660;--terracotta:#D12B00;--line:#e6e1d9}
  *{box-sizing:border-box}
  body{font-family:ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif;max-width:54rem;margin:0 auto;padding:5vh 1.5rem 10vh;color:var(--umber);background:var(--paper);line-height:1.55}
  a{color:var(--terracotta)}
  header{border-bottom:1px solid var(--line);padding-bottom:1.3rem;margin-bottom:2.2rem}
  h1{font-size:1.6rem;margin:0 0 .45rem;letter-spacing:-.012em}
  .sub{color:var(--rule);margin:0 0 .9rem;font-size:.95rem}
  .fb{display:inline-block;border:1px solid var(--terracotta);border-radius:.35rem;padding:.4rem .8rem;font-size:.87rem;font-weight:600;text-decoration:none}
  .fb:hover{background:var(--terracotta);color:var(--paper)}
  .inst{margin:0 0 2.6rem}
  .inst__line{display:flex;align-items:baseline;gap:.8rem;flex-wrap:wrap;border-bottom:2px solid var(--umber);padding-bottom:.4rem}
  .inst__line h2{font-size:1.15rem;margin:0;letter-spacing:-.01em}
  .inst__host{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.8rem;color:var(--rule);margin-left:auto}
  .inst__host a{color:var(--rule)}
  .inst__note{color:var(--rule);font-size:.87rem;margin:.6rem 0 1rem}
  .v{border-left:2px solid var(--line);padding:.15rem 0 .15rem 1rem;margin:0 0 1.1rem}
  .v--current{border-left-color:var(--terracotta)}
  .v__head{display:flex;align-items:baseline;gap:.6rem;flex-wrap:wrap}
  .v__num{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-weight:700;font-size:1rem}
  .v__name{font-weight:600}
  .v__date{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.78rem;color:var(--rule);margin-left:auto}
  .tag{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.65rem;text-transform:uppercase;letter-spacing:.07em;border:1px solid var(--line);border-radius:.2rem;padding:.05rem .35rem;color:var(--rule)}
  .tag--live{border-color:var(--terracotta);color:var(--terracotta)}
  .v__body{margin:.35rem 0 .4rem;color:var(--rule);font-size:.89rem}
  .v__links{margin:0;font-size:.85rem}
  .v__links a{text-decoration:none;border-bottom:1px solid var(--line)}
  .v__links a:hover{border-bottom-color:var(--terracotta)}
  h2.std{font-size:.72rem;text-transform:uppercase;letter-spacing:.1em;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;color:var(--rule);margin:2.8rem 0 .3rem;font-weight:500}
  .h2note{color:var(--rule);font-size:.85rem;margin:0 0 .9rem}
  .card{border:1px solid var(--line);background:var(--bone);padding:.9rem 1.1rem;margin:.55rem 0;border-radius:.4rem}
  .card a.t{font-weight:600;text-decoration:none;font-size:1rem}
  .card a.t:hover{text-decoration:underline}
  .card p{margin:.28rem 0 0;color:var(--rule);font-size:.87rem}
  .also{margin:.45rem 0 0;font-size:.82rem}
  .also a{color:var(--umber);text-decoration:none;border-bottom:1px solid var(--line)}
  .also a:hover{border-bottom-color:var(--umber)}
  code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.82em;background:#fff;border:1px solid var(--line);padding:.03rem .3rem;border-radius:.2rem;color:var(--rule)}
  .note{border-left:3px solid var(--terracotta);padding:.15rem 0 .15rem 1rem;margin:1.4rem 0 0;color:var(--rule);font-size:.88rem}
  .note strong{color:var(--umber)}
  footer{margin-top:3rem;padding-top:1.2rem;border-top:1px solid var(--line);color:var(--rule);font-size:.82rem}
</style></head><body>

<header>
  <h1>Development instances</h1>
  <p class="sub">Every surface we run, with its versions. Internal — not linked from the public site.</p>
  <a class="fb" href="https://github.com/refibcn/refibcn.github.io/blob/main/docs/DEVELOPMENT.md">File feedback &rarr; DEVELOPMENT.md</a>
</header>

<section class="inst">
  <div class="inst__line">
    <h2>Website</h2>
    <span class="inst__host"><a href="/">refibcn.github.io</a></span>
  </div>
  <p class="inst__note">Three version lines, one entry each — the converged build that is live,
  plus Andrea's and Luiz's latest, frozen for comparison. Snapshots are historically faithful, so
  they still read &ldquo;ReFi BCN&rdquo;; that is the point.</p>

  <div class="v v--current">
    <div class="v__head"><span class="v__num">v2.1</span><span class="v__name">converged</span><span class="tag tag--live">live</span><span class="v__date">2026-08-09</span></div>
    <p class="v__body">Andrea's brand system merged with the Motiu rename and org-os as a listed
    project — the Aug 17 landing. Terracotta primary, Geist headings, live Voronoi hero.</p>
    <p class="v__links"><a href="/">open site</a> &middot; <a href="/lab/">design system</a> &middot; <code>iteration/v2.1-aug17</code></p>
  </div>

  <div class="v">
    <div class="v__head"><span class="v__num">v2.0</span><span class="v__name">andrea</span><span class="tag">snapshot</span><span class="v__date">2026-08-07</span></div>
    <p class="v__body">Her push as delivered — 15-page lab on the atomic-design structure, live
    content-protected Voronoi hero, the palette + type relock. Before the rename and org-os.</p>
    <p class="v__links"><a href="/versions/andrea-v2/">open site</a> &middot; <a href="/versions/andrea-v2/lab/">design system</a> &middot; <code>iteration/andrea-v2</code></p>
  </div>

  <div class="v">
    <div class="v__head"><span class="v__num">v1.4</span><span class="v__name">luiz</span><span class="tag">snapshot</span><span class="v__date">2026-07-24</span></div>
    <p class="v__body">Iteration 4, editorial deepening — Averia headings, red primary, aurora
    pillar fields, tissue backgrounds, EN/CA/ES switch. Live until 2026-08-09.</p>
    <p class="v__links"><a href="/versions/luiz-i4/">open site</a> &middot; <a href="/versions/luiz-i4/lab/">design system</a> &middot; <code>iteration/luiz-4</code></p>
  </div>

  <div class="note">
    <strong>What to compare:</strong> Averia vs Geist headings &middot; red vs terracotta primary
    &middot; aurora fields vs photo-with-hover &middot; compact editorial pillars vs full pillar
    rows. File it as <em>keep X from version Y</em> in
    <a href="https://github.com/refibcn/refibcn.github.io/blob/main/docs/DEVELOPMENT.md">DEVELOPMENT.md</a>.
  </div>
</section>

<section class="inst">
  <div class="inst__line">
    <h2>Knowledge</h2>
    <span class="inst__host"><a href="https://knowledge.refibcn.cat/">knowledge.refibcn.cat</a></span>
  </div>
  <p class="inst__note">Regenerant Catalunya — KB engine, source containers, atlas, CRM directory.
  <code>/commons</code> and <code>/atlas</code> on the website redirect here.</p>
  <div class="v v--current">
    <div class="v__head"><span class="v__num">v1.0</span><span class="v__name">initial</span><span class="tag tag--live">live</span><span class="v__date">2026-08-10</span></div>
    <p class="v__body">First deploy of the standalone instance — 6 source containers, 416 objects,
    0 unattributed.</p>
    <p class="v__links"><a href="https://knowledge.refibcn.cat/">open site</a> &middot; <a href="https://knowledge.refibcn.cat/review">review lens</a> (password-gated)</p>
  </div>
</section>

<section class="inst">
  <div class="inst__line">
    <h2>Bioregioning</h2>
    <span class="inst__host"><a href="https://bioregioning.earth">bioregioning.earth</a></span>
  </div>
  <p class="inst__note">The third instance — Andrea's stewarded bioregional surface. Separate
  property on its own cycle; no snapshots taken here.</p>
  <div class="v v--current">
    <div class="v__head"><span class="v__name">current</span><span class="tag tag--live">live</span></div>
    <p class="v__links"><a href="https://bioregioning.earth">open site</a></p>
  </div>
</section>

<h2 class="std">Design system &amp; tools</h2>
<p class="h2note">Built from the current <code>main</code>, so these track v2.1. Each frozen
version above carries its own copy — that is how the design systems compare directly.</p>
<div class="card">
  <a class="t" href="/lab/">/lab/ — the design system</a>
  <p>Tokens, atoms, molecules, organisms, documented against what is actually wired into the
  build (<code>BD-2026-041</code>). Each page flags what is unused, incomplete, or missing.</p>
  <p class="also">Jump to: <a href="/lab/colors/">colors</a> &middot; <a href="/lab/typography/">typography</a> &middot; <a href="/lab/motifs/">motifs</a> &middot; <a href="/lab/sections/">sections</a> &middot; <a href="/lab/maps/">maps</a></p>
</div>
<div class="card">
  <a class="t" href="/lab-tools/">/lab-tools/ — raw experiment surfaces</a>
  <p>Pre-Astro standalone tools, kept because they do things the documented lab does not:
  live editors and side-by-side comparators.</p>
  <p class="also"><a href="/lab-tools/hero-lab.html">hero lab — Voronoi editor</a> &middot; <a href="/lab-tools/colors-compare.html">colors compare</a> &middot; <a href="/lab-tools/fonts-compare.html">fonts compare</a> &middot; <a href="/lab-tools/motifs-explore.html">motifs explore</a> &middot; <a href="/lab-tools/styles.html">styles</a></p>
</div>

<footer>
  Regenerated on every deploy by <code>scripts/deploy-with-versions.sh</code> — deploy only via
  that script, a bare <code>dist</code> push wipes the snapshots. <strong>One entry per version
  line:</strong> when someone pushes a new iteration, re-point their tag rather than adding a
  fourth block — git tags hold the history, this page holds the choice.
</footer>
</body></html>
HTML

touch dist/.nojekyll
echo "==> pushing gh-pages"
cd dist
rm -rf .git
git init -q -b gh-pages
git add -A
git -c user.name="refibcn-deploy" -c user.email="hello@refibcn.cat" commit -q -m "deploy: $(cd "$REPO_ROOT" && git log -1 --format='%h %s') + version snapshots"
git -c http.version=HTTP/1.1 -c http.postBuffer=524288000 push -f https://github.com/refibcn/refibcn.github.io.git gh-pages:gh-pages
cd "$REPO_ROOT" && rm -rf dist/.git

# ---------------------------------------------------------------------------
# Wait for the Pages build and RETRY ON ERROR.
#
# 2026-08-10: a deploy errored with a bare "Page build failed." (duration 0ms),
# then the identical tree built fine in 59s on the next attempt. Not size — the
# previous ~121MB deploy with the same /versions/ payload built in 33s. It is a
# transient GitHub-side failure, and it is invisible unless you poll: the API
# reports `building` for minutes before flipping to `errored`, and the old site
# keeps serving 200 the whole time. Never verify a deploy with a root 200.
# ---------------------------------------------------------------------------
REPO_SLUG="refibcn/refibcn.github.io"
if command -v gh >/dev/null 2>&1; then
  for attempt in 1 2 3; do
    echo "==> waiting for Pages build (attempt $attempt)"
    status="building"
    for _ in $(seq 1 40); do
      sleep 15
      status=$(gh api "repos/$REPO_SLUG/pages/builds/latest" --jq '.status' 2>/dev/null || echo building)
      [ "$status" != "building" ] && break
    done
    if [ "$status" = "built" ]; then
      echo "==> Pages build OK"
      break
    fi
    echo "!! Pages build status=$status — re-pushing to trigger a fresh build"
    [ "$attempt" = 3 ] && { echo "!! gave up after 3 attempts"; exit 1; }
    (cd dist && rm -rf .git && git init -q -b gh-pages && git add -A \
      && git -c user.name="refibcn-deploy" -c user.email="hello@refibcn.cat" \
           commit -q -m "deploy: retry $attempt after failed Pages build" \
      && git -c http.version=HTTP/1.1 -c http.postBuffer=524288000 \
           push -f "https://github.com/$REPO_SLUG.git" gh-pages:gh-pages >/dev/null 2>&1)
    rm -rf dist/.git
  done
else
  echo "!! gh CLI not found — CHECK THE BUILD MANUALLY, a silent 'errored' looks identical to success"
fi

echo "==> done — verify with a NEW hashed asset, never a root 200"
