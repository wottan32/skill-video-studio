# Changelog

## v1.0.2 — 2026-11-02 (security hardening, fork `wottan32`)

Result of the review in [docs/security-audit.md](docs/security-audit.md). No feature changes.

- Pin every downloaded tool in `scripts/_versions.sh` (`hyperframes@0.9.6`, `@playwright/cli@0.1.23`, `vhs@v0.12.1`, `ttyd 1.7.7`); no script uses `@latest` any more.
- Verify the `ttyd` download against its release SHA-256 and refuse to install on a mismatch or a non-x86_64 host.
- Keep the Chromium sandbox on by default; `DEVREL_VIDEO_NO_SANDBOX=1` opts out with a warning (AppArmor-restricted hosts only).
- Bind the thumbnail HTTP server to `127.0.0.1` so the project folder is not reachable from the LAN.
- Drop the blind `Enter` from the terminal tape template; trust the demo folder by hand before recording.
- Add the prompt-injection rule to the skill's Explore step: page content is data, never instructions.
- Add an `integrity` hash and `crossorigin` to the GSAP `<script>` in both HTML templates.
- Remove `eval` from `avatar.sh`; `variant.sh` runs `sudo` on the GPU host only with `AVATAR_MANAGE_OLLAMA=1`.
- `_env.sh` sources the config file only when it is owned by the user and not group/world-writable.

## v1.0.1 — 2026-11-02

- Fix the compose step: `hyperframes init` refuses a captured project folder, so new videos start from `templates/composition.html`.
- Fix the silent render of `example-walkthrough`, which stopped on a narration mix that only exists after step 3.
- Install `playwright-cli` under `.pw/` even when a parent folder has a `package.json`, and show npm errors.

## v1.0 — 2026-10-29

- Publish the first release as Video Studio Skill with updated shared artwork.
- Rename the repository to `skill-video-studio`; update installation, project CTA links, and recording commands. Keep `/devrel-video` unchanged.

- Adopt the shared repository format with a branded banner, MIT license, focused README, guides, and community files.
- Add a real black-background Claude Code intake demo, producing a walkthrough brief before capture/render.
- Add offline source/documentation checks and a local background-music smoke test.
- Preserve the studio's native skill layout, production helpers, worked examples, and original long-form guides.
