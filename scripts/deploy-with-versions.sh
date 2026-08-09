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

echo "==> versions index"
cat > dist/versions/index.html <<'HTML'
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex"><title>motiu · design iterations</title>
<style>
  body{font-family:ui-sans-serif,system-ui,sans-serif;max-width:44rem;margin:8vh auto;padding:0 1.5rem;color:#221a12;background:#fffffd;line-height:1.55}
  h1{font-size:1.5rem}li{margin:.7rem 0}a{color:#D12B00}small{color:#6b6660;display:block}
</style></head><body>
<h1>Design iterations — compare &amp; pick</h1>
<p>Frozen snapshots for the feedback pass. Walk each, then file section-level
notes in <a href="https://github.com/refibcn/refibcn.github.io/blob/main/docs/DEVELOPMENT.md">DEVELOPMENT.md</a>
saying <em>what to keep from which</em>.</p>
<ul>
  <li><a href="/">current — merged v2.1</a><small>Andrea's brand v2 + Motiu rename + org-os (live site, tag <code>iteration/v2.1-aug17</code>)</small></li>
  <li><a href="/versions/andrea-v2/">andrea-v2</a><small>Andrea's pure push: 15-page /lab, Voronoi hero, 08-07 palette+type relock (tag <code>iteration/andrea-v2</code>)</small></li>
  <li><a href="/versions/luiz-i4/">luiz-i4</a><small>Luiz's iteration 4: editorial deepening, Averia headings, red primary, aurora fields (tag <code>iteration/luiz-4</code>)</small></li>
</ul>
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
