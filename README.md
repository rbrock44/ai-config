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
  * Custom skills — a `SKILL.md` per folder describing a repeatable workflow. Empty for now
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
* Copy the contents of `claude/` into `~/.claude/`
* Restart Claude Code

---
