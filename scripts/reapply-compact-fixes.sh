#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-${JCODE_SRC:-/tmp/jcode-src}}"
PATCH_DIR="$HOME/.jcode/patches"

if [[ ! -d "$SRC/.git" ]]; then
  echo "error: '$SRC' is not a git checkout. Pass the Jcode source path as the first arg." >&2
  exit 1
fi

cd "$SRC"
if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: source checkout has uncommitted changes. Commit/stash them first: $SRC" >&2
  git status --short >&2
  exit 1
fi

apply_one() {
  local patch="$1"
  local subject
  subject="$(grep -m1 '^Subject: ' "$patch" | sed 's/^Subject: \[[^]]*\] //; s/^Subject: //')"
  if git log --format=%s --all | grep -Fxq "$subject"; then echo "✓ already present: $subject"; return 0; fi
  echo "→ applying: $subject"
  if git am --3way "$patch"; then return 0; fi
  git am --abort || true
  if git apply --reverse --check "$patch" >/dev/null 2>&1; then echo "✓ content already applied: $subject"; return 0; fi
  echo "error: failed to apply $patch" >&2
  exit 1
}

apply_one "$PATCH_DIR/0002-manual-compaction-native-auto.patch"
apply_one "$PATCH_DIR/0003-manual-compaction-live-manager.patch"
apply_one "$PATCH_DIR/0009-collect-pending-compaction-before-status-check.patch"
cargo fmt
cargo test messages_for_provider_
