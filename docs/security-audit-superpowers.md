# Análisis de seguridad — `obra/superpowers`

**Fecha:** 2026-11-03 · **Commit analizado:** `2ce8aa15d05bd57213e6f746f953aafb7ded7a8b` (v7.0.1, 2026-10-21) · **Resultado:** código seguro de instalar; la decisión real es de comportamiento y coste, no de seguridad. Recomendación en la sección 6.

Revisión previa a una posible instalación del plugin `superpowers` (Jesse Vincent / Prime Radiant, MIT) en una cuenta de Claude Code. Mismo método que en [security-audit.md](security-audit.md) y [security-audit-trailofbits.md](security-audit-trailofbits.md).

## 1. Alcance y método

- Clon aislado del repositorio en una carpeta temporal, con los hooks de git desactivados y sin ejecutar ninguno de sus scripts.
- Escáner (`python -I`) de los 229 archivos de texto: caracteres Unicode invisibles (categorías `Cf`/`Co`, tags `U+E0000–E007F`), instrucciones dirigidas al agente, ejecución remota (`curl | sh`, `eval`, `sudo`), acceso a credenciales, cambios de permisos (`bypassPermissions`, `--dangerously-skip-permissions`).
- Lectura completa de los 15 `SKILL.md`, de `hooks/hooks.json`, `hooks/session-start`, `hooks/run-hook.cmd`, los manifiestos (`.claude-plugin/plugin.json`, `marketplace.json`, `package.json`), todos los scripts de `skills/*/scripts/`, `skills/brainstorming/visual-companion.md`, `skills/diagnosing-superpowers/` (prompts, referencias, plantillas) y el `README.md`.
- Metadatos de GitHub: autoría reciente, releases, avisos de seguridad, issues relacionadas con seguridad, y presencia en el marketplace oficial de Anthropic.

**Fuera de alcance:** el código para otros harnesses (`.opencode/`, `.pi/`, `.hermes-plugin/`), que se instala en disco pero Claude Code no ejecuta; solo se revisó con búsquedas de patrones. El contenido de `docs/plans/` y `docs/superpowers/specs/` (documentos de diseño del propio proyecto).

## 2. Qué es

No es una colección de herramientas sino una **metodología de desarrollo impuesta al agente**: antes de programar, Claude hace brainstorming con el usuario, escribe un documento de diseño que el usuario aprueba, lo convierte en un plan de tareas de 2 a 5 minutos, las ejecuta con subagentes (uno por tarea más un revisor por tarea) y termina con una revisión de toda la rama y un menú merge/PR. Todo arranca con un hook `SessionStart` que inyecta en **cada sesión** (inicio, `/clear` y compactación) la skill `using-superpowers`, que obliga a invocar skills "si hay un 1 % de probabilidad de que apliquen".

| Dato | Valor |
|---|---|
| Archivos | 231 (15 `SKILL.md`, 1 hook, 10 scripts de skill, 107 archivos de tests) |
| Estrellas / forks | 311 616 / 27 724 |
| Última release | v7.0.1 (2026-10-21) |
| Marketplace oficial de Anthropic | Sí, fijado al commit `bb92a77` = v7.0.0 (2026-10-10) |
| Avisos de seguridad en GitHub | 0 |
| SECURITY.md / CODEOWNERS / CI | No / No / No (`.github/` solo contiene plantillas y FUNDING) |

## 3. Las 15 skills

### Flujo principal (en orden de uso)

