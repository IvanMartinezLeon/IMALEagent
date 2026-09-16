# AGENTS.md — IMALEagent

Contexto operativo para agentes que trabajen **dentro de este repositorio**.
Si aplicas cambios sobre proyectos de terceros usando esta configuración, las reglas que rigen son las de `~/.pi/agent/APPEND_SYSTEM.md` + el `AGENTS.md` de ese proyecto.

---

## 1. Qué es este repositorio

**No es una aplicación de negocio.** Es la capa de **instalación, configuración y onboarding** de un entorno de trabajo basado en [Pi](https://github.com/earendil-works/pi-coding-agent) para IMALE.

Lo que produce:

- un binario base (`@earendil-works/pi-coding-agent`) + paquetes (`pi-subagents`, adaptador MCP, `context-mode`),
- una configuración de agente homogénea copiada a `~/.pi/agent`,
- el comando `IMALEagent` (con `pi` como alias),
- scripts de verificación y desinstalación multiplataforma.

Consecuencia práctica: **el "producto" son ficheros de configuración y scripts**. Un cambio que rompe la idempotencia, el merge de config o el desinstalador es un cambio crítico, aunque parezca documental.

---

## 2. Comandos

No hay `package.json` en la raíz: no hay `npm test`. La validación se hace con los mismos comandos que ejecuta el CI (`.github/workflows/validate.yml`).

```bash
# 1. Sintaxis de todos los scripts bash
bash -n install.sh
for f in scripts/*.sh install/*.sh install/lib/*.sh install/templates/*.sh; do bash -n "$f"; done

# 2. Sintaxis de las extensiones TypeScript y de los helpers Node
for f in config/agent/extensions/*.ts config/agent/extensions/lib/*.ts; do
  node --experimental-strip-types --check "$f"
done
for f in install/lib/*.mjs; do node --check "$f"; done

# 3. JSON de configuración válido
for f in config/agent/settings.json config/agent/mcp.json \
         config/agent/presets.json config/agent/themes/imale-theme.json; do
  node -e "JSON.parse(require('node:fs').readFileSync(process.argv[1],'utf8'))" "$f"
done

# 4. Test E2E de instalación/desinstalación (HOME simulado, sin red ni npm)
bash scripts/test-install.sh

# 5. El release tarball se construye y no lleva .DS_Store
bash scripts/build-release.sh v0.0.0-local
tar tzf dist/imaleagent.tar.gz >/dev/null
```

ShellCheck está en el CI en modo **informativo y no bloqueante** (`continue-on-error: true`, severidad `error`). No lo pongas bloqueante en un PR salvo que hayas limpiado la salida en local.

Al tocar `install/lib/config-stage.sh` o `install/lib/uninstall-config.mjs`, **`scripts/test-install.sh` es obligatorio**: es el único test real de la etapa de configuración.

---

## 3. Mapa del repositorio

```text
.
├── install.sh                     # entry point curl|sh; detecta repo local y delega
├── config/agent/                  # ← FUENTE DE VERDAD de la configuración instalada
│   ├── settings.json              # tema, compaction, overrides de subagentes
│   ├── mcp.json                   # servidores MCP (context-mode lazy)
│   ├── presets.json               # presets del comando imale:preset
│   ├── APPEND_SYSTEM.md           # reglas de sistema inyectadas (committeado)
│   ├── GENERIC_RULES.md, BEST_PRACTICES.md, EXPLORATION_STRATEGY.md,
│   │   GUIDANCE_INDEX.md, MOBILE_GUIDELINES.md
│   ├── extensions/                # ai-router.ts, imale-header.ts, imale-preset.ts, lib/shared-ui.ts
│   ├── agents/                    # 7 subagentes generic-*
│   ├── prompts/                   # prompt workflows generic-* + pasos step-*
│   ├── skills/                    # skills IMALE (+ flutter-guidelines, dart-guidelines)
│   ├── templates/                 # SPEC_TEMPLATE.md, PLAN_TEMPLATE.md, guía de exploración
│   ├── examples/                  # ejemplos de exploración por tecnología
│   └── themes/                    # imale-theme.json
├── install/
│   ├── install.{sh,ps1,bat}       # instaladores por plataforma
│   ├── verify.{sh,ps1,bat}        # validación post-instalación
│   ├── uninstall.{sh,ps1,bat}     # desinstalación
│   ├── lib/
│   │   ├── config-stage.sh        # backup + copia + merge + manifiesto (testeado en E2E)
│   │   ├── merge-config.mjs       # deep merge JSON: existing = base, incoming gana
│   │   ├── write-manifest.mjs     # lista de ficheros instalados → desinstalador
│   │   └── uninstall-config.mjs   # borrado guiado por manifiesto
│   ├── templates/                 # wrappers pi / imaleagent
│   └── README.md, SETUP_GUIDE.md
├── scripts/
│   ├── build-release.sh           # empaqueta install/ + config/agent/ → dist/
│   └── test-install.sh            # test E2E con HOME simulado
└── .github/workflows/
    ├── validate.yml               # PR/push: sintaxis, JSON, cadenas, E2E, tarball
    └── release.yml                # tag v*: build + gh release create
```

---

## 4. Cómo funciona la instalación (modelo mental)

1. `install.sh` (raíz) detecta Windows nativo y aborta con instrucciones; en macOS/Linux/Git Bash/WSL delega en `install/install.sh`.
2. `install/install.sh` instala los paquetes y llama a `install_config_stage()`.
3. `config-stage.sh`: **backup** de lo que va a sobrescribir → `cp -R config/agent/. ~/.pi/agent/` → **merge** de `settings.json` y `mcp.json` → **manifiesto**.
4. `uninstall` borra **exactamente** lo que lista el manifiesto (`.imale-manifest`), nunca directorios completos.

Invariantes que no se pueden romper:

- **El merge nunca puede perder config del usuario** (`packages`, `defaultProvider/Model`, MCPs propios). `existing` es la base; el repo solo gana en las claves que define. Objetos: recursivo. Arrays: se reemplazan.
- **El manifiesto solo registra ficheros, nunca directorios.** Borrar `agents/` entero se llevaría por delante agentes propios del usuario.
- **La instalación es idempotente y re-ejecutable**; la copia previa queda en `.backup-<timestamp>`.
- **No dupliques la lista de ficheros instalados** en los tres lenguajes (sh/ps1/bat). La genera `write-manifest.mjs`; los instaladores la consumen.
- Si falta un helper en `install/lib/`, el instalador deja el desinstalador ciego: es un **error bloqueante**, no un warning.

---

## 5. Convenciones de código

### Idioma
- **Documentación, mensajes de usuario y comentarios explicativos: castellano.** El repo está escrito así; mantén la coherencia.
- **Identificadores, nombres de fichero, claves JSON y valores: inglés.**

### Bash (`install/*.sh`, `install/lib/*.sh`, `scripts/*.sh`, `install.sh`)
- `#!/usr/bin/env bash` + `set -euo pipefail` siempre.
- Resuelve el directorio propio primero; nunca asumas el cwd:
  ```bash
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || pwd)"
  ```
- **Quotea todas las expansiones** (`"${VAR}"`). El CI corre `shellcheck -S error`.
- Salida por `stderr` para errores y avisos (`echo ... >&2`), `stdout` para datos que se capturan.
- Colores vía `GREEN/YELLOW/RED/NC` ya definidos en el llamador; `config-stage.sh` los espera definidos.
- Funciones helper en `snake_case`; ficheros en `kebab-case`.
- Rutas de usuario con espacios: no las partas, quotea.

### Helpers Node (`install/lib/*.mjs`)
- ESM (`.mjs`), solo módulos `node:*`, **cero dependencias** (Node es prerequisito del instalador).
- `#!/usr/bin/env node` + docstring de uso al inicio.
- Códigos de salida explícitos y documentados (ver `merge-config.mjs`: `0` ok, `1` uso, `2` JSON inválido).
- Escribe mensajes operativos a `stderr`; el resultado va al fichero indicado como argumento.

### Extensiones TypeScript (`config/agent/extensions/*.ts`)
- Deben pasar `node --experimental-strip-types --check`: **sin enums, namespaces ni decoradores**; solo sintaxis borrable por tipos.
- Toda la UI compartida va en `lib/shared-ui.ts`; no dupliques helpers de TUI entre extensiones.
- Una extensión no debe asumir que otra está cargada.

### JSON de configuración (`config/agent/*.json`)
- JSON estricto (sin comentarios ni trailing commas). El CI lo valida.
- `settings.json`, `mcp.json` y `presets.json` son **fusionables**: documenta cualquier clave nueva que el merge deba respetar, porque el usuario puede tener la suya. Caso conocido: `mcpServers.context-mode` declara `args: []` a propósito, porque el merge conserva las claves ausentes en el overlay y sin ese array se heredarían los `args` de instalaciones antiguas basadas en `npx`.
- `context-mode` es la única instalación global npm sin `--ignore-scripts`: `better-sqlite3` necesita su prebuild y el paquete ejecuta su propio `postinstall`.

### Prompt workflows (`config/agent/prompts/`)
- Ficheros invocables: llevan `chain: step-a -> step-b` en el frontmatter.
- Los `step-*.md` son pasos de cadena, están pensados para ser encadenados y **no** se invocan directamente.
- Cada paso referenciado en un `chain:` **debe existir** como `<paso>.md`: el CI falla si no.
- `welcome.md` está excluido de esa validación.

---

## 6. Documentación

Solo tres documentos de proyecto, con responsabilidad única. No añadas un cuarto sin justificar hueco real:

| Documento | Responsabilidad |
|---|---|
| `README.md` | qué es el repo, arquitectura, onboarding general |
| `install/README.md` | instalación y uso del routing / subagentes |
| `install/SETUP_GUIDE.md` | validación, diagnóstico y troubleshooting |

Reglas:
- Si cambias un comando o una ruta, **actualiza los tres** donde aparezca. El repo ya arrastra incoherencias doc↔código: no añadas más.
- No documentes ficheros que no existen ni comandos no implementados.
- Si añades un agente, prompt, skill o preset, actualiza la lista del `README.md` y de `install/README.md`.

---

## 7. Higiene del repositorio

- **No versiones artefactos locales.** Comprueba con `git ls-files` antes de dar por bueno un fichero nuevo.
- `.DS_Store` está ignorado; si aparece uno trackeado, `git rm --cached` y añade la ruta al `.gitignore`.
- Las cachés de code intelligence (`.imale-data/`, `.eurecat-data/`) son **estado local por máquina** y no deben viajar en el repo. `.gitignore` ignora `.eurecat-data/` pero **falta `.imale-data/`**, y `.imale-data/pi-code-intelligence/global.sqlite` está trackeado.
- `dist/` es salida de build: nunca lo commitees (el build lo regenera y el CI lo verifica).
- No introduzcas secretos ni tokens en `config/agent/*.json` ni en los scripts: van a parar al `$HOME` de cualquiera que instale.

---

## 8. Trampas conocidas

- **Windows nativo no ejecuta bash.** `install.sh` aborta a propósito con instrucciones; el camino correcto es `install/install.ps1` o `install.bat`, que necesitan el árbol del repo (`config/agent` se resuelve desde su propia ubicación). Git Bash/WSL sí pueden usar el script.
- **`curl | sh` descarga el tarball de release**, no el repo. Si tocas rutas dentro del tarball, revisa `scripts/build-release.sh` (empaqueta solo `install/` y `config/agent/`) y `release.yml` (assets subidos).
- **Los tres instaladores están escritos a mano por plataforma.** Son candidatos naturales a divergir: al cambiar el flujo de instalación, revisa `install.sh`/`install.ps1`/`install.bat`, y `verify.*`/`uninstall.*` en paralelo.
- **`macOS` vs `GNU` en utilidades**: `stat -f%z` vs `stat -c%s`, `shasum` vs `sha256sum`. El patrón del repo es encadenar con `||`.
- **`verify.*` no sustituye al E2E**: los verificadores comprueban el estado del `$HOME`; `scripts/test-install.sh` comprueba la lógica.

---

## 9. Reglas del agente en este repo

- **Comunicación en castellano; código e identificadores en inglés.**
- **Pide permiso explícito antes de crear, modificar o borrar cualquier cosa fuera del directorio de trabajo activo.** Incluye `~/.pi/agent`: este repo *copia hacia allí*, pero un agente no debe escribir en el `$HOME` del usuario sin autorización.
- **No ejecutes instaladores reales** (`install/install.sh`, `verify.sh`, `uninstall.sh`) contra el `$HOME` del usuario para "probar". Usa `scripts/test-install.sh`, que trabaja en un sandbox temporal.
- Mapea antes de buscar: `ls` / `find -maxdepth` / este `AGENTS.md` antes de cualquier búsqueda amplia. `rg` siempre con ruta concreta y filtro (`-t sh`, `-g '*.ts'`).
- Salidas grandes (logs de CI, E2E verboso) → `context-mode` (`ctx_*`) en lugar de volcarlas en la conversación.
- Cambios no triviales → `SPEC.md` → `PLAN.md` → implementación. No implementes sin spec aprobada.
- Un solo escritor por working tree: no edites ficheros mientras un subagente worker esté corriendo.
