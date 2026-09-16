# IMALEagent

Repositorio de **instalación, configuración y onboarding técnico** para un entorno de trabajo basado en **Pi** dentro de IMALE.

Su función principal es dejar preparado un agente de desarrollo con una configuración homogénea, orientada a:

- exploración dirigida y acotada del código base
- gestión de contexto pesado con **context-mode**
- automatización y delegación con **subagentes**
- extensibilidad mediante **extensions**, **skills** y **themes** propios

> Este repo no contiene una aplicación de negocio. Contiene la base para instalar y operar IMALEagent.

---

## Tabla de contenidos

- [Objetivo](#objetivo)
- [Qué instala y configura](#qué-instala-y-configura)
- [Arquitectura del repositorio](#arquitectura-del-repositorio)
- [Mapa rápido del repo](#mapa-rápido-del-repo)
- [Estructura final recomendada](#estructura-final-recomendada)
- [Quick start para desarrolladores](#quick-start-para-desarrolladores)
- [Flujo recomendado dentro de Pi](#flujo-recomendado-dentro-de-pi)
- [Cómo funciona la configuración](#cómo-funciona-la-configuración)
- [Componentes técnicos clave](#componentes-técnicos-clave)
- [Scripts disponibles](#scripts-disponibles)
- [Verificación y diagnóstico](#verificación-y-diagnóstico)
- [Prueba de concepto incluida](#prueba-de-concepto-incluida)
- [Documentación interna](#documentación-interna)
- [Requisitos](#requisitos)

---

## Objetivo

Estandarizar cómo se instala y usa IMALEagent en cualquier proyecto.

Este repositorio evita que cada desarrollador tenga que configurar manualmente:

- paquetes adicionales
- MCPs necesarios
- extensiones de routing
- subagentes y prompt workflows genéricos reutilizables
- skills internas
- tema visual y preferencias básicas
- flujo recomendado para tareas de análisis, review y edición

El resultado esperado es que dos desarrolladores distintos, tras ejecutar el instalador, trabajen con una experiencia casi idéntica.

---

## Qué instala y configura

Los scripts de instalación dejan preparado lo siguiente:

### Binario base
- `@earendil-works/pi-coding-agent`

### Capacidades incluidas
- delegación y coordinación entre agentes
- adaptador MCP
- extensión Pi de `context-mode` (hooks de sesión, tools `ctx_*` y skills `ctx-*`)
- `pi-lens` para feedback en tiempo real de código (LSP, linters, formatters)
- `rpiv-todo` para seguimiento de tareas persistente sobre el editor
- `rpiv-ask-user-question` para cuestionarios estructurados al usuario

### Configuración de agente
Se copia `config/agent/*` a `~/.pi/agent`, incluyendo:

- `settings.json`
- `mcp.json`
- `presets.json`
- `APPEND_SYSTEM.md`
- `extensions/`
- `agents/`
- `prompts/`
- `skills/`
- `themes/`
- `templates/`
- `examples/`

### Integraciones operativas
- `context-mode` como MCP lazy-loaded mediante el binario global `context-mode`
- extensión `ai-router` para routing híbrido
- launcher `pi` (comando `IMALEagent`) orientado a contexto por proyecto

---

## Arquitectura del repositorio

El repositorio está organizado en tres capas:

### 1. Capa de instalación: `install/`
Contiene scripts multiplataforma y documentación operativa.

Responsabilidades:
- instalar IMALEagent y paquetes asociados
- copiar configuración al home del usuario
- dejar disponible el comando `IMALEagent` (y `pi` como alias)
- validar instalación y entorno
- documentar troubleshooting y flujo recomendado

### 2. Capa de configuración: `config/agent/`
Contiene la configuración real que ejecutará el agente una vez instalada.

Responsabilidades:
- definir comportamiento base del agente
- activar MCPs
- inyectar instrucciones de sistema adicionales
- registrar extensiones y habilidades reutilizables
- registrar subagentes y prompt workflows genéricos reutilizables
- aplicar identidad visual IMALE

### 3. Capa de guías de trabajo: `config/agent/*.md` y `config/agent/templates/`
Contiene las reglas y plantillas reutilizables que el agente instalado carga en cada sesión.

Responsabilidades:
- definir reglas de trabajo genéricas (`GENERIC_RULES.md`)
- cubrir especificaciones mobile (`MOBILE_GUIDELINES.md`)
- ofrecer plantillas de SPEC y PLAN reutilizables
- servir de material de onboarding

---

## Mapa rápido del repo

```text
.
├── config/
│   └── agent/
│       ├── APPEND_SYSTEM.md          # reglas de sistema añadidas al agente
│       ├── GENERIC_RULES.md          # reglas de trabajo reutilizables
│       ├── MOBILE_GUIDELINES.md      # puntos que cubrir en una spec mobile
│       ├── BEST_PRACTICES.md         # estándares de ingeniería
│       ├── EXPLORATION_STRATEGY.md   # estrategia de exploración (mapear → acotar → leer)
│       ├── GUIDANCE_INDEX.md         # índice de recursos disponibles
│       ├── settings.json             # ajustes base del agente
│       ├── mcp.json                  # definición MCP, incluyendo context-mode
│       ├── presets.json              # presets del agente (comando imale:preset)
│       ├── extensions/
│       │   ├── ai-router.ts          # routing híbrido según tipo de prompt
│       │   ├── imale-header.ts       # personalización visual/comportamiento UI
│       │   ├── imale-preset.ts       # selector interactivo de presets
│       │   └── lib/shared-ui.ts      # helpers TUI compartidos
│       ├── agents/                   # subagentes genéricos reutilizables
│       ├── prompts/                  # prompt workflows reutilizables
│       ├── skills/                   # skills especializadas IMALE
│       ├── templates/                # plantillas SPEC/PLAN y de exploración
│       ├── examples/                 # ejemplos de exploración por tecnología
│       └── themes/                   # tema visual del agente
├── install.sh                        # entry point cross-platform (curl|sh)
├── install/
│   ├── install.sh                    # instalador Linux/macOS
│   ├── install.ps1                   # instalador Windows PowerShell
│   ├── install.bat                   # instalador Windows CMD
│   ├── verify.*                      # validación post-instalación
│   ├── uninstall.*                   # desinstalación
│   ├── templates/                    # wrappers y plantillas auxiliares
│   ├── lib/                          # helpers Node: merge, manifiesto, desinstalación
│   │   ├── config-stage.sh
│   │   ├── merge-config.mjs
│   │   ├── write-manifest.mjs
│   │   └── uninstall-config.mjs
│   └── *.md                          # guías operativas
├── scripts/
│   ├── build-release.sh              # genera release tarball para curl|sh
│   └── test-install.sh               # test E2E de instalación/desinstalación
```

---

## Estructura final recomendada

Después de la limpieza documental, la estructura recomendada del repositorio queda así:

```text
.
├── README.md                        # visión general, onboarding y arquitectura
├── config/
│   └── agent/                      # configuración fuente que se copia a ~/.pi/agent
├── install/
│   ├── README.md                   # guía principal de instalación y routing
│   ├── SETUP_GUIDE.md              # validación, troubleshooting y diagnóstico
│   ├── install.*                   # instaladores por plataforma
│   ├── verify.*                    # scripts de verificación
│   ├── uninstall.*                 # scripts de desinstalación
│   ├── templates/                  # wrappers auxiliares usados por los instaladores
│   └── lib/                        # helpers Node: merge de config, manifiesto, desinstalación
├── scripts/
│   ├── build-release.sh            # genera el release tarball de curl|sh
│   └── test-install.sh             # test E2E de instalación/desinstalación
```

### Criterio de mantenimiento

La idea es mantener **pocos documentos y con responsabilidades claras**:

- `README.md` explica **qué es el repo y cómo orientarse**.
- `install/README.md` explica **cómo instalarlo y cómo usar el routing básico**.
- `install/SETUP_GUIDE.md` explica **cómo validarlo y diagnosticar problemas**.

Cualquier nueva documentación debería añadirse solo si aporta contenido no cubierto por estos tres documentos.

---

## Quick start para desarrolladores

### 1. Verifica prerequisitos

```bash
node --version
npm --version
```

Requisitos mínimos:
- Node.js `>= 18`
- npm disponible en PATH

### 2. Ejecuta el instalador

#### Opción rápida (assets del release) — sin clonar el repo

Los instaladores se publican como *assets* del release junto a `SHA256SUMS`.
Descarga y **verifica el script antes de ejecutarlo**:

**macOS / Linux / Windows (Git Bash / WSL):**

```bash
BASE=https://github.com/IvanMartinezLeon/IMALEagent/releases/latest/download

curl -fsSLO "${BASE}/install.sh"
curl -fsSLO "${BASE}/SHA256SUMS"

# Verifica install.sh (en Linux: sha256sum -c install.sh.sha256)
grep ' install\.sh$' SHA256SUMS > install.sh.sha256 && shasum -a 256 -c install.sh.sha256

bash install.sh
```

`install.sh` descarga el tarball, **verifica su checksum contra `SHA256SUMS`** y aborta sin extraer nada si no coincide.

Para fijar una versión: `INSTALL_VERSION=v1.0.0 bash install.sh`.

**Windows (PowerShell o CMD):**

Los scripts de Windows necesitan el árbol del repositorio, así que el camino soportado es el tarball:

```powershell
$base = 'https://github.com/IvanMartinezLeon/IMALEagent/releases/latest/download'
Invoke-WebRequest -Uri "$base/imaleagent.tar.gz" -OutFile imaleagent.tar.gz
Invoke-WebRequest -Uri "$base/SHA256SUMS" -OutFile SHA256SUMS

# Verifica el tarball antes de extraerlo
(Get-FileHash .\imaleagent.tar.gz -Algorithm SHA256).Hash
Get-Content .\SHA256SUMS | Select-String 'imaleagent.tar.gz'

tar -xzf imaleagent.tar.gz
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install\install.ps1
```

#### Opción desde el repositorio clonado

**Linux / macOS:**

```bash
cd install
bash install.sh
```

**Windows PowerShell:**

```powershell
cd install
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

**Windows CMD:**

```bat
cd install
install.bat
```

### 3. Valida la instalación

#### Linux / macOS

```bash
cd install
bash verify.sh
```

#### Windows PowerShell

```powershell
cd install
.\verify.ps1
```

#### Windows CMD

```bat
cd install
verify.bat
```

### 4. Abre IMALEagent en un proyecto

```bash
cd /ruta/a/tu/proyecto
pi
```

---

## Flujo recomendado dentro de Pi

Una vez dentro de Pi, el flujo operativo recomendado es:

```text
/login
/router-status
/mcp
```

### Para descubrimiento estructural
Mapea primero la estructura y después acota la búsqueda:

- `ls`, `find -maxdepth` y `AGENTS.md` para orientarte
- `rg -n "symbol" <directorio> -t <tipo>` para localizar uso
- `rg "symbol\(" <path> -l` para listar consumidores

Úsalo para preguntas como:
- dónde está implementado algo
- qué archivos dependen de un módulo
- qué tests o consumidores pueden romperse
- qué patrones locales existen ya en el repo

### Para subagentes y workflows genéricos
Usa los agentes y prompt workflows genéricos instalados globalmente cuando quieras delegar trabajo reutilizable entre proyectos.

Ejemplos útiles:

- `generic-context-builder` → construir contexto accionable antes de planificar
- `generic-planner` → convertir contexto en un plan mínimo
- `generic-worker` → implementar como single writer
- `generic-fixer` → arreglar bugs rápido sin planificador
- `generic-reviewer` → revisar un diff, plan o implementación
- `generic-parallel-review` → revisión paralela con varios ángulos
- `generic-doc-writer` → escribir o mejorar documentación técnica
- `generic-discovery` → discovery antes de editar
- `generic-implement-safe` → scout + plan + implementación + review
- `generic-fix-bug` → scout + fixer + reviewer (bugs rápidos)
- `generic-research-and-plan` → referencias externas + contexto local + plan
- `spec-mobile` → arranque rápido de especificación mobile

Ejemplos de uso:

```text
/prompt-workflow generic-discovery entender esta parte del código
/prompt-workflow generic-implement-safe aplicar este cambio con validación
/run generic-parallel-review "Revisa este cambio con foco en regresiones, validación y mantenibilidad"
```

### Para edición puntual
Cuando ya conoces los archivos relevantes, usa:

- `read`
- `edit`
- `write`
- `bash`

### Para logs o salidas grandes
Usa `context-mode`: sus tools `ctx_*` se registran por la extensión Pi y por el servidor MCP, además de las skills `ctx-search`, `ctx-index`, `ctx-stats`, `ctx-doctor`, `ctx-purge`, `ctx-insight` y `ctx-upgrade`.

Es el flujo recomendado para:
- logs extensos
- salidas de tests grandes
- búsquedas amplias
- agregación o parsing de información grande

---

## Cómo funciona la configuración

### `config/agent/settings.json`
Define ajustes base del agente, por ejemplo:
- tema activo
- preferencias de arranque
- opciones visuales

### `config/agent/mcp.json`
Declara servidores MCP. En este repo destaca:
- `context-mode`, lanzado con el binario global `context-mode` (`args: []` explícito para que el merge descarte los args de instalaciones antiguas basadas en `npx`)

### `config/agent/APPEND_SYSTEM.md`
Añade reglas de comportamiento del agente. Entre ellas:
- comunicación siempre en castellano
- código técnico en inglés
- obligación de pedir permiso antes de escribir fuera del directorio activo

### `config/agent/extensions/ai-router.ts`
Es una pieza clave del repositorio.

Responsabilidades principales:
- detectar capacidad del entorno (`router_status`)
- clasificar el prompt en modos como `general`, `structural`, `review` y `debug-heavy`
- inyectar reglas de routing en el system prompt
- sugerir búsqueda acotada (`rg` con ruta y filtro de tipo) antes de exploración amplia
- sugerir subagentes y prompt workflows genéricos cuando encajan con la tarea
- advertir cuando conviene usar `context-mode`

### `imale-header.ts`
Personalización visual y de comportamiento de la UI (branding IMALE).

### `imale-preset.ts`
Selector interactivo de presets vía el comando `imale:preset`.

---

## Componentes técnicos clave

### `ai-router`
Capa de orquestación ligera para decidir qué herramienta conviene usar antes.

Aporta:
- heurística de clasificación de prompts
- status contextual en UI
- reglas de routing híbrido

### `context-mode`
Se usa como complemento cuando el problema no es “qué editar”, sino “cómo analizar mucho contexto sin saturar la conversación”.

Se instala de dos formas complementarias:
- `npm install -g context-mode` → aporta el binario que lanza el servidor MCP
- `pi install npm:context-mode` → aporta la extensión Pi (hooks de sesión y routing) y las skills `ctx-*`

Casos típicos:
- resumir logs
- procesar salidas grandes de herramientas
- indexar documentación o resultados intermedios
- consultar memoria contextual almacenada

### `subagentes`
Permite delegar o paralelizar trabajo con subagentes.

Útil para:
- análisis en paralelo
- cadenas de revisión/planificación
- handoffs controlados
- tareas multi-fase con coordinación
- workflows genéricos reutilizables entre proyectos

En esta configuración se complementa con agentes y prompt workflows genéricos instalados desde `config/agent/agents/` y `config/agent/prompts/`.

Set incluido actualmente (`config/agent/agents/` y `config/agent/prompts/`):
- **agentes** (7): `generic-context-builder`, `generic-doc-writer`, `generic-fixer`, `generic-parallel-review`, `generic-planner`, `generic-reviewer`, `generic-worker`
- **prompt workflows** (5): `generic-discovery`, `generic-fix-bug`, `generic-implement-safe`, `generic-research-and-plan`, `spec-mobile`
- **step workflows** (7): `step-context-builder`, `step-fixer`, `step-planner`, `step-research`, `step-reviewer`, `step-scout`, `step-worker`
- **ejemplos** (1): `exploration-flutter-keko.md`

### Skills IMALE
El repo incorpora skills para tareas específicas (`config/agent/skills/`):
- `api-design`
- `architecture`
- `dart-guidelines` (móvil)
- `documentation`
- `fix`
- `flutter-guidelines` (móvil)
- `git`
- `learn`
- `review`
- `security`
- `spec-driven-development`
- `sync`
- `testing`
- `workflow-coordination`

---

## Scripts disponibles

### Instalación
- `install/install.sh`
- `install/install.ps1`
- `install/install.bat`

### Verificación
- `install/verify.sh`
- `install/verify.ps1`
- `install/verify.bat`

### Desinstalación
- `install/uninstall.sh`
- `install/uninstall.ps1`
- `install/uninstall.bat`

Todos los scripts están pensados para uso directo, sin depender de tooling adicional del repo.

---

## Verificación y diagnóstico

Además de los scripts `verify.*`, el stack recomienda estas comprobaciones:

```text
/router-status
/mcp
```

Qué valida cada una:

- `/router-status`: confirma si el routing híbrido detecta correctamente `subagentes` y `context-mode`
- `/mcp`: comprueba accesibilidad de MCPs y tools externas

---

## Plantillas de trabajo incluidas

El repositorio incluye plantillas reutilizables en `config/agent/templates/`:

- `SPEC_TEMPLATE.md` → qué debe cumplirse (se copia como `SPEC.md`)
- `PLAN_TEMPLATE.md` → cómo se implementa (se copia como `PLAN.md`)
- `project-exploration-guide.md` → estrategia de exploración por proyecto

Guías complementarias en `config/agent/`:

- `GENERIC_RULES.md` → reglas de trabajo aplicables a cualquier tarea
- `MOBILE_GUIDELINES.md` → puntos que debe cubrir la spec de una app mobile
- skills `flutter-guidelines` y `dart-guidelines` → directrices técnicas

Arranque rápido de una especificación mobile: `/spec-mobile`

---

## Documentación interna

Dentro de `install/` se mantiene solo la documentación operativa necesaria:

- `install/README.md` → guía principal de instalación, routing y uso de subagentes/prompt workflows genéricos
- `install/SETUP_GUIDE.md` → instalación detallada, validación y troubleshooting

---

## Requisitos

### Sistema
- Linux, macOS o Windows
- Node.js `>= 18`
- npm `>= 8`

### Operativos
- conexión a internet para instalar paquetes npm
- permisos de escritura sobre `~/.pi/agent`
- terminal compatible con el script de la plataforma correspondiente

---

## Resumen para onboarding

Si acabas de llegar al proyecto, el recorrido mínimo recomendado es:

1. lee este `README.md`
2. ejecuta el instalador de tu plataforma en `install/`
3. ejecuta el verificador correspondiente
4. abre IMALEagent dentro de un proyecto real
5. lanza `/router-status` para confirmar subagentes y context-mode
6. revisa `install/README.md` para ver el uso de subagentes y prompt workflows genéricos
7. prueba al menos uno de estos flujos: `generic-discovery` o `generic-implement-safe`
8. revisa `config/agent/GENERIC_RULES.md` y las plantillas de SPEC/PLAN antes de empezar una funcionalidad

Con eso deberías entender:
- qué instala este repo
- cómo se comporta el agente resultante
- qué herramientas usar primero según el tipo de tarea
- dónde extender la configuración si necesitas evolucionar el stack
