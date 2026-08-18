# AI Config

> This project holds my AI tooling configuration — settings, skills, agents, and the prompts that go with them <br/>

---

## 📚 Table of Contents

- [What's My Purpose?](#-whats-my-purpose)
- [How to Use](#-how-to-use)
  - [Claude Code](#claude-code)
  - [Shared](#shared)
- [Technologies](#-technologies)
- [Getting Started (Local Setup)](#-getting-started-local-setup)

---

## 🧠 What's My Purpose?

This project holds the config that shapes how AI tooling behaves across my projects — Claude Code settings, custom skills, subagents, slash commands, hooks, and the standing instructions it works from.

It is scoped to AI tooling only. Editor and IDE config lives in [dev-environment](https://github.com/rbrock44/dev-environment); shell and machine setup lives in [scripts](https://github.com/rbrock44/scripts).

---

## 🚦 How to Use

---

### Claude Code

Target: `~/.claude/` (`C:\Users\<user>\.claude` on Windows)

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

Credentials (`.credentials.json`), history, caches, session state, and telemetry are deliberately **not** captured — see `.gitignore`.

---

### Shared

Tool-agnostic prompt material — `CLAUDE.md` templates and prompt snippets that get copied into individual project repos rather than into a global config directory.

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
