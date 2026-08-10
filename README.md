# Gentler Coparent — marketing site

Static site for [www.gentlercoparent.com](https://www.gentlercoparent.com), deployed on Vercel.

## Google Search Console (do this after each content deploy)

You must click these in **your** GSC account (we can’t log in for you):

### 1. Submit / refresh sitemap
1. Open [Google Search Console](https://search.google.com/search-console)
2. Select property **`https://www.gentlercoparent.com`** (or Domain `gentlercoparent.com`)
3. Left menu → **Sitemaps**
4. Enter: `https://www.gentlercoparent.com/sitemap.xml`  
   (or just `sitemap.xml` if the property is already URL-prefix www)
5. **Submit**  
   If it already exists, open it and confirm **Success** / new URLs discovered.

### 2. Request indexing (priority URLs)
For each URL below: **URL Inspection** (top bar) → paste URL → **Request indexing**

| Priority | URL |
|----------|-----|
| 1 | `https://www.gentlercoparent.com/` |
| 2 | `https://www.gentlercoparent.com/high-conflict-co-parenting-messages` |
| 3 | `https://www.gentlercoparent.com/co-parenting-text-message-templates` |
| 4 | `https://www.gentlercoparent.com/features` |
| 5 | `https://www.gentlercoparent.com/features/message-shield` |
| 6 | `https://www.gentlercoparent.com/biff-co-parenting-messages` |
| 7 | `https://www.gentlercoparent.com/co-parenting-expense-messages` |
| 8 | `https://www.gentlercoparent.com/about` |

Indexing is a **request**, not instant. Can take hours–days.

### 3. Quick health checks
- [robots.txt](https://www.gentlercoparent.com/robots.txt) — `Allow: /` + sitemap line  
- [sitemap.xml](https://www.gentlercoparent.com/sitemap.xml) — lists all public pages  
- Prefer **www** (apex 308s to www)

## Analytics
- **Google Analytics:** `G-M8JJD3HFQM`
- **Vercel Web Analytics:** `js/analytics.bundle.js`
- App Store clicks → `app_store_click`

## Key pages
| Path | Purpose |
|------|---------|
| `/` | Homepage |
| `/high-conflict-co-parenting-messages` | SEO guide |
| `/co-parenting-text-message-templates` | SEO templates |
| `/features` | Product hub |
| `/features/message-shield` | Message Shield |
| `/features/tone-guardian` | Tone Guardian |
| `/features/decree` | Decree-aware answers |
| `/biff-co-parenting-messages` | BIFF guide |
| `/co-parenting-expense-messages` | Expense texts |
| `/parallel-parenting-communication` | Parallel parenting |
| `/before-you-send-co-parenting-text` | Before you send checklist |
| `/co-parenting-app-vs-message-coach` | Portal vs coach |
| `/about` | Founders |
| `/contact` | Form |

## Local analytics rebuild
```bash
npm i
npm run build:analytics
```

## App Store
https://apps.apple.com/us/app/gentler-coparent/id6742896499  
Free trial: 7 days or 20 messages, whichever comes first.
