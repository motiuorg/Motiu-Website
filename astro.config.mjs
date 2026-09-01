import { defineConfig } from "astro/config";

export default defineConfig({
  // Org root page → served at https://motiu.org/ (base "/").
  // Custom domain motiu.org wired via GitHub Pages + GoDaddy DNS.
  site: "https://motiu.org",
  output: "static",
  build: { format: "directory" },
  // i18n: EN live; CA/ES fall back to EN content until translated.
  // Default locale stays unprefixed (/about); ca/es get /ca/about, /es/about
  // serving EN via rewrite fallback for now.
  i18n: {
    defaultLocale: "en",
    locales: ["en", "ca", "es"],
    routing: { prefixDefaultLocale: false, fallbackType: "rewrite" },
    fallback: { ca: "en", es: "en" },
  },
});
