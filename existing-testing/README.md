# existing-testing — Existing Client Site (Testing CMS)

Same as `existing-prod/` but uses Testing CMS credentials (`*.cmstest.optimizely.com`).

## Setup (one time)

Commit the client site code into this folder:

```bash
cp -r /path/to/client-site/. existing-testing/
git add existing-testing/
git commit -m "feat: add existing client site for testing"
git push
```

## What the workflow does (case: existing-testing)

Same pipeline as `existing-prod/` but uses `TEST_*` secrets from GitHub Secrets,
including `TEST_CMS_API_URL` required for `.cmstest.optimizely.com` endpoints.

## Common use cases

| Scenario | Inputs |
|---|---|
| SDK version upgrade | `sdk_version: 5.4.1` |
| CMS content changes (re-generate) | (no SDK params) |
| Branch fix verification | `sdk_branch: bugfix/CMS-50805-token-endpoint-v5` |
