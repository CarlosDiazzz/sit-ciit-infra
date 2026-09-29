# sit-ciit-infra

Infraestructura compartida de **SIT-CIIT**: broker MQTT, base de datos de
series de tiempo, el contrato de mensajes (fuente de verdad) y scripts de
datos reales del corredor.

Ver también: [`sit-ciit-backend`](../sit-ciit-backend), [`sit-ciit-mobile`](../sit-ciit-mobile),
[`sit-ciit-dashboard`](../sit-ciit-dashboard).

## ¿Por qué 4 repos separados?

- **Despliegue independiente**: la infra se levanta en un servidor/VM, el
  backend en otro proceso, el dashboard es estático, el móvil se distribuye
  como app. Cada uno tiene su propio ciclo de release.
- **Stacks distintos**: Docker Compose, Node/Fastify, Expo/React Native,
  React/Vite — mezclarlos en un monorepo no aporta nada y complica el
  tooling de cada uno.
- **El contrato como frontera explícita**: en vez de compartir tipos vía un
  paquete interno de un monorepo, el contrato vive en `contracts/` de este
  repo y se copia explícitamente (`scripts/sync-contract.sh`) a los demás.
  Eso obliga a que todo cambio de contrato sea una decisión consciente y
  versionada (ver `contracts/CHANGELOG.md`), no un efecto colateral de un
  refactor en un paquete compartido.

## Levantar todo

```bash
cp .env.example .env        # ajustar si hace falta

# 1. Crear el primer usuario MQTT (interactivo, pide contraseña)
./scripts/create-mqtt-user.sh sitciit-dev

# 2. Levantar broker + base de datos
docker compose up -d

# 3. Verificar
docker compose ps
```

## Puertos

| Servicio    | Puerto | Uso                                  |
|-------------|--------|---------------------------------------|
| Mosquitto   | 1883   | MQTT (nodos, backend)                 |
| Mosquitto   | 9001   | MQTT sobre WebSocket                  |
| TimescaleDB | 5432   | Postgres (telemetría, eventos, etc.)  |

## Credenciales de ejemplo (solo desarrollo local)

Ver `.env.example`. Nunca commitear `.env` ni `mosquitto/config/passwd`
(ambos están en `.gitignore`).

Usuarios MQTT se gestionan con `scripts/create-mqtt-user.sh <usuario>`
(pide la contraseña de forma interactiva y no la deja en el historial de shell).

## El contrato de mensajes

- `contracts/contract.schema.json` — JSON Schema de todos los mensajes MQTT.
- `contracts/contract.ts` — mismos tipos en TypeScript.
- `contracts/CHANGELOG.md` — historial versionado (semver) del contrato.

Cuando el contrato cambia:

1. Editar `contracts/contract.schema.json` y `contracts/contract.ts`.
2. Subir versión (`CONTRACT_VERSION` / `"const": "..."`) siguiendo semver.
3. Documentar el cambio en `contracts/CHANGELOG.md`.
4. Correr `./scripts/sync-contract.sh` para propagar la copia a los otros
   tres repos (deben existir como carpetas hermanas de este repo).

## Scripts

- `scripts/sync-contract.sh` — copia `contracts/contract.ts` a
  `sit-ciit-backend`, `sit-ciit-mobile` y `sit-ciit-dashboard`.
- `scripts/create-mqtt-user.sh <usuario>` — crea/actualiza un usuario en
  `mosquitto/config/passwd` usando el propio contenedor de Mosquitto.
- `scripts/fetch-linea-z.ts` — descarga (una sola vez) el trazado real de la
  Línea Z desde OpenStreetMap/Overpass y lo guarda en `data/linea-z.geojson`.
  Correr con `npm install && npm run fetch:linea-z`. Datos © contribuyentes
  de OpenStreetMap, licencia [ODbL 1.0](https://www.openstreetmap.org/copyright).

## Documentación

- `docs/architecture.md` — diagrama de arquitectura (Mermaid).
- `docs/adr/` — decisiones técnicas cortas (ADR).
- `docs/demo-script.md` — guion de la demo final (criterio de aceptación).
