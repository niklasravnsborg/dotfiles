---
name: github-post
description: Post an issue, comment or review on GitHub as Niklas. Use before writing any issue, issue comment, PR comment, review reply or review body through gh or an API.
---

# GitHub posts

Posts go out from Niklas's account, so every one of them says a model wrote
it. Without the line, readers assume Niklas typed it himself.

```md
> [!NOTE]
> Written by [MODEL-ID] on behalf of Niklas

[actual post]
```

GitHub renders the alert with its own icon and label, so the line carries no
emoji of its own.

`MODEL-ID` is your own model identifier, no harness suffixes: `claude-opus-5`,
`claude-fable-5-1`, `gpt-6.1-sol`.

This covers issue bodies, issue comments, PR comments, replies to review
threads and review bodies. Anything a human reads as Niklas speaking needs the
line. Commit messages and PR descriptions carry their own attribution.

Say the thing and stop. A post earns its place by carrying a reason, a commit
SHA, a file reference or a screenshot. Acknowledging, agreeing or restating
what the diff already shows adds nothing. When you dismiss a finding, give the
reason that makes it wrong. When you changed something, say what and where.
