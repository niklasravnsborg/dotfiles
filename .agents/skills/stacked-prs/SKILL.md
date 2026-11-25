---
name: stacked-prs
description: Open and maintain dependent pull requests as a GitHub stack with `gh stack`. Use when a PR builds on another PR, and when fixing, rebasing or merging PRs in a stack.
---

# Stacked PRs

A PR that only works on top of another goes into a GitHub stack
(https://docs.github.com/en/pull-requests/get-started/about-stacked-prs).

Open each PR with `gh pr create`, its base being the branch below, then link
them bottom to top with `gh stack link <pr> <pr>...` and run
`gh stack checkout <stack-number>` for local tracking. Skip `gh stack submit`:
it opens drafts with generated titles.

A review fix goes into the commit, and so the layer, that introduced the code.
`gh stack rebase` carries it into the layers above, `gh stack push` pushes
them all. Merge only when I ask, with `gh stack merge <pr>`.
