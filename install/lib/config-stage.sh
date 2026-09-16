#!/bin/bash
#
# config-stage.sh — Copia, fusiona y registra la configuración de IMALEagent.
#
# Se carga desde install/install.sh. Está separado para que
# scripts/test-install.sh pueda ejercitar exactamente este código (y no una
# copia) sin ejecutar npm ni tocar el HOME real.
#
# Quien lo carga debe definir antes:
#   SCRIPT_DIR         directorio de install/
#   CONFIG_SOURCE_DIR  directorio config/agent del repositorio
#   AGENT_CONFIG_DIR   destino, normalmente ~/.pi/agent
#
# Y las variables de color GREEN/YELLOW/RED/NC para el output.

MERGE_HELPER="${SCRIPT_DIR}/lib/merge-config.mjs"
MANIFEST_HELPER="${SCRIPT_DIR}/lib/write-manifest.mjs"
MANIFEST="${AGENT_CONFIG_DIR}/.imale-manifest"
BACKUP_DIR="${AGENT_CONFIG_DIR}/.backup-$(date +%Y%m%d-%H%M%S)"

# Copia de seguridad de los elementos de configuración que van a ser sobrescritos.
backup_existing_config() {
	local copied=0 rel
	while IFS= read -r rel; do
		if [ ! -e "${AGENT_CONFIG_DIR}/${rel}" ]; then
			continue
		fi
		mkdir -p "${BACKUP_DIR}"
		cp -R "${AGENT_CONFIG_DIR}/${rel}" "${BACKUP_DIR}/${rel}"
		copied=$((copied + 1))
	done < <(cd "${CONFIG_SOURCE_DIR}" && find . -mindepth 1 -maxdepth 1 -exec basename {} \;)

	if [ "${copied}" -gt 0 ]; then
		echo -e "${GREEN}✓ Copia de seguridad de la config previa${NC}: ${BACKUP_DIR} (${copied} elemento(s))"
		return 0
	fi

	rmdir "${BACKUP_DIR}" 2>/dev/null || true
}

# Fusiona un JSON del repo con el previo del usuario en lugar de sobrescribirlo.
# Imprescindible para no perder `packages`, provider/model ni MCPs propios.
merge_json_file() {
	local rel="${1}"
	local incoming="${CONFIG_SOURCE_DIR}/${rel}"
	local previous="${BACKUP_DIR}/${rel}"
	local target="${AGENT_CONFIG_DIR}/${rel}"
	local merged=""

	if [ ! -f "${incoming}" ] || [ ! -f "${previous}" ]; then
		return 0
	fi

	merged="$(mktemp)"
	if node "${MERGE_HELPER}" "${incoming}" "${previous}" "${merged}" && [ -s "${merged}" ]; then
		mv "${merged}" "${target}"
		echo -e "${GREEN}✓ ${rel} fusionado${NC} con la configuración previa"
	else
		rm -f "${merged}"
		echo -e "${YELLOW}⚠ ${rel}${NC}: no se pudo fusionar, se ha instalado la versión del repo"
		echo -e "${YELLOW}  Copia previa:${NC} ${previous}"
	fi
}

# Etapa completa: backup, copia, merge de JSON y manifiesto.
# Los argumentos son rutas extra que también debe eliminar el desinstalador
# (los wrappers de bin/).
install_config_stage() {
	if [ ! -d "${CONFIG_SOURCE_DIR}" ]; then
		echo -e "${RED}✗ Error: No se encontró la carpeta de configuración en ${CONFIG_SOURCE_DIR}${NC}"
		return 1
	fi

	# El manifiesto lo escribe un helper: si falta, el desinstalador quedaría
	# ciego, así que es un error bloqueante.
	if [ ! -f "${MERGE_HELPER}" ] || [ ! -f "${MANIFEST_HELPER}" ]; then
		echo -e "${RED}✗ Error: Faltan los helpers de instalación en ${SCRIPT_DIR}/lib${NC}"
		return 1
	fi

	mkdir -p "${AGENT_CONFIG_DIR}"
	backup_existing_config
	cp -R "${CONFIG_SOURCE_DIR}/." "${AGENT_CONFIG_DIR}/"
	merge_json_file "settings.json"
	merge_json_file "mcp.json"

	if node "${MANIFEST_HELPER}" "${CONFIG_SOURCE_DIR}" "${MANIFEST}" "$@" >/dev/null; then
		echo -e "${GREEN}✓ Manifiesto de instalación${NC}: ${MANIFEST}"
		return 0
	fi

	echo -e "${RED}✗ Error: no se pudo escribir el manifiesto de instalación${NC}"
	return 1
}
