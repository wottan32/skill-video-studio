#!/usr/bin/env bash
# Optional local config for host-specific infra — sourced by tts.sh / avatar.sh / variant.sh.
# These features are "bring your own": narration needs any OpenAI-compatible TTS endpoint, the
# avatar needs any SSH host with a LatentSync checkout. Put your values ONCE in a file that is
# NOT committed (default: ~/.config/devrel-video/env, override with DEVREL_VIDEO_ENV), e.g.:
#
#   ORPHEUS_URL="https://my-tts.example.com/v1/audio/speech"   # OpenAI-compatible /v1/audio/speech
#   ORPHEUS_KEY="sk-..."                                        # bearer token (omit if the endpoint needs none)
#   AVATAR_HOST="user@gpu-host"                                 # ssh target for the LatentSync GPU box
#   LS_DIR="\$HOME/LatentSync"                                   # LatentSync checkout path on that host
#
# ponytail: no config framework — just source a dotfile if it exists. Env vars already set win.
# The file is EXECUTED as shell, so it must be yours alone: owned by you and not writable by anyone else
# (`chmod 600`). A file that fails that check is skipped with a warning instead of being sourced.
_cfg="${DEVREL_VIDEO_ENV:-$HOME/.config/devrel-video/env}"
if [ -f "$_cfg" ]; then                  # `if` (not `&&`) so a missing file returns 0 under `set -e`
  _mode="$(stat -c '%a' "$_cfg" 2>/dev/null || stat -f '%Lp' "$_cfg" 2>/dev/null || echo 600)"
  if [ ! -O "$_cfg" ] || [ $(( 8#$_mode & 8#022 )) -ne 0 ]; then   # group/other write bit set?
    echo "WARN: $_cfg must be owned by you and not group/world-writable (chmod 600) — not sourced" >&2
  else
    . "$_cfg"
  fi
  unset _mode
fi
