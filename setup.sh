#!/usr/bin/env bash
#
# Install or update this repo's Claude Code config into ~/.claude.
#
# Safe to run repeatedly. Files that already match are left alone, files that
# differ are backed up before being overwritten, and nothing outside the managed
# list below is ever touched or deleted.
#
#   ./setup.sh              install or update  ~/.claude  from this repo
#   ./setup.sh --pull       capture changes made on this machine back into the repo
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
  sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --pull)    MODE="pull" ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage ;;
    *)         die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

[ -d "$REPO_DIR/claude" ] || die "no claude/ dir next to setup.sh - run it from inside the ai-config repo"

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
    [ "$DRY_RUN" -eq 0 ] && cp -p "$src" "$dst"
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

say ""
if [ "$MODE" = "install" ]; then
  say "${C_BOLD}ai-config${C_RESET}  repo ${C_DIM}->${C_RESET} $CLAUDE_HOME"
else
  say "${C_BOLD}ai-config${C_RESET}  $CLAUDE_HOME ${C_DIM}->${C_RESET} repo"
fi
[ "$DRY_RUN" -eq 1 ] && say "${C_DIM}dry run - nothing will be written${C_RESET}"
say ""

if [ "$MODE" = "install" ]; then
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
