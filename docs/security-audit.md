# Análisis de seguridad — fork `wottan32/skill-video-studio`

**Fecha:** 2026-11-02 · **Commit analizado:** `f68ffe2` (v1.0.1, idéntico al upstream `aaitor/skill-video-studio`) · **Resultado:** apta para uso como skill de proyecto, con las mejoras de la sección 4 aplicadas en v1.0.2.

Este documento recoge la revisión de seguridad hecha antes de incorporar la skill `/devrel-video` a una cuenta de Claude Code, las mejoras que se consideraron necesarias y cuáles de ellas ya están aplicadas en este fork.

## 1. Alcance y método

- Clon del repositorio en una carpeta aislada, sin ejecutar hooks de git ni ninguno de sus scripts.
- Lectura completa de `SKILL.md`, `references/production-notes.md`, todos los `scripts/*`, todas las plantillas (`templates/*`), `scripts/check.py`, `examples/record_demo.py`, el workflow de CI y los documentos de `docs/`.
- Búsqueda de patrones en los 87 archivos de texto: caracteres Unicode invisibles (categorías `Cf`/`Co`, tags `U+E0000–E007F`), instrucciones dirigidas al agente ("ignore previous…", "do not tell…"), ejecución remota (`curl | sh`, `eval`, `sudo`), acceso a credenciales (`.ssh`, `.aws`, `.env`, tokens) y cambios en la configuración de Claude Code (hooks, `settings.json`, MCP).
- Comparación del fork con el upstream y verificación del origen de los paquetes npm que la skill descarga.

**Fuera de alcance:** el código de las dependencias externas (HyperFrames, Playwright CLI, VHS, ttyd, GSAP), el contenido de las imágenes y GIF de ejemplo, y las dos guías largas de la raíz (`local-*.md`), que solo se revisaron con búsquedas de patrones.

## 2. Lo que se comprobó y está bien

| Aspecto | Hallazgo |
|---|---|
| Procedencia | Fork idéntico al upstream (178 estrellas); autor y historial de commits coherentes. |
| Configuración de Claude Code | No incluye hooks, `settings.json`, `.mcp.json` ni plugins. Solo `examples/record_demo.py` genera ajustes, y únicamente para grabar la demo en una carpeta temporal con hooks y plugins desactivados. |
| Instrucciones al agente | Sin caracteres invisibles ni órdenes para saltarse permisos, ocultar acciones o leer credenciales. `SKILL.md` insiste en no grabar PII ni claves. |
| Red | `gen-bgm.py`, `retime.py`, `narrate.py`, `track_crop.py` y `check.py` no usan la red. Las conexiones de los demás scripts corresponden a funciones documentadas (npm, GitHub releases, TTS y host GPU configurados por el usuario). |
| Paquetes | `hyperframes` apunta al repositorio de HeyGen y `@playwright/cli` al de Microsoft. |
| CI | Acciones de GitHub fijadas por SHA, `permissions: contents: read`, sin secretos. |

## 3. Riesgos encontrados

