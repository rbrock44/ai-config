---
name: apply-all
description: Apply one instruction across every website repo listed in the directory app. Use when the user says "apply-all", "apply to all repos", "do this everywhere", "across all my sites", or otherwise asks for one change rolled out to the whole portfolio (upgrades, CI edits, SEO tags, dependency bumps, README changes). Detects repos whose stack differs from the majority and asks what to do about them before touching anything.
---

# apply-all

Roll one instruction across the portfolio, surfacing the repos it does not fit cleanly
**before** doing any work rather than improvising per repo.

## The roster

The source of truth is the `applications` array in
`C:\workspace\directory\src\app\app.component.ts` — the sites listed in the directory app.
Derive it fresh each run; never work from a hardcoded list, which goes stale as sites are
added and retired.

```bash
grep -oE "createGithub\('[^']+'\)" /c/workspace/directory/src/app/app.component.ts \
  | sed "s/createGithub('//;s/')//" | sort -u
```

Commented-out entries are excluded on purpose — they are retired or unreleased, so skip them.
Then filter to what is actually cloned under `C:\workspace`; report any listed repo that is
missing locally rather than silently dropping it.

Include `directory` itself when the instruction plausibly applies to it (it is an Angular site
like the rest), even though it does not list itself.

## Step 1 — detect stacks before touching anything

```bash
cd /c/workspace
for r in <roster>; do
  stack="unknown"
  [ -f "$r/angular.json" ] && stack="angular $(grep -oE '"@angular/core": *"[^"]+"' "$r/package.json" | grep -oE '[0-9]+' | head -1)"
  grep -q '"react"' "$r/package.json" 2>/dev/null && stack="react"
  [ -f "$r/build.gradle.kts" ] && stack="kotlin"
  echo "$r: $stack"
done
```

Adapt the probes to the instruction. A CI change should inspect `.github/workflows/*.yml`; a
dependency bump should read `package.json`; an SEO change should look at `index.html`. The
point is the same either way: **know what every repo looks like before editing the first one.**

## Step 2 — split into majority and outliers

Group the roster by whether the instruction applies the same way. Known standing outliers:

| Repo | Why it differs |
| --- | --- |
| `connect-4` | React + Vite, not Angular — Angular instructions do not map directly |
| `blog` | Angular but prerendered with its own content pipeline; deploy differs |
| `directory` | The index site, not listed in its own array |
| `enderle-cattle-company` | Shelved prototype — confirm before changing it at all |

That table is a starting point, not the answer. Re-derive outliers from what Step 1 actually
found; a repo can drift out of the majority at any time.

## Step 3 — ask about the outliers, once, up front

Use `AskUserQuestion` before making any edits. One question per distinct outlier situation,
each offering the realistic choices. For "get on the latest version of Angular" with
`connect-4` in the roster:

> **connect-4 is React + Vite, not Angular. What should happen there?**
> - Skip it — leave it alone, upgrade only the 15 Angular repos
> - Upgrade React instead — the equivalent change for its stack
> - Upgrade its build tooling — Vite and TypeScript to current
> - Stop and let me look at it first

Do not guess, and do not silently skip. Being asked once beforehand is the whole point of the
skill; discovering it mid-run and improvising is the failure mode it exists to prevent.

Ask about the majority group too when the instruction is ambiguous — "latest Angular" could
mean latest stable or matching whatever the others are on.

## Step 4 — work repo by repo

For each repo in the agreed plan:

1. Confirm it is on `master` and the tree is clean; stop and report if not
2. Make the change
3. Verify — build or test if the repo has one, since a failure in repo 3 of 16 probably
   repeats in the rest and is worth catching early
4. **Stop before committing.** Every commit needs its own explicit approval
5. **Never push.** Not once, not at the end, not when asked to "commit and push"

If a repo fails partway, finish the others and report the failure — do not abandon the run,
and do not leave a repo half-edited without saying so.

## Step 5 — report

A table: repo, what changed, verification result, commit status. Name explicitly every repo
skipped and why. If the roster had repos not cloned locally, list them.

## Rules that always apply

These come from `~/.claude/CLAUDE.md` and matter more than usual here, because a mistake
repeats 16 times:

- No AI attribution anywhere — commits, PRs, comments, docs
- Commit messages: lowercase, one line, present-tense verb, under ~50 chars, no
  `feat:`/`chore:` prefix. The same message across repos is fine and expected
- `master` is the default branch, not `main`
- CI gets a test step, never a lint gate
- Do only what was asked. A portfolio-wide run is exactly where unrequested "while I was in
  here" cleanups do the most damage
