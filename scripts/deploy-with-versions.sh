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
  body{font-family:ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif;max-width:52rem;margin:0 auto;padding:6vh 1.5rem 10vh;color:var(--umber);background:var(--paper);line-height:1.55}
  header{border-bottom:1px solid var(--line);padding-bottom:1.3rem;margin-bottom:.5rem}
  h1{font-size:1.6rem;margin:0 0 .45rem;letter-spacing:-.012em}
  .sub{color:var(--rule);margin:0;font-size:.95rem}
  h2{font-size:.72rem;text-transform:uppercase;letter-spacing:.1em;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;color:var(--rule);margin:2.4rem 0 .3rem;font-weight:500}
  .h2note{color:var(--rule);font-size:.85rem;margin:0 0 .9rem}
  .card{border:1px solid var(--line);background:var(--bone);padding:.9rem 1.1rem;margin:.55rem 0;border-radius:.4rem}
  .card a.t{color:var(--terracotta);font-weight:600;text-decoration:none;font-size:1.02rem}
  .card a.t:hover{text-decoration:underline}
  .card p{margin:.28rem 0 0;color:var(--rule);font-size:.88rem}
  .also{margin:.45rem 0 0;font-size:.82rem;color:var(--rule)}
  .also a{color:var(--umber);text-decoration:none;border-bottom:1px solid var(--line)}
  .also a:hover{border-bottom-color:var(--umber)}
  code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.84em;background:#fff;border:1px solid var(--line);padding:.03rem .3rem;border-radius:.2rem}
  .note{border-left:3px solid var(--terracotta);padding:.15rem 0 .15rem 1rem;margin:1.6rem 0 0;color:var(--rule);font-size:.9rem}
  .note strong{color:var(--umber)}
  footer{margin-top:3rem;padding-top:1.2rem;border-top:1px solid var(--line);color:var(--rule);font-size:.82rem}
  footer a{color:var(--rule)}
</style></head><body>

<header>
  <h1>Development instances</h1>
  <p class="sub">Every surface we build, in one place — live instances, the design system and its
  tools, and frozen snapshots of earlier iterations. Internal; not linked from the public site.</p>
</header>

<h2>Live instances</h2>
<p class="h2note">The three-instance model (<code>BD-2026-046</code>) — separate surfaces, one brand.</p>
<div class="card">
  <a class="t" href="/">motiu — the co-op website</a>
  <p>This site. Brand v2 + Motiu naming + org-os as a listed project. The Aug 17 landing.</p>
</div>
<div class="card">
  <a class="t" href="https://knowledge.refibcn.cat/">Knowledge instance</a>
  <p>Regenerant Catalunya: the KB engine, source containers, atlas, and the CRM directory.
  <code>/commons</code> and <code>/atlas</code> here now redirect there.</p>
  <p class="also">Also: <a href="https://knowledge.refibcn.cat/review">review lens</a> (password-gated)</p>
</div>
<div class="card">
  <a class="t" href="https://bioregioning.earth">Bioregioning Earth</a>
  <p>The third instance — Andrea's stewarded bioregional surface. Separate property, shared direction.</p>
</div>

<h2>Design system &amp; tools</h2>
<p class="h2note">Built from the current <code>main</code>, so these track whatever is live at the root.</p>
<div class="card">
  <a class="t" href="/lab/">/lab/ — the design system</a>
  <p>The brand book: tokens, atoms, molecules, organisms, documented against what is actually
  wired into the build. Atomic-design structure (<code>BD-2026-041</code>); each page flags what
  is unused, incomplete, or missing.</p>
  <p class="also">Jump to:
    <a href="/lab/colors/">colors</a> ·
    <a href="/lab/typography/">typography</a> ·
    <a href="/lab/motifs/">motifs</a> ·
    <a href="/lab/sections/">sections</a> ·
    <a href="/lab/maps/">maps</a></p>
</div>
<div class="card">
  <a class="t" href="/lab-tools/">/lab-tools/ — raw experiment surfaces</a>
  <p>Pre-Astro standalone tools, kept because they do things the documented lab does not:
  live editors and side-by-side comparators.</p>
  <p class="also">
    <a href="/lab-tools/hero-lab.html">hero lab — Voronoi editor</a> ·
    <a href="/lab-tools/colors-compare.html">colors compare</a> ·
    <a href="/lab-tools/fonts-compare.html">fonts compare</a> ·
    <a href="/lab-tools/motifs-explore.html">motifs explore</a> ·
    <a href="/lab-tools/styles.html">styles</a></p>
</div>

<h2>Frozen iterations — compare &amp; pick</h2>
<p class="h2note">Rebuilt from git tags on every deploy. Historically faithful, so they still read
&ldquo;ReFi BCN&rdquo; — that is the point.</p>
<div class="card">
  <a class="t" href="/versions/andrea-v2/">andrea-v2</a>
  <p>Andrea's pure push, 2026-08-07 — 15-page lab, live Voronoi hero, the palette + type relock.
  Before the Motiu rename and the org-os entry. Tag <code>iteration/andrea-v2</code>.</p>
  <p class="also">Its design system: <a href="/versions/andrea-v2/lab/">/versions/andrea-v2/lab/</a></p>
</div>
<div class="card">
  <a class="t" href="/versions/luiz-i4/">luiz-i4</a>
  <p>Luiz's iteration 4 — editorial deepening: Averia headings, red primary, aurora pillar fields,
  tissue backgrounds. What was live until 2026-08-09. Tag <code>iteration/luiz-4</code>.</p>
  <p class="also">Its design system: <a href="/versions/luiz-i4/lab/">/versions/luiz-i4/lab/</a></p>
</div>

<div class="note">
  <strong>Filing feedback:</strong> walk the current site, then the two snapshots, and say
  <em>what to keep from which</em> — in
  <a href="https://github.com/refibcn/refibcn.github.io/blob/main/docs/DEVELOPMENT.md">DEVELOPMENT.md</a>.
  Live comparisons worth making: Averia vs Geist headings · red vs terracotta primary ·
  aurora fields vs photo-with-hover · compact editorial pillars vs full pillar rows.
</div>

<footer>
  Regenerated on every deploy by <code>scripts/deploy-with-versions.sh</code> — deploy only via
  that script, a bare <code>dist</code> push wipes the snapshots. Add an iteration: tag it, then
  add one line to <code>VERSIONS</code>.
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
echo "==> done — verify with a NEW hashed asset, never a root 200"
