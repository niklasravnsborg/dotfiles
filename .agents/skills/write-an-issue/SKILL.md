---
name: write-an-issue
description: Write a GitHub issue for a feature, refactor or architecture change. Use when the user wants to plan work, write a PRD or RFC, create an issue or ticket, or split a plan into issues.
---

# Write an issue

An issue records a problem and what we decided to do about it, so someone can
pick it up without the conversation that produced it.

## Process

1. Explore the code to check the user's assumptions and learn the current
   state. Answer what the code can answer yourself.
2. Ask about the decisions that are still open, one at a time, until the
   design holds together. For a big or fuzzy plan, use the grill-me skill.
3. Write the issue with the template below and create it with
   `gh issue create`, following the github-post skill. Don't ask for review
   first; share the URL.

Small issues stay small. Skip a section rather than pad it.

## Template

```md
## Problem

What's wrong or missing, and why it matters now.

## Decision

What we'll do and the choices behind it: modules and their interfaces,
schema or API changes, alternatives we rejected and why.

## Done when

- [ ] Observable, checkable outcome
- [ ] ...

## Out of scope

What this issue deliberately leaves out.
```

Add a section only when the issue needs it:

- **Interface**, for refactors: the signature, a usage example, and what it
  hides from callers.
- **Testing**, when the approach isn't obvious: which boundary to test and
  which existing tests become redundant.

No file paths or code snippets beyond the interface sketch. They go stale
before the issue is done.

## Splitting

If the work is too big for one PR, propose thin vertical slices. Each slice
is a narrow path through every layer that can be verified on its own. Show
the list with dependencies, agree on it with the user, then create one issue
per slice in dependency order. Each slice issue uses the same template, links
the parent issue and names what it's blocked by.
