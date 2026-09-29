# Guion de la demo (criterio de aceptación)

El sistema se considera terminado cuando este guion completo funciona con
**2 celulares Android + 1 laptop**, sin datos simulados en ningún paso.

## Montaje

- **Celular A** — modo Nodo, `role: primary`, `unitId: unit-01`,
  `nodeId: unit-01-a`. Dentro de una caja/contenedor de prueba.
- **Celular B** — modo Nodo + Operador (pestañas), `role: backup`,
  `unitId: unit-01`, `nodeId: unit-01-b`.
- **Laptop** — `sit-ciit-dashboard` abierto en el navegador, sesión
  `control_center` iniciada.
- Los tres apuntando al mismo broker (`sit-ciit-infra` corriendo, IP de la
  laptop accesible en la misma red Wi-Fi/hotspot).

## Pasos

1. **Arranque en vivo.** A y B mandan telemetría real (acelerómetro, luz,
   GPS si hay señal). El dashboard muestra el mapa y las gráficas
   actualizándose sin intervención manual.
2. **Eventos de borde.** Se agita la caja → evento `impact` (severity
   según magnitud). Se abre la caja → `door_open`. Ambos deben aparecer en
   la vista de Eventos del dashboard en segundos, con GPS si está
   disponible.
3. **Comando exitoso.** Desde el dashboard (control_center) se envía
   `set_sampling_rate` a A. El comando pasa `sent → delivered → executed`
   y el siguiente `heartbeat` de A refleja el nuevo `samplingMs`.
4. **Nodo sin señal.** A entra en modo avión. Se generan eventos en A (se
   quedan en su outbox local, visible en pantalla como cola pendiente).
   Desde el dashboard se manda un comando a A → queda en `sent` (no hay
   `delivered` porque A está desconectado).
5. **Failover.** El backend detecta que A no manda heartbeat en 15 s, lo
   marca offline, y como B (backup) sigue online, la fuente activa de
   `unit-01` pasa a B. Se registra el evento `source_failover` y el
   dashboard lo refleja (fuente activa = B).
6. **Operador confirma y activa alarma.** Desde B (vista Operador) se
   confirma la alerta pendiente y se dispara `trigger_alarm` sobre B (o
   sobre otra unidad) — vibración + sonido + pantalla parpadeando en el
   celular objetivo.
7. **Reconexión y recuperación.** A sale de modo avión: su outbox
   sincroniza los eventos generados sin señal, conservando su `ts`
   original (el dashboard los marca como tardíos por la diferencia entre
   `ts` y `received_at`). A recibe el comando pendiente (retenido por
   Mosquitto, `clean: false`) y lo confirma `executed`. La fuente activa
   de `unit-01` regresa a A.

## Qué observar en cada pantalla

| Pantalla                | Qué mostrar en cada paso |
|--------------------------|---------------------------|
| Dashboard → Mapa         | posición en vivo, trazado real de la Línea Z |
| Dashboard → Unidad       | gráficas en vivo, primary/backup, fuente activa, cola reportada |
| Dashboard → Eventos      | severidad, confirmación, marca de "tardío" |
| Dashboard → Comandos     | estados `sent → delivered → executed/rejected`, tiempos |
| Dashboard → Bitácora     | quién mandó qué comando y cuándo |
| Celular Nodo             | estado de conexión, últimas lecturas, cola pendiente (outbox) |
| Celular Operador         | alertas en vivo, botones trigger/stop alarm |
