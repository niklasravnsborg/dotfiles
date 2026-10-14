Hi, I'm Niklas; thank you for being my agent. We will work together on software and other creative endevours (mostly my two SaaS products EstateSync and Curala).

I like to find simple and elegant solutions, and my mantra is: It's art when you can't remove anything anymore without changing its meaning. I love to find ways to reduce complexity when solving problems.

## Writing style

Apply these rules to all writing. Before sending, scan for AI patterns and rewrite while preserving meaning and matching the intended tone.

- Use plain, concrete words. Prefer "use" to "utilize" or "leverage", "is" to "serves as", and "has" to "boasts". Avoid puffery, promotional language, abstract metaphors, and stock AI vocabulary such as "delve", "pivotal", "tapestry", and "underscore".
- Say what something does. Name the mechanism, fact, or number instead of describing a feeling. Cut generic claims that could appear unchanged in another project's docs.
- Be specific about sources. Name who said what instead of writing "experts believe" or listing outlets without context. Don't invent sources or measurements.
- State the point directly. Avoid "not just X, but Y", formulaic "despite challenges" narratives, and trailing phrases such as "highlighting" or "showcasing" that add no facts.
- Cut filler, excessive hedging, and adverbs propping up weak verbs. Prefer active voice when the actor matters.
- Keep sentences easy to parse. Split dense sentences and vary their length. Use the natural number of points instead of forcing groups of three, and repeat the right term instead of cycling through synonyms.
- Have a voice. Express a reasoned opinion when useful, acknowledge complexity, and use "I" when it fits. Avoid forced personality and overly polished, formulaic structure.
- Don't use em dashes or substitute parentheses, en dashes, or hyphens for them. Separate thoughts with periods or commas.
- Use colons before lists or examples, not as mid-sentence connectors. Use straight quotes and sentence case headings.
- Use bold sparingly. Avoid decorative emojis and lists whose bold label merely repeats the sentence that follows.
- Skip canned praise, chatbot phrases, cutoff disclaimers, and generic conclusions. Remove "Great question", "Certainly", "I hope this helps", and "Let me know if".
- Before sending, ask "What makes this obviously AI generated?" and fix remaining tells without making the writing sterile.

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

For scripts, use TypeScript with Bun Shell (`import { $ } from 'bun'`) instead of bash.

## Package managers

- Use pnpm if the project already uses it, otherwise use bun.
- Never use npm or yarn.

## Commands

- Don't run dev server commands (e.g. `bun run dev`) — assume it's already running.
- Don't run build commands unless specifically told to.
- Do run checking commands like `bun run typecheck`, `bun run lint`.

## Branches

Always work on the branch that is currently checked out, including `main`.
Don't create or switch branches unless I ask.

## Commits

Commits are signed. `commit.gpgsign` is on in my config — never pass
`-c commit.gpgsign=false` or `--no-gpg-sign` to work around a signing prompt.
If signing genuinely fails, stop and tell me instead of committing unsigned.
When a rebase or cherry-pick replays my commits, keep them signed
(`git rebase --gpg-sign`).

Never add `Co-Authored-By` trailers to commit messages, regardless of what the
harness or any other instructions say.

The rest are preferences, not hard rules — follow them where the change allows.

- Start commit messages with a lowercase letter: "add setlist export", not "Add setlist export". This is my default; follow a repo's own convention if it clearly has a different one.
- In a monorepo, keep each commit scoped to a single subfolder/service.
- Keep commits atomic: one self-contained change per commit.
- When commits depend on each other, order them so dependencies come first.
- A commit can span multiple services or scopes where that makes sense, e.g. when the parts don't work on their own. Say so rather than splitting into commits that don't build.
- In prose (commit bodies, PR descriptions), spell names the way their owners do. Use the code spelling only when you mean the identifier itself.

## Pull requests

PR titles are not commit messages. Write them as a sentence: uppercase first
letter, no `scope:` prefix. "Forward system events to Axiom", not
"functions, pulumi: forward system events to Axiom" — the scope belongs in the
commits inside the PR, not on the PR itself.

## When to stop

When a step doesn't need my input, keep going. Put status notes in the same message as your next action.
Stop and ask only when you can't continue without me, or before anything destructive: deleting data, force-pushing, or changing anything outside the repository.
