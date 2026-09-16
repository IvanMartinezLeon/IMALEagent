#!/bin/bash

# Instalador de IMALEagent para Linux/macOS

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== IMALEagent Installer (Linux/macOS) ===${NC}"
echo ""

if ! command -v node &>/dev/null; then
	echo -e "${RED}✗ Error: Node.js no está instalado.${NC}"
	echo -e "${YELLOW}Instala Node.js v18.0.0 o superior desde https://nodejs.org/${NC}"
	exit 1
fi

echo -e "${GREEN}✓ Node.js $(node -v) detectado${NC}"

if ! command -v npm &>/dev/null; then
	echo -e "${RED}✗ Error: npm no está instalado.${NC}"
	exit 1
fi

echo -e "${GREEN}✓ npm $(npm -v) detectado${NC}"
echo ""

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SOURCE_DIR="${SCRIPT_DIR}/../config/agent"
TEMPLATE_DIR="${SCRIPT_DIR}/templates"
AGENT_CONFIG_DIR="${HOME}/.pi/agent"
AGENT_BIN_DIR="${AGENT_CONFIG_DIR}/bin"
WRAPPER_PATH="${AGENT_BIN_DIR}/pi"
# La etapa de configuración (backup + copia + merge + manifiesto) vive en
# lib/config-stage.sh para poder probarla de forma aislada.
CONFIG_STAGE="${SCRIPT_DIR}/lib/config-stage.sh"
if [ ! -f "${CONFIG_STAGE}" ]; then
	echo -e "${RED}✗ Error: No se encontró ${CONFIG_STAGE}${NC}"
	exit 1
fi
# shellcheck source=lib/config-stage.sh
. "${CONFIG_STAGE}"

append_path_block() {
	local rc_file="$1"
	local marker_start="# >>> IMALEagent PATH >>>"

	mkdir -p "$(dirname "${rc_file}")"
	touch "${rc_file}"

	if grep -Fqs "${marker_start}" "${rc_file}"; then
		return 0
	fi

	cat >>"${rc_file}" <<'EOF'
# >>> IMALEagent PATH >>>
export PATH="$HOME/.pi/agent/bin:$PATH"
# <<< IMALEagent PATH <<<
EOF
}

resolve_real_pi_bin() {
	local wrapper_candidate="${AGENT_BIN_DIR}/pi"
	local candidate=""

	if command -v pi &>/dev/null; then
		candidate="$(command -v pi)"
		if [ "${candidate}" != "${wrapper_candidate}" ]; then
			printf '%s\n' "${candidate}"
			return 0
		fi
	fi

	local npm_global_prefix=""
	npm_global_prefix="$(npm prefix -g 2>/dev/null || true)"
	if [ -n "${npm_global_prefix}" ] && [ -x "${npm_global_prefix}/bin/pi" ]; then
		printf '%s\n' "${npm_global_prefix}/bin/pi"
		return 0
	fi

	return 1
}

check_pi_package() {
	local pkg="$1"
	local label="$2"
	local list_output
	list_output="$("${PI_BIN}" list 2>/dev/null || true)"
	if echo "${list_output}" | grep -q "${pkg}"; then
		echo -e "${GREEN}✓ ${label}${NC}: Instalado y activo"
		return 0
	else
		echo -e "${RED}✗ ${label}${NC}: No detectado en 'pi list'"
		return 1
	fi
}

verify_subagent_config() {
	local required=(
		"generic-context-builder.md"
		"generic-doc-writer.md"
		"generic-fixer.md"
		"generic-planner.md"
		"generic-worker.md"
		"generic-reviewer.md"
		"generic-parallel-review.md"
	)
	local missing=0
	for f in "${required[@]}"; do
		if [ ! -f "${AGENT_CONFIG_DIR}/agents/${f}" ]; then
			((missing++))
		fi
	done
	if [ ${missing} -eq 0 ]; then
		echo -e "${GREEN}✓ Subagentes genéricos${NC}: Configuración copiada correctamente"
	else
		echo -e "${RED}✗ Subagentes genéricos${NC}: Faltan ${missing} archivo(s) — la configuración no se copió completamente"
		return 1
	fi
}

