#!/usr/bin/env bash
#
# Install or update this repo's Claude Code and Copilot config on this machine.
#
# Claude Code  ->  files copied into ~/.claude
# Copilot      ->  VS Code user settings pointed at copilot/copilot-instructions.md
#
# Safe to run repeatedly. Files that already match are left alone, files that
# differ are backed up before being overwritten, and nothing outside the managed
# list below is ever touched or deleted.
#
#   ./setup.sh              install or update Claude + Copilot config on this machine
#   ./setup.sh --pull       capture Claude changes made on this machine back into the repo
#   ./setup.sh --claude     Claude Code config only
#   ./setup.sh --copilot    Copilot (VS Code) config only
#   ./setup.sh --dry-run    show what would change, touch nothing
#   ./setup.sh --help
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
BACKUP_DIR="$CLAUDE_HOME/backups/ai-config-sync/$(date +%Y%m%d-%H%M%S)"

# Managed files, relative to the repo's claude/ dir and to ~/.claude.
MANAGED_FILES=(
  "CLAUDE.md"
  "settings.json"
  "statusline-command.js"
)
# Managed directories, synced by contents.
MANAGED_DIRS=(
  "skills"
  "agents"
  "commands"
  "hooks"
)

MODE="install"
DRY_RUN=0
DO_CLAUDE=1
DO_COPILOT=1
n_new=0; n_updated=0; n_same=0; n_backed_up=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_BOLD=$'\033[1m'
else
  C_RESET=""; C_DIM=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_BOLD=""
fi

say()  { printf '%s\n' "$*"; }
ok()   { printf '  %snew%s      %s\n'      "$C_GREEN"  "$C_RESET" "$*"; }
upd()  { printf '  %supdated%s  %s\n'      "$C_YELLOW" "$C_RESET" "$*"; }
same() { printf '  %sunchanged%s %s\n'     "$C_DIM"    "$C_RESET" "$*"; }
warn() { printf '  %swarn%s     %s\n'      "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '%serror%s %s\n'           "$C_RED"    "$C_RESET" "$*" >&2; exit 1; }

usage() {
  sed -n '3,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --pull)    MODE="pull" ;;
    --claude)  DO_CLAUDE=1; DO_COPILOT=0 ;;
    --copilot) DO_COPILOT=1; DO_CLAUDE=0 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage ;;
    *)         die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

[ -d "$REPO_DIR/claude" ] || die "no claude/ dir next to setup.sh - run it from inside the ai-config repo"

if [ "$MODE" = "pull" ] && [ "$DO_CLAUDE" -eq 0 ]; then
  die "--pull applies to Claude config only; there is nothing to pull back from VS Code settings"
fi

backup() {
  local dst="$1" rel="$2"
  [ "$DRY_RUN" -eq 1 ] && return 0
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  cp -p "$dst" "$BACKUP_DIR/$rel"
  n_backed_up=$((n_backed_up + 1))
}

# copy_file <src> <dst> <label> — copies only when content differs, backing up first.
copy_file() {
  local src="$1" dst="$2" rel="$3"
  if [ ! -f "$dst" ]; then
    ok "$rel"
    n_new=$((n_new + 1))
    if [ "$DRY_RUN" -eq 0 ]; then
      mkdir -p "$(dirname "$dst")"
      cp -p "$src" "$dst"
    fi
  elif cmp -s "$src" "$dst"; then
    same "$rel"
    n_same=$((n_same + 1))
  else
    upd "$rel"
    n_updated=$((n_updated + 1))
    backup "$dst" "$rel"
    # not `[ ... ] && cp` - as the last statement in the branch that returns 1
    # on a dry run, and set -e then kills the script mid-listing.
    if [ "$DRY_RUN" -eq 0 ]; then
      cp -p "$src" "$dst"
    fi
  fi
}

# copy_tree <src_dir> <dst_dir> <label_prefix> — additive; never deletes on the far side.
copy_tree() {
  local src="$1" dst="$2" prefix="$3"
  [ -d "$src" ] || return 0
  local f rel
  while IFS= read -r -d '' f; do
    rel="${f#"$src"/}"
    [ "$(basename "$rel")" = ".gitkeep" ] && continue
    copy_file "$f" "$dst/$rel" "$prefix/$rel"
  done < <(find "$src" -type f -print0)
}


