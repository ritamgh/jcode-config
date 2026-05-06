#!/usr/bin/env bash
set -euo pipefail
SRC="${1:-${JCODE_SRC:-/tmp/jcode-src}}"
PATCH="$HOME/.jcode/patches/0001-opencode-cache-model-routing.patch"
cd "$SRC"
subject="$(grep -m1 '^Subject: ' "$PATCH" | sed 's/^Subject: \[[^]]*\] //; s/^Subject: //')"
if git log --format=%s --all | grep -Fxq "$subject"; then echo "✓ already present: $subject"; exit 0; fi
git am --3way "$PATCH"
cargo fmt
cargo test cached_openai_compatible_models_are_recognized_for_profile_routing
