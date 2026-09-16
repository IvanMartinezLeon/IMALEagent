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
trap 'rm -rf "${TMP_DIR}"' EXIT

if [ "${VERSION}" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download/imaleagent.tar.gz"
else
  DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/imaleagent.tar.gz"
fi

curl -fsSL "${DOWNLOAD_URL}" | tar xz -C "${TMP_DIR}"

if [ ! -f "${TMP_DIR}/install/install.sh" ]; then
  echo "[IMALEagent] ERROR: El tarball descargado no contiene install/install.sh" >&2
  echo "[IMALEagent] URL: ${DOWNLOAD_URL}" >&2
  exit 1
fi

exec bash "${TMP_DIR}/install/install.sh"
