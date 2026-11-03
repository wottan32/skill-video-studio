# Auditoría de seguridad: `trailofbits/skills`

Revisión previa a instalar el marketplace de plugins de Trail of Bits en Claude Code. Complementa a [security-audit.md](security-audit.md) (la revisión de este repositorio) y se incluye aquí porque `supply-chain-risk-auditor` es la herramienta recomendada para cubrir lo que aquella dejó pendiente: auditar las dependencias que descarga la skill `/devrel-video`.

| Dato | Valor |
|---|---|
| Repositorio | <https://github.com/trailofbits/skills> |
| Commit revisado | `711af095215ad4ecde5b90cd1d0124b3f1c4ca9e` (2026-11-02) |
| Fecha de la revisión | 2026-11-03 |
| Tamaño | 46 plugins, 97 `SKILL.md`, 1 600 archivos (855 md, 175 py, 68 sh, 18 js) |
| Licencia | CC-BY-SA-4.0 |
| Veredicto | **Seguro de instalar por plugin**; ver matices en §4 |

## 1. Alcance y método

- Clon `--depth 1` en un directorio aislado del scratchpad; nada se ejecutó desde dentro del clon.
- Escaneo de los 1 600 archivos con un script propio (`python -I`): caracteres Unicode invisibles (categorías `Cf`/`Co`, rango de etiquetas U+E0000–E007F) y patrones de riesgo (`ignore previous`, `curl | sh`, `sudo`, `eval`, `--dangerously-skip-permissions`, `bypassPermissions`, rutas a credenciales, `base64 -d`, `/dev/tcp`).
- Lectura completa de: `marketplace.json`, `CODEOWNERS`, los tres `hooks.json` y todos sus scripts (`gh-cli`, `modern-python`, `fp-check`), el único `.mcp.json` (`zeroize-audit`), `Makefile` y los workflows de CI.
- Lectura del `SKILL.md`, `plugin.json` y scripts de los cinco plugins que se piensan usar: `supply-chain-risk-auditor`, `agentic-actions-auditor`, `insecure-defaults`, `differential-review`, `fp-check`.
- No se ejecutó ningún plugin ni sus tests; no se auditó el código de las herramientas externas que invocan (Semgrep, pip-audit, Serena…).

## 2. Lo que está bien

- **Procedencia.** `CODEOWNERS` con dos responsables globales (`@dguido`, `@kz-tob`) y un dueño nombrado por plugin; `marketplace.json` a nombre de Trail of Bits (`opensource@trailofbits.com`); autor y versión por plugin.
- **Sin inyección de prompts ni código oculto.** Cero frases dirigidas al agente. Solo tres archivos contienen caracteres invisibles y los tres son legítimos: un emoji de familia en un ejemplo Swift (`U+200D`, `sharp-edges/references/lang-swift.md:96`) y dos espacios de ancho cero que impiden renderizar un bloque de ejemplo (`U+200B`, `spec-to-code-compliance/resources/ANALYSIS_FORMAT.md:23,26`).
- **CI serio.** Las cinco actions fijadas por SHA completo (`actions/checkout`, `setup-node`, `setup-python`, `pre-commit/action`, `openai/codex-action`). `validate.yml` comprueba frontmatter, metadatos, ausencia de correos personales y que cada plugin cargue en Claude Code y Codex. `Makefile` reproduce el CI en local: `ruff`, `shellcheck`, `shfmt`, `bats`, tests Python/JS y validadores con autotest.
- **Permisos acotados.** 37 de 97 skills declaran `allowed-tools`. Los cinco revisados en detalle sí lo hacen:
  - `supply-chain-risk-auditor`: `Read Write Bash Glob Grep`
  - `agentic-actions-auditor`: `Read Grep Glob Bash`
  - `differential-review`: `Read Write Grep Glob Bash`
  - `fp-check`: `Read Grep Glob LSP Bash Task Write Edit AskUserQuestion TaskCreate TaskUpdate TaskList TaskGet`
  - `insecure-defaults` (comando `/insecure-defaults:audit`): `Bash Workflow`
- **Falsos positivos del escáner.** Las ~100 coincidencias de `sudo`, `curl | sh`, `npm i -g` y `bypassPermissions` están en documentación de instalación de herramientas externas (uv, rustup, apt, Mull), en tests (`claude plugin eval`, `evals/run-evals.sh`) o en ejemplos de reglas YARA, no en código que se ejecute al usar una skill. El `eval` de `static-analysis/.../run-scans.sh:352,355` es una asignación indirecta a un array con nombre controlado por el propio script (compatibilidad con bash 3.2).

