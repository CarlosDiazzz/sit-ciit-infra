# Flujo de trabajo

Guía práctica del día a día. El porqué de estas reglas está en
[`adr/0004-flujo-de-ramas.md`](adr/0004-flujo-de-ramas.md).

Regla corta: **cada quien en su rama, `main` siempre arranca, integrar
seguido.**

## Las ramas

| Rama | Quién |
|---|---|
| `main` | nadie commitea directo; solo recibe integraciones |
| `carlos-branch` | Carlos |
| `alexis-branch` | Alexis |

Existen en los cuatro repos: `sit-ciit-infra`, `sit-ciit-backend`,
`sit-ciit-dashboard`, `sit-ciit-mobile`.

## Al empezar a trabajar

Ponerse al día con lo que la otra persona integró:

```bash
git checkout main
git pull origin main
git checkout <tu-rama>
git rebase main
```

Si el rebase se detiene por un conflicto: resolverlo, `git add <archivo>`,
`git rebase --continue`. Para abandonar y volver al estado anterior,
`git rebase --abort`.

## Mientras trabajas

Commitear en tu rama con la frecuencia que quieras, incluso trabajo a
medias — es tu rama, no molesta a nadie:

```bash
git add <archivos>
git commit -m "feat: ..."
git push origin <tu-rama>
```

Pushear la rama propia seguido sirve de respaldo y deja ver a la otra
persona en qué andas.

## Al integrar a `main`

Cuando algo funciona de punta a punta (no hace falta que la funcionalidad
esté completa):

```bash
# 1. rebasar sobre lo último de main
git checkout main && git pull origin main
git checkout <tu-rama> && git rebase main

# 2. verificar que sigue funcionando DESPUÉS del rebase
#    (el rebase puede romper algo aunque no haya habido conflictos)
npm run typecheck        # o lo que corresponda al repo

# 3. integrar
git checkout main
git merge --ff-only <tu-rama>
git push origin main

# 4. volver a tu rama
git checkout <tu-rama>
```

`--ff-only` falla si `main` avanzó mientras tanto. Eso es deseable: avisa
de que hay que volver al paso 1 en vez de crear un merge enredado.

Después de integrar, avisar por el canal del equipo qué entró, sobre todo
si toca archivos compartidos (`package.json`, configuración, layout).

## El contrato: caso especial

`contracts/contract.ts` y `contract.schema.json` solo se editan en
`sit-ciit-infra`, y son la fuente de verdad de los cuatro repos.

1. Avisar a la otra persona **antes** de tocarlo.
2. Subir la versión (semver) y actualizar `contracts/CHANGELOG.md`.
3. Correr `./scripts/sync-contract.sh` para propagar las copias.
4. Integrar ese cambio a `main` **solo**, sin mezclarlo con otro trabajo,
   y avisar en cuanto esté arriba.

Las copias en `src/contract/contract.ts` de backend, dashboard y mobile
nunca se editan a mano.

## Si el push es rechazado

```
Updates were rejected because the remote contains work that you do not have
```

Significa que la otra persona pusheó primero. No usar `--force`: rebasar y
volver a intentar.

```bash
git fetch origin
git rebase origin/main     # o git rebase origin/<tu-rama> si es tu rama
git push origin <rama>
```

`--force-with-lease` solo tiene sentido sobre la rama propia y después de
un rebase, nunca sobre `main`.

## Convención de commits

Prefijo tipo Conventional Commits, en español, describiendo el porqué y no
solo el qué:

```
feat: agrega vista de eventos con filtro por severidad
fix: corrige create-mqtt-user.sh con mosquitto_passwd 2.x
chore: sincronizar contract.ts v1.0.0 desde sit-ciit-infra
docs: documenta el flujo de ramas
```