| Skill | Qué hace | Beneficio |
|---|---|---|
| `using-superpowers` | Se inyecta al inicio de cada sesión. Regla: comprobar skills antes de cualquier respuesta, incluidas preguntas. Tabla de "pensamientos que son racionalizaciones". | Las demás skills se disparan solas. Es también la fuente del riesgo R1. |
| `brainstorming` | Antes de construir algo nuevo: preguntas de una en una, exploración del proyecto, 2-3 enfoques con recomendación, documento de diseño en `docs/superpowers/specs/` y una puerta dura: nada se construye sin aprobación del usuario. Incluye un *visual companion*: servidor local que muestra mockups HTML en el navegador y registra los clics. | Evita construir lo que no se quería. El "builder check" (un subagente lee el diseño como si fuera a implementarlo) detecta huecos antes de programar. |
| `using-git-worktrees` | Crea un worktree aislado (`.worktrees/`), verifica que esté en `.gitignore`, instala dependencias y comprueba que los tests pasan antes de tocar nada. Prefiere la herramienta nativa del harness si existe. | La rama actual queda intacta; línea base verde antes de empezar. |
| `writing-plans` | Convierte el diseño en tareas con rutas exactas, código completo y pasos de verificación; cabecera con restricciones globales. | Reduce la improvisación del agente durante la implementación. |
| `subagent-driven-development` | Por tarea: implementador fresco con un *brief* extraído del plan, revisor de spec y calidad, bucle de corrección con tope, *ledger* en `.superpowers/sdd/` que sobrevive a la compactación. Revisión final de toda la rama. Elección explícita de modelo por rol. | Contexto limpio por tarea, revisión sistemática, recuperación tras compactación. |
| `executing-plans` | Variante barata: el agente ejecuta las tareas en la propia sesión, con un único revisor al final. Scripts `task-start`/`task-done` que solo anotan la tarea si los tests pasan. | Mismo plan y ledger con una fracción del coste. |
| `test-driven-development` | Ningún código de producción sin un test que haya fallado antes. Red → verificar rojo → verde mínimo → verificar verde → refactor. Borra código escrito antes del test. | Tests que prueban algo. Incluye referencia de anti-patrones. |
| `requesting-code-review` | Despacha un subagente revisor con contexto preciso (nunca el historial de la sesión) tras cada tarea; informa por severidad. | Problemas detectados antes de encadenarse. |
| `receiving-code-review` | Al recibir feedback: verificar antes de implementar, prohibido el asentimiento performativo, chequeo YAGNI, cómo rebatir con rigor. Trata a los revisores externos con más escepticismo. | Evita implementar a ciegas sugerencias erróneas; defensa parcial contra inyección vía comentarios de PR. |
| `verification-before-completion` | Ninguna afirmación de "funciona/pasa" sin haber ejecutado el comando y leído la salida. | Elimina el "debería funcionar". |
| `finishing-a-development-branch` | Tests completos → menú de exactamente 3 opciones (merge local / push + PR / dejar la rama). Descartar trabajo solo si el usuario escribe literalmente `discard`; nunca `--force` por iniciativa propia. | Integración siempre decidida por el usuario, con guardas contra pérdida de trabajo. |

### Apoyo

| Skill | Qué hace | Beneficio |
|---|---|---|
| `systematic-debugging` | Cuatro fases: causa raíz → patrones → hipótesis → fix. Prohibido parchear síntomas. Técnicas anexas y `find-polluter.sh` (bisección de tests que ensucian estado). | Menos "prueba esto a ver". |
| `dispatching-parallel-agents` | Cuándo y cómo lanzar varios subagentes sobre dominios independientes. | Paralelismo sin conflictos. |
| `diagnosing-superpowers` | Si una sesión fue mal: lee las transcripciones en disco, lanza 7 subagentes analistas, informe con citas `ruta:línea`, y opcionalmente busca/crea issue en GitHub o exporta un *bundle* anonimizado. | Forense de sesiones con evidencia. Ver R3. |
| `writing-skills` | TDD aplicado a documentación: escenario de presión sin la skill → fallo → escribir skill → pasa. Anti-patrones. | La única guía seria encontrada para probar que una skill cambia el comportamiento. Útil para mejorar `/devrel-video`. |

## 4. Lo que se comprobó y está bien

