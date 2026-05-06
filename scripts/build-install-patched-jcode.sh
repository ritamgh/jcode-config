#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-${JCODE_SRC:-/tmp/jcode-src}}"
INSTALL_DIR="$HOME/.jcode/builds/versions/opencode-cache-fix"

if [[ ! -d "$SRC/.git" ]]; then
  echo "error: '$SRC' is not a git checkout. Pass the Jcode source path as the first arg." >&2
  exit 1
fi

"$HOME/.jcode/scripts/reapply-local-jcode-fixes.sh" "$SRC"

cd "$SRC"
cargo build --release --bin jcode

mkdir -p "$INSTALL_DIR"
cp target/release/jcode "$INSTALL_DIR/jcode"
chmod +x "$INSTALL_DIR/jcode"
ln -sfn "$INSTALL_DIR/jcode" "$HOME/.jcode/builds/current/jcode"
ln -sfn "$INSTALL_DIR/jcode" "$HOME/.jcode/builds/stable/jcode"

"$INSTALL_DIR/jcode" version | head -8 || true
cat <<MSG

Installed patched Jcode to:
  $INSTALL_DIR/jcode

Repointed:
  ~/.jcode/builds/current/jcode
  ~/.jcode/builds/stable/jcode

Restart Jcode to use the installed binary:
  pkill -f "$HOME/.jcode/builds/stable/jcode --provider auto serve" || true
  pkill -f "$HOME/.jcode/builds/current/jcode --fresh-spawn" || true
  jcode
MSG