# Guías y plantillas del flujo SPEC -> PLAN -> TASKS y del soporte mobile.
verify_guides_and_templates() {
	local required=(
		"GENERIC_RULES.md"
		"MOBILE_GUIDELINES.md"
		"templates/SPEC_TEMPLATE.md"
		"templates/PLAN_TEMPLATE.md"
		"skills/flutter-guidelines/SKILL.md"
		"skills/dart-guidelines/SKILL.md"
		"prompts/spec-mobile.md"
	)
	local missing=0
	for f in "${required[@]}"; do
		if [ ! -f "${AGENT_CONFIG_DIR}/${f}" ]; then
			((missing++))
		fi
	done
	if [ ${missing} -eq 0 ]; then
		echo -e "${GREEN}✓ Guías y plantillas${NC}: Copiadas correctamente"
	else
		echo -e "${RED}✗ Guías y plantillas${NC}: Faltan ${missing} archivo(s) — la configuración no se copió completamente"
		return 1
	fi
}

echo -e "${YELLOW}Instalando IMALEagent...${NC}"
if ! npm install -g --loglevel=error --ignore-scripts @earendil-works/pi-coding-agent >/dev/null 2>&1; then
	echo -e "${RED}✗ Error: No se pudo instalar @earendil-works/pi-coding-agent${NC}"
	exit 1
fi

# context-mode se instala globalmente porque el servidor MCP de mcp.json usa su
# binario `context-mode`. Sin --ignore-scripts: better-sqlite3 necesita su prebuild
# y el paquete ejecuta su propio postinstall.
echo -e "${YELLOW}Instalando context-mode (global)...${NC}"
if ! npm install -g --loglevel=error context-mode >/dev/null 2>&1; then
	echo -e "${RED}✗ Error: No se pudo instalar context-mode globalmente${NC}"
	exit 1
fi

echo -e "${YELLOW}Copiando la configuración de IMALEagent...${NC}"
install_config_stage "bin/pi" "bin/imaleagent"
echo -e "${GREEN}✓ Configuración copiada ${NC}"
echo -e "${GREEN}✓ Extensiones del agente instaladas${NC} (ai-router, imale-header, imale-preset)"
verify_subagent_config
verify_guides_and_templates

echo -e "${YELLOW}Instalando y activando paquetes...${NC}"
PI_BIN="$(resolve_real_pi_bin || true)"

if [ -z "${PI_BIN}" ]; then
	echo -e "${RED}✗ Error: No se pudo localizar el ejecutable de pi después de la instalación.${NC}"
	exit 1
fi

echo -e "${YELLOW}Instalando Coding Agent...${NC}"
if "${PI_BIN}" install npm:pi-subagents >/dev/null 2>&1; then
	echo -e "${GREEN}✓ Paquete Coding Agent instalado${NC}"
else
	echo -e "${RED}✗ Error al instalar Coding Agent (pi-subagents)${NC}"
	exit 1
fi

echo -e "${YELLOW}Instalando MCP Adapter...${NC}"
if "${PI_BIN}" install npm:pi-mcp-adapter >/dev/null 2>&1; then
	echo -e "${GREEN}✓ Paquete MCP Adapter instalado${NC}"
else
	echo -e "${RED}✗ Error al instalar MCP Adapter (pi-mcp-adapter)${NC}"
	exit 1
fi

echo -e "${YELLOW}Instalando Context Mode...${NC}"
if "${PI_BIN}" install npm:context-mode >/dev/null 2>&1; then
	echo -e "${GREEN}✓ Paquete Context Mode instalado${NC}"
else
	echo -e "${RED}✗ Error al instalar Context Mode (context-mode)${NC}"
	exit 1
fi

