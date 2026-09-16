# Instalación de IMALEagent

Guía principal para instalar **IMALEagent** desde este repositorio.

Este directorio contiene los scripts y documentos necesarios para dejar preparado un entorno homogéneo de trabajo con:

- **Pi** como agente base
- **subagentes** para delegación y coordinación entre agentes
- **adaptador MCP** para integración MCP
- **context-mode** para salidas grandes y contexto pesado (binario global + extensión Pi)
- **ai-router** para routing híbrido según el tipo de tarea
- subagentes y prompt workflows genéricos reutilizables entre proyectos

> Si vienes por primera vez al proyecto, puedes leer antes el `../README.md` de la raíz para entender la arquitectura completa del repositorio.

---

## Tabla de contenidos

- [Qué hace esta instalación](#qué-hace-esta-instalación)
- [Qué se copia al entorno del usuario](#qué-se-copia-al-entorno-del-usuario)
- [Requisitos previos](#requisitos-previos)
- [Instalación rápida](#instalación-rápida)
- [Instalación manual mínima](#instalación-manual-mínima)
- [Primer arranque](#primer-arranque)
- [Flujo recomendado tras instalar](#flujo-recomendado-tras-instalar)
- [Resumen del routing híbrido](#resumen-del-routing-híbrido)
- [Subagentes y prompt workflows genéricos incluidos](#subagentes-y-prompt-workflows-genéricos-incluidos)
- [Verificación](#verificación)
- [Documentación relacionada](#documentación-relacionada)
- [Notas operativas](#notas-operativas)

---

## Qué hace esta instalación

Los scripts de este directorio realizan estas acciones:

1. Instalan `@earendil-works/pi-coding-agent` globalmente.
2. Copian `config/agent/*` a `~/.pi/agent` o `%USERPROFILE%\.pi\agent`.
3. Instalan y activan:
   - subagentes
   - adaptador MCP
   - extensión Pi de `context-mode`
4. Instalan el binario global `context-mode` y lo configuran en `mcp.json`.
5. Dejan disponible la extensión `ai-router`.
6. Preparan el comando `IMALEagent` (y `pi` como alias) orientado a contexto por proyecto.

El objetivo es disponer de una **base de trabajo coherente para IMALE** en cualquier proyecto.

---

## Qué se copia al entorno del usuario

La configuración fuente vive en:

- `../config/agent/`

Y se copia al entorno del usuario incluyendo, entre otros elementos:

- `settings.json`
- `mcp.json`
- `APPEND_SYSTEM.md`
- `extensions/`
- `agents/`
- `prompts/`
- `skills/`
- `themes/`

Esto significa que los scripts de `install/` son la puerta de entrada, pero el comportamiento final del agente depende principalmente de la configuración mantenida en `config/agent/`.

---

## Requisitos previos

### Requisitos mínimos

- **Node.js** `>= 18.0.0`
- **npm** disponible en PATH
- conexión a internet para descargar paquetes npm

### Comprobación rápida

```bash
node --version
npm --version
```

---

## Instalación desde el release (sin clonar el repositorio)

Instala IMALEagent descargando los *assets* del release. Descarga siempre el
script y **verifícalo con `SHA256SUMS` antes de ejecutarlo**.

### macOS / Linux / Windows (Git Bash / WSL)

```bash
BASE=https://github.com/IvanMartinezLeon/IMALEagent/releases/latest/download

curl -fsSLO "${BASE}/install.sh"
curl -fsSLO "${BASE}/SHA256SUMS"

# Linux: sha256sum -c install.sh.sha256
grep ' install\.sh$' SHA256SUMS > install.sh.sha256 && shasum -a 256 -c install.sh.sha256

bash install.sh
```

> También funciona en Windows si usas **Git Bash** o **WSL**.
>
> No uses `sh`: el instalador es bash (`${BASH_SOURCE[0]}`). Invócalo con `bash install.sh`.

`install.sh` descarga el tarball, verifica su checksum contra `SHA256SUMS` y
aborta sin extraer nada si no coincide.

### Windows (PowerShell o CMD)

`install/install.ps1` e `install/install.bat` resuelven `config/agent` desde su
propia ubicación y por eso **necesitan el árbol del repositorio**: se usan desde
dentro del tarball, no sueltos.

```powershell
$base = 'https://github.com/IvanMartinezLeon/IMALEagent/releases/latest/download'
Invoke-WebRequest -Uri "$base/imaleagent.tar.gz" -OutFile imaleagent.tar.gz
Invoke-WebRequest -Uri "$base/SHA256SUMS" -OutFile SHA256SUMS

# Verifica el tarball antes de extraerlo
(Get-FileHash .\imaleagent.tar.gz -Algorithm SHA256).Hash
Get-Content .\SHA256SUMS | Select-String 'imaleagent.tar.gz'

tar -xzf imaleagent.tar.gz
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install\install.ps1     # o install\install.bat desde CMD
```

### Instalar una versión específica

En Unix, mediante la variable de entorno que lee `install.sh`:

```bash
INSTALL_VERSION=v1.0.0 bash install.sh
```

En Windows, descarga los assets de ese tag cambiando `/latest/download` por
`/download/v1.0.0` en la URL base del bloque anterior.

---

## Instalación desde el repositorio

Si ya tienes clonado el repositorio:

### Linux / macOS

```bash
cd install
bash install.sh
```

### Windows PowerShell

```powershell
cd install
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

### Windows Command Prompt

```bat
cd install
install.bat
```

---

## Instalación manual mínima

> ⚠ No recomendada. Prefiere el instalador automático (un solo comando curl/iwr) que copia también toda la configuración IMALE.

Si aún así necesitas instalar los paquetes base manualmente, ejecuta los comandos equivalentes que aparecen en los scripts de `install/`.

> Importante: la instalación manual cubre los paquetes, pero **no sustituye completamente** a los scripts de este repositorio, porque no copia por sí sola toda la configuración IMALE. Si quieres dejar también `~/.pi/agent` alineado con este proyecto, usa el instalador automático.

---

## Primer arranque

Una vez terminada la instalación:

Una vez terminada la instalación:

```bash
cd /ruta/a/tu/proyecto
pi
```

Una vez arrancado:

```text
/login
/router-status
/mcp
```

---

## Flujo recomendado tras instalar

### 1. Confirmar routing y capacidades

```text
/router-status
```

Esto te indica si el entorno detecta correctamente:
- `subagentes`
- `context-mode`
- tipo de repositorio
- política de routing activa

### 2. Confirmar que las guías están disponibles

```text
/spec-mobile
/welcome
```

Las guías (`GENERIC_RULES.md`, `MOBILE_GUIDELINES.md`), las plantillas de SPEC/PLAN y las skills `flutter-guidelines`/`dart-guidelines` se copian a `~/.pi/agent/` y quedan disponibles en cualquier proyecto.

### 3. Usar el flujo adecuado según la tarea

#### Descubrimiento estructural
Mapea primero y después acota la búsqueda. En la práctica:

```bash
ls -la && find . -maxdepth 3 -type d -not -path "*/node_modules/*"
rg -n "symbol" src/module/ -t ts -m 10
rg "symbol\(" src/ -l -t ts
```

Para preguntas como:
- dónde está implementada una lógica
- qué consumidores se verán afectados
- qué tests revisar antes de tocar un archivo compartido
- qué patrones existentes conviene reutilizar

#### Funcionalidades nuevas
Empieza por la especificación: usa el prompt `/spec-mobile` o copia `templates/SPEC_TEMPLATE.md` como `SPEC.md`.

#### Subagentes y workflows genéricos
Cuando el trabajo sea reutilizable entre proyectos, delega con la capa genérica instalada globalmente.

Casos típicos:
- discovery antes de editar
- planificar antes de implementar
- implementación segura con single writer
- review puntual o review paralelo
- investigación externa + contexto local + plan

Ejemplos:

```text
/prompt-workflow generic-discovery entender esta parte del código
/prompt-workflow generic-implement-safe aplicar este cambio con validación
/run generic-parallel-review "Revisa este cambio con foco en corrección, cobertura de tests y simplicidad"
```

#### Edición puntual
Cuando ya conoces los archivos relevantes, usa:

```text
read
edit
write
bash
```

#### Logs y salidas pesadas
Para outputs grandes o análisis que no conviene volcar en conversación, usa:

```text
/mcp
```

Y después las tools `ctx_` de `context-mode`.

---

## Resumen del routing híbrido

La instalación deja preparado un flujo híbrido con tres capas:

- búsqueda acotada (`rg`, `read`) para descubrimiento e impacto
- `context-mode` para logs, salidas grandes y procesamiento pesado
- tools nativas (`read`, `edit`, `write`, `bash`) para implementación puntual

### Cuándo usar cada capa

#### Structural mode
Para preguntas como:
- dónde está implementado algo
- qué archivos están relacionados
- qué tests o consumidores pueden romperse
- qué patrón local conviene reutilizar

Empieza por:

```bash
ls -la && find . -maxdepth 3 -type d -not -path "*/node_modules/*"
rg -n "symbol" src/ -t ts -m 10
rg "symbol\(" src/ -l -t ts
```

#### Review mode
Para revisión de cambios, calidad o seguridad:

```bash
rg -l "<símbolo cambiado>" src/ -t ts      # consumidores afectados
```

Y después lectura puntual en los archivos shortlistados.

#### Debug-heavy mode
Para logs o outputs grandes:

```text
/mcp
```

Y luego tools `ctx_` de `context-mode`.

#### General mode
Cuando ya sabes qué tocar:

```text
read
edit
write
bash
```

### Intención del diseño

La idea no es sustituir las tools nativas, sino ordenar el flujo:

- la búsqueda acotada decide dónde mirar primero
- `context-mode` evita inundar la conversación con salida pesada
- las tools nativas ejecutan la implementación final

---

## Subagentes y prompt workflows genéricos incluidos

Esta configuración instala subagentes y además copia una capa genérica reutilizable para cualquier proyecto en:

- `~/.pi/agent/agents/`
- `~/.pi/agent/prompts/`

### Subagentes genéricos

- `generic-context-builder` → construye contexto compacto y accionable antes de planificar o editar
- `generic-planner` → crea un plan mínimo y ejecutable
- `generic-worker` → implementa cambios pequeños y validados como **single writer**
- `generic-fixer` → 🆕 arregla bugs rápido sin planificador, con diagnóstico y parche mínimo
- `generic-reviewer` → revisa planes, diffs e implementación con evidencia
- `generic-parallel-review` → orquesta revisión paralela con varios ángulos y devuelve una síntesis única
- `generic-doc-writer` → 🆕 escribe y mejora documentación técnica, READMEs y guías

### Prompt workflows genéricos

- `generic-discovery` → `scout` + `generic-context-builder`
- `generic-implement-safe` → `scout` + `generic-planner` + `generic-worker` + `generic-reviewer`
- `generic-fix-bug` → 🆕 `scout` + `generic-fixer` + `generic-reviewer` (bugs rápidos, sin planner)
- `generic-research-and-plan` → `researcher` + `scout` + `generic-planner`

### Optimización de costes: modelos por subagente

Cada subagente puede usar un modelo diferente al del agente principal. Esto permite gastar modelos baratos en tareas de lectura rápida y modelos potentes solo cuando toca planificar o implementar.

**Estrategia recomendada:**

| Subagente | Modelo sugerido | Coste | Motivo |
|---|---|---|---|
| **scout** | `gpt-5-mini` / `gemini-2.5-flash` | Bajo | Solo lectura, busca archivos |
| **context-builder** | `gpt-5-mini` / `gemini-2.5-flash` | Bajo | Solo lectura, sintetiza contexto |
| **planner** | `claude-sonnet-4` | Medio | Planificación, necesita razonamiento |
| **worker** | `claude-sonnet-4` | Medio | Implementación, necesita precisión |
| **reviewer** | `claude-sonnet-4` | Medio | Revisión, necesita criterio |

**Cómo configurarlo en `~/.pi/agent/settings.json`:**

```json
{
  "subagents": {
    "agentOverrides": {
      "scout": {
        "model": "openai/gpt-5-mini",
        "thinking": "off"
      },
      "context-builder": {
        "model": "openai/gpt-5-mini",
        "thinking": "off"
      },
      "planner": {
        "model": "anthropic/claude-sonnet-4",
        "thinking": "high"
      },
      "worker": {
        "model": "anthropic/claude-sonnet-4",
        "thinking": "high"
      },
      "reviewer": {
        "model": "anthropic/claude-sonnet-4",
        "thinking": "high"
      }
    }
  }
}
```

También se puede configurar por paso en un prompt workflow o inline al lanzar un agente:

```text
/run reviewer[model=anthropic/claude-sonnet-4] "Revisa este código"
```

> ⚡ **Ahorro estimado**: Usando `gpt-5-mini` para scout y context-builder, reduces el coste de esas fases ~10x sin perder calidad en el resultado final.

---

## Cuándo usarlas

### `generic-discovery`
Úsala cuando todavía no sabes:
- dónde está implementada una funcionalidad
- qué archivos deberías revisar primero
- qué superficie de impacto tiene un cambio

Ejemplo:

```text
/prompt-workflow generic-discovery entender el flujo de autenticación
```

#### `generic-implement-safe`
Úsala para cambios normales o medianos donde quieras un flujo seguro con un solo writer.

Ejemplo:

```text
/prompt-workflow generic-implement-safe aplicar este refactor siguiendo los patrones existentes
```

#### `generic-fix-bug`
Úsala para bugs que requieren diagnóstico, parche mínimo y validación rápida. Sin planificador, va directo al grano.

Ejemplo:

```text
/prompt-workflow generic-fix-bug el login falla con 401 aunque las credenciales son correctas
```

#### `generic-research-and-plan`
Úsala cuando necesites combinar documentación externa y contexto local antes de implementar.

Ejemplo:

```text
/prompt-workflow generic-research-and-plan evaluar cómo integrar esta librería en el proyecto
```

#### `generic-reviewer`
Úsalo para revisión puntual de un diff, plan o implementación.

Ejemplo:

```text
/run generic-reviewer "Revisa este diff con foco en regresiones y validación"
```

#### `generic-parallel-review`
Úsalo cuando quieras una revisión más fuerte con varios ángulos en paralelo.

Ángulos por defecto:
- corrección y regresiones
- tests y validación
- simplicidad y mantenibilidad

Si el prompt habla de auth, permisos, secretos, privacidad o compliance, el tercer ángulo pasa a ser de seguridad.

Ejemplo:

```text
/run generic-parallel-review "Revisa este cambio con foco en regresiones, tests y complejidad"
```

### Relación con `ai-router`

La extensión `ai-router` no lanza estos subagentes automáticamente, pero ahora sí puede sugerirlos cuando detecta prompts de:

- descubrimiento estructural amplio
- implementación multi-fase
- revisión profunda
- investigación con referencias externas

La activación sigue siendo explícita: tú decides cuándo ejecutar `/run`, `/prompt-workflow` o pedirlo en lenguaje natural.

---

## Verificación

### Linux / macOS

```bash
cd install
bash verify.sh
```

### Windows PowerShell

```powershell
cd install
.\verify.ps1
```

### Windows CMD

```bat
cd install
verify.bat
```

Las verificaciones comprueban, entre otros puntos:

- presencia de `node`, `npm` y `IMALEagent` / `pi`
- instalación y activación de subagentes
- instalación y activación del adaptador MCP
- instalación y activación de la extensión Pi de `context-mode`
- presencia de `context-mode` en `~/.pi/agent/mcp.json`
- disponibilidad de la extensión `ai-router`
- presencia de los subagentes genéricos instalados en `~/.pi/agent/agents`
- presencia de los prompt workflows genéricos instaladas en `~/.pi/agent/prompts`

---

## Documentación relacionada

### Dentro de `install/`

- `README.md` → guía principal de instalación, routing y uso de subagentes/prompt workflows genéricos
- `SETUP_GUIDE.md` → guía detallada, validación y troubleshooting

### Referencias externas

- [Pi](https://pi.dev/docs/latest)
- [subagentes](https://pi.dev/packages/pi-subagents)
- [adaptador MCP](https://pi.dev/packages/pi-mcp-adapter)

---

## Notas operativas

- Los instaladores usan `npm install -g --ignore-scripts` para reducir la superficie de ejecución innecesaria. **Excepción**: `context-mode` se instala globalmente sin `--ignore-scripts`, porque su dependencia `better-sqlite3` necesita el prebuild y el paquete ejecuta su propio `postinstall`.
- El servidor MCP de `context-mode` usa el binario global `context-mode`, no `npx`. Por eso `config/agent/mcp.json` declara `args: []`: el merge conserva las claves que el overlay no define, y sin ese array se heredarían los `args` de instalaciones antiguas basadas en `npx`.
- La configuración IMALE añade reglas operativas al agente, incluyendo comunicación en castellano y restricciones de escritura fuera del directorio activo sin permiso explícito.
- `context-mode` sigue siendo la vía recomendada para logs grandes, outputs pesados y procesamiento de contexto extenso.
- La extensión `ai-router` no sustituye a las tools nativas: ayuda a decidir **qué mirar primero** y **con qué herramienta conviene empezar**.

---

## Publicar un release

Para que el instalador `curl | sh` funcione, los scripts deben estar disponibles en una URL.

### Opción 1: Automático con GitHub Actions (recomendado)

El workflow `.github/workflows/release.yml` ya está configurado. Solo tienes que:

```bash
git tag v1.2.3
git push origin v1.2.3
```

Automáticamente se:
1. Genera el tarball
2. Crea un GitHub Release con los archivos adjuntos
3. Genera notas de release automáticas

### Opción 2: Manual desde terminal

```bash
# 1. Generar el tarball
bash scripts/build-release.sh v1.2.3

# 2. Crear tag y subirlo
git tag v1.2.3
git push origin v1.2.3

# 3. Crear release con gh CLI
#    Mismos assets que publica release.yml: el entry point, el tarball (con su
#    alias) y sus checksums. install/install.ps1|bat no se publican sueltos:
#    necesitan el árbol del repo y van dentro del tarball.
gh release create v1.2.3 \
  dist/imaleagent-v1.2.3.tar.gz \
  dist/imaleagent.tar.gz \
  dist/SHA256SUMS \
  install.sh \
  --title "v1.2.3" \
  --notes "..."
```

### Opción 3: desde el repositorio clonado (desarrollo)

Sin release publicado, el camino soportado es ejecutar el instalador del propio
repositorio (no hay rama `release` ni scripts servidos por RAW):

```bash
bash install/install.sh          # Linux / macOS / Git Bash / WSL
```

```powershell
.\install\install.ps1            # Windows PowerShell
```

> ⚠ **Desarrollo no es reproducible.** Para instalaciones reales usa siempre un tag versionado y verifica `SHA256SUMS`.

### Opción 4: Dominio propio

Con un dominio propio (`IMALEagent.dev`), sirve el script desde un CDN o haz un redirect a los assets del release en GitHub, manteniendo la verificación de `SHA256SUMS`.

---

## Resumen rápido

Si quieres el flujo mínimo recomendado:

1. ejecuta el instalador de tu plataforma
2. valida con `verify.*`
3. ejecuta `IMALEagent` dentro de un proyecto
4. ejecuta `/router-status`
5. revisa `config/agent/GENERIC_RULES.md` y las plantillas de SPEC/PLAN
6. prueba al menos uno de estos flujos: `generic-discovery` o `generic-implement-safe`
7. usa `rg` acotado antes de explorar a ciegas
8. usa `context-mode` para salidas grandes
