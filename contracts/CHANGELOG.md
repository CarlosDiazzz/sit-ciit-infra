# Changelog del contrato SIT-CIIT

Versionado semántico. Cualquier cambio a `contract.schema.json` o `contract.ts`
debe reflejarse aquí y en el campo `contractVersion` de ambos archivos.

## [1.0.0] - 2026-09-29

Versión inicial del contrato.

- Sobre común (`Envelope`) para mensajes nodo → nube: `telemetry`, `event`,
  `heartbeat`, `ack`.
- `CmdMessage` para mensajes nube → nodo (comandos), con reglas de autoridad
  `control_center` / `operator`.
- Tópicos MQTT: `sitciit/{nodeId}/telemetry|event|heartbeat|cmd|ack`, todos QoS 1.
