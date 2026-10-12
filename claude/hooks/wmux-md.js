// Open a markdown file in wmux, reusing a view that already shows it.
//
//   node wmux-md.js <file>   refresh the view showing <file>, or open one if none
//   node wmux-md.js --hook   PostToolUse on Edit/Write: refresh only, never open
//
// wmux's `markdown <file>` always opens a new view, so repeated edits pile up
// tabs. `markdown get <id>` reports each view's filePath, which is enough to
// find the existing one and `markdown set <id> --file` it instead.
const { execFileSync } = require('child_process');
const path = require('path');

const WMUX_JS = process.env.WMUX_CLI ||
  'C:/Users/rbroc/AppData/Local/Programs/wmux/resources/cli/wmux.js';
const MD_EXT = /\.(md|markdown|mdx)$/i;

function wmux(...args) {
  const out = execFileSync(process.execPath, [WMUX_JS, ...args], {
    encoding: 'utf8', timeout: 5000, stdio: ['ignore', 'pipe', 'ignore'],
  });
  try { return JSON.parse(out); } catch { return null; }
}

const norm = (p) => path.resolve(p).replace(/\//g, '\\').toLowerCase();

function findViews(file) {
  const target = norm(file);
  const surfaces = (wmux('list-surfaces') || {}).surfaces || [];
  return surfaces
    .filter((s) => s.type === 'markdown')
    .filter((s) => {
      const info = wmux('markdown', 'get', s.id);
      return info && info.filePath && norm(info.filePath) === target;
    })
    .map((s) => s.id);
}

function refresh(file, openIfMissing) {
  if (!MD_EXT.test(file)) return;
  const ids = findViews(file);
  for (const id of ids) wmux('markdown', 'set', id, '--file', path.resolve(file));
  if (!ids.length && openIfMissing) wmux('markdown', path.resolve(file));
  if (openIfMissing) console.log(ids.length ? `refreshed ${ids.length} view(s)` : 'opened');
}

if (process.argv[2] === '--hook') {
  let raw = '';
  process.stdin.on('data', (c) => (raw += c));
  process.stdin.on('end', () => {
    try {
      const file = JSON.parse(raw).tool_input?.file_path;
      if (file) refresh(file, false);
    } catch { /* wmux absent or bad input: stay silent */ }
  });
} else if (process.argv[2]) {
  try { refresh(process.argv[2], true); } catch (e) { console.error(e.message); process.exit(1); }
} else {
  console.error('usage: node wmux-md.js <file> | --hook');
  process.exit(2);
}
