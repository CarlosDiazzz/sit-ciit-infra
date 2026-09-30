# Despliegue, costos y escalabilidad

Análisis de qué cuesta poner SIT-CIIT en producción y hasta dónde aguanta
la arquitectura actual. Las cifras de volumen salen de medir la base real
(no de estimaciones): **22 bytes por fila** de telemetría en TimescaleDB,
incluyendo índices.

## Qué hay que desplegar

| Pieza | Qué es | Dónde vive |
|---|---|---|
| Mosquitto | broker MQTT, puertos 1883 y 9001 | servidor |
| TimescaleDB | Postgres + extensión de series de tiempo | servidor o gestionado |
| Backend | Fastify + suscriptor MQTT + Socket.IO | servidor |
| Dashboard | estático (Vite build) | CDN o el mismo servidor |
| App móvil | Expo, se instala en cada celular | los nodos |

El dashboard compila a archivos estáticos: no necesita servidor propio y
puede ir en cualquier CDN gratuito.

## Volumen de datos

A 1 Hz por nodo, funcionando 24/7:

| Nodos | Filas/día | GB/mes | GB/año |
|---|---|---|---|
| 2 | 172 800 | 0.11 | 1.4 |
| 10 | 864 000 | 0.57 | 6.8 |
| 50 | 4 320 000 | 2.85 | 34 |
| 200 | 17 280 000 | 11.4 | 137 |
| 1000 | 86 400 000 | 57 | 684 |

El dato importante: **el almacenamiento no es el problema**. Mil nodos
generan 684 GB al año, y eso se reduce mucho con las políticas de
compresión de TimescaleDB (ver más abajo).

## Costo mensual estimado

Tres escenarios, con precios de referencia de 2026 (Hetzner / DigitalOcean
/ AWS). Son órdenes de magnitud, no cotizaciones.

### Demo y piloto (2-10 nodos)

| Concepto | Opción | USD/mes |
|---|---|---|
| VPS 2 vCPU / 4 GB | Hetzner CX22 | ~5 |
| Dashboard estático | Cloudflare Pages / Netlify | 0 |
| Dominio + TLS | Let's Encrypt | ~1 |
| **Total** | | **~6** |

Todo cabe en una sola máquina con Docker Compose, que es exactamente lo
que ya tenemos en `docker-compose.yml`.

### Operación real (50 nodos)

| Concepto | Opción | USD/mes |
|---|---|---|
| VPS 4 vCPU / 8 GB | Hetzner CX32 | ~12 |
| Respaldos automáticos | snapshot diario | ~3 |
| Dashboard estático | CDN | 0 |
| **Total** | | **~15** |

### Producción con base gestionada (200+ nodos)

| Concepto | Opción | USD/mes |
|---|---|---|
| Servidor de aplicación | 4 vCPU / 8 GB | ~25 |
| Timescale Cloud / RDS | gestionado con respaldos | ~70–150 |
| Balanceador + TLS | | ~12 |
| **Total** | | **~110–190** |

El salto de precio viene de la base gestionada. Mientras el equipo pueda
operar Postgres, seguir en VPS propio cuesta una fracción.

### Datos móviles (lo que sí se acumula)

Cada celular publicando a 1 Hz consume **~0.9 GB/mes** de datos móviles
(payload ~250 B más overhead de TLS y MQTT). Con 50 nodos son 45 GB/mes
en planes de datos — fácilmente el gasto mayor de todo el sistema.

Bajar el muestreo a una muestra cada 5 s lo deja en **0.18 GB/mes por
nodo**, cinco veces menos. El contrato ya permite ajustarlo en caliente
con el comando `set_sampling_rate`: conviene muestrear rápido solo cuando
hay movimiento o alerta.

## Qué escala bien tal como está

**El contrato desacopla todo.** Nodos, backend y dashboard solo comparten
`contract.ts`. Se puede sustituir el celular por un ESP32 sin tocar el
servidor, que es un requisito explícito del proyecto.

**El particionado de TimescaleDB.** `telemetry` es una hypertable
particionada por tiempo: las consultas recientes no pagan el costo de los
datos históricos, y se pueden comprimir o borrar particiones viejas sin
tocar las nuevas.