| # | Riesgo | Dónde | Por qué importa | Nivel |
|---|---|---|---|---|
| R1 | Dependencias sin versión fija | `npx hyperframes@latest`, `@playwright/cli@latest`, `vhs@latest` | Una versión comprometida se ejecutaría en el equipo sin ningún cambio en la skill. `hyperframes` publica varias versiones al día. | **Alto** |
| R2 | Binario descargado sin verificar | `capture-terminal.sh` descarga `ttyd` de la "última" release | No comprueba ningún checksum antes de ejecutarlo. | **Medio** |
| R3 | Sandbox de Chromium desactivado siempre | `capture.sh`, `thumbnail.sh` (`PLAYWRIGHT_MCP_SANDBOX=false`) | Se desactiva incluso al visitar webs de terceros; solo hace falta en hosts con AppArmor restrictivo. | **Medio** |
| R4 | Carpeta del proyecto expuesta en la red local | `thumbnail.sh` lanza `python3 -m http.server` sin `--bind` | Durante el renderizado, cualquier equipo de la LAN puede leer capturas y briefs. | **Medio** |
| R5 | Aceptación automática de confianza | `terminal-script.tape` pulsa `Enter` a ciegas tras abrir `claude` | Con una ruta equivocada aprobaría la carpeta o el prompt que estuviera en pantalla. | **Medio** |
| R6 | Inyección de prompts | Paso 2 "Explore" de `SKILL.md` | La skill hace que Claude lea páginas web; una página maliciosa podría intentar darle instrucciones. La skill no lo advertía. | **Medio** |
| R7 | Envío de datos personales | `avatar.sh`, `tts.sh` | El rostro y la voz del presentador van al host GPU y al servicio TTS que el usuario configure. | **Medio** (opcional) |
| R8 | Ejecución remota con `eval` y `sudo` | `avatar.sh` (`eval echo "$LS_DIR"`), `variant.sh` (`sudo systemctl stop ollama` por SSH) | Actúa sobre el host GPU con privilegios; `eval` sobre un valor leído de un archivo de configuración. | **Bajo** (opcional) |
| R9 | Recursos externos sin integridad | Plantillas HTML cargan GSAP desde jsDelivr y fuentes de Google | GSAP tiene versión fija pero sin hash `integrity`; además filtran actividad a esos CDN. | **Bajo** |
| R10 | Archivo de configuración ejecutable | `_env.sh` hace `source` de `~/.config/devrel-video/env` | Su contenido se ejecuta como shell sin comprobar propietario ni permisos. | **Bajo** |

## 4. Mejoras necesarias y estado

| # | Mejora | Estado en v1.0.2 |
|---|---|---|
| R1 | Fijar versiones en un único archivo (`scripts/_versions.sh`): `hyperframes@0.9.6`, `@playwright/cli@0.1.23`, `vhs@v0.12.1`. Ningún script usa ya `@latest`. | ✅ Aplicada |
| R2 | Fijar `ttyd 1.7.7` y verificar su SHA-256 contra el `SHA256SUMS` de la release antes de instalarlo; abortar si no coincide o la arquitectura no es x86_64. | ✅ Aplicada |
| R3 | Sandbox activo por defecto; desactivarlo solo con `DEVREL_VIDEO_NO_SANDBOX=1`, que imprime un aviso. | ✅ Aplicada |
| R4 | `http.server --bind 127.0.0.1` y navegación a `127.0.0.1`. | ✅ Aplicada |
| R5 | Eliminar el `Enter` automático; la plantilla exige confiar la carpeta a mano antes de grabar. | ✅ Aplicada |
| R6 | `SKILL.md` indica que el contenido de la página es dato, no instrucción; parar y mostrar al usuario cualquier texto dirigido al agente; grabar solo sitios que el usuario nombró y sin sesión iniciada. | ✅ Aplicada |
| R7 | No configurar narración ni avatar hasta necesitarlos; usar un host propio y una clave SSH exclusiva. | ⚠️ Decisión del usuario (documentada) |
| R8 | Sustituir `eval` por expansión de parámetros; `sudo` solo con `AVATAR_MANAGE_OLLAMA=1` y `sudo -n` (sin pedir contraseña). | ✅ Aplicada |
| R9 | Añadir `integrity="sha384-…"` (hash verificado contra el publicado por jsDelivr) y `crossorigin="anonymous"` al `<script>` de GSAP. Las fuentes de Google no admiten `integrity`: vendorizar para trabajo confidencial, como ya indica `production-notes.md`. | ✅ Aplicada (GSAP) / ⚠️ Fuentes: vendorizar |
| R10 | `_env.sh` solo hace `source` si el archivo es del usuario y no tiene permisos de escritura para grupo u otros; si no, avisa y lo omite. | ✅ Aplicada |

## 5. Recomendaciones de uso

