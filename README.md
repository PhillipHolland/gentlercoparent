# Gentler Coparent — marketing site

Static site for [www.gentlercoparent.com](https://www.gentlercoparent.com), deployed on Vercel.

## After deploy checklist

### Google Search Console
1. Property verified (Domain DNS and/or URL prefix `https://www.gentlercoparent.com`)
2. Submit sitemap: `https://www.gentlercoparent.com/sitemap.xml`
3. Confirm robots: `https://www.gentlercoparent.com/robots.txt`
4. Request indexing for `/` if needed (URL Inspection)

### Analytics
- **Google Analytics:** `G-M8JJD3HFQM` (gtag on every page)
- **Vercel Web Analytics:** `js/analytics.bundle.js` (production inject)
- App Store clicks fire `app_store_click` in GA (+ Vercel custom event when available)

### Clean URLs
Vercel `cleanUrls` serves `/about` → `about.html`. Old `.html` paths 301 to clean paths.

## Local analytics rebuild

```bash
npm i
npm run build:analytics
```

## App Store

- Listing: https://apps.apple.com/us/app/gentler-coparent/id6742896499
- Free trial messaging: 7 days or 20 messages, whichever comes first