| Aspecto | Hallazgo |
|---|---|
| Caracteres ocultos | 0 en 229 archivos de texto. |
| Inyecciones | 0 patrones dirigidos al agente fuera de lo declarado. Las 15 coincidencias del escáner (`--dangerously-skip-permissions`, `bypassPermissions`) están todas en `tests/`, el arnés de pruebas del proyecto, que el plugin nunca ejecuta. |
| Red en el código activo | Ninguna. El hook (`hooks/session-start`) solo lee `skills/using-superpowers/SKILL.md` y emite JSON; los scripts de `sdd` usan solo `git` y `awk`. Sin `curl | sh`, `eval`, `sudo`, ni acceso a `.ssh`/`.aws`/tokens. |
| Visual companion (`server.cjs`, 723 líneas) | Node sin dependencias (decisión documentada como mitigación de cadena de suministro). Escucha en `127.0.0.1`, puerto alto aleatorio, token de 256 bits por sesión comparado en tiempo constante, cookie `HttpOnly; SameSite=Strict`, comprobación de `Origin` en WebSocket, cabeceras `X-Frame-Options: DENY`, `CSP frame-ancestors 'none'`, `Referrer-Policy: no-referrer`, protección contra path traversal y symlinks en `/files/`, límite de 10 MB por frame, apagado por inactividad (4 h) o muerte del proceso padre, archivos con `umask 077`. Apertura del navegador con `execFile` (sin shell). `stop-server.sh` verifica la identidad del proceso antes de matarlo y solo borra directorios bajo `/tmp`. |
| Guardas de destrucción | Borrar rama solo con `discard` literal; nunca `--force`; parada obligatoria ante operaciones irreversibles, acciones sensibles de seguridad o efectos fuera del worktree (merge, push, publicar). |
| Hook en Windows | `run-hook.cmd` es un polyglot cmd/bash que busca `bash.exe` en rutas fijas de Git for Windows y filtra los lanzadores WSL; si no hay bash, sale sin error. |
| Procedencia | Autor identificado; marketplace oficial de Anthropic lo distribuye fijado por SHA; 0 avisos de seguridad; MIT. |

## 5. Riesgos encontrados

| # | Riesgo | Dónde | Por qué importa | Nivel |
|---|---|---|---|---|
| R1 | Inyección de contexto global y coercitiva | `hooks/session-start`, `skills/using-superpowers/SKILL.md` | El hook mete en todas las sesiones (todos los proyectos, scope user) un bloque `<EXTREMELY_IMPORTANT>` con lenguaje de presión. Cambia el comportamiento del agente en todo, no solo al programar. Issues abiertas del propio proyecto: #2377 (el lenguaje de presión degrada el comportamiento en los modelos Claude actuales) y #1480 (el hook dispara la detección de inyección de Claude). La #2509 (el bloque anulaba las instrucciones del usuario) se cerró añadiendo "las instrucciones del usuario tienen prioridad". | **Medio** (comportamiento) |
| R2 | Telemetría a terceros | `server.cjs:106,249` | La página del visual companion carga un logo desde `primeradiant.com` con la versión en la URL: un beacon a la empresa del autor cada vez que se abre. Documentado en el README; sin datos del proyecto; `referrerpolicy=no-referrer`. Se desactiva con `SUPERPOWERS_DISABLE_TELEMETRY=1`, `DISABLE_TELEMETRY` o `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`. | **Bajo** (opt-out) |
| R3 | Lectura y exportación de transcripciones | `skills/diagnosing-superpowers/` | Lee los `.jsonl` de `~/.claude/projects/` (código, salidas de comandos, posibles secretos) y los pasa a 7 subagentes. Puede crear issues en GitHub y empaquetar un bundle "anonimizado" cuyo *scrub* es un prompt a un LLM, no un redactor determinista; la skill admite que puede fallar y exige revisar cada archivo. Todo tras aprobación explícita y nunca sin que se pida. | **Medio** si se usa; nulo si no se invoca |
| R4 | Instalación automática de dependencias | `using-git-worktrees` paso 2 | Ejecuta `npm install`, `pip install -r`, `poetry install`, `cargo build`, `go mod download` sin preguntar. En un repo propio es lo normal; en uno ajeno recién clonado ejecuta sus scripts de instalación sin aviso. | **Medio** |
| R5 | Autonomía prolongada y coste | `subagent-driven-development` | Diseñado para no parar entre tareas y trabajar horas; cada tarea = implementador + revisor + hasta 5 rondas de corrección. Los implementadores hacen commits solos (en la rama aislada). El README advierte que el controlador "es el asiento más caro". | **Medio** (económico y de control) |
| R6 | Opción `--host 0.0.0.0` | `visual-companion.md`, `start-server.sh` | El companion puede exponerse a toda la red si el agente lo decide (la guía lo sugiere para entornos remotos). El token mitiga, pero la URL completa con `?key=` se imprime en la terminal y se guarda en `.superpowers/brainstorm/.last-token` dentro del proyecto. | **Bajo** |
| R7 | Archivos en el repositorio del usuario | `sdd-workspace`, `visual-companion.md` | Crea `.superpowers/` (ledgers, briefs, diffs, mockups, token) y `docs/superpowers/specs/`. `.superpowers/sdd/` se auto-ignora; `.superpowers/brainstorm/` no: la skill solo pide recordar al usuario que lo añada al `.gitignore`. | **Bajo** |
| R8 | Gobernanza de un solo mantenedor | repositorio | Todos los commits recientes de `main` son de una persona; sin CODEOWNERS, SECURITY.md ni CI. Con 311 k estrellas, una cuenta comprometida = actualización maliciosa masiva. Mitigación real: el marketplace oficial fija el SHA y Anthropic lo revisa antes de subirlo. | **Medio** (estructural) |
| R9 | Código inerte de otros harnesses | `.opencode/`, `.pi/`, `.hermes-plugin/` | Se instala en disco pero Claude Code no lo ejecuta. Revisado con patrones: sin red ni ejecución. | **Nulo** |

