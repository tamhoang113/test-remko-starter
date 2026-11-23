# existing-prod — Existing Client Site (Production CMS)

This folder should contain an existing Next.js optimizely-saas-starter client site.
The E2E workflow uses Production CMS credentials and verifies SDK upgrades on real code.

## Setup (one time)

Commit the client site code into this folder:

```bash
cp -r /path/to/client-site/. existing-prod/
git add existing-prod/
git commit -m "feat: add existing client site for prod testing"
git push
```

## What the workflow does (case: existing-prod)

1. Verifies `package.json` exists in this folder
2. Optionally updates `@remkoj/*` versions (`sdk_version` input)
3. Writes `.env` with Production CMS credentials from GitHub Secrets
4. Optionally swaps SDK packages with a dxp-clients branch build (`sdk_branch` input)
5. Runs: `yarn install` -> `nextjs:create` -> `compile` -> `build`
6. Commits updated generated files (`src/components/cms/`, `src/gql/`) to `main`
7. Vercel auto-deploys from the committed build
8. Polls Vercel until READY, then outputs the URL for manual QA check

## Common use cases

| Scenario | Inputs |
|---|---|
| SDK version upgrade | `sdk_version: 5.4.1` |
| CMS content changes (re-generate) | (no SDK params) |
| Branch fix verification | `sdk_branch: bugfix/CMS-50805-token-endpoint-v5` |
