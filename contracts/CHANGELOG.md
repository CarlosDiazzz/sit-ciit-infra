# Changelog del contrato SIT-CIIT

Versionado semántico. Cualquier cambio a `contract.schema.json` o `contract.ts`
debe reflejarse aquí y en el campo `contractVersion` de ambos archivos.

## [1.2.0] - 2026-09-30

- `EventKind` suma cuatro eventos de dinámica de marcha, detectados en el
  nodo: `hard_brake`, `curve_overspeed`, `dynamic_impact` y
  `track_irregularity`. Amplían el alcance del sistema: además de vigilar
  la integridad de la carga, miden las fuerzas del movimiento del tren
  que son las que la dañan.
- No se agregan campos nuevos: los cuatro reusan `value` y `threshold`
  del `EventPayload`, con el significado documentado en `contract.ts`
  (desaceleración en g, aceleración lateral en g, magnitud dinámica en g
  y amplitud en g, respectivamente). Si la detección calibrada pide datos
  propios —radio de curva, longitud de onda del defecto— se añaden en un
  1.3.0.
- Cambio compatible: un nodo que hable 1.1.0 sigue funcionando, solo que
  sin emitir estos eventos. La validación ya aceptaba cualquier `1.x.x`.

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
