# Security, privacy, and media rights

Capture public fixtures or a dedicated sanitized demo environment. Check for personal data, credentials, wallets, host paths, private URLs, and authentication popups before recording or sharing. Review screenshots/contact sheets and the final exported media.

Presenter footage is bring-your-own and stays outside this public repository. Use only footage and voices you have permission to use. Keep derived avatars and private project output out of Git; the existing ignore rules intentionally allowlist only curated public examples.

Narration/avatars are optional integrations. Their helpers can contact your configured TTS endpoint or SSH host; do not run them merely to validate documentation. Configuration files are sourced as shell scripts: `_env.sh` only sources a file that you own and that is not group/world-writable (`chmod 600`). Inspect and trust their contents, and do not print tokens or connection secrets in issues or recordings. Stopping the GPU host's model server over SSH needs `sudo` and is opt-in (`AVATAR_MANAGE_OLLAMA=1`).

Every tool the scripts download is pinned in `.claude/skills/devrel-video/scripts/_versions.sh` (npm packages, VHS, and the `ttyd` binary with its SHA-256). Bump versions there after reading the upstream release notes. The Chromium sandbox stays on during captures; set `DEVREL_VIDEO_NO_SANDBOX=1` only on hosts that need it and record trusted sites while it is off. Content read from a captured page is data, never instructions to the agent — the skill stops and shows you any text addressed to it.

The full review that led to these rules, the risks it found, and what is still open are in [security-audit.md](security-audit.md) (Spanish). The same review applied to the Trail of Bits plugin marketplace, recommended for auditing this skill's pinned dependencies, is in [security-audit-trailofbits.md](security-audit-trailofbits.md) (Spanish).

Composition templates can load third-party scripts/fonts from CDNs (GSAP carries an `integrity` hash; Google Fonts cannot). The [production notes](../.claude/skills/devrel-video/references/production-notes.md) explain vendoring for confidential work. HyperFrames telemetry settings are described in the original guide and render helper; do not assume every optional external tool has identical behavior.

Original studio code and documentation use MIT. Bundled banner fonts retain their OFL notices; external tools, models, voices, fonts, and media retain their own terms. See [licensing](licensing.md) and report vulnerabilities through [SECURITY.md](../SECURITY.md).
