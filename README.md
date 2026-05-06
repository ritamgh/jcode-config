# Jcode local config

This repo tracks only safe, portable Jcode config plus local patch scripts.

Tracked:
- `config.toml`
- `patches/*.patch`
- `scripts/*.sh`

Intentionally ignored:
- auth files and API tokens
- sessions and transcripts
- logs, cache, builds, telemetry, active pids

## Reapply local Jcode source fixes

From anywhere:

```bash
~/.jcode/scripts/reapply-local-jcode-fixes.sh /path/to/jcode/source
```

If no source path is given, the script uses `/tmp/jcode-src`.
It applies:
1. OpenCode Go cached model routing fix.
2. Manual `/compact` native-auto and live-manager fixes.

## Build and install patched Jcode

```bash
~/.jcode/scripts/build-install-patched-jcode.sh /path/to/jcode/source
```

This builds `jcode`, installs it to:

```text
~/.jcode/builds/versions/opencode-cache-fix/jcode
```

and repoints both:

```text
~/.jcode/builds/current/jcode
~/.jcode/builds/stable/jcode
```

Updates may overwrite these symlinks, so rerun the build/install script after `jcode update` until the fixes land upstream.
