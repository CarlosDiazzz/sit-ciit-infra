// Descarga (una sola vez) el trazado real de la Línea Z / Corredor Interoceánico
// del Istmo de Tehuantepec (Salina Cruz, Oax. — Coatzacoalcos, Ver.) desde
// OpenStreetMap vía la API de Overpass, y lo guarda como GeoJSON en data/linea-z.geojson.
//
// NO genera datos falsos: es una sola descarga de datos reales de OSM, usada
// después como capa de mapa (no como fuente de telemetría).
//
// Datos © contribuyentes de OpenStreetMap, licencia ODbL 1.0:
// https://www.openstreetmap.org/copyright
//
// Uso:
//   npx tsx scripts/fetch-linea-z.ts
//
// Si la consulta no encuentra vías (los nombres en OSM pueden variar), abre
// la misma consulta en https://overpass-turbo.eu/ , ajusta el filtro de
// `name` y vuelve a correr el script.

import { writeFile, mkdir } from "node:fs/promises";
import path from "node:path";

const OVERPASS_URL = "https://overpass-api.de/api/interpreter";

// Bounding box aproximado del corredor Salina Cruz <-> Coatzacoalcos
// (south, west, north, east).
const BBOX = "16.0,-95.4,18.3,-94.2";

// Filtro por nombre: cubre las variantes con las que la vía férrea del
// Istmo suele aparecer etiquetada en OSM.
const NAME_FILTER =
  "Interoce|Transístmico|Transistmico|Ferrocarril del Istmo|Línea Z|Linea Z|FIT";

const QUERY = `
[out:json][timeout:180];
(
  way["railway"~"^(rail|light_rail)$"]["name"~"${NAME_FILTER}",i](${BBOX});
);
out geom;
`.trim();

interface OverpassGeometryPoint {
  lat: number;
  lon: number;
}

interface OverpassWay {
  type: "way";
  id: number;
  tags?: Record<string, string>;
  geometry?: OverpassGeometryPoint[];
}

interface OverpassResponse {
  elements: OverpassWay[];
}

async function main() {
  console.log("Consultando Overpass API...");
  console.log(QUERY);

  const res = await fetch(OVERPASS_URL, {
    method: "POST",
    headers: { "Content-Type": "text/plain" },
    body: QUERY,
  });

  if (!res.ok) {
    throw new Error(`Overpass respondió ${res.status}: ${await res.text()}`);
  }

  const data = (await res.json()) as OverpassResponse;
  const ways = data.elements.filter(
    (el): el is OverpassWay => el.type === "way" && !!el.geometry?.length
  );

  if (ways.length === 0) {
    throw new Error(
      "No se encontraron vías. Ajusta NAME_FILTER o BBOX en este script " +
        "(prueba la consulta en https://overpass-turbo.eu/ primero)."
    );
  }

  const geojson = {
    type: "FeatureCollection" as const,
    metadata: {
      source: "OpenStreetMap contributors, ODbL 1.0 (https://www.openstreetmap.org/copyright)",
      query: QUERY,
      fetchedAt: new Date().toISOString(),
    },
    features: ways.map((way) => ({
      type: "Feature" as const,
      properties: {
        osmWayId: way.id,
        name: way.tags?.name ?? null,
        railway: way.tags?.railway ?? null,
        operator: way.tags?.operator ?? null,
      },
      geometry: {
        type: "LineString" as const,
        coordinates: way.geometry!.map((pt) => [pt.lon, pt.lat]),
      },
    })),
  };

  const outDir = path.resolve(import.meta.dirname, "..", "data");
  const outFile = path.join(outDir, "linea-z.geojson");
  await mkdir(outDir, { recursive: true });
  await writeFile(outFile, JSON.stringify(geojson, null, 2), "utf-8");

  console.log(`Guardado ${ways.length} segmentos en ${outFile}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
