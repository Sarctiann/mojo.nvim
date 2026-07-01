---
name: mojo-community-post
description: Use when writing community update posts about mojo.nvim for Discord, Reddit, or other channels. Triggered by "write a post", "share an update", "draft a message".
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  scope: project
---

# Community Post

Write short update posts about mojo.nvim for community channels.

## When to use

- A new feature was shipped and needs to be announced
- A VS Code release was audited and the gap is closing
- The plugin reached a milestone worth sharing

## Format

```
🔥 **[mojo.nvim](<repo link>) update**

<1-2 sentences about what triggered this update>

**What's new:**

- **Feature name** *(plugin)* — description
- **Feature name** — description

**What we already support:**

- **Feature name** *(plugin)* — description
- **Feature name** — description
```

## Rules

- Keep posts under Discord's 2000-character limit — run `scripts/check-post-length.py <post.md>` after writing
- Lead with the trigger (new release, new feature, etc.)
- One feature per bullet, grouped logically
- `**Feature** *(plugin)* — desc` for plugin integrations
- `**Feature** — desc` for self-contained features
- Always include the repo link in the title (first line)
- Focus on plugin tooling for Mojo — avoid repo maintenance (scripts, docs, README changes)

## Reference

See `TEMPLATE.md` in this directory for the annotated template with examples.
