# Informe de riesgo de cadena de suministro — dependencias de desarrollo

**Fecha:** 2026-11-03 · **Herramienta:** `supply-chain-risk-auditor` 2.0.4 (Trail of Bits, commit `711af09`) · **Commit del fork:** `bf7c452`

Único manifiesto del repositorio: `requirements-dev.txt` (PyYAML, numpy), usado solo por `scripts/check.py` y la CI. Ninguna de las dos dependencias forma parte de lo que la skill ejecuta al producir vídeo.

Límites de esta corrida: `numpy` está declarado como rango (`>=2,<3`) sin lockfile, así que sus avisos se comprobaron contra la última versión publicada (2.5.4) y no contra la que instala el proyecto; no hay árbol transitivo que examinar; PyPI no expone ACL de publicación ni attestations legibles por el colector, y sus contadores de descargas están desactivados. Cómo repetirla: [security-audit.md](security-audit.md), sección 6.

El informe que sigue es la salida de `render.py` sin cambios, salvo la ruta local del repositorio y la ruta de la caché, sustituidas por descripciones.

---

# Supply Chain Risk Report — `skill-video-studio`

**Scanned:** repository root  
**Commit:** `bf7c452d89c5`  
**Manifests read:** `requirements-dev.txt`  
**Scanned at:** 2026-11-03T11:13:32+00:00  
**Direct dependencies:** 2 (PyPI 2)

## Summary

- **No known advisory affects any of the 2 direct dependencies** — but 1 was not checked at a project-resolved version (latest-release fallback or go.mod minimum; see Method and caveats).
- Transitive dependencies were **not examined**: no lockfile resolves the transitive tree (package-lock.json, uv.lock, or a go 1.17+ go.mod).
- 0 of 2 dependencies carry at least one finding, 0 of which reach production.
- Weakest coverage: **Install-time script execution**, established for 0 of 2; the Coverage section lists every criterion.

## Production dependencies

Every direct dependency is declared as a development dependency, so none
of them ships in the built artifact.

## Findings

No dependency was flagged on these criteria.

## Upstream repository and CI hygiene — OpenSSF Scorecard

These criteria describe each dependency's own repository, not the audited
project. Remediation, where any exists, is upstream.

No dependency was flagged on these criteria.

## Transitive advisories

Not examined: no lockfile resolves the transitive tree (package-lock.json, uv.lock, or a go 1.17+ go.mod). Commit a lockfile to close this gap.

## Informational

Measured, not flagged.

- **CI token permissions**: median 10/10 across 2 scored dependencies; 1 score below 6. Not flagged — this measures whether CI workflows declare least-privilege tokens, which tracks project maturity rather than the likelihood of malicious code being published.
- **Changes reviewed by a second person**: median 9/10 across 2 scored dependencies; 1 score below 6. Not flagged — this measures the share of recent commits reviewed by a second person, which is low for most small single-maintainer projects and largely restates publisher concentration.
- **Publish provenance**: not determinable for any dependency in this project.
- **Security policy published**: 2 of 2 publish a security policy.
- **Download volume**: not determinable for any dependency in this project.

## Coverage

What was and was not measured, per criterion.

| Criterion | Tier | Assessed | Flagged | Not assessable |
|---|---|---|---|---|
| Known advisories | A | 2/2 | 0 | 0 |
| Deprecated or yanked | A | 2/2 | 0 | 0 |
| Repository archived | A | 2/2 | 0 | 0 |
| Maintenance activity | A | 2/2 | 0 | 0 |
| Publisher concentration | B | 0/2 | 0 | 2 |
| Install-time script execution | B | 0/2 | 0 | 2 |
| Dangerous CI workflow | scorecard | 2/2 | 0 | 0 |
| CI token permissions | scorecard | 2/2 | 0 | 0 |
| Checked-in binaries | scorecard | 2/2 | 0 | 0 |
| Changes reviewed by a second person | scorecard | 2/2 | 0 | 0 |
| Publish provenance | info | 0/2 | 0 | 2 |
| Security policy published | info | 2/2 | 0 | 0 |
| Download volume | info | 0/2 | 0 | 2 |

## Not assessable

**Download volume**

- 2 dependencies — PyPI's download counters are disabled and return -1: `numpy`, `pyyaml`

**Install-time script execution**

- 2 dependencies — install-time execution depends on whether a wheel or an sdist is installed, which this collector does not determine: `numpy`, `pyyaml`

**Publish provenance**

- 2 dependencies — PyPI publish attestations are not read by this collector: `numpy`, `pyyaml`

**Publisher concentration**

- 2 dependencies — PyPI publishes no upload ACL, so who can publish this package is not observable: `numpy`, `pyyaml`

## Method and caveats

- cache directory ownership was not verified: os.getuid is POSIX-only, so a cache at the collector's default location under the user's temp directory owned by another user would not be detected on this platform. Keep the cache under your own user profile, or pass --cache with a private path.
- 1 dependencies are specified as a version range with no lockfile, so their advisories were matched against the current latest release rather than against what this project installs — commit a lockfile for an exact answer: numpy
- Optional tooling detected: npm. Not installed, so not used: bundler-audit, cargo-audit, osv-scanner, pip-audit.
- Direct dependencies only. Advisories attach to the package that ships the affected code, so an umbrella package can look clean while its components are not — rails 5.0.0 reports 0 advisories where actionpack 5.0.0 reports 10. Transitive dependencies were not examined: no lockfile resolves the transitive tree (package-lock.json, uv.lock, or a go 1.17+ go.mod).
- HTTP sources: 10 fetched, 2 served from cache (oldest 0.0h old), 0 refetched as stale, 0 unavailable offline, 0 errors.
