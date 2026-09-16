#!/usr/bin/env node
/**
 * merge-config.mjs — Fusiona la configuración de IMALEagent con la ya instalada.
 *
 * Uso:
 *   node merge-config.mjs <incoming.json> <existing.json> <out.json>
 *
 * Reglas:
 *   - `existing` es la base: conserva cualquier clave que el repo no defina
 *     (por ejemplo `packages`, `defaultProvider`, `defaultModel`,
 *     `lastChangelogVersion` y servidores MCP propios del usuario).
 *   - `incoming` (la versión del repo) gana en las claves que sí define.
 *   - El merge es recursivo para objetos; los arrays se reemplazan.
 *
 * Códigos de salida:
 *   0  fusión correcta
 *   1  uso incorrecto
 *   2  alguno de los ficheros no es JSON válido
 *
 * Node es un requisito previo del instalador, así que está siempre disponible.
 */
import { existsSync, readFileSync, writeFileSync } from "node:fs";

const USAGE = "uso: merge-config.mjs <incoming.json> <existing.json> <out.json>";

function fail(message, code = 1) {
  process.stderr.write(`${message}\n`);
  process.exit(code);
}

const [, , incomingPath, existingPath, outPath] = process.argv;
if (!incomingPath || !existingPath || !outPath) fail(`[merge-config] ${USAGE}`);

const isPlainObject = (value) => value !== null && typeof value === "object" && !Array.isArray(value);

function readJson(path, label) {
  if (!existsSync(path)) return undefined;
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch (error) {
    fail(`[merge-config] ${label} no es JSON válido (${path}): ${error.message}`, 2);
  }
}

/** Deep merge: `overlay` wins, `base` keeps every key the overlay does not define. */
function merge(base, overlay) {
  if (!isPlainObject(base) || !isPlainObject(overlay)) return overlay;
  const merged = { ...base };
  for (const [key, value] of Object.entries(overlay)) {
    merged[key] = isPlainObject(value) && isPlainObject(base[key]) ? merge(base[key], value) : value;
  }
  return merged;
}

const incoming = readJson(incomingPath, "config del repositorio");
if (incoming === undefined) fail(`[merge-config] no existe la config del repositorio: ${incomingPath}`);
const existing = readJson(existingPath, "config instalada");

const merged = existing === undefined ? incoming : merge(existing, incoming);

if (existing !== undefined) {
  const preserved = Object.keys(existing).filter((key) => !(key in incoming));
  if (preserved.length > 0) {
    process.stdout.write(`[merge-config] claves conservadas de la config previa: ${preserved.join(", ")}\n`);
  }
}

writeFileSync(outPath, `${JSON.stringify(merged, null, 2)}\n`);
