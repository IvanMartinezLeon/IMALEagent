#!/usr/bin/env bash
#
# IMALEagent – Cross-platform entry point
# ==========================================
# Uso:
#   curl -fsSL https://imaleagent.dev/install.sh | bash
#
# Compatibilidad:
#   macOS / Linux / Windows (Git Bash / WSL)
#   Windows nativo → muestra el comando PowerShell equivalente
#
# Variables de entorno:
#   INSTALL_VERSION  — versión a instalar (default: latest)
#   INSTALL_DIR      — directorio de instalación (default: ~/.pi/agent)
#
set -euo pipefail

REPO_OWNER="IvanMartinezLeon"
REPO_NAME="IMALEagent"
VERSION="${INSTALL_VERSION:-latest}"

# ──────────────────────────────────────────────
# 1. Detectar Windows nativo
# ──────────────────────────────────────────────
# Git Bash y Cygwin también heredan OS=Windows_NT, pero sí pueden ejecutar este
# script, así que no deben tratarse como Windows nativo.
is_native_windows() {
  [ "${OS:-}" = "Windows_NT" ] || return 1
  [ -n "${MSYSTEM:-}" ] && return 1        # Git Bash / MSYS2
  [ -n "${CYGWIN:-}" ] && return 1         # Cygwin
  [ -n "${WSL_DISTRO_NAME:-}" ] && return 1 # WSL
  return 0
}

if is_native_windows; then
  echo "[IMALEagent] Windows nativo detectado: este script es de bash." >&2
  echo "" >&2
  echo "  El instalador de Windows necesita el arbol del repositorio" >&2
  echo "  (install\\install.ps1 resuelve config\\agent desde su propia ubicacion)." >&2
  echo "" >&2
  echo "  1. Descarga y descomprime la release:" >&2
  if [ "${VERSION}" = "latest" ]; then
    echo "     https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download/imaleagent.tar.gz" >&2
  else
    echo "     https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/imaleagent.tar.gz" >&2
  fi
  echo "  2. Ejecuta:  install\\install.ps1   (o install\\install.bat con CMD)" >&2
  echo "" >&2
  echo "  Desde Git Bash o WSL puedes usar este mismo comando." >&2
  exit 1
fi

# ──────────────────────────────────────────────
# 2. Detectar ejecución local (repo clonado)
# ──────────────────────────────────────────────
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || pwd)"
if [ -f "${SCRIPT_DIR}/install/install.sh" ]; then
  echo "[IMALEagent] Local install detected, using repo installer." >&2
  exec bash "${SCRIPT_DIR}/install/install.sh"
fi

# ──────────────────────────────────────────────
# 3. Modo curl | sh — descargar release tarball
# ──────────────────────────────────────────────
echo "[IMALEagent] Descargando IMALEagent ${VERSION}..." >&2

TMP_DIR="$(mktemp -d)"
# Ya no se usa `exec` para lanzar el instalador: al ser un subproceso, este trap
# sí llega a ejecutarse y no deja el tarball extraído en /tmp.
trap 'rm -rf "${TMP_DIR}"' EXIT

RELEASE_BASE="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases"
if [ "${VERSION}" = "latest" ]; then
  RELEASE_BASE="${RELEASE_BASE}/latest/download"
else
  RELEASE_BASE="${RELEASE_BASE}/download/${VERSION}"
fi
TARBALL_URL="${RELEASE_BASE}/imaleagent.tar.gz"
SUMS_URL="${RELEASE_BASE}/SHA256SUMS"

# ──────────────────────────────────────────────
# 3.1 Descarga a fichero (sin pipe a tar)
# ──────────────────────────────────────────────
if ! curl -fsSL -o "${TMP_DIR}/imaleagent.tar.gz" "${TARBALL_URL}"; then
  echo "[IMALEagent] ERROR: no se pudo descargar el release desde ${TARBALL_URL}" >&2
  exit 1
fi

# ──────────────────────────────────────────────
# 3.2 Verificación de integridad obligatoria
# ──────────────────────────────────────────────
if ! curl -fsSL -o "${TMP_DIR}/SHA256SUMS" "${SUMS_URL}" || [ ! -s "${TMP_DIR}/SHA256SUMS" ]; then
  echo "[IMALEagent] ERROR: el release no publica SHA256SUMS (${SUMS_URL})" >&2
  echo "[IMALEagent] Sin checksum no se extrae ni ejecuta el tarball." >&2
  echo "[IMALEagent] Usa un release que incluya SHA256SUMS o instala desde el repo clonado:" >&2
  echo "             bash install/install.sh" >&2
  exit 1
fi

verify_sha256() {
  # Solo la entrada del tarball: SHA256SUMS también cubre install.sh, que no
  # está presente en este directorio temporal.
  grep ' imaleagent\.tar\.gz$' "${TMP_DIR}/SHA256SUMS" >"${TMP_DIR}/SHA256SUMS.tarball" || return 1
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "${TMP_DIR}" && sha256sum -c SHA256SUMS.tarball)
  elif command -v shasum >/dev/null 2>&1; then
    (cd "${TMP_DIR}" && shasum -a 256 -c SHA256SUMS.tarball)
  else
    echo "[IMALEagent] ERROR: no hay sha256sum ni shasum disponibles para verificar." >&2
    return 1
  fi
}

if ! verify_sha256 >/dev/null; then
  echo "[IMALEagent] ERROR: el checksum del tarball NO coincide con SHA256SUMS." >&2
  echo "[IMALEagent] Descarga abortada. No se ha extraído ni ejecutado nada." >&2
  exit 1
fi
echo "[IMALEagent] ✓ Checksum verificado contra SHA256SUMS" >&2

# ──────────────────────────────────────────────
# 3.3 Extracción
# ──────────────────────────────────────────────
tar xzf "${TMP_DIR}/imaleagent.tar.gz" -C "${TMP_DIR}"

if [ ! -f "${TMP_DIR}/install/install.sh" ]; then
  echo "[IMALEagent] ERROR: El tarball descargado no contiene install/install.sh" >&2
  echo "[IMALEagent] URL: ${TARBALL_URL}" >&2
  exit 1
fi

bash "${TMP_DIR}/install/install.sh"
