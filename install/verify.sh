#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== IMALEagent Verification ===${NC}"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

check_command() {
	local cmd=$1
	local pretty_name=${2:-$cmd}

	if command -v "$cmd" &>/dev/null; then
		local version=$("$cmd" --version 2>/dev/null || echo "N/A")
		echo -e "${GREEN}✓ $pretty_name${NC}: $version"
		((CHECKS_PASSED++))
	else
		echo -e "${RED}✗ $pretty_name${NC}: No instalado"
		((CHECKS_FAILED++))
	fi
}

echo -e "${BLUE}== Verificaciones del Sistema ==${NC}"
echo ""
check_command "node" "Node.js"
check_command "npm" "npm"
check_command "pi" "IMALEagent"
check_command "imaleagent" "IMALEagent CLI"

echo ""
echo -e "${BLUE}== Variables de Entorno (Opcional) ==${NC}"
echo ""
if [ -n "${ANTHROPIC_API_KEY}" ]; then
	echo -e "${GREEN}✓ ANTHROPIC_API_KEY${NC}: Configurada"
	((CHECKS_PASSED++))
else
	echo -e "${YELLOW}⚠ ANTHROPIC_API_KEY${NC}: No configurada (puedes usar /login en IMALEagent)"
fi

echo ""
echo -e "${BLUE}== Información de IMALEagent ==${NC}"
echo ""

