#!/usr/bin/env bash
#
# build-release.sh — Genera el release tarball para el instalador curl
# ====================================================================
# Uso:
#   bash scripts/build-release.sh [version]
#
# El tarball generado contiene solo lo necesario para instalar:
#   - install/      (scripts de instalación para todas las plataformas)
#   - config/agent/ (configuración IMALE)
#
# El resultado se escribe en dist/imaleagent.tar.gz
#
# Ejemplo:
#   bash scripts/build-release.sh v1.2.3
#   # → dist/imaleagent-v1.2.3.tar.gz
#   # → dist/imaleagent.tar.gz          (alias latest)
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd 2>/dev/null || pwd)"

VERSION="${1:-}"
if [ -z "${VERSION}" ]; then
  VERSION="$(cd "${PROJECT_ROOT}" && git describe --tags --always 2>/dev/null || echo "dev")"
fi

echo "📦 IMALEagent Release Builder"
echo "   Versión: ${VERSION}"
echo "   Proyecto: ${PROJECT_ROOT}"
echo ""

# ── Validaciones ──────────────────────────────
for dir in "install" "config/agent"; do
  if [ ! -d "${PROJECT_ROOT}/${dir}" ]; then
    echo "❌ ERROR: No se encuentra ${dir}/ en la raíz del proyecto."
    exit 1
  fi
done

# ── Crear directorio de salida ────────────────
DIST_DIR="${PROJECT_ROOT}/dist"
mkdir -p "${DIST_DIR}"

# ── Empaquetar ────────────────────────────────
TARBALL="${DIST_DIR}/imaleagent.tar.gz"
TARBALL_TAGGED="${DIST_DIR}/imaleagent-${VERSION}.tar.gz"

echo "📁 Contenido del tarball:"
echo "   install/"
echo "   config/agent/"
echo ""

# Crear tarball con solo lo necesario (rutas relativas a la raíz del proyecto)
cd "${PROJECT_ROOT}"
tar czf "${TARBALL}" \
  --exclude="*.DS_Store" \
  install/ \
  config/agent/

# Copia etiquetada con versión
cp "${TARBALL}" "${TARBALL_TAGGED}"

# ── Resumen ───────────────────────────────────
ORIGINAL_SIZE="$(stat -f%z "${TARBALL}" 2>/dev/null || stat -c%s "${TARBALL}" 2>/dev/null)"
ORIGINAL_SIZE_KB=$(( ORIGINAL_SIZE / 1024 ))

echo "✅ Release generado correctamente:"
echo ""
echo "   ${TARBALL_TAGGED}  (${ORIGINAL_SIZE_KB} KB)"
echo "   ${TARBALL}                (alias latest)"
echo ""
echo "   SHA256:"
shasum -a 256 "${TARBALL}" "${TARBALL_TAGGED}" 2>/dev/null || sha256sum "${TARBALL}" "${TARBALL_TAGGED}" 2>/dev/null

echo ""
echo "🚀 Para publicar un release en GitHub:"
echo "   1. Crea el tag:   git tag ${VERSION}"
echo "   2. Sube el tag:   git push origin ${VERSION}"
echo "   3. El workflow .github/workflows/release.yml crea el Release y sube:"
echo "      - ${TARBALL_TAGGED}  (y su alias ${TARBALL})"
echo "      - install.sh, install/install.sh, install/install.ps1, install/install.bat"
echo ""
echo "   Esos assets son los que consumen los comandos documentados:"
echo "   macOS/Linux/Git Bash:"
echo "     curl -fsSL https://github.com/IvanMartinezLeon/IMALEagent/releases/latest/download/install.sh | bash"
echo "   Windows: descarga releases/latest/download/imaleagent.tar.gz y ejecuta install\\install.ps1"
echo ""
