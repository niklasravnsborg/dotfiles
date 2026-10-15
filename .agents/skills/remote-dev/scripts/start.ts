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

// Configure Serve before stopping the current app, so a failure leaves it running.
await $`tailscale serve --bg --https=443 http://127.0.0.1:${port}`;

// The tmux server has its own environment, so pass this one through explicitly.
const env = Object.entries({
  ...process.env,
  PORT: port,
  DEV_ALLOWED_ORIGIN: host,
})
  .filter(([key]) => !key.startsWith("TMUX"))
  .flatMap(([key, value]) => ["-e", `${key}=${value}`]);

await $`tmux kill-session -t remote-dev`.nothrow().quiet();
await $`tmux new-session -d -s remote-dev -c ${process.cwd()} ${env} ${command} ${";"} set-option -w -t remote-dev remain-on-exit on`;

console.log(
  `Project: ${process.cwd()}\nApp: https://${host}\nLogs: tmux capture-pane -pt remote-dev -S -200`,
);
