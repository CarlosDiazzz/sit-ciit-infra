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

read -rsp "Contraseña para ${1}: " PASSWORD
echo

# mosquitto_passwd 2.x no acepta flags combinados (-cb) y además se niega a
# escribir con -c si el archivo ya existe. Por eso se genera dentro del
# contenedor (sobre un archivo temporal) y se copia el resultado al host:
# se monta el directorio, no el archivo, para que el usuario nuevo se agregue
# al passwd existente en vez de recrearlo.
CONFIG_DIR="$(dirname "${PASSWD_FILE}")"

docker run --rm \
  -v "${CONFIG_DIR}:/out" \
  eclipse-mosquitto:2 \
  sh -c "
    set -e
    if [ -s /out/passwd ]; then
      cp /out/passwd /tmp/passwd
      mosquitto_passwd -b /tmp/passwd '${1}' '${PASSWORD}'
    else
      mosquitto_passwd -c -b /tmp/passwd '${1}' '${PASSWORD}'
    fi
    cp /tmp/passwd /out/passwd
  "

# El proceso mosquitto corre con otro UID dentro del contenedor y necesita
# poder leer el archivo montado (ver CLAUDE.md).
chmod 644 "${PASSWD_FILE}"

echo "Usuario '${1}' creado/actualizado en ${PASSWD_FILE}"
echo "Reinicia el contenedor mosquitto para aplicar: docker compose restart mosquitto"
