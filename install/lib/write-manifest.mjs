#!/usr/bin/env node
/**
 * write-manifest.mjs — Registra lo que el instalador ha copiado.
 *
 * Uso:
 *   node write-manifest.mjs <sourceDir> <manifestPath> [extraRelativePath...]
 *
 * Escribe en <manifestPath> una ruta relativa por línea, en formato POSIX.
 * El desinstalador la usa para eliminar exactamente lo instalado, en lugar de
 * mantener listas duplicadas (y desincronizadas) en tres lenguajes distintos.
 *
 * Node es un requisito previo del instalador, así que está siempre disponible.
 */
import { readdirSync, writeFileSync } from "node:fs";
import * as path from "node:path";

const [, , sourceDir, manifestPath, ...extras] = process.argv;

if (!sourceDir || !manifestPath) {
  process.stderr.write("[write-manifest] uso: write-manifest.mjs <sourceDir> <manifestPath> [extra...]\n");
  process.exit(1);
}

/**
 * Rutas relativas de los ficheros bajo `dir`.
 *
 * Sólo se registran ficheros, nunca directorios: borrar un directorio completo
 * en la desinstalación eliminaría también material propio del usuario que viva
 * dentro (por ejemplo `agents/mi-agente.md`). Los directorios vacíos los limpia
 * después el desinstalador.
 */
function walk(dir, prefix = "") {
  const entries = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const relative = prefix ? `${prefix}/${entry.name}` : entry.name;
    if (entry.isDirectory()) {
      entries.push(...walk(path.join(dir, entry.name), relative));
    } else {
      entries.push(relative);
    }
  }
  return entries;
}

const paths = [...walk(sourceDir), ...extras].filter(Boolean);
writeFileSync(manifestPath, `${paths.join("\n")}\n`);
process.stdout.write(`[write-manifest] ${paths.length} fichero(s) registrados en ${manifestPath}\n`);
