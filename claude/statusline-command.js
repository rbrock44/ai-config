#!/usr/bin/env node
'use strict';

// Claude Code statusLine script.
// Shows: git repo name : git branch | model | context remaining | rate limits (5h/7d)
// Degrades gracefully when any piece of information is unavailable
// (e.g. outside a git repo, or before the first API response).

const { execSync } = require('child_process');
const fs = require('fs');

function readStdin() {
  try {
    return fs.readFileSync(0, 'utf8');
  } catch (e) {
    return '';
  }
}

let data = {};
try {
  data = JSON.parse(readStdin() || '{}');
} catch (e) {
  data = {};
}

const cwd = data.cwd || (data.workspace && data.workspace.current_dir) || process.cwd();

function run(cmd, cwd) {
  try {
    return execSync(cmd, { cwd, stdio: ['ignore', 'pipe', 'ignore'] })
      .toString()
      .trim();
  } catch (e) {
    return null;
  }
}

function gitInfo(cwd) {
  let repoName = null;
  let branch = null;

  // Prefer repo identity supplied directly by Claude Code, when present.
  const repo = data.workspace && data.workspace.repo;
  if (repo && repo.name) {
    repoName = repo.owner ? `${repo.owner}/${repo.name}` : repo.name;
  }

  branch = run('git --no-optional-locks rev-parse --abbrev-ref HEAD', cwd);
  if (branch === 'HEAD') {
    const short = run('git --no-optional-locks rev-parse --short HEAD', cwd);
    branch = short ? `detached@${short}` : 'detached';
  }

  if (!repoName) {
    const top = run('git --no-optional-locks rev-parse --show-toplevel', cwd);
    if (top) {
      repoName = top.split(/[\\/]/).filter(Boolean).pop();
    }
  }

  // If we couldn't determine a branch, we're most likely not in a git repo at all.
  if (!branch) {
    repoName = repoName && run('git --no-optional-locks rev-parse --is-inside-work-tree', cwd)
      ? repoName
      : null;
  }

  return { repoName, branch };
}

const { repoName, branch } = gitInfo(cwd);

const modelName = data.model && data.model.display_name;

let ctxPart = null;
const ctx = data.context_window;
if (ctx && ctx.remaining_percentage != null) {
  ctxPart = `Ctx ${Math.round(ctx.remaining_percentage)}% left`;
}

let ratePart = null;
if (data.rate_limits) {
  const bits = [];
  const five = data.rate_limits.five_hour;
  const week = data.rate_limits.seven_day;
  if (five && five.used_percentage != null) {
    bits.push(`5h ${Math.round(five.used_percentage)}%`);
  }
  if (week && week.used_percentage != null) {
    bits.push(`7d ${Math.round(week.used_percentage)}%`);
  }
  if (bits.length) {
    ratePart = bits.join(' ');
  }
}

const CYAN = '\x1b[36m';
const MAGENTA = '\x1b[35m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const RESET = '\x1b[0m';

const segments = [];

if (repoName || branch) {
  const repoBranch = [repoName, branch].filter(Boolean).join(':');
  segments.push(`${CYAN}${repoBranch}${RESET}`);
}

if (modelName) {
  segments.push(`${MAGENTA}${modelName}${RESET}`);
}

if (ctxPart) {
  segments.push(`${GREEN}${ctxPart}${RESET}`);
}

if (ratePart) {
  segments.push(`${YELLOW}${ratePart}${RESET}`);
}

process.stdout.write(segments.join('  |  '));