# ---------------------------------------------------------------------------
# Copilot
#
# Copilot has no global instructions file, so the equivalent is pointing VS Code
# user settings at the repo copy. Repo-level .github/copilot-instructions.md
# files still apply on top of this.
# ---------------------------------------------------------------------------

vscode_settings_path() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) printf '%s' "${APPDATA:-$HOME/AppData/Roaming}/Code/User/settings.json" ;;
    Darwin)               printf '%s' "$HOME/Library/Application Support/Code/User/settings.json" ;;
    *)                    printf '%s' "$HOME/.config/Code/User/settings.json" ;;
  esac
}

find_python() {
  local c
  for c in python3 python py; do
    # command -v is not enough on Windows: python3 is often the Microsoft Store
    # stub, which resolves on PATH but errors out when actually run.
    if command -v "$c" >/dev/null 2>&1 && "$c" -c "" >/dev/null 2>&1; then
      printf '%s' "$c"; return 0
    fi
  done
  return 1
}

setup_copilot() {
  local instr="$REPO_DIR/copilot/copilot-instructions.md"
  local settings py
  settings="$(vscode_settings_path)"

  if [ ! -f "$instr" ]; then
    warn "copilot/copilot-instructions.md not in repo, skipped"
    return 0
  fi
  if [ ! -f "$settings" ]; then
    warn "VS Code settings not found at $settings"
    warn "open VS Code once to create it, then re-run"
    return 0
  fi
  if ! py="$(find_python)"; then
    warn "no python found - cannot edit settings.json safely"
    warn "add this to $settings by hand:"
    warn "  \"github.copilot.chat.codeGeneration.instructions\": [{ \"file\": \"$instr\" }]"
    return 0
  fi

  local rc=0
  AI_INSTR="$instr" AI_SETTINGS="$settings" AI_DRYRUN="$DRY_RUN" AI_BACKUP="$BACKUP_DIR"     "$py" - <<'PYEOF' || rc=$?
import json, os, shutil, sys

instr    = os.environ["AI_INSTR"]
settings = os.environ["AI_SETTINGS"]
dry      = os.environ["AI_DRYRUN"] == "1"
backup   = os.environ["AI_BACKUP"]

KEYS = [
    "github.copilot.chat.codeGeneration.instructions",
    "github.copilot.chat.commitMessageGeneration.instructions",
]

raw = open(settings, encoding="utf-8-sig").read()
try:
    data = json.loads(raw)
except json.JSONDecodeError as e:
    sys.stderr.write("json error: %s\n" % e)
    sys.exit(3)

changed = False
for key in KEYS:
    entries = data.get(key)
    if not isinstance(entries, list):
        entries = [] if entries is None else [entries]
    # drop any previous pointer at this repo's file, wherever it used to live
    kept = [e for e in entries
            if not (isinstance(e, dict) and str(e.get("file", "")).replace("\\", "/").endswith("copilot/copilot-instructions.md"))]
    already = len(kept) != len(entries) and any(
        isinstance(e, dict) and os.path.normcase(os.path.normpath(str(e.get("file", "")))) ==
        os.path.normcase(os.path.normpath(instr)) for e in entries)
    if already and len(kept) == len(entries) - 1:
        print("  unchanged vscode %s" % key.split(".")[-2])
        continue
    kept.append({"file": instr})
    data[key] = kept
    changed = True
    print("  set       vscode %s" % key.split(".")[-2])

if not changed:
    sys.exit(0)
if dry:
    sys.exit(10)

os.makedirs(backup, exist_ok=True)
shutil.copy2(settings, os.path.join(backup, "vscode-settings.json"))
with open(settings, "w", encoding="utf-8", newline="\n") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
    f.write("\n")
sys.exit(10)
PYEOF

  if [ "$rc" -eq 10 ]; then
    n_updated=$((n_updated + 1))
    return 0
  fi
  if [ "$rc" -eq 3 ]; then
    warn "$settings is not valid JSON (comments or a trailing comma?)"
    warn "fix it in VS Code, or add the entry by hand - nothing was written"
    return 0
  fi
  return 0
}

