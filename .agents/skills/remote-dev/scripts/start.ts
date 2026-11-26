import { $ } from "bun";

const [flag, port, separator, ...command] = Bun.argv.slice(2);
if (
  flag !== "--port" ||
  !/^\d+$/.test(port ?? "") ||
  separator !== "--" ||
  !command.length
) {
  console.error(
    "Usage: bun start.ts --port <frontend-port> -- <dev-command...>",
  );
  process.exit(1);
}

const status = (await $`tailscale status --json`.json()) as {
  BackendState: string;
  Self?: { DNSName?: string };
};
const host = status.Self?.DNSName?.replace(/\.$/, "");
if (status.BackendState !== "Running" || !host) {
  throw new Error(
    "Connect this computer to Tailscale before starting remote development.",
  );
}

// A Rex server that this script started would belong to the calling agent
// session and stop with it, so only use one that is already running.
const rex = ["rex", "--autostart=false"];
if ((await $`${rex} whoami`.nothrow().quiet()).exitCode !== 0) {
  throw new Error(
    "No Rex server runs on this computer. Connect to it from the Rex app, then start the app again.",
  );
}

// Configure Serve before stopping the current app, so a failure leaves it running.
await $`tailscale serve --bg --https=443 http://127.0.0.1:${port}`;

await $`${rex} kill remote-dev`.nothrow().quiet();
await $`${rex} new remote-dev -c ${process.cwd()} --keep-open -- env PORT=${port} DEV_ALLOWED_ORIGIN=${host} ${command}`.quiet();

console.log(
  `Project: ${process.cwd()}\nApp: https://${host}\nLogs: rex capture -s remote-dev --trim`,
);
