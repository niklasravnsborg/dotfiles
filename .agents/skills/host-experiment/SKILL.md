---
name: host-experiment
description: Host an experiment, prototype or side service on krake, Niklas's experiments VM, reachable only in his tailnet. Use when the user asks to host, run or put something "on krake" or "on the experiment VM", or to update, list or tear down an experiment there. For production sites use deploy-website, for dev servers on this computer remote-dev.
---

# Host an experiment on krake

krake is a NixOS VM on the tailnet. Every experiment is a Docker Compose project in `/srv/<name>`, published with `tailscale serve` at `https://krake.tail7b070d.ts.net:<port>`. `/srv/README.md` lists what runs there. Never change the VM itself or the staatsqualle repo for an experiment. NixOS has no `apt`, so everything the experiment needs goes into its image.

Connect with `ssh krake` as `nik`. Docker and `tailscale serve` need no sudo. On the first connection pass `-o StrictHostKeyChecking=accept-new`.

## Host

1. Pick a short kebab-case name that isn't in `/srv` yet.
2. Copy the project to `/srv/<name>` with `rsync -a --filter=':- .gitignore' --exclude .git`, which leaves out `node_modules` and `.env`, or `git clone` it there. Add a `compose.yaml`, and a `Dockerfile` if the project has none, in `/srv/<name>` and not in the source repo, unless the user wants them committed. Run the production build, not the dev server.
3. Pick the port: the lowest one from 8001 up that `/srv/README.md` and `tailscale serve status` don't use.
4. Publish only on localhost, so nothing bypasses the tailnet's HTTPS, and keep it running across reboots:

   ```yaml
   services:
     app:
       build: .
       restart: unless-stopped
       ports:
         - "127.0.0.1:8001:3000"
   ```

   Data goes in named volumes. Secrets go in `/srv/<name>/.env`, never in `compose.yaml`. Don't copy production secrets unless the user says so.

5. `docker compose up -d --build`, then `tailscale serve --bg --https=<port> http://localhost:<port>`.
6. Add a row to the table in `/srv/README.md`, creating it if needed: name, port, what it is, source repo or path, date.
7. Verify with `curl -fsS https://krake.tail7b070d.ts.net:<port>` from this computer and check `docker compose logs`.

For LLM calls, CLIProxyAPI serves OpenAI, Claude and Gemini compatible APIs at `http://10.0.0.1:8317` inside krake. Ask the user for its key. krake reaches the internet, but not the LAN or other tailnet devices.

## Update

Copy the changes again, then `docker compose up -d --build` in `/srv/<name>`. The port and serve config stay.

## Tear down

This deletes the experiment's data, so ask first. In `/srv/<name>`: `docker compose down --volumes --rmi local`, then `tailscale serve --https=<port> off`, remove the directory and its row in `/srv/README.md`.

## Handoff

Report the URL, how you verified it and anything the user still has to provide, like secrets.
