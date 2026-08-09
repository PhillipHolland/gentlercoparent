import { inject } from '@vercel/analytics';

// Static HTML site (not Next.js) — use inject(), not <Analytics />.
// Force production so esbuild can't leave NODE_ENV=development in the bundle
// (that was loading the debug script and skipping real page views).
inject({ mode: 'production' });
