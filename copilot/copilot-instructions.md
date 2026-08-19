# Working Preferences

Personal rules that apply to every repo.

This file and `claude/CLAUDE.md` are mirrors — the same rules phrased for a different tool.
**Change one, change the other.**

Per-repo architecture, commands, and code conventions do **not** belong here. Those go in
that repo's own `.github/copilot-instructions.md`, below these rules.

---

## No AI attribution

Hard rule, no exceptions.

- No `Co-Authored-By` trailer naming Copilot, Claude, Anthropic, GitHub, or any AI tool
- No "Generated with", "🤖", or similar in commit messages, PR titles, or PR bodies
- No "written by AI", "AI-generated", or tool names in code comments, docs, or READMEs

Commit history should read as if it were written by hand, because that is the point.

---

## Commit messages

Measured across 1,845 hand-authored commits: 87% start lowercase, 98% are subject-only,
median subject length is 21 characters, and 5 use a conventional-commit prefix.

- One line. No body unless the change genuinely cannot be explained in the subject
- Start lowercase
- Start with a present-tense verb: `add`, `update`, `fix`, `remove`, `upgrade`, `refactor`,
  `enhance`, `change`, `create`, `move`, `rename`
- Aim for under 50 characters
- No trailing period
- No `feat:` / `fix:` / `chore:` prefix — conventional commits are not used here
- No emoji, no ticket references, no scopes

Real examples from the history:

```
add jwt decoder
update readme
fix image description bug growing in width
upgrade to angular 22
add test step before deploy
remove email link generator, it's been moved to utilities
```

Do not write:

```
feat: add JWT decoder widget          <- no conventional prefix
Add JWT decoder.                      <- no leading capital, no trailing period
fix: resolve issue #42                <- no prefix, no ticket ref
✨ add jwt decoder                     <- no emoji
```

---

## Git safety

- Never run `git push` — not `push`, not `push --force`, not any variant
- Every commit needs its own explicit approval; approval for one is not approval for the next
- Never `--no-verify` or skip hooks
- Prefer a new commit over amending

---

## Branches

`master` is the default branch, not `main` — 18 of 21 deploy workflows trigger on it.

Work that lands on `main` in a `master` repo silently never deploys. There is no error,
nothing simply happens.

---

## CI

- Add a test step. Never add a lint gate. Currently 15 workflows run tests and 0 run lint,
  and that is deliberate
- Deploys go to `gh-pages` via `peaceiris/actions-gh-pages`
- Node version is pinned via `.nvmrc` where it matters
- Angular repos stay on the current major (14 of 15 are on Angular 22)

---

## Repo conventions

- Repo, folder, and file names are kebab-case
- READMEs follow a set format: title, one-line blockquote purpose, emoji section headings,
  and a Table of Contents linking `What's My Purpose?` / `How to Use` / `Technologies` /
  `Getting Started (Local Setup)`. 25 of 29 READMEs use it
- Repo instructions live in `.github/copilot-instructions.md` as the single source of truth;
  that repo's `CLAUDE.md` is a short pointer to it, not a second copy
- Sites are GitHub Pages on `ryan-brock.com` subdomains, with the subdomain set via `CNAME`

---

## Predicted next steps

End **every** response with a numbered list of the most likely next steps, each with a
confidence percentage, ordered highest first.

```
1. commit and push (60%)
2. run the e2e suite (25%)
3. fix the failing spec (10%)
```

- **Aim for a total near 100%.** Coming in under is fine and expected — the shortfall is the
  unlisted long tail of possibilities not worth enumerating. Never exceed 100%
- A low total is a signal, not sloppiness: it means the next move is genuinely open. Do not
  inflate numbers to close the gap
- Predict what *I* am actually likely to ask for next given what just happened — not a generic
  menu. If a test run failed, `fix the failing spec` is the top entry, not `commit`
- **Never offer a stop option.** No `stop here`, no `nothing further`, no `leave it as is`.
  I stop on my own — listing it wastes a slot on the one option I never need told
- Two entries is fine when only two are plausible. Do not pad to three, and do not recycle the
  same three options response after response
- Short phrases, no explanation attached — the percentage carries the reasoning
- This applies to short responses and to responses that end by asking a question. In that case
  predict which way I will answer

---

## Response style

Caveman. Few words. Few words do better trick.

- Drop articles, pronouns, filler. Short sentences. Fragments fine
- No preamble, no restating my question back at me, no summary of what you just said
- Say what you did and what it means. Nothing else
- **Never compress these:** file paths, commands, flags, numbers, error text, repo and branch
  names. Wrong path costs more than saved words
- Tables, code blocks, and diffs stay normal — caveman applies to prose only
- Bad news stays clear. Terse never means vague about a failure

---

## Scope

Do the task asked. Do not fold in unrelated refactors, dependency bumps, or "while I was in
here" cleanups.

Architecture and code-style conventions vary by repo and are not standardized globally. Read
the repo's own instructions file rather than assuming a house style.
