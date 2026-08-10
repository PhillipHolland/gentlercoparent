# Gentler Coparent Website — Growth Plan  
### Rank → App Store funnel

**Site:** https://www.gentlercoparent.com  
**Repo:** https://github.com/PhillipHolland/gentlercoparent  
**Git author:** Phillip Holland `<phillip.b.holland@me.com>` only  
**App:** iOS 2.0.3 (86) — continuity: `gentler-coparent-ios/docs/CONTINUITY_APP_STATUS.md`  
**App Store:** https://apps.apple.com/us/app/gentler-coparent/id6742896499  
**Last updated:** 2026-08-10  

---

## 1. Point of the site (north star)

| Goal | Metric |
|------|--------|
| **Rank** for high-intent co-parenting queries | GSC impressions + clicks on money pages |
| **Convert** visitors to App Store installs | `app_store_click` events, trial starts |
| **Trust** as the calm-communication layer (not a court messenger) | Bounce rate, time on page, FAQ engagement |

**Positioning one-liner:**  
*Gentler Coparent is your AI co-parenting coach—Message Shield, Tone Guardian, decree-aware answers, and rewrites you copy into the tools you already use.*

**Not competing as:** OurFamilyWizard / TalkingParents / AppClose (shared court messaging platforms).  
**Competing as:** BestInterest-style AI help, ChatGPT-for-co-parenting, “how do I reply?” intent.

---

## 2. Current site maturity (audit snapshot)

### What you already have (good foundation)
- Static HTML + Vercel; clean deploy path  
- GA4 `G-M8JJD3HFQM` + Vercel analytics + `app_store_click`  
- Smart App Banner (`app-id=6742896499`)  
- Canonical, OG/Twitter basics, Organization + SoftwareApplication JSON-LD  
- `robots.txt` + `sitemap.xml`  
- SEO content pages:
  - `/high-conflict-co-parenting-messages`
  - `/co-parenting-text-message-templates`
- Legal: privacy, usage agreement, about, contact  
- GSC checklist in README  

### Gaps vs product (2.0.3) + ranking goals
| Gap | Impact |
|-----|--------|
| Homepage does not name **Message Shield / Tone Guardian** as products | Misses differentiation + screenshot story |
| Decree = vague “when you add them,” not **citations → open page** | Weak vs “parenting plan / decree questions” intent |
| Feature cards still generic (chat / schedule / calm) | Doesn’t match app starters users see |
| Marketing screenshots not fully wired as social/hero assets | Lower trust / CTR from search & social |
| Only **2** SEO guides | Thin topical authority |
| OG image is logo-sized (338×338), not 1200×630 | Weak link previews |
| No dedicated `/features` or tool landing pages | Hard to rank tool names + long-tail |
| Trial copy “7 days or 20 messages” must stay accurate vs Store | Compliance / trust |
| No explicit “works with court messaging apps” complement story | SEO + positioning vs OFW/TP comparison queries |

**Maturity score (rough):**  
- Technical SEO shell: **B**  
- Content depth: **C+**  
- Product messaging alignment: **C** (pre–2.0.3 framing)  
- Conversion polish: **B−**  

---

## 3. Competitor research (condensed)

### Court / shared-messaging platforms
| Player | Owns | Weak for your wedge |
|--------|------|---------------------|
| **OurFamilyWizard** | Court recognition, ToneMeter, documentation | Expensive; both parents; not “coach for me alone” |
| **TalkingParents** | Immutable records; Sentiment Scanner + rewrite | Still a shared channel product |
| **AppClose** | All-in-one, reviews, value | Coordination suite, not personal AI coach |
| **2Houses / WeParent / Cozi** | Schedules, low conflict | Not high-conflict message help |

### AI / adjacent
| Player | Note |
|--------|------|
| **BestInterest** | Hostile-message screening — closest **category** peer |
| Generic ChatGPT | Zero co-parent UX, no decree-on-device, no Shield/Tone productization |

### Implications for site copy
1. **Complement, don’t replace** court apps → “Write here. Send there.”  
2. Own language: **Shield, Tone Guardian, decree citations, journal** — not “another co-parenting calendar.”  
3. Comparison SERPs (“OFW vs…”) → eventual soft comparison page: *when you need documentation vs when you need a calmer draft.*  
4. Never put **OurFamilyWizard** in the **app UI**; site may say “court co-parenting apps” generically (safer) or name carefully only in blog/compare content if legal/marketing OK.

