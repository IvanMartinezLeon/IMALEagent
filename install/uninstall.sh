#!/bin/bash

# IMALEagent Uninstaller for Linux/macOS
# Uninstall script for IMALEagent

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== IMALEagent Uninstaller (Linux/macOS) ===${NC}"
echo ""

# Check if npm is installed
if ! command -v npm &>/dev/null; then
	echo -e "${RED}✗ Error: npm is not installed.${NC}"
	exit 1
fi

echo -e "${YELLOW}This will uninstall IMALEagent from your system.${NC}"
read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo -e "${YELLOW}Uninstallation cancelled.${NC}"
	exit 0
fi

AGENT_CONFIG_DIR="${HOME}/.pi/agent"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
UNINSTALL_HELPER="${SCRIPT_DIR}/lib/uninstall-config.mjs"

PI_BIN=""
if command -v pi &>/dev/null; then
	PI_BIN="$(command -v pi)"
else
	NPM_GLOBAL_PREFIX="$(npm prefix -g 2>/dev/null || true)"
	if [ -n "${NPM_GLOBAL_PREFIX}" ] && [ -x "${NPM_GLOBAL_PREFIX}/bin/pi" ]; then
		PI_BIN="${NPM_GLOBAL_PREFIX}/bin/pi"
	fi
fi

check_pi_package_presence() {
	local pkg="$1"
	local label="$2"
	if [ -n "${PI_BIN}" ]; then
		local list_output
		list_output="$("${PI_BIN}" list 2>/dev/null || true)"
		if echo "${list_output}" | grep -q "${pkg}" 2>/dev/null; then
			echo -e "  ${GREEN}✓${NC} ${label}"
			return 0
		fi
	fi
	echo -e "  ${YELLOW}⚠${NC} ${label}: No instalado"
	return 0
}

check_config_presence() {
	local file="$1"
	local label="$2"
	if [ -f "${AGENT_CONFIG_DIR}/${file}" ] || [ -d "${AGENT_CONFIG_DIR}/${file}" ]; then
		echo -e "  ${GREEN}✓${NC} ${label}"
	else
		echo -e "  ${YELLOW}⚠${NC} ${label}: No encontrado"
	fi
	return 0
}

echo ""
echo -e "${YELLOW}Checking installed packages...${NC}"
check_pi_package_presence "@catdaemon/pi-code-intelligence" "Code Intelligence"
check_pi_package_presence "pi-mcp-adapter" "MCP Adapter"
check_pi_package_presence "pi-subagents" "Coding Agent"

echo ""
echo -e "${YELLOW}Checking subagent config...${NC}"
check_config_presence "agents/generic-context-builder.md" "generic-context-builder"
check_config_presence "agents/generic-planner.md" "generic-planner"
check_config_presence "agents/generic-worker.md" "generic-worker"
check_config_presence "agents/generic-reviewer.md" "generic-reviewer"
check_config_presence "agents/generic-parallel-review.md" "generic-parallel-review"
check_config_presence "prompts/generic-discovery.md" "generic-discovery prompt workflow"
check_config_presence "prompts/generic-implement-safe.md" "generic-implement-safe prompt workflow"
check_config_presence "prompts/generic-research-and-plan.md" "generic-research-and-plan prompt workflow"

echo ""
echo -e "${YELLOW}Removing IMALE packages...${NC}"

if [ -n "${PI_BIN}" ]; then
	echo -e "${YELLOW}  Desinstalando Ask User...${NC}"
	if "${PI_BIN}" remove npm:pi-ask-user >/dev/null 2>&1; then
		echo -e "${GREEN}  ✓ Ask User desinstalado${NC}"
	else
		echo -e "${YELLOW}  ⚠ Ask User no estaba instalado${NC}"
	fi

	echo -e "${YELLOW}  Desinstalando Web Access...${NC}"
	if "${PI_BIN}" remove npm:pi-web-access >/dev/null 2>&1; then
		echo -e "${GREEN}  ✓ Web Access desinstalado${NC}"
	else
		echo -e "${YELLOW}  ⚠ Web Access no estaba instalado${NC}"
	fi

	echo -e "${YELLOW}  Desinstalando Code Intelligence...${NC}"
	if "${PI_BIN}" remove npm:@catdaemon/pi-code-intelligence >/dev/null 2>&1; then
		echo -e "${GREEN}  ✓ Code Intelligence desinstalado${NC}"
	else
		echo -e "${YELLOW}  ⚠ Code Intelligence no estaba instalado${NC}"
	fi

	echo -e "${YELLOW}  Desinstalando MCP Adapter...${NC}"
	if "${PI_BIN}" remove npm:pi-mcp-adapter >/dev/null 2>&1; then
		echo -e "${GREEN}  ✓ MCP Adapter desinstalado${NC}"
	else
		echo -e "${YELLOW}  ⚠ MCP Adapter no estaba instalado${NC}"
	fi

	echo -e "${YELLOW}  Desinstalando Coding Agent...${NC}"
	if "${PI_BIN}" remove npm:pi-subagents >/dev/null 2>&1; then
		echo -e "${GREEN}  ✓ Coding Agent desinstalado${NC}"
	else
		echo -e "${YELLOW}  ⚠ Coding Agent no estaba instalado${NC}"
	fi
fi

echo -e "${YELLOW}Uninstalling IMALEagent...${NC}"

# Uninstall the underlying agent using npm
npm uninstall -g @earendil-works/pi-coding-agent

echo -e "${YELLOW}Removing IMALE configuration from ${AGENT_CONFIG_DIR}...${NC}"
# Un único helper Node para los tres desinstaladores: evita listas duplicadas.
if [ -f "${UNINSTALL_HELPER}" ]; then
	node "${UNINSTALL_HELPER}" "${AGENT_CONFIG_DIR}"
else
	echo -e "  ${RED}✗ No se encontró ${UNINSTALL_HELPER}${NC}"
	echo -e "  ${YELLOW}Elimina a mano la configuración de ${AGENT_CONFIG_DIR}${NC}"
fi

echo ""
echo -e "${YELLOW}Verifying removal...${NC}"
if command -v pi &>/dev/null; then
	echo -e "  ${RED}✗${NC} pi sigue disponible en el PATH"
else
	echo -e "  ${GREEN}✓${NC} pi eliminado del PATH"
fi
if [ -d "${AGENT_CONFIG_DIR}" ]; then
	echo -e "  ${YELLOW}⚠${NC} ${AGENT_CONFIG_DIR} aún existe (residuos o copias de seguridad)"
else
	echo -e "  ${GREEN}✓${NC} Configuración eliminada de ${AGENT_CONFIG_DIR}"
fi
echo ""
echo -e "${GREEN}[OK] IMALEagent uninstalled${NC}"
echo ""
echo -e "${YELLOW}Other package managers: pnpm remove -g @earendil-works/pi-coding-agent / yarn global remove ... / bun uninstall -g ...${NC}"
echo ""