**La deduplicación por `msgId`.** Los reintentos QoS 1 no generan filas
duplicadas, así que reenviar no corrompe los datos. Eso permite reintentar
sin miedo cuando la red falla.

**El dashboard es estático.** No hay renderizado en servidor: escala
poniéndolo en un CDN, con costo prácticamente cero.

**La arquitectura hexagonal del backend.** El dominio no conoce Fastify,
MQTT ni Postgres. Cambiar Mosquitto por otro broker, o Postgres por otra
base, es escribir un adaptador nuevo, no reescribir las reglas.

## Qué hay que cambiar para escalar

Por orden de urgencia según crezca el número de nodos.

### 1. Compresión y retención (antes de 50 nodos)

Verificado en la base actual: `compression_enabled = false` en la
hypertable `telemetry`, y ninguna migración define políticas. El único
job que aparece (`policy_telemetry`) es interno de TimescaleDB, no
nuestro.

TimescaleDB puede comprimir particiones viejas (típicamente 10-20× en
series de tiempo) y borrar automáticamente lo que pase de cierta edad.
Sin esto, la base crece sin límite.

```sql
ALTER TABLE telemetry SET (timescaledb.compress);
SELECT add_compression_policy('telemetry', INTERVAL '7 days');
SELECT add_retention_policy('telemetry', INTERVAL '1 year');
```

Decidir cuánto histórico se necesita es una decisión de negocio, no
técnica: para auditoría de siniestros puede hacer falta un año.

### 2. Una sola instancia del backend (límite actual)

Hoy el backend es un proceso único y eso impone dos límites:

- **El vigilante de liveness** (`livenessWatcher`) corre en memoria. Con
  dos instancias, ambas evaluarían las mismas caídas y registrarían
  eventos duplicados.
- **Socket.IO sin adaptador compartido** solo emite a los clientes
  conectados a esa instancia.

Con 200+ nodos o para tener alta disponibilidad hace falta: un adaptador
de Redis para Socket.IO, y mover el vigilante a un proceso aparte o
tomar un lock en la base para que solo uno evalúe a la vez.

Mientras sea un proceso, el límite práctico está en el orden de **cientos
de nodos**, no de miles.

### 3. Mosquitto en un solo nodo

Aguanta miles de conexiones en una máquina modesta, pero es un punto
único de fallo. Para alta disponibilidad hay que ir a un broker en
clúster (EMQX, HiveMQ, NanoMQ) — el contrato no cambia, solo la
infraestructura.

### 4. Agregados continuos para el dashboard

Hoy las gráficas consultan filas crudas. Con meses de histórico eso se
vuelve lento. TimescaleDB tiene *continuous aggregates*: promedios por
minuto u hora calculados de forma incremental, que es lo que una vista de
histórico necesita (nadie mira 86 400 puntos de un día).

### 5. Autenticación y TLS antes de exponer nada

Pendientes de la Fase 6, pero son requisito de despliegue, no mejora:

- **MQTT sin TLS**: hoy va en claro por el puerto 1883. En Internet,
  cualquiera en la ruta ve la telemetría y las credenciales.
- **CORS abierto** (`origin: "*"`) en el backend y en Socket.IO, con un
  comentario en el código de restringirlo al agregar login.
- **Un solo usuario MQTT compartido** por todos los nodos. Lo correcto es
  un usuario por nodo con ACL por tópico, para que un celular robado no
  pueda publicar como otro ni leer lo ajeno.

## Resumen

| Horizonte | Nodos | Costo/mes | Cambios necesarios |
|---|---|---|---|
| Demo | 2–10 | ~6 USD | ninguno |
| Piloto | 10–50 | ~15 USD | compresión, retención, TLS, auth |
| Operación | 50–200 | ~25–40 USD | agregados continuos |
| Escala | 200+ | ~110–190 USD | Redis, vigilante aparte, broker en clúster |

La arquitectura aguanta hasta cientos de nodos sin rediseño. Lo que hay
que resolver antes de producción no es escala, es **seguridad** (TLS,
auth, un usuario por nodo) y **retención** (compresión y borrado
automático).
