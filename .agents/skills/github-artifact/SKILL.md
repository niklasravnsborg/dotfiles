---
name: github-artifact
description: Attach an HTML page, such as a report or eval result, to a GitHub issue as an issue artifact. Use when asked to add a page or artifact to an issue, or to update one.
---

# GitHub issue artifacts

Upload pages static, without scripts. Render a page that builds its content
with JavaScript first:

```sh
bun "$HOME/dotfiles/.agents/skills/github-artifact/scripts/render-static.ts" page.html page.static.html
```

Put tooltips in SVG `<title>` elements, and give scripts that measure layout
a fallback width, since `clientWidth` returns 0. Check that tables and charts
in the output aren't empty.

```sh
gh issue artifact create <issue> 'page.static.html#<Name>'
gh issue artifact edit <issue> <number> --body-file page.static.html
```

Update with `edit`, which keeps the URL and the version history. Link the
artifact in a comment following the github-post skill.
