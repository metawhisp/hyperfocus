# Hyperfocus landing — deploy handoff

Production-ready landing page for **hyperfocus.monster**. This folder is the whole site.
Static, self-contained, **no build step, no dependencies, zero external network requests**
(the Doto font is subset + embedded; nothing is fetched at runtime).

## Files
| File | Purpose |
|---|---|
| `index.html` | The entire page (interactive hero). Self-contained. 26 KB. |
| `CNAME` | Custom domain for GitHub Pages — contains `hyperfocus.monster`. |
| `.nojekyll` | Tells GitHub Pages to serve files as-is (no Jekyll processing). |

Source prototype lives at `../prototypes/hero-orb-live.html`. `index.html` is its production
build: Doto font subset (600 KB → 3.7 KB), meta/OG tags + favicon added, Download CTA turned
into a placeholder (see below).

## ⚠️ ONE required edit before publishing
The Download button href is a placeholder token. Replace **`__DMG_URL__`** in `index.html`
with the real macOS `.dmg` download URL:

```bash
sed -i '' 's#__DMG_URL__#https://REAL-DMG-LINK-HERE#' index.html
```

There is exactly one occurrence. Until it's replaced the "Download for macOS" button points nowhere.

## Deploy — GitHub Pages (recommended; `gh` is authed as `metawhisp`)
The domain is already on Cloudflare, so GitHub Pages hosts the files and Cloudflare DNS points at it.

1. **Put the site on a Pages source.** Either a dedicated repo (e.g. `metawhisp/hyperfocus-site`)
   or a `gh-pages` branch. The published root must contain `index.html`, `CNAME`, `.nojekyll`.
   Example with a new repo:
   ```bash
   gh repo create metawhisp/hyperfocus-site --public --disable-issues
   cd /tmp && git clone https://github.com/metawhisp/hyperfocus-site && cd hyperfocus-site
   cp /path/to/site/{index.html,CNAME,.nojekyll} .
   git add -A && git commit -m "Launch hyperfocus.monster landing" && git push
   ```
2. **Enable Pages** (root of the default branch):
   ```bash
   gh api -X POST repos/metawhisp/hyperfocus-site/pages -f 'source[branch]=main' -f 'source[path]=/'
   ```
   The `CNAME` file sets the custom domain to `hyperfocus.monster` automatically.

3. **Cloudflare DNS** (NS: `kara/charles.ns.cloudflare.com`; the domain currently returns nothing).
   Point apex + www at GitHub Pages:
   - `A  @  185.199.108.153` · `185.199.109.153` · `185.199.110.153` · `185.199.111.153`
   - `CNAME  www  metawhisp.github.io`
   - Set these records to **DNS only (grey cloud)** first so GitHub can issue the Let's Encrypt
     cert for the custom domain. Once HTTPS is live you can re-enable the Cloudflare proxy
     (orange cloud) with SSL mode **Full**.
4. In the repo's **Pages settings**, confirm custom domain `hyperfocus.monster` and tick
   **Enforce HTTPS** once the certificate is provisioned.

## Verify after publish
```bash
curl -sI https://hyperfocus.monster/ | grep -i '^HTTP'          # expect 200
curl -s  https://hyperfocus.monster/ | grep -c '__DMG_URL__'    # expect 0 (placeholder replaced)
```
Then open it: the orb should chase the cursor; clicking the orb toggles the noise/hyperfocus
demo; the Download button should hit the real DMG.

## Notes
- **Font:** Doto (the app's dot-matrix display face) is subset to Basic Latin and embedded as
  woff2. If the visible copy ever gains characters outside Basic Latin, re-subset from
  `../Hyperfocus/Resources/Fonts/Doto-Variable.ttf`.
- **OG image:** no social-preview image yet (TODO) — add an `og:image` when one exists.
- **What it is:** hero-only launch page. Body copy, palette, and the orb match the macOS app's
  FLIGHT DECK design. All copy is truthful (no invented stats/testimonials).
