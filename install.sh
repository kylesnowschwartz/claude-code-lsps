#!/usr/bin/env bash
#
# Install LSP plugins for Claude Code.
#
# Usage: ./install.sh [claude-dir] [marketplace-source]
#
#   claude-dir          Path to .claude config dir (default: ~/.claude)
#   marketplace-source  Local path or GitHub owner/repo (default: this repo dir)
#
# Examples:
#   ./install.sh                                                  # real install
#   ./install.sh /tmp/claude-test                                 # smoketest settings + binaries
#   ./install.sh ~/.claude kylesnowschwartz/claude-code-lsps      # from GitHub
#
# NOTE: Run from a regular terminal, not inside Claude Code.
#       The `claude plugin` commands use a TUI that needs a real terminal.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${1:-$HOME/.claude}"
MARKETPLACE="${2:-$SCRIPT_DIR}"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

PLUGINS=(
  pyright
  gopls
  typescript-language-server
  lua-language-server
  bash-language-server
  rust-analyzer
  ruby-lsp
)

# Only pyright differs: plugin "pyright" → binary "pyright-langserver"
binary_for() {
  case "$1" in
  pyright) echo "pyright-langserver" ;;
  *) echo "$1" ;;
  esac
}

# --- Step 1: Enable ENABLE_LSP_TOOL ------------------------------------------

echo "==> Enabling ENABLE_LSP_TOOL in $SETTINGS_FILE"
mkdir -p "$CLAUDE_DIR"

if [ ! -f "$SETTINGS_FILE" ]; then
  printf '{\n  "ENABLE_LSP_TOOL": "1"\n}\n' >"$SETTINGS_FILE"
  echo "    created $SETTINGS_FILE"
elif python3 -c "
import json, sys
with open('$SETTINGS_FILE') as f:
    sys.exit(0 if json.load(f).get('ENABLE_LSP_TOOL') == '1' else 1)
" 2>/dev/null; then
  echo "    already enabled"
else
  python3 -c "
import json
path = '$SETTINGS_FILE'
with open(path) as f:
    d = json.load(f)
d['ENABLE_LSP_TOOL'] = '1'
with open(path, 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"
  echo "    added to existing settings"
fi

# --- Step 2: Register marketplace + install plugins --------------------------

echo "==> Registering marketplace: $MARKETPLACE"
claude plugin marketplace add "$MARKETPLACE"

echo "==> Installing plugins"
for plugin in "${PLUGINS[@]}"; do
  echo "    installing ${plugin}@claude-code-lsps ..."
  claude plugin install "${plugin}@claude-code-lsps" || true
done

# --- Step 3: Check binaries ---------------------------------------------------

echo "==> Checking LSP binaries"
missing=0
for plugin in "${PLUGINS[@]}"; do
  binary="$(binary_for "$plugin")"
  if command -v "$binary" &>/dev/null; then
    echo "    $binary -- found"
  else
    echo "    $binary -- MISSING"
    missing=$((missing + 1))
  fi
done

# --- Summary ------------------------------------------------------------------

echo ""
found=$((${#PLUGINS[@]} - missing))
echo "==> $found/${#PLUGINS[@]} LSP binaries on PATH"

if [ "$missing" -gt 0 ]; then
  echo ""
  echo "Missing binaries auto-install on next session start (hooks/check-*.sh)."
  echo "Or install manually:"
  echo "  pip install pyright"
  echo "  go install golang.org/x/tools/gopls@latest"
  echo "  npm i -g typescript-language-server typescript"
  echo "  brew install lua-language-server"
  echo "  brew install bash-language-server"
  echo "  rustup component add rust-analyzer"
  echo "  gem install ruby-lsp"
fi

echo ""
echo "Verify after restarting Claude Code:"
echo "  grep 'Total LSP servers loaded' $CLAUDE_DIR/debug/latest"