if command -v pi &>/dev/null; then
	AGENT_CONFIG_DIR="${HOME}/.pi/agent"

	if [ -f "${AGENT_CONFIG_DIR}/settings.json" ]; then
		echo -e "${GREEN}✓ Configuración IMALE${NC}: ${AGENT_CONFIG_DIR}"
		((CHECKS_PASSED++))
	else
		echo -e "${YELLOW}⚠ Configuración IMALE${NC}: No encontrada en ${AGENT_CONFIG_DIR}"
	fi

	PI_LIST="$(pi list 2>/dev/null || true)"
	if echo "${PI_LIST}" | grep -q "pi-subagents"; then
		echo -e "${GREEN}✓ Coding Agent${NC}: Instalado y activo"
		((CHECKS_PASSED++))
	else
		echo -e "${RED}✗ Coding Agent${NC}: No detectado en 'pi list'"
		((CHECKS_FAILED++))
	fi

	if echo "${PI_LIST}" | grep -q "pi-mcp-adapter"; then
		echo -e "${GREEN}✓ MCP Adapter${NC}: Instalado y activo"
		((CHECKS_PASSED++))
	else
		echo -e "${RED}✗ MCP Adapter${NC}: No detectado en 'pi list'"
		((CHECKS_FAILED++))
	fi

	if echo "${PI_LIST}" | grep -q "@catdaemon/pi-code-intelligence"; then
		echo -e "${GREEN}✓ Code Intelligence${NC}: Instalado y activo"
		((CHECKS_PASSED++))
	else
		echo -e "${RED}✗ Code Intelligence${NC}: No detectado en 'pi list'"
		((CHECKS_FAILED++))
	fi

	if echo "${PI_LIST}" | grep -q "pi-web-access"; then
		echo -e "${GREEN}✓ Web Access${NC}: Instalado y activo"
		((CHECKS_PASSED++))
	else
		echo -e "${RED}✗ Web Access${NC}: No detectado en 'pi list'"
		((CHECKS_FAILED++))
	fi

	if echo "${PI_LIST}" | grep -q "pi-ask-user"; then
		echo -e "${GREEN}✓ Ask User${NC}: Instalado y activo"
		((CHECKS_PASSED++))
	else
		echo -e "${RED}✗ Ask User${NC}: No detectado en 'pi list'"
		((CHECKS_FAILED++))
	fi

	if [ -f "${AGENT_CONFIG_DIR}/mcp.json" ] && grep -q '"context-mode"' "${AGENT_CONFIG_DIR}/mcp.json"; then
		echo -e "${GREEN}✓ context-mode MCP${NC}: Configurado en ${AGENT_CONFIG_DIR}/mcp.json"
		((CHECKS_PASSED++))
	else
		echo -e "${YELLOW}⚠ context-mode MCP${NC}: No detectado en ${AGENT_CONFIG_DIR}/mcp.json"
	fi

	IMALE_EXTENSIONS=(
		"extensions/ai-router.ts"
		"extensions/imale-header.ts"
		"extensions/imale-preset.ts"
		"extensions/lib/shared-ui.ts"
	)
	MISSING_EXTENSIONS=0
	for ext in "${IMALE_EXTENSIONS[@]}"; do
		if [ ! -f "${AGENT_CONFIG_DIR}/${ext}" ]; then
			echo -e "${YELLOW}⚠ Extensión${NC}: ${ext} no encontrada"
			((MISSING_EXTENSIONS++))
		fi
	done
	if [ ${MISSING_EXTENSIONS} -eq 0 ]; then
		echo -e "${GREEN}✓ Extensiones IMALE${NC}: Instaladas en ${AGENT_CONFIG_DIR}/extensions"
		((CHECKS_PASSED++))
	else
		echo -e "${RED}✗ Extensiones IMALE${NC}: Faltan ${MISSING_EXTENSIONS} archivo(s)"
		((CHECKS_FAILED++))
	fi

	GENERIC_AGENTS=(
		"generic-context-builder.md"
		"generic-planner.md"
		"generic-worker.md"
		"generic-reviewer.md"
		"generic-parallel-review.md"
	)
	MISSING_GENERIC_AGENTS=0
	for agent_file in "${GENERIC_AGENTS[@]}"; do
		if [ ! -f "${AGENT_CONFIG_DIR}/agents/${agent_file}" ]; then
			((MISSING_GENERIC_AGENTS++))
		fi
	done
	if [ ${MISSING_GENERIC_AGENTS} -eq 0 ]; then
		echo -e "${GREEN}✓ Subagentes genéricos${NC}: Instalados en ${AGENT_CONFIG_DIR}/agents"
		((CHECKS_PASSED++))
	else
		echo -e "${RED}✗ Subagentes genéricos${NC}: Faltan ${MISSING_GENERIC_AGENTS} archivo(s) en ${AGENT_CONFIG_DIR}/agents"
		((CHECKS_FAILED++))
	fi

	GENERIC_PROMPTS=(
		"generic-discovery.md"
		"generic-fix-bug.md"
		"generic-implement-safe.md"
		"generic-research-and-plan.md"
		"step-scout.md"
		"step-planner.md"
		"step-worker.md"
		"step-reviewer.md"
	)
	MISSING_GENERIC_PROMPTS=0
	for prompt_file in "${GENERIC_PROMPTS[@]}"; do
		if [ ! -f "${AGENT_CONFIG_DIR}/prompts/${prompt_file}" ]; then
			((MISSING_GENERIC_PROMPTS++))
		fi
	done
	if [ ${MISSING_GENERIC_PROMPTS} -eq 0 ]; then
		echo -e "${GREEN}✓ Prompt workflows genéricos${NC}: Instalados en ${AGENT_CONFIG_DIR}/prompts"
		((CHECKS_PASSED++))
	else
		echo -e "${RED}✗ Prompt workflows genéricos${NC}: Faltan ${MISSING_GENERIC_PROMPTS} archivo(s) en ${AGENT_CONFIG_DIR}/prompts"
		((CHECKS_FAILED++))
	fi
else
	echo -e "${RED}IMALEagent no está instalado${NC}"
	echo "Ejecuta: bash install.sh"
fi

echo ""
echo -e "${BLUE}== Summary ==${NC}"
echo ""
if [ $CHECKS_FAILED -eq 0 ]; then
	echo -e "${GREEN}✓ All checks passed${NC}"
else
	echo -e "${RED}✗ ${CHECKS_FAILED} check(s) failed — run install.sh first${NC}"
fi
echo ""