1. **Instalar como skill de proyecto**, no en `~/.claude/skills`: clonar en su propia carpeta y abrir `claude` ahí. Así solo está disponible cuando se trabaja en vídeo.
2. **Fijar el commit o el tag** (`git clone --branch v1.0.2 --depth 1 …`) en lugar de seguir `main`.
3. **Ejecutar en Linux, WSL2 o una VM.** Los scripts están pensados para Linux (varios no funcionan en Windows nativo) y el aislamiento limita el daño si una dependencia estuviera comprometida.
4. **Revisar `scripts/_versions.sh` antes de cada subida de versión**, leyendo las notas de la release del paquete. `hyperframes` cambia muy deprisa.
5. **Grabar solo sitios de confianza o entornos de demo**, con el navegador sin sesiones iniciadas y sin datos reales. Revisar el *contact sheet* y el vídeo final antes de publicar.
6. **Dejar narración y avatar para después**, y cuando se usen, con un host GPU propio, una clave SSH exclusiva para esa tarea y un archivo `~/.config/devrel-video/env` con `chmod 600`.
7. **Vendorizar GSAP y las fuentes** en proyectos confidenciales (ver `production-notes.md` → Vendoring).

## 6. Auditoría de dependencias (2026-11-03)

Las dependencias directas se auditaron con `supply-chain-risk-auditor` 2.0.4 de Trail of Bits (revisión previa de ese plugin en [security-audit-trailofbits.md](security-audit-trailofbits.md)). Resultado: 0 avisos y 0 hallazgos en las 5 dependencias medidas; las 5 tienen repositorio activo y política de seguridad publicada.

| Informe | Cubre | Resultado |
|---|---|---|
| [supply-chain-report-pinned-tools.md](supply-chain-report-pinned-tools.md) | `hyperframes@0.9.6`, `@playwright/cli@0.1.23`, `vhs v0.12.1` (manifiesto sintético a partir de `_versions.sh`) | 0 avisos; ambos paquetes npm con provenance y sin script de instalación |
| [supply-chain-report-dev-deps.md](supply-chain-report-dev-deps.md) | `requirements-dev.txt` (PyYAML 6.0.3, numpy) | 0 avisos; numpy comprobado en 2.5.4 por declararse como rango |

Lo que la medición no cubre:

- `ttyd` 1.7.7: binario de GitHub Releases, ecosistema no soportado. Su control es el SHA-256 de `capture-terminal.sh` (R2).
- Dependencias transitivas de los paquetes npm: no se generó `package-lock.json`. Para cubrirlas, generar uno fuera del repositorio con `npm i --package-lock-only hyperframes@0.9.6 @playwright/cli@0.1.23` y pasar el colector sobre él.
- `numpy` declarado como `>=2,<3`: fijar la versión en `requirements-dev.txt` hace que el aviso se compruebe contra lo instalado.
- `hyperframes` no tiene informe OpenSSF Scorecard; concentración de publicadores no observable en npm con provenance, PyPI ni Go.

Cómo repetirla tras cada subida de versión en `_versions.sh` (con el plugin instalado y `gh` autenticado):

```sh
uv run --project <skill>/scripts <skill>/scripts/collect.py <dir-con-manifiestos> --json out/findings.json
uv run --project <skill>/scripts <skill>/scripts/render.py out/findings.json --out out/report.md
```

donde `<skill>` es `~/.claude/plugins/cache/trailofbits/supply-chain-risk-auditor/<versión>/skills/supply-chain-risk-auditor`.

## 7. Pendiente

- Auditar el código de HyperFrames, Playwright CLI, VHS y ttyd: es el mayor riesgo que queda, y está fuera del control de esta skill. La auditoría de la sección 6 mide metadatos de registro, avisos y repositorio, no el código.
- Cubrir el árbol transitivo de los paquetes npm y fijar `numpy` (ver sección 6).
- Revisar línea a línea `local-devrel-video-studio-guide.md` y `local-talking-video-avatar-guide.md`.
- Comprobar que las funciones opcionales (TTS, avatar, VHS) siguen funcionando con las versiones fijadas; en esta revisión no se ejecutó ningún script.
