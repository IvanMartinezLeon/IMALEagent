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
case "${OS:-}" in
  Windows_NT)
    echo "[IMALEagent] Windows nativo detectado." >&2
    echo "" >&2
    echo "  Para instalar en Windows PowerShell:" >&2
    if [ "${VERSION}" = "latest" ]; then
      echo "    iwr -useb https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download/install.ps1 | iex" >&2
    else
      echo "    iwr -useb https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/install.ps1 | iex" >&2
    fi
    echo "" >&2
    echo "  Para instalar en Windows CMD:" >&2
    if [ "${VERSION}" = "latest" ]; then
      echo "    curl -fsSL https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download/install.bat -o install.bat && install.bat" >&2
    else
      echo "    curl -fsSL https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/install.bat -o install.bat && install.bat" >&2
    fi
    echo "" >&2
    exit 1
    ;;
esac

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
