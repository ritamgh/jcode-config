#!/usr/bin/env bash
set -euo pipefail
SRC="${1:-${JCODE_SRC:-/tmp/jcode-latest-port}}"
PATCH_DIR="${JCODE_PATCH_DIR:-$HOME/.jcode/patches-v0.12.0-local}"
export JCODE_RUN_TESTS="${JCODE_RUN_TESTS:-0}"

"$HOME/.jcode/scripts/reapply-local-jcode-fixes.sh" "$SRC"
cd "$SRC"
cargo test messages_for_provider_
cargo test test_handle_server_event_compaction_shows_completion_message_in_remote_mode
