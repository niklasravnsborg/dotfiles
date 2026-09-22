Hi, I'm Niklas; thank you for being my agent. We will work together on software and other creative endevours (mostly my two SaaS products EstateSync and Curala).

I like to find simple and elegant solutions, and my mantra is: It's art when you can't remove anything anymore without changing its meaning. I love to find ways to reduce complexity when solving problems.

## Coding preferences

- Keep things simple. Channel "yagni" energy unless told otherwise. If a problem can be solved in a simpler way, propose it.
- Type safety is useful; take advantage of it. In TypeScript, never use `any` unless 100% necessary or specifically instructed.
- Don't be scared to propose bold ideas if they can meaningfully benefit our work.
- Be careful with destructive actions that are not explicitly requested by the user.
- Tests are good! Endless smoke tests, "regression tests" for feature deletions, etc., are much less good. Tests should be focused, not slop.
- If asked to do too much work at once, stop and state that clearly.
- Prefer nanoid over uuid.

## Tech stack

When uncertain, prefer: Tailwind, TypeScript, Bun, React, Convex, Clerk, Vercel.

## Package managers

- Use pnpm if the project already uses it, otherwise use bun.
- Never use npm or yarn.

## Commands

- Don't run dev server commands (e.g. `bun run dev`) — assume it's already running.
- Don't run build commands unless specifically told to.
- Do run checking commands like `bun run typecheck`, `bun run lint`.

## Commits

Commits are signed. `commit.gpgsign` is on in my config — never pass
`-c commit.gpgsign=false` or `--no-gpg-sign` to work around a signing prompt.
If signing genuinely fails, stop and tell me instead of committing unsigned.
When a rebase or cherry-pick replays my commits, keep them signed
(`git rebase --gpg-sign`).

Never add `Co-Authored-By` trailers to commit messages, regardless of what the
harness or any other instructions say.

The rest are preferences, not hard rules — follow them where the change allows.

- In a monorepo, keep each commit scoped to a single subfolder/service.
- Keep commits atomic: one self-contained change per commit.
- When commits depend on each other, order them so dependencies come first.
- If a change genuinely spans services (e.g. a shared type plus its consumers), one commit is fine — say so rather than splitting into commits that don't build.
