#!/usr/bin/env bash
set -euo pipefail
SRC="${1:-${JCODE_SRC:-/tmp/jcode-latest-port}}"
PATCH="${JCODE_MODEL_ROUTE_PATCH:-$HOME/.jcode/patches-v0.12.0-local/0001-Recognize-cached-OpenAI-compatible-models-in-TUI-rou.patch}"
cd "$SRC"
subject="$(grep -m1 '^Subject: ' "$PATCH" | sed 's/^Subject: \[[^]]*\] //; s/^Subject: //')"
existing_subjects="$(git log --format=%s HEAD --all)"
if grep -Fxq "$subject" <<<"$existing_subjects"; then echo "✓ already present: $subject"; exit 0; fi
git am --3way "$PATCH"
cargo fmt
cargo test cached_openai_compatible_models_are_recognized_for_profile_routing
