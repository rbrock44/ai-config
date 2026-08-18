# Working Preferences

Personal rules that apply to every repo. Install to `~/.claude/CLAUDE.md` so they load in
every project.

This file and `copilot/copilot-instructions.md` are mirrors — the same rules phrased for a
different tool. **Change one, change the other.**

Per-repo architecture, commands, and code conventions do **not** belong here. Those go in
that repo's own `.github/copilot-instructions.md`.

---

## 🚫 No AI attribution

Hard rule, no exceptions.

- No `Co-Authored-By: Claude` (or any AI/Anthropic/Copilot) trailer on commits
- No "Generated with Claude Code", "🤖", or similar in commit messages, PR titles, or PR bodies
- No "written by AI", "AI-generated", or tool names in code comments, docs, or READMEs
- Applies to commits made by subagents too — when briefing one that will commit, say so explicitly

Commit history should read as if it were written by hand, because that is the point.

---

## 📝 Commit messages

Measured across 1,845 hand-authored commits: 87% start lowercase, 98% are subject-only,
median subject length is 21 characters, and 5 use a conventional-commit prefix.

**The form:**

- One line. No body unless the change genuinely cannot be explained in the subject
- Start lowercase
- Start with a present-tense verb: `add`, `update`, `fix`, `remove`, `upgrade`, `refactor`,
  `enhance`, `change`, `create`, `move`, `rename`
- Aim for under 50 characters
- No trailing period
- No `feat:` / `fix:` / `chore:` prefix — conventional commits are not used here
- No emoji, no ticket references, no scopes

**Real examples from the history:**

```
add jwt decoder
update readme
fix image description bug growing in width
upgrade to angular 22
add test step before deploy
remove email link generator, it's been moved to utilities
```

**Do not write:**

```
feat: add JWT decoder widget          <- no conventional prefix
Add JWT decoder.                      <- no leading capital, no trailing period
fix: resolve issue #42                <- no prefix, no ticket ref
✨ add jwt decoder                     <- no emoji
```

---

## 🔒 Git safety

- **Never run `git push`.** Not `push`, not `push --force`, not any variant. Even when asked
  to "commit and push" — stop after the commit and say so
- **Every commit needs its own explicit approval.** Approval for one commit is not approval
  for the next one, and "commits in general" is not approval for any specific commit
- Never `--no-verify` or skip hooks
- Prefer a new commit over amending

---

## 🌿 Branches

`master` is the default branch, not `main` — 18 of 21 deploy workflows trigger on it.

Work that lands on `main` in a `master` repo **silently never deploys**. There is no error,
nothing simply happens. Check which branch the workflow actually watches before assuming a
deploy is broken.

---

## ⚙️ CI

- **Add a test step. Never add a lint gate.** Currently 15 workflows run tests and 0 run lint.
  This is deliberate — if a lint gate is wanted it will be asked for explicitly
- Deploys go to `gh-pages` via `peaceiris/actions-gh-pages` (18 workflows use it)
- Node version is pinned via `.nvmrc` where it matters
- Angular repos stay on the current major (14 of 15 are on Angular 22) — upgrades are routine,
  not risky changes to avoid

---

## 📁 Repo conventions

- Repo, folder, and file names are kebab-case
- READMEs follow a set format: title, one-line blockquote purpose, emoji section headings,
  and a Table of Contents linking `What's My Purpose?` / `How to Use` / `Technologies` /
  `Getting Started (Local Setup)`. 25 of 29 READMEs use it — match it when adding one
- Repo instructions live in `.github/copilot-instructions.md` as the single source of truth.
  That repo's `CLAUDE.md` is a short pointer to it, not a second copy
- Sites are GitHub Pages on `ryan-brock.com` subdomains, with the subdomain set via `CNAME`

---

## 🧭 Scope

Do the task asked. Do not fold in unrelated refactors, dependency bumps, or "while I was in
here" cleanups — raise them separately and let them be chosen.

Architecture and code-style conventions vary by repo and are not standardized globally. Read
the repo's own instructions file rather than assuming a house style.
