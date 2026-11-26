---
name: remote-dev
description: Start or configure a local development app for HTTPS access from other devices in Niklas's Tailscale network. Use for remote dev previews and switching the active project or worktree on this computer.
---

# Remote development

The [starter](scripts/start.ts) runs one dev app per computer in the Rex
session `remote-dev` and points Tailscale Serve's HTTPS root at its port. The
URL is `https://<this computer's Tailscale DNS name>`. Niklas can watch the app
in Rex, and it keeps running after the agent session that started it ends.
Starting another app replaces the session, which stops the previous app and
its children.

## Start an app

Read the project's instructions and dev scripts to pick its full dev command
(including backend watchers) and the port the frontend actually listens on.
The starter sets `PORT` and `DEV_ALLOWED_ORIGIN`, but explicit port flags in
the project win. It does not install dependencies, copy secrets or choose a
database.

Run from the target checkout. The dev command gets the login shell's
environment, not the caller's, so wrap it in the project's environment where
it needs one, e.g. `nix develop --command bun run dev` for Nix projects:

```sh
bun "$HOME/dotfiles/.agents/skills/remote-dev/scripts/start.ts" --port 3000 -- bun run dev
```

Check the logs with `rex capture -s remote-dev --trim`, then request the HTTPS
URL. Stop with `rex kill remote-dev`.

A Rex server must already run on this computer. Tailscale must be connected
with Serve/HTTPS enabled. If Serve prints an activation link, give it to the user and retry. Do
not enable Funnel.

If the port is held by a server started outside this skill, ask before
stopping it.

## Prepare a project

Don't change the project's dev scripts for this. It's personal machine tooling.

For Next.js, merge this into the existing config, keeping any existing allowed
origins. The variable is a hostname without protocol or port:

```js
allowedDevOrigins: process.env.DEV_ALLOWED_ORIGIN
  ? [process.env.DEV_ALLOWED_ORIGIN]
  : [],
```

Other frameworks need their own host and HMR configuration.
