# Copilot

`copilot-instructions.md` holds the cross-repo preferences. Copilot has no true global
instructions file, so there are two ways to apply it.

## Per repo (preferred, matches existing repos)

Paste the contents at the **top** of the repo's `.github/copilot-instructions.md`, above the
repo-specific `## Commands` / `## Architecture` / `## Conventions` sections, then add a
`CLAUDE.md` pointing at it:

```markdown
# <Repo Name>

See `.github/copilot-instructions.md` for architecture, commands, and conventions —
that file is the single source of truth for repo instructions, kept in sync for both
Copilot and Claude Code.
```

This is the pattern already used in `compare-achievements`.

## Globally in VS Code

Point VS Code's user settings at a local copy so it applies everywhere without editing each
repo. Add to `%APPDATA%\Code\User\settings.json` (tracked in the `dev-environment` repo):

```json
"github.copilot.chat.codeGeneration.instructions": [
  { "file": "C:\workspace\ai-config\copilot\copilot-instructions.md" }
]
```

Repo-level `.github/copilot-instructions.md` files still apply on top of this, so the two
approaches compose. The global setting only reaches Copilot Chat in VS Code — it does not
apply to Copilot on github.com or in other editors, which is why the per-repo copy is still
worth having.