say ""
if [ "$MODE" = "install" ]; then
  if [ "$DO_CLAUDE" -eq 1 ] && [ "$DO_COPILOT" -eq 1 ]; then
    say "${C_BOLD}ai-config${C_RESET}  repo ${C_DIM}->${C_RESET} $CLAUDE_HOME ${C_DIM}+${C_RESET} VS Code settings"
  elif [ "$DO_CLAUDE" -eq 1 ]; then
    say "${C_BOLD}ai-config${C_RESET}  repo ${C_DIM}->${C_RESET} $CLAUDE_HOME"
  else
    say "${C_BOLD}ai-config${C_RESET}  repo ${C_DIM}->${C_RESET} VS Code settings"
  fi
else
  say "${C_BOLD}ai-config${C_RESET}  $CLAUDE_HOME ${C_DIM}->${C_RESET} repo"
fi
[ "$DRY_RUN" -eq 1 ] && say "${C_DIM}dry run - nothing will be written${C_RESET}"
say ""

if [ "$MODE" = "install" ]; then
  if [ "$DO_CLAUDE" -eq 1 ]; then
  [ "$DRY_RUN" -eq 0 ] && mkdir -p "$CLAUDE_HOME"

  settings_changed=0
  for f in "${MANAGED_FILES[@]}"; do
    if [ -f "$REPO_DIR/claude/$f" ]; then
      before=$n_updated
      copy_file "$REPO_DIR/claude/$f" "$CLAUDE_HOME/$f" "$f"
      if [ "$f" = "settings.json" ] && [ "$n_updated" -gt "$before" ]; then
        settings_changed=1
      fi
    else
      warn "$f not in repo, skipped"
    fi
  done

  for d in "${MANAGED_DIRS[@]}"; do
    copy_tree "$REPO_DIR/claude/$d" "$CLAUDE_HOME/$d" "$d"
  done

  if [ "$settings_changed" -eq 1 ]; then
    warn "settings.json was overwritten - Claude Code writes to it directly, so check the"
    warn "backup for machine state the repo copy does not carry"
  fi
  fi

  if [ "$DO_COPILOT" -eq 1 ]; then
    setup_copilot
  fi
else
  for f in "${MANAGED_FILES[@]}"; do
    if [ -f "$CLAUDE_HOME/$f" ]; then
      copy_file "$CLAUDE_HOME/$f" "$REPO_DIR/claude/$f" "$f"
    else
      warn "$f not present in $CLAUDE_HOME, skipped"
    fi
  done

  for d in "${MANAGED_DIRS[@]}"; do
    copy_tree "$CLAUDE_HOME/$d" "$REPO_DIR/claude/$d" "$d"
  done

  # memory/ is deliberately not tracked - it carries project and client specifics.
  if [ -d "$CLAUDE_HOME/memory" ] || [ -d "$REPO_DIR/claude/memory" ]; then
    warn "memory/ is never synced - it stays local by design"
  fi
fi

say ""
say "${C_BOLD}summary${C_RESET}  ${C_GREEN}$n_new new${C_RESET}, ${C_YELLOW}$n_updated updated${C_RESET}, ${C_DIM}$n_same unchanged${C_RESET}"
if [ "$n_backed_up" -gt 0 ]; then
  say "         $n_backed_up file(s) backed up to $BACKUP_DIR"
fi

if [ "$DRY_RUN" -eq 1 ]; then
  say ""
  say "${C_DIM}dry run - re-run without --dry-run to apply${C_RESET}"
elif [ "$MODE" = "install" ] && [ $((n_new + n_updated)) -gt 0 ]; then
  say ""
  say "restart Claude Code to pick up the changes"
elif [ "$MODE" = "pull" ] && [ $((n_new + n_updated)) -gt 0 ]; then
  say ""
  say "review with ${C_BOLD}git diff${C_RESET}, then commit"
fi
say ""
