# ADR 0004 — Una rama por persona, `main` siempre integrable

**Estado:** Aceptado

## Contexto

Somos dos personas trabajando en cuatro repos a la vez (`sit-ciit-infra`,
`sit-ciit-backend`, `sit-ciit-dashboard`, `sit-ciit-mobile`), en la misma
franja de horas y sobre una base de código que todavía es andamiaje: casi
cualquier cambio toca archivos raíz (`package.json`, `App.tsx`,
`docker-compose.yml`).

Trabajando los dos directo sobre `main` ya se produjo un choque: un push a
`sit-ciit-infra` fue rechazado porque el otro había pusheado a `main`
mientras tanto, y hubo que rebasar para integrarlo. Con más volumen de
cambios eso deja de ser una molestia y empieza a costar trabajo perdido.

Tampoco queremos el extremo opuesto: ramas largas por funcionalidad que
viven días y terminan en un merge doloroso, con el contrato de mensajes
(`contracts/contract.ts`) desincronizado entre repos.

## Decisión

- **Cada persona trabaja en su propia rama**, con su nombre:
  `carlos-branch`, `alexis-branch`. Ya existen en los cuatro repos.
- **Nadie commitea directo a `main`.** `main` solo avanza integrando una
  rama de persona.
- **Antes de empezar el día y antes de integrar**: `git pull` de `main` y
  `git rebase origin/main` sobre la rama propia. Rebase, no merge, para
  que el historial quede lineal y legible.
- **Integrar seguido** (idealmente cada vez que algo funciona de punta a
  punta, no cuando la funcionalidad completa está lista). Una rama que
  lleva más de un día sin volver a `main` es una señal de alarma.
- **El contrato es la excepción estricta**: `contracts/` solo se toca en
  `sit-ciit-infra`, se avisa a la otra persona antes, se sube la versión
  semver, se actualiza el CHANGELOG y se corre `scripts/sync-contract.sh`.
  Un cambio de contrato se integra a `main` solo, sin mezclarlo con otro
  trabajo.
- **Dueño por repo mientras dure el MVP**, para minimizar el solape:
  backend y la infraestructura de datos las lleva una persona; dashboard
  la otra; mobile e infra se tocan de ambos lados, coordinando antes.

## Consecuencias

- (+) `main` se mantiene en un estado que siempre arranca: si algo se
  rompe, se rompe en la rama de quien lo está escribiendo.
- (+) Los conflictos aparecen al rebasar la rama propia, uno a la vez y en
  contexto, en vez de aparecer como un push rechazado a mitad de otra cosa.
- (+) Cada quien puede commitear a su ritmo, incluso trabajo a medias, sin
  arrastrar a la otra persona.
- (-) Hay que rebasar seguido. Una rama que se deja quieta varios días
  acumula conflictos igual: la disciplina de integrar seguido es parte de
  la decisión, no un detalle opcional.
- (-) Al ser dos personas no usamos pull requests con revisión formal
  (sería un cuello de botella). A cambio, el requisito es avisar por el
  canal del equipo qué se integró a `main`, sobre todo si toca archivos
  compartidos.

## Notas

No usamos ramas efímeras por funcionalidad (`feat/...`) porque con dos
personas y un MVP corto el costo de coordinación supera el beneficio. Si
el equipo crece o el proyecto pasa a mantenimiento, conviene revisar esta
decisión y pasar a ramas por cambio con pull request.
