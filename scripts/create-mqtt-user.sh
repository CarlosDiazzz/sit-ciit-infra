#!/usr/bin/env bash
# Crea (o actualiza) un usuario en mosquitto/config/passwd usando el propio
# contenedor de Mosquitto (mosquitto_passwd), para no depender de tenerlo
# instalado localmente.
#
# Uso:
#   ./scripts/create-mqtt-user.sh <usuario>
#   (pedirá la contraseña de forma interactiva)

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Uso: $0 <usuario>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PASSWD_FILE="${INFRA_DIR}/mosquitto/config/passwd"

touch "${PASSWD_FILE}"

FLAG="-b"
if [ ! -s "${PASSWD_FILE}" ]; then
  FLAG="-cb"
fi

read -rsp "Contraseña para ${1}: " PASSWORD
echo

docker run --rm \
  -v "${PASSWD_FILE}:/mosquitto/config/passwd" \
  eclipse-mosquitto:2 \
  mosquitto_passwd "${FLAG}" /mosquitto/config/passwd "${1}" "${PASSWORD}"

echo "Usuario '${1}' creado/actualizado en ${PASSWD_FILE}"
echo "Reinicia el contenedor mosquitto para aplicar: docker compose restart mosquitto"
