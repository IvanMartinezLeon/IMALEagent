#!/usr/bin/env node
/**
 * uninstall-config.mjs — Retira la configuración instalada por IMALEagent.
 *
 * Uso:
 *   node uninstall-config.mjs <agentConfigDir>
 *
 * Fuente única de verdad para los tres desinstaladores (bash, PowerShell, CMD):
 * así las listas de limpieza no se desincronizan entre plataformas.
 *
 * Reglas de seguridad:
 *   - Sólo elimina ficheros. Nunca directorios completos, para no borrar
 *     material propio del usuario (por ejemplo `agents/mi-agente.md`).
 *   - Nunca toca `settings.json` ni `mcp.json` sin restaurarlos antes desde la
 *     copia de seguridad más antigua (el estado previo a la instalación).
 *   - Nunca toca los directorios `.backup-*`.
 *   - Los directorios que queden vacíos se eliminan al final.
 *
 * Node es un requisito previo del instalador, así que está siempre disponible.
 */
import { existsSync, readdirSync, readFileSync, rmSync, rmdirSync, copyFileSync } from "node:fs";
import * as path from "node:path";

const [, , agentConfigDir] = process.argv;

if (!agentConfigDir) {
  process.stderr.write("[uninstall-config] uso: uninstall-config.mjs <agentConfigDir>\n");
  process.exit(1);
}

const log = (message) => process.stdout.write(`[uninstall-config] ${message}\n`);
const manifestPath = path.join(agentConfigDir, ".imale-manifest");

/** Ficheros que las instalaciones antiguas (sin manifiesto) sí dejaban registrados. */
const LEGACY_FILES = [
  "APPEND_SYSTEM.md",
  "BEST_PRACTICES.md",
  "EXPLORATION_STRATEGY.md",
  "GUIDANCE_INDEX.md",
  "logo.txt",
  "presets.json",
  "extensions/ai-router.ts",
  "extensions/imale-header.ts",
  "extensions/imale-preset.ts",
  "extensions/lib/shared-ui.ts",
  "themes/imale-theme.json",
  "themes/imale-theme-colors.md",
  "bin/pi",
  "bin/pi.cmd",
  "bin/imaleagent",
  "bin/imaleagent.cmd",
];

const PACKAGE_DIRS = [
  "npm/node_modules/context-mode",
  "npm/node_modules/pi-mcp-adapter",
  "npm/node_modules/pi-subagents",
  "npm/node_modules/pi-lens",
  "npm/node_modules/@juicesharp/rpiv-todo",
  "npm/node_modules/@juicesharp/rpiv-ask-user-question",
];

const MERGED_JSON = ["settings.json", "mcp.json"];

function readManifest() {
  if (!existsSync(manifestPath)) return undefined;
  return readFileSync(manifestPath, "utf8")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
}

function removeEntry(relative) {
  const target = path.join(agentConfigDir, ...relative.split("/"));
  if (!existsSync(target)) return false;
  rmSync(target, { recursive: true, force: true });
  return true;
}

/** Copia de seguridad más antigua: el estado anterior a la primera instalación. */
function oldestBackupDir() {
  if (!existsSync(agentConfigDir)) return undefined;
  const backups = readdirSync(agentConfigDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && entry.name.startsWith(".backup-"))
    .map((entry) => entry.name)
    .sort();
  return backups.length > 0 ? path.join(agentConfigDir, backups[0]) : undefined;
}

function restoreMergedJson(backupDir) {
  for (const file of MERGED_JSON) {
    const target = path.join(agentConfigDir, file);
    const previous = backupDir ? path.join(backupDir, file) : undefined;
    if (previous && existsSync(previous)) {
      copyFileSync(previous, target);
      log(`${file} restaurado desde ${path.basename(backupDir)}`);
    } else if (existsSync(target)) {
      rmSync(target, { force: true });
      log(`${file} eliminado (no existía antes de instalar)`);
    }
  }
}

function pruneEmptyDirs(dir) {
  if (!existsSync(dir)) return;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (entry.name.startsWith(".backup-")) continue;
    const child = path.join(dir, entry.name);
    pruneEmptyDirs(child);
    try {
      rmdirSync(child);
    } catch {
      // no está vacío o no se puede borrar: se deja tal cual
    }
  }
}

// ── 1. Ficheros instalados ────────────────────────────────────────────
const manifest = readManifest();
let removed = 0;

if (manifest) {
  for (const relative of manifest) {
    if (removeEntry(relative)) removed++;
  }
  log(`${removed} fichero(s) eliminados según el manifiesto`);
} else {
  log(`AVISO: no se encontró ${manifestPath}; se eliminan sólo las rutas conocidas`);
  for (const relative of LEGACY_FILES) {
    if (removeEntry(relative)) removed++;
  }
  log(`${removed} fichero(s) conocidos eliminados`);
  log(`AVISO: revisa a mano ${agentConfigDir}/agents, /prompts y /skills`);
}

// ── 2. settings.json y mcp.json vuelven al estado previo ──────────────
const backupDir = oldestBackupDir();
if (backupDir) {
  restoreMergedJson(backupDir);
} else {
  log("AVISO: sin copia de seguridad previa; settings.json y mcp.json se dejan como están");
  for (const file of MERGED_JSON) removeEntry(file);
}
rmSync(manifestPath, { force: true });

// ── 3. Paquetes instalados en el directorio del agente ────────────────
for (const relative of PACKAGE_DIRS) removeEntry(relative);

// ── 4. Directorios vacíos ─────────────────────────────────────────────
pruneEmptyDirs(agentConfigDir);

if (backupDir) {
  log(`copias de seguridad conservadas en ${agentConfigDir}/.backup-* (bórralas a mano si no las necesitas)`);
}

const leftovers = existsSync(agentConfigDir) && readdirSync(agentConfigDir).some((name) => !name.startsWith(".backup-"));
log(leftovers ? `quedan elementos propios en ${agentConfigDir} (no instalados por IMALEagent)` : `configuración eliminada de ${agentConfigDir}`);