Lo que **no** se encontró: exfiltración, modificación de `settings.json` o permisos, servidores MCP, descargas de binarios, `curl | sh`, acceso a credenciales, caracteres ocultos.

## 6. Recomendación

Seguro de instalar desde el punto de vista del código. La decisión real es de comportamiento y coste: Superpowers impone un proceso pesado en todas las sesiones, y la app de escritorio de Claude Code ya trae varias de sus piezas (plan mode, worktrees, lista de tareas, verificación, revisiones). Para proyectos pequeños con auditoría manual, el valor neto es dudoso y el coste en tokens, cierto.

Si se instala:

1. **Solo desde el marketplace oficial**, nunca desde `obra/superpowers-marketplace`: se recibe el commit fijado y revisado por Anthropic (`bb92a77`, v7.0.0), no lo último del autor.
   ```sh
   claude plugin install superpowers@claude-plugins-official
   ```
2. **Desactivar la telemetría** antes del primer uso: `SUPERPOWERS_DISABLE_TELEMETRY=1`.
3. **Añadir `.superpowers/` al `.gitignore` global** (`git config --global core.excludesFile`).
4. **No usar `diagnosing-superpowers` para exportar bundles ni crear issues** sin revisar cada archivo a mano.
5. **No aceptar `--host 0.0.0.0`** en el visual companion.
6. **Probarlo dos semanas** en un proyecto nuevo. La skill de brainstorming incluye la salida "Or if you'd rather I just dive in, say so"; si molesta en todas las sesiones: `claude plugin uninstall superpowers`.
7. **Antes de cada `claude plugin update`**, comparar el SHA nuevo del marketplace oficial con el anterior y leer `RELEASE-NOTES.md`.

**Alternativa preferida para este entorno:** no instalar el plugin completo y copiar como skills de proyecto solo las que aportan disciplina sin imponer proceso ni hook: `test-driven-development`, `systematic-debugging` y `verification-before-completion`, más `writing-skills` para mejorar `/devrel-video`. Son Markdown sin red; el único ejecutable es `find-polluter.sh` en `systematic-debugging`, un bucle de bisección legible que solo lanza `npm test` por archivo. Se invocan a voluntad.

**Estado a 2026-11-03:** plugin no instalado. Se aplicó la alternativa: `test-driven-development`, `systematic-debugging` y `verification-before-completion` copiadas desde el commit `2ce8aa1` como skills de usuario (fuera de este repositorio), tras re-escanear los 9 archivos copiados (0 caracteres ocultos, 0 patrones). Cambios locales: la `description` de `test-driven-development` se reescribió para que solo se active a petición, y las dos referencias `superpowers:` de `systematic-debugging` apuntan a las copias locales; `verification-before-completion` es idéntica a upstream. Cada copia lleva un `SOURCE.md` con procedencia y diff. Verificación de no regresión con cinco sesiones `claude -p` en un directorio vacío sin MCP: una pregunta neutra y una tarea trivial de código no invocaron ninguna skill; la invocación explícita cargó `systematic-debugging` correctamente; un supuesto bug inexistente se reprodujo y se rechazó sin cambios. Coste fijo añadido al contexto: las tres descripciones, unos 150 tokens por sesión.
