# ADR 0003 — TimescaleDB para telemetría

**Estado:** Aceptado

## Contexto

`telemetry` puede llegar hasta 1 muestra/segundo por nodo, con varios
nodos activos simultáneamente durante la demo y, en un despliegue real,
durante todo un trayecto Salina Cruz–Coatzacoalcos. Se necesitan consultas
por rango de tiempo (`GET /telemetry?unitId&from&to`) eficientes.

## Decisión

Usar `timescale/timescaledb` (Postgres + extensión TimescaleDB) y
convertir la tabla `telemetry` en hypertable particionada por `ts`.

## Consecuencias

- (+) Se mantiene SQL/Postgres estándar (el equipo ya conoce `pg`), solo
  se agrega la extensión — no hay que aprender un motor de series de
  tiempo distinto.
- (+) Particionado automático por tiempo sin tener que implementarlo a
  mano en el backend.
- (+) `pg` (driver de Node) funciona igual contra TimescaleDB que contra
  Postgres plano.
- (-) Una dependencia más pesada que Postgres vanilla para un hackatón,
  pero el volumen de `telemetry` justifica no dejarlo como tabla normal
  sin particionar.
