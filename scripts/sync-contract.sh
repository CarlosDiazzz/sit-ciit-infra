#!/usr/bin/env bash
# Copia contracts/contract.ts a los otros tres repos del proyecto.
# Asume que sit-ciit-backend, sit-ciit-mobile y sit-ciit-dashboard son
# carpetas hermanas de sit-ciit-infra (mismo padre en el filesystem).
#
# Uso: ./scripts/sync-contract.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PARENT_DIR="$(cd "${INFRA_DIR}/.." && pwd)"
SOURCE_FILE="${INFRA_DIR}/contracts/contract.ts"

VERSION="$(grep -oP '(?<=CONTRACT_VERSION = ")[^"]+' "${SOURCE_FILE}")"

TARGETS=(
  "sit-ciit-backend"
  "sit-ciit-mobile"
  "sit-ciit-dashboard"
)

if [ ! -f "${SOURCE_FILE}" ]; then
  echo "No se encontró ${SOURCE_FILE}" >&2
  exit 1
fi

for repo in "${TARGETS[@]}"; do
  target_dir="${PARENT_DIR}/${repo}/src/contract"
  target_file="${target_dir}/contract.ts"

  if [ ! -d "${PARENT_DIR}/${repo}" ]; then
    echo "Aviso: ${PARENT_DIR}/${repo} no existe, se omite." >&2
    continue
  fi

  mkdir -p "${target_dir}"
  {
    echo "// AUTO-GENERADO por sit-ciit-infra/scripts/sync-contract.sh"
    echo "// Copiado de sit-ciit-infra/contracts/contract.ts — version ${VERSION}"
    echo "// No editar aquí: editar la fuente de verdad y volver a correr el script."
    echo ""
    cat "${SOURCE_FILE}"
  } > "${target_file}"

  echo "Sincronizado -> ${target_file} (v${VERSION})"
done
