# AI Config

> This project holds my AI tooling configuration — settings, skills, agents, and the prompts that go with them <br/>

---

## 📚 Table of Contents

- [What's My Purpose?](#-whats-my-purpose)
- [How to Use](#-how-to-use)
  - [Working Preferences](#working-preferences)
  - [Claude Code](#claude-code)
  - [Copilot](#copilot)
  - [Shared](#shared)
- [Technologies](#-technologies)
- [Getting Started (Local Setup)](#-getting-started-local-setup)

---

## 🧠 What's My Purpose?

This project holds the config that shapes how AI tooling behaves across my projects.

It is scoped to AI tooling

---

## 🚦 How to Use

---

### Working Preferences

The cross-repo rules: no AI attribution, commit message style, git safety, branch and CI
conventions. Written twice, once per tool, because neither tool reads the other's file:

* `claude/CLAUDE.md` → install to `~/.claude/CLAUDE.md`
* `copilot/copilot-instructions.md` → see [Copilot](#copilot) below for the two install paths

**These two files are mirrors. Change one, change the other.**

Only cross-repo preferences go in them. Per-repo architecture, commands, and code style
belong in that repo's own `.github/copilot-instructions.md`.

---

### Claude Code

Target: `~/.claude/` (`C:\Users\<user>\.claude` on Windows)

* `CLAUDE.md`
  * The working preferences above. Loads in every project once installed at `~/.claude/CLAUDE.md`
* `settings.json`
  * Dark theme, opus model, custom status line, `frontend-design` plugin enabled
* `statusline-command.js`
  * Renders the status line. Referenced by `settings.json` as `node ~/.claude/statusline-command.js`
* `memory/`
  * **Deliberately not in this repo.** Standing instructions that persist across sessions live at
    `~/.claude/projects/<project-slug>/memory/` — one fact per file, indexed by `MEMORY.md`.
    They are kept local because they accumulate project and client specifics that do not belong
    in a public repo
* `skills/`
  * Custom skills — a `SKILL.md` per folder describing a repeatable workflow
  * `apply-all/` — say **apply-all** with an instruction to roll it across every website repo
    listed in the `directory` app. Derives the roster from `directory`'s source rather than a
    hardcoded list, detects which repos the instruction does not fit (React `connect-4`, the
    shelved `enderle-cattle-company`, and so on), and asks what to do about them **before**
    editing anything
* `agents/`
  * Custom subagent definitions, one markdown file each with frontmatter for model and tools. Empty for now
* `commands/`
  * Custom slash commands, one markdown file per command. Empty for now
* `hooks/`
  * Scripts fired on tool events. Wired up through `settings.json`, not by dropping files here. Empty for now

Credentials (`.credentials.json`), history, caches, session state, and telemetry are deliberately **not** captured, see `.gitignore`.

---

### Copilot

Copilot has no true global instructions file, so `copilot/copilot-instructions.md` gets
applied one of two ways:

* **Per repo** — paste it at the top of that repo's `.github/copilot-instructions.md`, above
  the repo-specific sections, and add a short `CLAUDE.md` pointing at it. This is the pattern
  already used in `compare-achievements`
* **Globally in VS Code** — point `github.copilot.chat.codeGeneration.instructions` in user
  settings at a local copy

See `copilot/README.md` for both, including the exact settings snippet.

---

### Shared

Tool-agnostic prompt material, `CLAUDE.md` templates and prompt snippets that get copied into individual project repos rather than into a global config directory.

---

## 🛠 Technologies

- Claude Code
- Markdown
- Javascript

---

## 🚀 Getting Started (Local Setup)

* Install [Claude Code](https://claude.com/claude-code)
* Clone [repo](https://github.com/rbrock44/ai-config)
* Run `./setup.sh`
* Restart Claude Code

---

### setup.sh

Sets up **both tools**. Safe to run repeatedly — it is the update path as well as the install
path, so on a second machine it is `git pull && ./setup.sh`.

| Tool | What it does |
| --- | --- |
| Claude Code | copies `claude/` into `~/.claude/` |
| Copilot | points VS Code user settings at `copilot/copilot-instructions.md` |

```bash
./setup.sh              # install or update both
./setup.sh --pull       # capture Claude changes made on this machine back into the repo
./setup.sh --claude     # Claude Code only
./setup.sh --copilot    # Copilot only
./setup.sh --dry-run    # show what would change, touch nothing
./setup.sh --help
```

What it does and does not do:

* Files that already match are reported `unchanged` and left alone — no needless rewrites
* A file that differs is **backed up before being overwritten**, into
  `~/.claude/backups/ai-config-sync/<timestamp>/`
* Only the managed set is touched: `CLAUDE.md`, `settings.json`, `statusline-command.js`, and
  the `skills/`, `agents/`, `commands/`, `hooks/` trees. Everything else in `~/.claude` —
  credentials, history, sessions, caches, plugins — is never read or written
* It never deletes on the far side. Removing a skill from the repo will not remove it from
  `~/.claude`; delete that by hand
* `memory/` is never synced in either direction, by design
* `settings.json` is written by Claude Code itself, so overwriting it can drop machine state.
  The script warns specifically when that file was the one replaced, and points at the backup

`--pull` is the reverse direction, for when a skill or setting was edited on the machine
rather than in the repo. Review with `git diff` before committing. It is Claude-only —
there is nothing to pull back out of VS Code settings.

`CLAUDE_HOME` overrides the target if `~/.claude` is not where the config lives.

**On the Copilot half:** it writes two keys into VS Code user settings —
`github.copilot.chat.codeGeneration.instructions` and
`...commitMessageGeneration.instructions` — both pointing at this repo's file, using an
absolute path derived at runtime so each machine gets its own. Existing settings are preserved
and the file is backed up first. If the settings file has comments or a trailing comma it is
not valid JSON, so the script refuses to touch it and tells you rather than risking your
config. This covers Copilot Chat in VS Code only — not github.com and not other editors, which
still need the per-repo `.github/copilot-instructions.md`. See `copilot/README.md`.

---
