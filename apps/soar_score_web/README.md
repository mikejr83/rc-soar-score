# soar_score_web

The RC Soar Score public site: product information, documentation and help, support, and the published contest results. Next.js (App Router, TypeScript).

```bash
npm install
npm run dev     # http://localhost:3000
npm run build
npm run lint
npm test
```

Set `NEXT_PUBLIC_SOAR_SCORE_API_BASE_URL` to the API server (default `http://localhost:8080`). See `AGENTS.md` for the layout and rules, and `docs/adr/0005-public-site-nextjs.md` for why this app replaced the Flutter public site.
