#!/usr/bin/env bash
#
# test-install.sh — Test E2E de la etapa de configuración y del desinstalador.
#
# Ejercita el código real de install/lib/config-stage.sh y
# install/lib/uninstall-config.mjs contra un HOME simulado, así que no toca la
# instalación del usuario. No requiere red ni npm.
#
# Uso:
#   bash scripts/test-install.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "${SANDBOX}"' EXIT

FAILURES=0
fail() {
	echo "  ✗ ${1}" >&2
	FAILURES=$((FAILURES + 1))
}
pass() { echo "  ✓ ${1}"; }
section() { echo; echo "▸ ${1}"; }

assert_file() {
	if [ -e "${1}" ]; then pass "${2}"; else fail "${2} (falta ${1})"; fi
}
assert_no_file() {
	if [ ! -e "${1}" ]; then pass "${2}"; else fail "${2} (sigue existiendo ${1})"; fi
}
assert_json() {
	if node -e "
		const fs = require('node:fs');
		const d = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
		if (!(${2})) process.exit(1);
	" "${1}"; then
		pass "${3}"
	else
		fail "${3} (${1})"
	fi
}

# ── Preparar un HOME simulado con configuración previa del usuario ─────
AGENT_CONFIG_DIR="${SANDBOX}/home/.pi/agent"
mkdir -p "${AGENT_CONFIG_DIR}/agents" "${AGENT_CONFIG_DIR}/skills/mi-skill"

cat >"${AGENT_CONFIG_DIR}/settings.json" <<'JSON'
{
  "theme": "tema-propio",
  "packages": ["npm:pi-subagents", "npm:mi-paquete"],
  "defaultModel": "mi-modelo",
  "defaultProvider": "mi-provider"
}
JSON
cat >"${AGENT_CONFIG_DIR}/mcp.json" <<'JSON'
{ "mcpServers": { "mi-servidor": { "command": "foo" } } }
JSON
echo 'contenido propio' >"${AGENT_CONFIG_DIR}/agents/mi-agente.md"
echo 'contenido propio' >"${AGENT_CONFIG_DIR}/skills/mi-skill/SKILL.md"

PRE_INSTALL_SETTINGS="$(cat "${AGENT_CONFIG_DIR}/settings.json")"

# ── Etapa de configuración: código real del instalador ────────────────
CONFIG_SOURCE_DIR="${PROJECT_ROOT}/config/agent"
SCRIPT_DIR="${PROJECT_ROOT}/install"
GREEN=""
YELLOW=""
RED=""
NC=""
# shellcheck source=../install/lib/config-stage.sh
. "${SCRIPT_DIR}/lib/config-stage.sh"

section "Instalación"
install_config_stage "bin/pi" "bin/imaleagent"

assert_file "${AGENT_CONFIG_DIR}/settings.json" "settings.json instalado"
assert_file "${AGENT_CONFIG_DIR}/extensions/ai-router.ts" "extensión ai-router.ts instalada"
assert_file "${AGENT_CONFIG_DIR}/extensions/imale-preset.ts" "extensión imale-preset.ts instalada"
assert_file "${AGENT_CONFIG_DIR}/prompts/generic-discovery.md" "prompt workflow generic-discovery instalado"
assert_file "${AGENT_CONFIG_DIR}/themes/imale-theme.json" "tema imale-theme instalado"
assert_file "${AGENT_CONFIG_DIR}/GENERIC_RULES.md" "reglas genéricas instaladas"
assert_file "${AGENT_CONFIG_DIR}/MOBILE_GUIDELINES.md" "guías mobile instaladas"
assert_file "${AGENT_CONFIG_DIR}/templates/SPEC_TEMPLATE.md" "plantilla SPEC instalada"
assert_file "${AGENT_CONFIG_DIR}/templates/PLAN_TEMPLATE.md" "plantilla PLAN instalada"
assert_file "${AGENT_CONFIG_DIR}/skills/flutter-guidelines/SKILL.md" "skill flutter-guidelines instalada"
assert_file "${AGENT_CONFIG_DIR}/skills/dart-guidelines/SKILL.md" "skill dart-guidelines instalada"
assert_file "${AGENT_CONFIG_DIR}/prompts/spec-mobile.md" "prompt spec-mobile instalado"
assert_file "${AGENT_CONFIG_DIR}/.imale-manifest" "manifiesto escrito"
assert_no_file "${AGENT_CONFIG_DIR}/chains" "no se instala ningún directorio chains/"

section "La configuración previa del usuario se conserva"
assert_json "${AGENT_CONFIG_DIR}/settings.json" \
	"d.theme === 'imale-theme'" \
	"el tema del repo gana (theme=imale-theme)"
assert_json "${AGENT_CONFIG_DIR}/settings.json" \
	"d.packages.includes('npm:mi-paquete') && d.packages.includes('npm:pi-subagents')" \
	"packages previos conservados"
assert_json "${AGENT_CONFIG_DIR}/settings.json" \
	"d.defaultModel === 'mi-modelo' && d.defaultProvider === 'mi-provider'" \
	"provider y modelo previos conservados"
