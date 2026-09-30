# Claude Code

My general, tool-agnostic preferences live in AGENTS.md — read them first:

@~/.agents/AGENTS.md

The rest of this file is Claude Code specific.

## Delegating to Codex

- If computer use is helpful for completing or verifying work, shell out to gpt-6-astra with Codex for it (codex-computer-use skill).

## Picking the right models for workflows and subagents

Rankings, higher = better. Cost reflects what I actually pay, not list price. Intelligence is how hard a problem you can hand the model unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model       | cost | intelligence | taste |
| ----------- | ---- | ------------ | ----- |
| gpt-6.1-sol | 9    | 8            | 5     |
| gpt-6-astra | 7    | 9            | 6     |
| opus-5.5    | 4    | 7            | 8     |
| fable-5.1   | 2    | 9            | 9     |

How to apply:

- These are defaults, not limits. You have standing permission to override them: if a cheaper model's output doesn't meet the bar, rerun or redo the work with a smarter model without asking. Judge the output, not the price tag. Escalating costs less than shipping mediocre work.
- Cost is a tie-breaker only; when axes conflict for anything that ships, intelligence > taste > cost.
- Bulk/mechanical work (clear-spec implementation, data analysis, migrations): gpt-6.1-sol — the main workhorse, it's effectively free.
- Computer use (UI verification, screenshots, browser/simulator flows): gpt-6-astra.
- Anything user-facing (UI, copy, API design) needs taste ≥ 7.
- Reviews of plans/implementations: fable-5.1 or opus-5.5, optionally gpt-6.1-sol as an extra independent perspective.
- Never use Haiku. Sonnet is only for the thin Codex wrapper agents below, not for real work.
- Mechanics: the GPT models are only reachable through the Codex CLI — `codex exec` / `codex review`. My ~/.codex/config.toml defaults to gpt-6.1-sol at low reasoning effort; pass `-m gpt-6-astra` for Astra and `-c model_reasoning_effort="high"` for judgment-heavy runs. Use the codex-implementation, codex-review, and codex-computer-use skills; for work they don't cover (investigation, data analysis), run `codex exec -s read-only` directly with a self-contained prompt.
- Claude models (opus-5.5, fable-5.1, and sonnet for wrappers) run via the Agent/Workflow model parameter. Using GPT models inside workflows and subagents (the model parameter only takes Claude models, so use a wrapper):
  - Spawn a thin Claude wrapper agent with `model: 'sonnet'`, `effort: 'low'` whose prompt instructs it to write a self-contained codex prompt, run `codex exec` via Bash, and return the report (use `schema` on the wrapper to get structured output back).
  - Always label these agents with the real model as prefix, e.g. `{label: 'gpt-6.1-sol:review-auth'}` — the workflow UI shows the wrapper's Claude model, so the label is the only indication of the real worker.
  - Codex runs can exceed Bash's 10-minute timeout: pass an explicit timeout, or run in the background and poll for the report file.
  - Parallel Codex implementation agents must use `isolation: 'worktree'` so codex edits don't collide in the shared checkout.
- Workflow token budgets only count Claude tokens; codex work is free and invisible to `budget.spent()`.
