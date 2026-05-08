#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-${JCODE_SRC:-/tmp/jcode-latest-port}}"
PATCH_DIR="${JCODE_PATCH_DIR:-$HOME/.jcode/patches-v0.12.0-local}"
BASE_REF="${JCODE_BASE_REF:-v0.12.0}"
RUN_TESTS="${JCODE_RUN_TESTS:-1}"

if [[ ! -d "$SRC/.git" ]]; then
  echo "error: '$SRC' is not a git checkout. Pass the Jcode source path as the first arg." >&2
  exit 1
fi
if [[ ! -d "$PATCH_DIR" ]]; then
  echo "error: patch dir not found: $PATCH_DIR" >&2
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
  subject="$(awk '
    /^Subject: / {
      sub(/^Subject: \[[^]]*\] /, "")
      sub(/^Subject: /, "")
      line = $0
      while ((getline nextline) > 0 && nextline ~ /^[[:space:]]/) {
        sub(/^[[:space:]]+/, " ", nextline)
        line = line nextline
      }
      print line
      exit
    }
  ' "$patch")"

  local existing_subjects
  existing_subjects="$(git log --format=%s HEAD --all)"
  if grep -Fxq "$subject" <<<"$existing_subjects"; then
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

shopt -s nullglob
patches=("$PATCH_DIR"/*.patch)
if (( ${#patches[@]} == 0 )); then
  echo "error: no .patch files found in $PATCH_DIR" >&2
  exit 1
fi

for patch in "${patches[@]}"; do
  apply_patch_file "$patch"
done

cargo fmt

if [[ "$RUN_TESTS" != "0" ]]; then
  cargo test cached_openai_compatible_models_are_recognized_for_profile_routing
  cargo test messages_for_provider_
  cargo test agent::tools::tests
  cargo test context_guard
  cargo test interlang::tests
  cargo test display_name_prefers_renamed_title_over_generated_short_name
  cargo test test_handle_server_event_compaction_shows_completion_message_in_remote_mode
  cargo test -p jcode-terminal-launch ghostty_spawn_uses_adjacent_tab_applescript_without_new_window_fallback
fi

cat <<MSG
Done. Local Jcode fixes are applied in: $SRC
Patch dir: $PATCH_DIR
Base ref: $BASE_REF
MSG
