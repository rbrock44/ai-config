# AI Config

Configuration repo for AI tooling — Claude Code settings, custom skills/agents/commands, and
the cross-repo working preferences both Claude and Copilot follow. No build, no tests, no
deploy; everything here is config and markdown that gets copied to a target location.

## Layout

- `claude/CLAUDE.md` — cross-repo working preferences, installed to `~/.claude/CLAUDE.md` so
  they load in every project
- `copilot/copilot-instructions.md` — the same preferences phrased for Copilot; see
  `copilot/README.md` for the two ways to install it
- `claude/settings.json`, `claude/statusline-command.js` — copied to `~/.claude/`
- `claude/{skills,agents,commands,hooks}/` — custom Claude Code extensions, empty for now
- `shared/` — tool-agnostic prompt material copied into individual project repos

## Conventions

- **`claude/CLAUDE.md` and `copilot/copilot-instructions.md` are mirrors.** They state the
  same rules in tool-appropriate wording. Editing one without the other is a bug — the whole
  point is that both tools behave the same way
- Preference files make claims backed by counts measured from the actual repos ("18 of 21
  workflows", "87% start lowercase"). If a claim is updated, re-measure rather than estimating
- Only cross-repo preferences belong in those two files. Per-repo architecture, commands, and
  code style go in that repo's own `.github/copilot-instructions.md`
- `memory/` is deliberately absent and gitignored — it accumulates project and client
  specifics that do not belong in a public repo
- Nothing machine-specific gets committed: no absolute install paths, no credentials, no
  session or cache state. See `.gitignore`
