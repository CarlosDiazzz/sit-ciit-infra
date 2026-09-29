# ADR 0001 — Cuatro repositorios separados en vez de monorepo

**Estado:** Aceptado

## Contexto

SIT-CIIT tiene cuatro componentes con stacks y ciclos de vida distintos:
infraestructura (Docker), backend (Node/Fastify), móvil (Expo/React
Native) y dashboard (React/Vite).

## Decisión

Cuatro repos independientes, con el contrato de mensajes como frontera
explícita entre ellos (ver ADR 0004 — pendiente si se necesita detallar
el mecanismo de sync).

## Consecuencias

- (+) Cada repo se despliega y versiona por separado.
- (+) El tooling de cada stack no interfiere con los demás (no hay que
  reconciliar configs de ESLint/TS/bundlers de Node, Expo y Vite en un
  solo workspace).
- (+) El contrato compartido obliga a que los cambios de interfaz entre
  componentes sean explícitos y versionados, no un refactor silencioso de
  un paquete interno.
- (-) Sincronizar el contrato requiere un paso manual
  (`scripts/sync-contract.sh`) en vez de ser automático como en un
  monorepo con paquete compartido. Se acepta el costo porque el proyecto
  es pequeño (4 repos, 1 contrato) y el hackatón no justifica la
  infraestructura de un monorepo.
