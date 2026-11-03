#!/usr/bin/env bash
# Pinned versions of every tool the scripts download or run through npx/go/curl — sourced by the
# capture/render helpers. Bump them HERE, on purpose, after reading the upstream release notes;
# never `@latest` in a script (a hijacked release would run on your machine with no change to this repo).
# See docs/security-audit.md for the review that introduced the pins.
HYPERFRAMES_VERSION="${HYPERFRAMES_VERSION:-0.9.6}"            # npm: hyperframes (HeyGen)  — many releases/day, review diffs before bumping
PLAYWRIGHT_CLI_VERSION="${PLAYWRIGHT_CLI_VERSION:-0.1.23}"    # npm: @playwright/cli (Microsoft)
VHS_VERSION="${VHS_VERSION:-v0.12.1}"                          # go: github.com/charmbracelet/vhs
TTYD_VERSION="${TTYD_VERSION:-1.7.7}"                          # github release: tsl0922/ttyd
TTYD_SHA256_X86_64="${TTYD_SHA256_X86_64:-8a217c968aba172e0dbf3f34447218dc015bc4d5e59bf51db2f2cd12b7be4f55}"  # from the release's SHA256SUMS
