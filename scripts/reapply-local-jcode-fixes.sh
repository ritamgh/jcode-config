#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-${JCODE_SRC:-/tmp/jcode-src}}"
PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../patches" && pwd)"

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

apply_patch_file() {
  local patch="$1"
  local subject
  subject="$(grep -m1 '^Subject: ' "$patch" | sed 's/^Subject: \[[^]]*\] //; s/^Subject: //')"

  if git log --format=%s --all | grep -Fxq "$subject"; then
    echo "✓ already present: $subject"
    return 0
  fi

  echo "→ applying: $subject"
  if git am --3way "$patch"; then
    echo "✓ applied: $subject"
    return 0
  fi

  echo "git am failed, aborting and checking whether patch is already applied..." >&2
  git am --abort || true
  if git apply --reverse --check "$patch" >/dev/null 2>&1; then
    echo "✓ patch content already applied without matching commit: $subject"
    return 0
  fi

  echo "error: failed to apply patch: $patch" >&2
  exit 1
}

apply_patch_file "$PATCH_DIR/0001-opencode-cache-model-routing.patch"
apply_patch_file "$PATCH_DIR/0002-manual-compaction-native-auto.patch"
apply_patch_file "$PATCH_DIR/0003-manual-compaction-live-manager.patch"
apply_patch_file "$PATCH_DIR/0004-renamed-session-title-display-name.patch"
apply_patch_file "$PATCH_DIR/0005-remote-session-rename.patch"
apply_patch_file "$PATCH_DIR/0006-ghostty-child-sessions-tabs.patch"
apply_patch_file "$PATCH_DIR/0007-ghostty-tabs-no-window-fallback.patch"

cargo fmt
cargo test cached_openai_compatible_models_are_recognized_for_profile_routing
cargo test messages_for_provider_
cargo test display_name_prefers_renamed_title_over_generated_short_name
cargo test -p jcode-terminal-launch ghostty_spawn_uses_adjacent_tab_applescript_without_new_window_fallback

echo "Done. Local Jcode fixes are applied in: $SRC"
