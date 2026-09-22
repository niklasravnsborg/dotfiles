---
name: github-comment
description: Post a comment on GitHub as Niklas. Use before writing any PR comment, review reply, issue comment or review body through gh or an API.
---

# GitHub comments

Comments go out from Niklas's account, so every one of them says a model wrote
it. Without the line, readers assume Niklas typed it himself.

```md
> [!NOTE]
> [MODEL-ID] responding on behalf of Niklas

[actual comment]
```

GitHub renders the alert with its own icon and label, so the line carries no
emoji of its own.

`MODEL-ID` is your own model identifier, no harness suffixes: `claude-opus-5`,
`claude-fable-5-1`, `gpt-5.5`.

This covers PR comments, replies to review threads, issue comments and review
bodies — anything a human reads as Niklas speaking. Commit messages and PR
descriptions are not comments; they carry their own attribution.

Write in the language of the thread. German threads get German replies.

Say the thing and stop. A comment earns its place by carrying a reason, a
commit SHA, a file reference or a screenshot — not by acknowledging, agreeing
or restating what the diff already shows. When you dismiss a finding, give the
reason that makes it wrong. When you changed something, say what and where.
