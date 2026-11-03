# Informe de riesgo de cadena de suministro — herramientas fijadas en `_versions.sh`

**Fecha:** 2026-11-03 · **Herramienta:** `supply-chain-risk-auditor` 2.0.4 (Trail of Bits, commit `711af09`) · **Commit del fork:** `bf7c452`

Las herramientas que la skill instala en tiempo de ejecución (`npx hyperframes`, `npx @playwright/cli`, `go install …/vhs`) no figuran en ningún manifiesto del repositorio; están fijadas en `.claude/skills/devrel-video/scripts/_versions.sh`. Para auditarlas se generó fuera del repositorio un `package.json` y un `go.mod` sintéticos con exactamente esas versiones (`hyperframes@0.9.6`, `@playwright/cli@0.1.23`, `github.com/charmbracelet/vhs v0.12.1`) y se pasó el colector sobre ellos. `ttyd` 1.7.7 se descarga como binario de GitHub Releases: ecosistema no soportado por el colector, no auditado; su control sigue siendo la verificación SHA-256 en `capture-terminal.sh`.

Límites de esta corrida: solo dependencias directas (el `go.mod` sintético no resuelve árbol transitivo y no se generó `package-lock.json`); la concentración de publicadores no es observable en npm con provenance ni en Go; `hyperframes` no tiene informe OpenSSF Scorecard. Cómo repetirla: [security-audit.md](security-audit.md), sección 6.

El informe que sigue es la salida de `render.py` sin cambios, salvo la ruta temporal del manifiesto sintético y la ruta de la caché, sustituidas por descripciones.

---

# Supply Chain Risk Report — `pinned`

**Scanned:** synthetic manifest (`package.json` + `go.mod`) generated from `scripts/_versions.sh`  
**Manifests read:** `package.json`, `go.mod`  
**Scanned at:** 2026-11-03T11:13:45+00:00  
**Direct dependencies:** 3 (Go 1, npm 2)

## Summary

- **No known advisory affects any of the 3 direct dependencies** — but 1 was not checked at a project-resolved version (latest-release fallback or go.mod minimum; see Method and caveats).
- The lockfile resolves no packages beyond the direct dependencies.
- 0 of 3 dependencies carry at least one finding, 0 of which reach production.
- Weakest coverage: **Publisher concentration**, established for 0 of 3; the Coverage section lists every criterion.

## Production dependencies

2 dependencies are declared as runtime dependencies and ship in the built artifact. Advisory status is given for every one, clean or not.

| Dependency | Version | Advisories | Other findings |
|---|---|---|---|
| `@playwright/cli` | 0.1.23 | none known | — |
| `hyperframes` | 0.9.6 | none known | — |

## Findings

No dependency was flagged on these criteria.

## Upstream repository and CI hygiene — OpenSSF Scorecard

These criteria describe each dependency's own repository, not the audited
project. Remediation, where any exists, is upstream.

No dependency was flagged on these criteria.

## Transitive advisories

`go.mod` resolves no packages beyond the direct dependencies.

## Informational

Measured, not flagged.

- **CI token permissions**: median 0/10 across 2 scored dependencies; 2 score below 6. Not flagged — this measures whether CI workflows declare least-privilege tokens, which tracks project maturity rather than the likelihood of malicious code being published.
- **Changes reviewed by a second person**: median 9/10 across 2 scored dependencies; 1 score below 6. Not flagged — this measures the share of recent commits reviewed by a second person, which is low for most small single-maintainer projects and largely restates publisher concentration.
- **Publish provenance**: 2 of 2 publish with build provenance.
- **Security policy published**: 3 of 3 publish a security policy.
- **Download volume**: established for 2 of 3; median 1,727,953/week. Lowest: `hyperframes` (1,546,850/wk), `@playwright/cli` (1,727,953/wk).

## Coverage

What was and was not measured, per criterion.

| Criterion | Tier | Assessed | Flagged | Not assessable |
|---|---|---|---|---|
| Known advisories | A | 3/3 | 0 | 0 |
| Deprecated or yanked | A | 2/3 | 0 | 1 |
| Repository archived | A | 3/3 | 0 | 0 |
| Maintenance activity | A | 3/3 | 0 | 0 |
| Publisher concentration | B | 0/3 | 0 | 3 |
| Install-time script execution | B | 3/3 | 0 | 0 |
| Dangerous CI workflow | scorecard | 2/3 | 0 | 1 |
| CI token permissions | scorecard | 2/3 | 0 | 1 |
| Checked-in binaries | scorecard | 2/3 | 0 | 1 |
| Changes reviewed by a second person | scorecard | 2/3 | 0 | 1 |
| Publish provenance | info | 2/3 | 0 | 1 |
| Security policy published | info | 3/3 | 0 | 0 |
| Download volume | info | 2/3 | 0 | 1 |

## Not assessable

**Checked-in binaries**

- 1 dependency — OpenSSF Scorecard has no report for this repository: `hyperframes`

**Changes reviewed by a second person**

- 1 dependency — OpenSSF Scorecard has no report for this repository: `hyperframes`

**Dangerous CI workflow**

- 1 dependency — OpenSSF Scorecard has no report for this repository: `hyperframes`

**Deprecated or yanked**

- 1 dependency — module deprecation is declared in the module's own go.mod, which is not read: `github.com/charmbracelet/vhs`

**Download volume**

- 1 dependency — Go has no download-count concept: `github.com/charmbracelet/vhs`

**Publish provenance**

- 1 dependency — Go has no publish-provenance concept; module integrity comes from the checksum database instead: `github.com/charmbracelet/vhs`

**Publisher concentration**

- 2 dependencies — publishes from CI with provenance, so the effective publisher set is whoever can merge to the release branch — not externally observable: `@playwright/cli`, `hyperframes`
- 1 dependency — Go has no registry ACL; publishing is repository write access, which GitHub does not expose to third parties: `github.com/charmbracelet/vhs`

**CI token permissions**

- 1 dependency — OpenSSF Scorecard has no report for this repository: `hyperframes`

## Method and caveats

- cache directory ownership was not verified: os.getuid is POSIX-only, so a cache at the collector's default location under the user's temp directory owned by another user would not be detected on this platform. Keep the cache under your own user profile, or pass --cache with a private path.
- 1 dependencies come from go.mod, which records a minimum version; module-version selection may build something higher: github.com/charmbracelet/vhs
- Optional tooling detected: npm. Not installed, so not used: bundler-audit, cargo-audit, osv-scanner, pip-audit.
- The lockfile (go.mod) resolves no packages beyond the direct dependencies.
- HTTP sources: 15 fetched, 2 served from cache (oldest 0.0h old), 0 refetched as stale, 0 unavailable offline, 0 errors.