---

## 4. SEO targeting

### Primary intents (buy / install)
| Intent cluster | Example queries | Target URL |
|----------------|-----------------|------------|
| High-conflict messages | high conflict co-parenting texts, hostile co-parent message | `/high-conflict-…` + homepage |
| How to reply | how to respond to difficult co-parent, calm reply to ex | templates + Shield page |
| Message tone | tone down text before sending, BIFF co-parenting | Tone Guardian page |
| Co-parenting app AI | AI co-parenting app, co-parenting message rewriter | homepage + `/features` |
| Decree / order | ask divorce decree app, parenting plan questions | decree landing |

### Secondary (traffic + authority)
- Co-parenting text templates (exists)  
- Parallel parenting communication  
- Gray rock / BIFF (educational; CTA to app)  
- Expense / schedule message scripts  
- Journal after exchange / documentation for yourself  

### Keyword principles
- Prefer **problem language** users type over brand jargon.  
- One primary intent per page; internal link to App Store CTA.  
- Product names (Shield, Tone Guardian) as secondary keywords once pages exist.  
- Avoid medical/legal advice claims; “not a lawyer” footer on guides.

### Measurement
- GSC: queries, CTR, pages  
- GA4: landing page → `app_store_click` conversion rate  
- Rank track (optional later): top 20 keywords monthly  

---

## 5. Product features to feature on the site (from app 2.0.3)

### P0 — homepage + features hub
1. **Message Shield** — toxicity / heat read + calm reply (you stay in control; we don’t send).  
2. **Tone Guardian** — paste draft → cooler, child-focused version.  
3. **Rewrite / screenshot reply** — attach real message.  
4. **Decree-aware answers** — cite [D1]…, tap to open **your** PDF page; on-device decree privacy.  
5. **Raise an issue calmly** — facts + one clear ask.  

### P1 — trust & retention story  
6. **Journal** — process privately, emotion tags.  
7. **Reply-ready notifications** — leave while AI works.  
8. **Home Screen shortcuts** — New chat / Journal / Rewrite.  
9. **Works with your co-parenting app** — copy/paste workflow.  

### P2 — visual only  
10. Light/dark app icon, polished marketing screens (1290×2796 set).  

### Do not market as hero
- CloudKit, RAG internals, CS extract versions, eval harnesses.

---

## 6. Information architecture (target)

```
/                           Homepage (rank + convert)
/features                   Hub: Shield, Tone, Decree, Journal, Rewrite
/features/message-shield    Tool landing (SEO + deep CTA)
/features/tone-guardian
/features/decree            “Answers from your order”
/high-conflict-…            Guide (exists — refresh CTAs + product names)
/co-parenting-text-…        Templates (exists — refresh)
/guides/…                   New guides (phase 2)
/about /contact /privacy /usage-agreement
```

Clean URLs already (no `.html` in sitemap) — keep Vercel rewrites consistent.

---

## 7. Homepage redesign brief (maturity + convert)

### Above the fold
- **H1:** Problem/outcome oriented (not only “Harmonize”).  
  Example direction: *Calm the next message. Stay focused on the kids.*  
- Sub: coach for high-conflict communication; rewrites, Shield, Tone, decree Q&A.  
- **Primary CTA:** App Store badge (existing tracking).  
- Hero visual: **01_home_starters** marketing frame (or device mock).  
- Trust row: iPhone · Free trial (accurate terms) · On-device decree privacy  

### Sections (scroll)
1. **Three tools** — Shield | Tone | Rewrite (screenshots 02–03).  
2. **Decree** — citations open your order (new visual when ready).  
3. **How it works** — Paste/screenshot → calm draft → copy to your messaging app.  
4. **Journal** — process privately (screenshot 06).  
5. **FAQ** — trial, privacy, not legal advice, works alone or with court apps.  
6. **Final CTA** — App Store.  

### On-page SEO (homepage)
- Title ~60 chars: include *co-parenting* + *communication* or *messages*.  
- Meta description with trial + primary benefit.  
- One H1; H2s for tools.  
- Internal links to both SEO guides + future feature URLs.  
- SoftwareApplication schema: update description to name Shield/Tone/decree.  
- OG: **1200×630** social card (not square logo).  