assert_json "${AGENT_CONFIG_DIR}/mcp.json" \
	"Object.keys(d.mcpServers).includes('mi-servidor') && Object.keys(d.mcpServers).includes('context-mode')" \
	"mcp.json fusiona servidores previos y añade context-mode"

BACKUP_COUNT="$(find "${AGENT_CONFIG_DIR}" -maxdepth 1 -name '.backup-*' | wc -l | tr -d ' ')"
[ "${BACKUP_COUNT}" = "1" ] && pass "se creó una copia de seguridad" || fail "se esperaba 1 copia de seguridad, hay ${BACKUP_COUNT}"

section "El manifiesto registra ficheros, nunca directorios"
MANIFEST="${AGENT_CONFIG_DIR}/.imale-manifest"
MANIFEST_LINES="$(grep -c . "${MANIFEST}" || true)"
[ "${MANIFEST_LINES}" -gt 40 ] && pass "manifiesto con ${MANIFEST_LINES} entradas" || fail "manifiesto con solo ${MANIFEST_LINES} entradas"

DIRS_IN_MANIFEST=0
while IFS= read -r entry; do
	[ -n "${entry}" ] || continue
	if [ -d "${AGENT_CONFIG_DIR}/${entry}" ]; then
		DIRS_IN_MANIFEST=$((DIRS_IN_MANIFEST + 1))
	fi
done <"${MANIFEST}"
[ "${DIRS_IN_MANIFEST}" -eq 0 ] \
	&& pass "ninguna entrada del manifiesto es un directorio" \
	|| fail "${DIRS_IN_MANIFEST} directorio(s) en el manifiesto: borrarían material propio del usuario"

grep -q '^bin/imaleagent$' "${MANIFEST}" \
	&& pass "el manifiesto incluye el wrapper bin/imaleagent" \
	|| fail "el manifiesto no incluye bin/imaleagent"

# ── Desinstalación: código real del desinstalador ─────────────────────
section "Desinstalación"
node "${SCRIPT_DIR}/lib/uninstall-config.mjs" "${AGENT_CONFIG_DIR}" >"${SANDBOX}/uninstall.log" 2>&1 || {
	fail "el desinstalador devolvió un error"
	cat "${SANDBOX}/uninstall.log" >&2
}

assert_no_file "${AGENT_CONFIG_DIR}/extensions/ai-router.ts" "extensión ai-router.ts eliminada"
assert_no_file "${AGENT_CONFIG_DIR}/prompts/generic-discovery.md" "prompt workflow eliminado"
assert_no_file "${AGENT_CONFIG_DIR}/themes/imale-theme.json" "tema eliminado"
assert_no_file "${AGENT_CONFIG_DIR}/.imale-manifest" "manifiesto eliminado"
assert_no_file "${AGENT_CONFIG_DIR}/extensions" "directorio extensions/ podado al quedar vacío"

section "La desinstalación no toca material propio del usuario"
assert_file "${AGENT_CONFIG_DIR}/agents/mi-agente.md" "agents/mi-agente.md conservado"
assert_file "${AGENT_CONFIG_DIR}/skills/mi-skill/SKILL.md" "skills/mi-skill/SKILL.md conservado"
assert_file "${AGENT_CONFIG_DIR}/agents" "directorio agents/ se mantiene (no estaba vacío)"

section "settings.json y mcp.json vuelven al estado previo"
assert_json "${AGENT_CONFIG_DIR}/settings.json" \
	"d.theme === 'tema-propio' && d.defaultModel === 'mi-modelo' && d.defaultProvider === 'mi-provider'" \
	"settings.json restaurado desde la copia de seguridad"
if [ "$(node -e "console.log(String(JSON.stringify(JSON.parse(require('node:fs').readFileSync(process.argv[1],'utf8'))) === JSON.stringify(JSON.parse(process.argv[2]))))" "${AGENT_CONFIG_DIR}/settings.json" "${PRE_INSTALL_SETTINGS}")" = "true" ]; then
	pass "settings.json idéntico al de antes de instalar"
else
	fail "settings.json no coincide con el estado previo a instalar"
fi
assert_json "${AGENT_CONFIG_DIR}/mcp.json" \
	"Object.keys(d.mcpServers).length === 1 && Object.keys(d.mcpServers)[0] === 'mi-servidor'" \
	"mcp.json restaurado (solo el servidor propio)"

BACKUP_AFTER="$(find "${AGENT_CONFIG_DIR}" -maxdepth 1 -name '.backup-*' | wc -l | tr -d ' ')"
[ "${BACKUP_AFTER}" = "1" ] && pass "la copia de seguridad se conserva tras desinstalar" || fail "la copia de seguridad desapareció"

# ── Resultado ─────────────────────────────────────────────────────────
echo
if [ "${FAILURES}" -eq 0 ]; then
	echo "✅ test-install.sh: todas las comprobaciones pasan"
	exit 0
fi
echo "❌ test-install.sh: ${FAILURES} comprobación(es) fallida(s)" >&2
exit 1
