# sit-ciit-infra

## Resumen

Repo de infraestructura de SIT-CIIT: `docker-compose.yml` (Mosquitto +
TimescaleDB), el **contrato de mensajes** (fuente de verdad, ver abajo),
scripts de datos reales del corredor Salina Cruz–Coatzacoalcos, y docs de
arquitectura/ADR/demo.

Hermano de `sit-ciit-backend`, `sit-ciit-mobile`, `sit-ciit-dashboard`
(se asume que las cuatro carpetas están al mismo nivel).

## Restricciones del proyecto (aplican a todo SIT-CIIT)

- **No hay hardware dedicado.** Los nodos de campo son celulares Android
  usando sensores reales. La arquitectura debe permitir sustituir el
  celular por un ESP32 después, sin rediseñar: el ESP32 hablaría el mismo
  contrato MQTT.
- **Prohibido simular datos** en el flujo real (nada de generadores de
  telemetría falsa ni mocks fuera de tests unitarios). Los únicos datos son
  los de sensores reales y APIs públicas reales (Overpass/OSM, Open-Meteo,
  OpenCelliD).
- Fuera del MVP (solo documentar, no implementar): Bluetooth cel↔cel, SMS
  desde el celular, LoRa, satelital, CAN-Bus, ETA con ML.

## El contrato (contracts/)

- `contract.schema.json` + `contract.ts` son la fuente de verdad.
  Versión actual: **1.0.0** (ver `contracts/CHANGELOG.md`).
- Tópicos MQTT, QoS 1 siempre:
  ```
  sitciit/{nodeId}/telemetry   nodo → nube
  sitciit/{nodeId}/event       nodo → nube
  sitciit/{nodeId}/heartbeat   nodo → nube (cada 5 s)
  sitciit/{nodeId}/cmd         nube → nodo
  sitciit/{nodeId}/ack         nodo → nube
  ```
- Nodos usan `clientId` = `nodeId` y `clean: false` (el broker retiene
  comandos mientras el nodo está desconectado).
- Antes de tocar el contrato: avisar al usuario, subir versión (semver) y
  actualizar el CHANGELOG. Después de cualquier cambio, correr
  `./scripts/sync-contract.sh`.

## Comandos útiles

```bash
# levantar/bajar infra
docker compose up -d
docker compose down            # agrega -v para borrar volúmenes (¡destructivo!)
docker compose ps
docker compose logs -f mosquitto

# usuarios MQTT
./scripts/create-mqtt-user.sh <usuario>

# sincronizar contrato a los otros repos
./scripts/sync-contract.sh

# datos reales de la Línea Z (una sola vez)
npm install
npm run fetch:linea-z

# probar mosquitto manualmente
docker run --rm --network sit-ciit-infra_default eclipse-mosquitto:2 \
  mosquitto_pub -h mosquitto -u <usuario> -P <password> -t test -m hola

# probar timescaledb
docker exec -it sit-ciit-timescaledb psql -U sitciit -d sitciit
```

## Notas de implementación

- `mosquitto/config/passwd` se genera con `create-mqtt-user.sh`, nunca se
  commitea (está en `.gitignore`). El permiso debe quedar en `644` (no
  `600`/`700`): el proceso `mosquitto` dentro del contenedor corre con un
  UID distinto al del host y necesita poder leer el archivo montado.
- `data/*.geojson` no se commitea por defecto (se regenera con el script);
  si se decide fijar una versión para la demo, quitarlo del `.gitignore`
  puntualmente y commitearlo explícitamente.
