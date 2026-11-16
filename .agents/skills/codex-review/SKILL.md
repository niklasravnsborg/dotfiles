---
name: codex-review
description: Get an independent review of changes, commits or a PR from GPT Sol. Use when the user asks for a Codex or Sol review, or when the model rubric calls for Sol as reviewer.
---

# Codex Review

Sol reviews a change independently. Its findings are evidence, not authority: check each one before you act on it or pass it on.

## 1. Scope

Run `git status --short` and leave unrelated changes alone. Pick the base:

- uncommitted changes: `HEAD`, plus untracked files
- commits on the branch: `git merge-base HEAD origin/main`
- a PR: the merge base with its base branch. Check out its head only if the tree is clean.

Write down the intent and what is out of scope in a sentence or two, and run the checks that cover the change.

## 2. Brief

```
Review only. Do not edit files, commit, push, comment on PRs, or start subagents.
Repo: <abs path>  Base: <sha>  Diff: git diff <base> [-- <paths>] (read untracked files too)
Intent: <what the change is for>
Out of scope: <what it deliberately doesn't do>
Checks: <commands and results, or none>
Read the surrounding code and config, not just the diff. Find bugs, broken callers,
security issues and mismatches with the intent. Flag code, tests or guards the intent
doesn't need, and name the simpler alternative where there is one.
blocker = the intended case is wrong. should = a real bug or risk callers will hit.
nit = everything else, including rare paths and style.
Reply with VERDICT: APPROVE or CHANGES, then one line per finding:
S1 [blocker|should|nit] <file>:<line> <claim and failure mode>. Fix: <suggestion>
```

Add what Sol can't see: the owner's bar of simplicity first, facts about the running system, files you're unsure about.

## 3. Start Sol

Set reasoning effort to high on either route, the Codex default is low.

- **T3 Code**: take the newest Sol under the Codex provider in `orchestrator_capabilities` and start it with `delegate_task`, `role: "review"`, `mode: "async"`.
- **Otherwise** run `codex exec` read-only, with the brief on stdin and only Sol's final reply in the report:

  ```bash
  DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX")"
  # write the brief to $DIR/brief.md
  codex exec -C "$PWD" -s read-only -c model_reasoning_effort="high" \
    -o "$DIR/report.md" - < "$DIR/brief.md" > "$DIR/run.log" 2>&1
  ```

  A review can outlast Bash's 10 minutes, so pass an explicit timeout or run it in the background.

Skip `codex review`: it takes no brief, so Sol never learns the intent. If neither route works, say so instead of using another model. A timeout, an error or an empty reply is not an approval. Don't edit the files under review while Sol runs.

## 4. Check the findings

Judge each finding and its severity yourself, on the brief's scale. Test claims about external systems cheaply against the real thing: a dry run, a validate endpoint, a request that changes nothing.

- Agree: make the smallest fix, preferably by deleting or narrowing code.
- Disagree: say why, with a file and line, a test or command output.
- Nit or out of scope: decline in one line and list it as a follow-up.

Keep a ledger of id, severity, outcome and evidence. Don't agree just to end the review.

## 5. Another round

Only after a fix that changes behavior for a blocker or should, or when the user asks. Start a new review with the same brief, the ledger and the diff since the last round, and ask Sol to check only open ids and changed code.

Stop when Sol approves, after two extra rounds unless a security, auth or data-loss finding is still open, or when a point stays disputed after two replies. In that last case show both sides in a few lines and let the user decide.

## 6. Report

Name the target, route, model and rounds. Separate confirmed, disproved and declined findings, each with a reason. If Sol found nothing, say so and name what it read. Don't push.
