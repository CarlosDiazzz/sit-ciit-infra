# Arquitectura SIT-CIIT

## Vista general

```mermaid
flowchart LR
    subgraph Nodo["Celular Android — sit-ciit-mobile (modo Nodo)"]
        Sensores["Sensores\nacelerómetro / giroscopio\nGPS / luz / presión"]
        Edge["Detección en el borde\nimpact / door / rollover"]
        Outbox["Outbox SQLite\n(store-and-forward)"]
        Sensores --> Edge --> Outbox
    end

    subgraph Broker["sit-ciit-infra"]
        MQTT["Mosquitto\nQoS 1, clean=false"]
    end

    subgraph Backend["sit-ciit-backend"]
        Ingesta["Ingesta MQTT\n(valida con Zod, dedup por msgId)"]
        Monitor["Monitor de nodos\nfailover primary/backup"]
        Cruzada["Validación cruzada\nsensor_disagreement"]
        Comandos["Comandos\nautoridad + bitácora"]
        API["API REST (Fastify)"]
        WS["Socket.IO"]
        DB[("TimescaleDB\ntelemetry / events / commands")]
        Ingesta --> DB
        Monitor --> DB
        Cruzada --> DB
        Comandos --> DB
        API --> DB
        Ingesta --> Monitor --> Cruzada
        Monitor --> WS
        Cruzada --> WS
        Comandos --> WS
    end

    subgraph Operador["Celular Android — sit-ciit-mobile (modo Operador)"]
        OpUI["Alertas en vivo\ntrigger/stop alarm"]
    end

    subgraph Dash["sit-ciit-dashboard"]
        Mapa["Mapa (Línea Z, OpenCelliD, clima)"]
        Graficas["Gráficas en vivo"]
        Bitacora["Bitácora de comandos"]
    end

    Outbox -- "telemetry / event / heartbeat / ack" --> MQTT
    MQTT -- "cmd" --> Outbox
    MQTT <--> Ingesta
    API -- "POST /commands" --> MQTT

    WS --> Dash
    API --> Dash
    WS --> Operador
    API --> Operador
```

## Por qué esta forma

- **El nodo nunca depende de la nube para detectar eventos**: el borde
  (celular) decide `impact`/`door_open`/`rollover` localmente con los
  umbrales configurados, y el outbox garantiza que el evento no se pierde
  aunque no haya señal. Esto es lo que permite operar en el Istmo, donde
  hay tramos sin cobertura celular.
- **Mosquitto con `clean: false` y QoS 1** hace que el broker retenga
  comandos pendientes para un nodo desconectado — el comando se entrega en
  cuanto el nodo reconecta, sin que el backend tenga que reintentarlo.
- **El backend es hexagonal** (dominio/aplicación separados de los
  adaptadores MQTT/HTTP/Postgres) para poder, en el futuro, sustituir el
  nodo celular por un ESP32 hablando el mismo contrato MQTT sin tocar el
  dominio.
- **TimescaleDB** porque `telemetry` es una serie de tiempo de alto volumen
  (hasta 1 muestra/segundo por nodo); una hypertable evita tener que
  reinventar particionado por tiempo.

## Trazado real de la Línea Z

`sit-ciit-infra/data/linea-z.geojson`, descargado una sola vez desde OSM/
Overpass (`scripts/fetch-linea-z.ts`), se usa como capa estática en el
mapa del dashboard. No se regenera en cada demo.