## 3. Hallazgos por plugin

| # | Plugin | Hallazgo | Riesgo |
|---|---|---|---|
| H1 | `zeroize-audit` | `.mcp.json` arranca `uvx --from git+https://github.com/oraios/serena` **sin fijar tag ni commit**: ejecuta el HEAD de un repositorio de terceros en cada sesión. | **Medio-alto** (cadena de suministro) |
| H2 | `gh-cli` | Hooks `SessionStart`/`PreToolUse`/`SessionEnd`. Antepone un *shim* de `gh` al `PATH` vía `CLAUDE_ENV_FILE`; el hook `PreToolUse` **deniega** cualquier `curl`/`wget` a `github.com`, `api.github.com`, `raw.githubusercontent.com` o `gist.github.com`, y el shim bloquea `gh api …/contents` y clones fuera de `$TMPDIR/gh-clones-<session_id>`. En `SessionEnd` ejecuta `rm -rf "$TMPDIR/gh-clones-$session_id"` (session_id validado con `^[a-zA-Z0-9_-]+$`). Código correcto y defensivo, pero cambia el comportamiento de **toda** sesión mientras está habilitado. | Medio (intrusivo, no malicioso) |
| H3 | `modern-python` | Hook `SessionStart` que antepone shims de `python`, `python3`, `pip`, `pip3`, `pipx`, `uv` al `PATH`. Añade la línea a `CLAUDE_ENV_FILE` **sin deduplicar**; `gh-cli` documenta que esa acumulación en resume/compact puede truncar el entorno y romper cada llamada a Bash. | Bajo-medio |
| H4 | `fp-check` | Hooks `Stop` y `SubagentStop` de tipo `prompt`: una llamada extra al modelo cada vez que el agente intenta terminar, para exigir que las 5 fases y 6 gates estén completas. | Coste, no seguridad |
| H5 | `supply-chain-risk-auditor` | Envía **nombre y versión** de las dependencias del proyecto a `api.osv.dev`, `registry.npmjs.org`, `api.npmjs.org`, `pypi.org`, `proxy.golang.org`, `api.deps.dev`, `api.scorecard.dev` y `api.github.com`. Usa `gh auth token` (si existe) como `Authorization: Bearer` solo contra `api.github.com` para ampliar la cuota. Puede invocar `pip-audit`. No envía código fuente. | Bajo; relevante en proyectos confidenciales |
| H6 | `devcontainer-setup` | Configura `permissions.defaultMode = "bypassPermissions"` y un alias `claude-yolo='claude --dangerously-skip-permissions'` **dentro del contenedor**, por diseño y documentado en su README. `Dockerfile` instala Claude Code y fnm con `curl … | bash`. | Aceptable solo en contenedor desechable |
| H7 | repositorio | No hay `SECURITY.md` ni guía en el README sobre cómo revisar los plugins antes de habilitarlos. | Informativo |

## 4. Recomendaciones de instalación

1. Añadir el marketplace y habilitar **solo** los plugins que se vayan a usar:
   ```bash
   claude plugin marketplace add trailofbits/skills
   claude plugin install supply-chain-risk-auditor@trailofbits
   claude plugin install agentic-actions-auditor@trailofbits
   claude plugin install insecure-defaults@trailofbits
   claude plugin install differential-review@trailofbits
   ```
2. **No habilitar `zeroize-audit`** hasta que su `.mcp.json` fije Serena a un commit o tag (H1).
3. Dejar `gh-cli` y `modern-python` deshabilitados salvo que se quieran sus shims de forma consciente (H2, H3). Si se habilitan, saber que `curl`/`wget` a GitHub quedarán bloqueados en Bash.
4. `devcontainer-setup` solo en un contenedor desechable; nunca aplicar su `post_install.py` al `~/.claude` del host (H6).
5. En proyectos confidenciales, revisar el lockfile antes de correr `supply-chain-risk-auditor`: los nombres de paquetes privados saldrían hacia OSV/deps.dev (H5).
6. Fijar la versión instalada (el marketplace apunta a `main`): tras instalar, anotar el commit revisado en este documento y repetir el escaneo de §1 antes de actualizar.

## 5. Primer uso previsto

Ejecutar `/supply-chain-risk-auditor` sobre este repositorio para auditar las dependencias fijadas en `.claude/skills/devrel-video/scripts/_versions.sh` (`hyperframes@0.9.6`, `@playwright/cli@0.1.23`, `vhs@v0.12.1`, `ttyd 1.7.7`), que [security-audit.md](security-audit.md) dejó como pendiente.
