# ADR 0002 — Mosquitto con clientId estable y clean=false

**Estado:** Aceptado

## Contexto

El corredor Salina Cruz–Coatzacoalcos tiene tramos sin cobertura celular.
Un nodo (celular) puede quedar desconectado del broker por minutos u
horas. Los comandos emitidos hacia ese nodo (`sitciit/{nodeId}/cmd`) no
deben perderse mientras está desconectado.

## Decisión

- Cada nodo se conecta con `clientId` = `nodeId` (estable, no aleatorio) y
  `clean: false`.
- Todos los tópicos usan QoS 1 (al menos una entrega).
- Mosquitto se configura con `persistence true`, así la sesión y los
  mensajes en cola sobreviven a un reinicio del broker.

## Consecuencias

- (+) Un comando emitido mientras el nodo está offline se entrega en
  cuanto el nodo reconecta con el mismo `clientId`, sin que el backend
  tenga que llevar su propia cola de reintentos por nodo.
- (+) QoS 1 + `msgId` (UUID) en el sobre común permite deduplicar en el
  backend (`UNIQUE` constraint) sin perder mensajes por reintentos del
  cliente MQTT.
- (-) Si dos procesos usan el mismo `nodeId` como `clientId`
  simultáneamente, Mosquitto desconecta a uno (comportamiento estándar de
  MQTT para `clientId` duplicado). Se documenta como restricción: un
  `nodeId` = un proceso conectado a la vez.
