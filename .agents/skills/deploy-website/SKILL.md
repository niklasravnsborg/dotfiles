---
name: deploy-website
description: Deploy a website or web app to production on Cloudflare. Use when the user asks to deploy, publish, host, or put a site online, or to set up its domain or automatic deploys. Skip if they name another provider. For temporary previews on their own devices, use remote-dev.
---

# Deploy a website

Deploy the local checkout, including uncommitted changes, with `bunx wrangler`. If the project already deploys somewhere else, ask before migrating.

## Setup

1. `wrangler whoami`. If not logged in, run `wrangler login` and wait for the user to approve it in the browser. If several accounts could match, ask which one.
2. Run the project's build if it has one; a deploy request counts as permission. Serve the build output directly. Buildless sites need no Worker script. Framework apps that need a server use the Cloudflare adapter. Never upload server code or secrets as assets.
3. Update the existing Wrangler config, or add `wrangler.jsonc`, and add `.wrangler/` to `.gitignore`:

   ```jsonc
   {
     "name": "project-name",
     "compatibility_date": "<today>",
     "assets": { "directory": "./dist" },
     "routes": [{ "pattern": "example.com", "custom_domain": true }],
   }
   ```

   Use the domain the user names. Its zone must be in the selected Cloudflare account; if it isn't, tell the user before deploying. If they name none, use `<project-name>.niklasravnsborg.com`. Before claiming a Worker name or hostname, check it doesn't already exist.

4. `wrangler deploy`, then verify HTTPS and a few assets on the live hostname.

## GitHub Actions (only when asked)

Add a workflow on the production branch with a manual trigger. Run checks first, then deploy with `cloudflare/wrangler-action` at a pinned version. Serialize deploys with `concurrency`. Store a scoped `CLOUDFLARE_API_TOKEN` as a repo secret and the account ID as a repo variable, never the local OAuth token. If creating the token needs the user, tell them the exact step. Don't also enable Cloudflare's Git builds. Run the workflow once and verify the result.

## Handoff

Report the live URL, how you verified it, any blockers, and what was committed or pushed.

Docs: [Static Assets](https://developers.cloudflare.com/workers/static-assets/) · [Custom domains](https://developers.cloudflare.com/workers/configuration/routing/custom-domains/) · [GitHub Actions](https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/)