---

## 8. On-site SEO improvements (checklist)

### Technical
- [ ] Confirm apex → www 308 and HTTPS  
- [ ] Sitemap lastmod bump on every content deploy  
- [ ] Request indexing for new/changed URLs in GSC  
- [ ] 1200×630 `og:image` + `twitter:card` = `summary_large_image`  
- [ ] Image `alt` text with natural keywords on marketing shots  
- [ ] Performance: compress hero/images; keep CSS cache-bust `?v=`  
- [ ] FAQPage schema on homepage FAQ (if not already complete)  
- [ ] BreadcrumbList on guide/feature pages  

### Content
- [ ] Align all pages with **2.0.3 product language**  
- [ ] Unique H1 + meta per page (no duplicates)  
- [ ] CTA blocks every ~1 scroll on long guides  
- [ ] Internal link graph: guides ↔ features ↔ home  
- [ ] Soft “not legal advice” on all guides  

### Conversion SEO (often ignored)
- [ ] Deep links / smart banner already — keep app-argument clean  
- [ ] Same App Store URL everywhere (`id6742896499`)  
- [ ] Track which landing page drives `app_store_click`  

---

## 9. Content / SEO roadmap (phased)

### Phase A — Align & convert (1–2 sprints) **← start here**
1. Homepage rewrite + feature grid matching app.  
2. Wire marketing screenshots (1290×2796 set).  
3. Refresh two existing SEO pages (CTAs + Shield/Tone mentions).  
4. OG social card + schema description update.  
5. Deploy; GSC sitemap + request index.  

### Phase B — Tool landings (rank product terms)
6. `/features` hub.  
7. Message Shield page.  
8. Tone Guardian page.  
9. Decree answers page (privacy-forward).  

### Phase C — Authority content
10. 4–6 new guides (BIFF examples, expense scripts, parallel parenting messages, “before you send”).  
11. Optional: “Court messaging apps vs communication coach” compare.  
12. Expand templates library (indexed, crawlable).  

### Phase D — Growth systems
13. Monthly content cadence (1 guide).  
14. Light backlink outreach (divorce coaches, mediators — careful, ethical).  
15. Review GSC queries → new pages from real impressions.  

---

## 10. Funnel design (every page)

```
Search / Social / Referral
        ↓
  Landing (home | guide | feature)
        ↓
  Value proof (screenshot + one benefit)
        ↓
  App Store CTA  ──→  Trial  ──→  Habit (Shield/Tone/chat)
```

**CTA rules**
- Primary always App Store (not “Contact” or “Learn more” alone).  
- Secondary: soft “See how Message Shield works” → feature section/page.  
- No dead ends: legal pages still footer-link home + store.  

---

## 11. Polish / brand maturity

| Area | Action |
|------|--------|
| Visual system | Match app cream/teal; use new dove icon on web favicon + OG when approved |
| Screenshots | Prefer full marketing frames (headline + phone) already designed |
| Copy voice | Calm, specific, child-first; no Grok/xAI; no “all 50 states lawyer” overclaim |
| Trust | Founders on About; clear trial; privacy of decree on-device |
| Mobile | Sticky App Store sheet already — verify after homepage change |

---

## 12. Success criteria (90 days)

| Metric | Direction |
|--------|-----------|
| Organic clicks (GSC) | Up vs pre-refresh baseline |
| Homepage → App Store click rate | Up |
| Rankings for “high conflict co-parenting messages” + templates | Maintain/improve |
| New tool pages indexed | Shield / Tone / decree live in GSC |
| Message bounce on home | Down |

---

## 13. Execution order (recommended next engineering)

1. **Homepage** product alignment (Shield, Tone, decree, journal, CTAs).  
2. **Assets** — screenshots + 1200×630 OG.  
3. **Refresh** high-conflict + templates pages.  
4. **Deploy** + GSC.  
5. **Feature landings** if Phase A converts.  

App continuity for product claims:  
`https://github.com/PhillipHolland/gentler-coparent-ios/blob/main/docs/CONTINUITY_APP_STATUS.md`

---

## 14. Out of scope (for now)

- Android store page  
- Blog CMS migration (static HTML is fine until content volume hurts)  
- Paid ads (optional later; organic plan first)  
- Naming OFW in app binary  

---

*Living plan — update when Phase A ships or GSC priorities shift.*
