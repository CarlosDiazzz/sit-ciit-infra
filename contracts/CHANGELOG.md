# Changelog del contrato SIT-CIIT

Versionado semántico. Cualquier cambio a `contract.schema.json` o `contract.ts`
debe reflejarse aquí y en el campo `contractVersion` de ambos archivos.

## [1.1.0] - 2026-09-29

- `TelemetryPayload.mag?: Vector3` — lectura cruda del magnetómetro (µT).
  Es un dato más, no un rumbo/brújula: calcular eso necesita compensar
  inclinación con el acelerómetro y calibración, queda fuera del MVP.
- `contractVersion` deja de exigir el literal exacto `"1.0.0"` y pasa a
  aceptar cualquier `1.x.x` (`^1\.\d+\.\d+$`) — un bump de minor debe ser
  compatible con clientes que sigan en una versión anterior de 1.x, no
  romperlos.

## [1.0.0] - 2026-09-29

Versión inicial del contrato.

- Sobre común (`Envelope`) para mensajes nodo → nube: `telemetry`, `event`,
  `heartbeat`, `ack`.
- `CmdMessage` para mensajes nube → nodo (comandos), con reglas de autoridad
  `control_center` / `operator`.
- Tópicos MQTT: `sitciit/{nodeId}/telemetry|event|heartbeat|cmd|ack`, todos QoS 1.
