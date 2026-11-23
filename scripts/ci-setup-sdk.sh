#!/usr/bin/env bash
# ci-setup-sdk.sh <dxp-clients-branch> [project-folder]
#
# Clones remkoj/optimizely-dxp-clients at the given branch,
# builds it, packs each @remkoj/* package to <project-folder>/.packages/*.tgz,
# then rewrites <project-folder>/package.json to use file: paths so Vercel can
# install from the committed tarballs.
set -euo pipefail

BRANCH="${1:-}"
FOLDER="${2:-.}"

if [ -z "$BRANCH" ]; then
  echo "Usage: ci-setup-sdk.sh <branch> [project-folder]" >&2
  exit 1
fi

WORKSPACE="$(pwd)"
PROJECT_DIR="$WORKSPACE/$FOLDER"
DXP_DIR="$WORKSPACE/dxp-clients"

echo "==> Cloning optimizely-dxp-clients @ $BRANCH"
git clone --branch "$BRANCH" --depth 1 \
  https://github.com/remkoj/optimizely-dxp-clients.git "$DXP_DIR"

# Fix .yarnrc.yml: replace pnpMode with nodeLinker:node-modules
if [ -f "$DXP_DIR/.yarnrc.yml" ]; then
  if grep -q 'pnpMode' "$DXP_DIR/.yarnrc.yml"; then
    sed -i 's/pnpMode:.*/nodeLinker: node-modules/' "$DXP_DIR/.yarnrc.yml"
    echo "  fixed .yarnrc.yml: pnpMode -> nodeLinker:node-modules"
  fi
fi

echo "==> Building dxp-clients"
cd "$DXP_DIR"
corepack yarn install
corepack yarn prepare 2>/dev/null || corepack yarn build

echo "==> Packing tarballs into $FOLDER/.packages/"
PACKAGES=(
  optimizely-cms-nextjs
  optimizely-cms-react
  optimizely-graph-client
  optimizely-cms-api
  optimizely-cms-cli
  optimizely-graph-functions
)

mkdir -p "$PROJECT_DIR/.packages"
for PKG in "${PACKAGES[@]}"; do
  PKG_DIR="$DXP_DIR/packages/$PKG"
  if [ -d "$PKG_DIR" ]; then
    cd "$PKG_DIR"
    corepack yarn pack --out "$PROJECT_DIR/.packages/$PKG.tgz"
    echo "  packed: $FOLDER/.packages/$PKG.tgz"
  else
    echo "  skip (not found): packages/$PKG"
  fi
done

echo "==> Updating $FOLDER/package.json with file: paths"
cd "$PROJECT_DIR"
node - <<'NODE_EOF'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));

const pkgMap = {
  '@remkoj/optimizely-cms-nextjs':      'optimizely-cms-nextjs',
  '@remkoj/optimizely-cms-react':       'optimizely-cms-react',
  '@remkoj/optimizely-graph-client':    'optimizely-graph-client',
  '@remkoj/optimizely-cms-api':         'optimizely-cms-api',
  '@remkoj/optimizely-cms-cli':         'optimizely-cms-cli',
  '@remkoj/optimizely-graph-functions': 'optimizely-graph-functions',
};

for (const section of ['dependencies', 'devDependencies']) {
  if (!pkg[section]) continue;
  for (const [name, subdir] of Object.entries(pkgMap)) {
    if (name in pkg[section] && !pkg[section][name].startsWith('portal:')) {
      const tgzPath = `.packages/${subdir}.tgz`;
      if (fs.existsSync(tgzPath)) {
        pkg[section][name] = `file:${tgzPath}`;
      }
    }
  }
}

// Add NODE_OPTIONS=--preserve-symlinks to compile/watch
for (const script of ['compile', 'watch']) {
  if (pkg.scripts?.[script] && !pkg.scripts[script].includes('NODE_OPTIONS')) {
    pkg.scripts[script] = `NODE_OPTIONS=--preserve-symlinks ${pkg.scripts[script]}`;
  }
}

// Pin graphql resolution to avoid duplicate module issues
pkg.resolutions = { ...(pkg.resolutions || {}), graphql: '16.14.2' };

fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
console.log('  package.json updated with file: tarball paths');
NODE_EOF

echo "==> SDK setup complete (branch: $BRANCH, folder: $FOLDER)"