echo -e "${YELLOW}Instalando pi-lens...${NC}"
if "${PI_BIN}" install npm:pi-lens >/dev/null 2>&1; then
	echo -e "${GREEN}✓ Paquete pi-lens instalado${NC}"
else
	echo -e "${RED}✗ Error al instalar pi-lens${NC}"
	exit 1
fi

echo -e "${YELLOW}Instalando rpiv-todo...${NC}"
if "${PI_BIN}" install npm:@juicesharp/rpiv-todo >/dev/null 2>&1; then
	echo -e "${GREEN}✓ Paquete rpiv-todo instalado${NC}"
else
	echo -e "${RED}✗ Error al instalar rpiv-todo${NC}"
	exit 1
fi

echo -e "${YELLOW}Instalando rpiv-ask-user-question...${NC}"
if "${PI_BIN}" install npm:@juicesharp/rpiv-ask-user-question >/dev/null 2>&1; then
	echo -e "${GREEN}✓ Paquete rpiv-ask-user-question instalado${NC}"
else
	echo -e "${RED}✗ Error al instalar rpiv-ask-user-question${NC}"
	exit 1
fi

echo -e "${YELLOW}Verificando paquetes instalados...${NC}"
check_pi_package "pi-subagents" "Coding Agent" || true
check_pi_package "pi-mcp-adapter" "MCP Adapter" || true
check_pi_package "context-mode" "Context Mode" || true
check_pi_package "pi-lens" "pi-lens" || true
check_pi_package "@juicesharp/rpiv-todo" "rpiv-todo" || true
check_pi_package "@juicesharp/rpiv-ask-user-question" "rpiv-ask-user-question" || true

if [ ! -f "${TEMPLATE_DIR}/pi-unix-wrapper.sh" ]; then
	echo -e "${RED}✗ Error: No se encontró la plantilla del wrapper en ${TEMPLATE_DIR}/pi-unix-wrapper.sh${NC}"
	exit 1
fi

if [ ! -f "${TEMPLATE_DIR}/imaleagent-wrapper.sh" ]; then
	echo -e "${RED}✗ Error: No se encontró la plantilla del wrapper en ${TEMPLATE_DIR}/imaleagent-wrapper.sh${NC}"
	exit 1
fi

mkdir -p "${AGENT_BIN_DIR}"
PI_BIN_ESCAPED="$(printf '%s' "${PI_BIN}" | sed 's/[&|]/\\&/g')"
sed "s|__PI_REAL_BIN__|${PI_BIN_ESCAPED}|g" "${TEMPLATE_DIR}/pi-unix-wrapper.sh" >"${WRAPPER_PATH}"
chmod +x "${WRAPPER_PATH}"

# Crear comando imaleagent
IMALE_WRAPPER_PATH="${AGENT_BIN_DIR}/imaleagent"
sed "s|__PI_REAL_BIN__|${PI_BIN_ESCAPED}|g" "${TEMPLATE_DIR}/imaleagent-wrapper.sh" >"${IMALE_WRAPPER_PATH}"
chmod +x "${IMALE_WRAPPER_PATH}"

append_path_block "${HOME}/.profile"
append_path_block "${HOME}/.bashrc"
append_path_block "${HOME}/.zshrc"
export PATH="${AGENT_BIN_DIR}:$PATH"

echo -e "${GREEN}[OK] IMALEagent installed at ${WRAPPER_PATH}${NC}"

echo ""

if command -v pi &>/dev/null; then
	echo -e "${GREEN}[OK] IMALEagent is available in your PATH${NC}"
else
	echo -e "${YELLOW}[WARN] Restart your terminal or run: source ~/.bashrc${NC}"
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. cd /your/project  &&  imaleagent"
echo "  2. /login  or  export ANTHROPIC_API_KEY=your-key"
echo "  3. Docs: https://pi.dev/docs/latest"
echo ""
echo -e "${BLUE}Config installed:${NC} ${AGENT_CONFIG_DIR}"
echo ""
