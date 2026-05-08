#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-${JCODE_SRC:-/tmp/jcode-latest-port}}"
INSTALL_DIR="${JCODE_INSTALL_DIR:-$HOME/.jcode/builds/versions/v0.12.0-local-patches}"
SOURCE_SNAPSHOT_DIR="${JCODE_SOURCE_SNAPSHOT_DIR:-$HOME/.jcode/builds/sources/v0.12.0-local-patches}"
PATCH_DIR="${JCODE_PATCH_DIR:-$HOME/.jcode/patches-v0.12.0-local}"
BASE_REF="${JCODE_BASE_REF:-v0.12.0}"

if [[ ! -d "$SRC/.git" ]]; then
  echo "error: '$SRC' is not a git checkout. Pass the Jcode source path as the first arg." >&2
  exit 1
fi

"$HOME/.jcode/scripts/reapply-local-jcode-fixes.sh" "$SRC"

cd "$SRC"
cargo build --release --bin jcode

mkdir -p "$INSTALL_DIR"
tmp_bin="$INSTALL_DIR/jcode.tmp.$$"
cp target/release/jcode "$tmp_bin"
chmod +x "$tmp_bin"
mv "$tmp_bin" "$INSTALL_DIR/jcode"
ln -sfn "$INSTALL_DIR/jcode" "$HOME/.jcode/builds/current/jcode"
ln -sfn "$INSTALL_DIR/jcode" "$HOME/.jcode/builds/stable/jcode"

rm -rf "$SOURCE_SNAPSHOT_DIR"
mkdir -p "$SOURCE_SNAPSHOT_DIR"
tar --exclude='./target' --exclude='./.git' -cf - . | tar -C "$SOURCE_SNAPSHOT_DIR" -xf -
git rev-parse HEAD > "$SOURCE_SNAPSHOT_DIR/.jcode-source-commit"

rm -rf "$PATCH_DIR"
mkdir -p "$PATCH_DIR"
git format-patch -o "$PATCH_DIR" "$BASE_REF..HEAD"

"$INSTALL_DIR/jcode" --version || "$INSTALL_DIR/jcode" version | head -8 || true
cat <<MSG

Installed patched Jcode to:
  $INSTALL_DIR/jcode

Repointed:
  ~/.jcode/builds/current/jcode
  ~/.jcode/builds/stable/jcode

Refreshed:
  $SOURCE_SNAPSHOT_DIR
  $PATCH_DIR
MSG
