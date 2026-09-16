/**
 * IMALE Preset Selector
 *
 * Interactive TUI preset selector (IMALE:preset) with themed overlay.
 * Cambia el comportamiento del agente entre modos: documentación, revisión,
 * implementación, debug, arquitectura, exploración y general.
 *
 * Integración:
 * - Inyecta instrucciones en el system prompt via before_agent_start
 * - Cambia herramientas activas y nivel de thinking por preset
 * - Emite evento IMALE:agent-mode para sincronizar el footer del header
 * - Persiste el preset activo entre sesiones via pi.appendEntry
 * - Lee presets de ~/.pi/agent/presets.json con fallback built-in
 */

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { showSelectList } from "./lib/shared-ui";

// ── Types ────────────────────────────────────────────────────────────────

interface Preset {
  label: string;
  description: string;
  emoji: string;
  footerLabel: string;
  thinkingLevel?: "off" | "minimal" | "low" | "medium" | "high" | "xhigh";
  tools?: string[];
  instructions: string;
}

interface PresetManifest {
  [key: string]: Preset;
}

// ── Built-in presets (fallback when no presets.json) ──────────────────────

const BUILTIN_PRESETS: PresetManifest = {
  general: {
    label: "✦ General",
    description: "Modo predeterminado – capacidades equilibradas",
    emoji: "✦",
    footerLabel: "general",
    thinkingLevel: "medium",
    instructions:
      "Modo general predeterminado. Capacidades equilibradas.\n\nComportamiento:\n- Sin restricciones de herramientas\n- Respuestas adaptadas al contexto\n- Modo por defecto",
  },
  documentacion: {
    label: "📖 Documentación",
    description: "Generar, revisar y mantener documentación técnica",
    emoji: "📖",
    footerLabel: "docs",
    thinkingLevel: "high",
    instructions:
      "Estás en MODO DOCUMENTACIÓN. Tu objetivo es generar, revisar y mantener documentación técnica de alta calidad.\n\nReglas:\n- Prioriza claridad y completitud sobre brevedad\n- Genera documentación en Markdown bien estructurado\n- Incluye ejemplos de código funcionales y completos\n- Documenta APIs con request/response reales\n- Mantén un tono profesional pero accesible\n- Si revisas documentación existente, señala secciones obsoletas, incompletas o ambiguas\n- Usa español para audiencia general, inglés para APIs técnicas y código\n- Incluye secciones de troubleshooting cuando corresponda\n- Añade enlaces a recursos relacionados\n- Sigue la guía de estilo del proyecto si existe",
  },
  revision: {
    label: "✓ Revisión",
    description: "Code review, calidad y seguridad – solo lectura",
    emoji: "✓",
    footerLabel: "review",
    thinkingLevel: "high",
    instructions:
      "Estás en MODO REVISIÓN. Tu objetivo es revisar código de forma exhaustiva y proponer mejoras.\n\nReglas:\n- Lee archivos completos (sin offset/limit) para tener contexto total\n- Busca: bugs, problemas de seguridad, code smells, falta de tests, strings sin traducir, violaciones de arquitectura, rendimiento\n- Para cada hallazgo: explica el problema, por qué es problemático y la solución propuesta\n- Clasifica hallazgos por severidad: 🔴 crítico, 🟠 alto, 🟡 medio, 🔵 bajo, ⚪ sugerencia\n- Verifica cobertura de tests y patrones de testing\n- Señala código muerto (principio YAGNI)\n- Revisa consistencia con el resto del código base\n- Comprueba que no haya secretos hardcodeados (tokens, passwords, API keys)\n- Al final, da un resumen ejecutivo con puntuación general y prioridades",
    tools: ["read", "bash", "grep", "find", "ls", "rg"],
  },
  implementacion: {
    label: "⚡ Implementación",
    description: "Escribir código enfocado y correcto",
    emoji: "⚡",
    footerLabel: "implement",
    thinkingLevel: "high",
    instructions:
      "Estás en MODO IMPLEMENTACIÓN. Tu objetivo es hacer cambios de código enfocados, correctos y bien probados.\n\nReglas:\n- Mantén el alcance ajustado. Haz exactamente lo que se pide, ni más ni menos\n- Lee archivos antes de editarlos para entender el estado actual\n- Haz ediciones quirúrgicas con edit (prefiere edit sobre write para archivos existentes)\n- Explica brevemente tu razonamiento antes de cada cambio\n- Sigue las convenciones del proyecto: estructura, naming, patrones, estilos\n- Ejecuta tests o type checks después de los cambios si el proyecto los tiene\n- Si encuentras complejidad inesperada, PARA y explica el problema en lugar de improvisar\n- Si no existe un plan o spec, pregunta antes de empezar cambios no triviales\n- No dejes código comentado, console.logs, o todo(s) sin resolver\n- Al terminar: resume lo que se hizo y nota trabajo pendiente o tests necesarios",
    tools: ["read", "bash", "edit", "write", "rg"],
  },
  debug: {
    label: "◉ Debug",
    description: "Diagnóstico profundo y resolución de bugs",
    emoji: "◉",
    footerLabel: "debug",
    thinkingLevel: "high",
    instructions:
      "Estás en MODO DEBUG. Tu objetivo es diagnosticar y resolver problemas técnicos de forma metódica.\n\nReglas:\n- Enfoque forense: primero entiende el problema, luego busca la causa raíz\n- Lee logs, trazas de error y salida de tests primero\n- Formula hipótesis antes de hacer cambios\n- Aísla variables: cambia una cosa a la vez\n- Usa salida verbosa/verbose cuando sea necesario\n- Si hay logs grandes (>50 líneas), usa context-mode (ctx_write/ctx_read) o guarda en archivo en vez de volcar en conversación\n- Documenta hallazgos intermedios para no perder contexto\n- Si usas subagentes, usa fork para no contaminar el contexto principal\n- Al resolver: explica la causa raíz y por qué la solución funciona\n- Si no encuentras la causa, resume lo descartado y sugiere siguientes pasos\n- Mapea la estructura y acota la búsqueda antes de tocar el código",
  },
  arquitectura: {
    label: "⊡ Arquitectura",
    description: "Análisis estructural, diseño y ADRs",
    emoji: "⊡",
    footerLabel: "arch",
    thinkingLevel: "high",
    instructions:
      "Estás en MODO ARQUITECTURA. Tu objetivo es analizar y diseñar la estructura del sistema.\n\nReglas:\n- Mapea la estructura del proyecto antes de proponer cambios\n- Localiza los consumidores de cada símbolo o módulo antes de tocarlo\n- Analiza: acoplamiento, cohesión, separación de concerns, patrones, deuda técnica\n- Propón cambios estructurales con diagramas en Markdown (Mermaid si aplica)\n- Identifica riesgos arquitectónicos y trade-offs explícitamente\n- Para diseños nuevos: enumera componentes, responsabilidades, interfaces y flujo de datos\n- Evalúa si la arquitectura actual escala para los requisitos\n- Documenta decisiones y su justificación (ADR - Architecture Decision Record)\n- Sugiere mejoras incrementales, no rewriting completo a menos que sea necesario\n- Señala violaciones del principio de responsabilidad única y dependency inversion",
  },
  exploracion: {
    label: "🔍 Exploración",
    description: "Onboarding y descubrimiento del código base",
    emoji: "🔍",
    footerLabel: "explore",
    thinkingLevel: "medium",
    instructions:
      "Estás en MODO EXPLORACIÓN. Tu objetivo es entender un código base nuevo o una parte desconocida del proyecto.\n\nReglas:\n- Sigue la jerarquía de 3 pasos: mapear estructura → `rg` acotado → `read` dirigido\n- Comienza con una vista general: estructura de directorios, tecnologías principales, patrones\n- Identifica: entry points, configuraciones clave, modelos de datos, flujos principales\n- Documenta hallazgos a medida que avanzas para no repetir exploración\n- Si encuentras tests, revísalos para entender el comportamiento esperado\n- Al final: resume la arquitectura, puntos clave y recomendaciones para trabajo futuro",
  },
};

// ── Helpers ──────────────────────────────────────────────────────────────

function loadPresets(cwd: string): PresetManifest {
  const globalPath = join(getAgentDir(), "presets.json");
  const projectPath = join(cwd, ".pi", "presets.json");

  let merged: PresetManifest = { ...BUILTIN_PRESETS };

  // Load global presets (override built-ins)
  if (existsSync(globalPath)) {
    try {
      const content = readFileSync(globalPath, "utf-8");
      const globalPresets: PresetManifest = JSON.parse(content);
      merged = { ...merged, ...globalPresets };
    } catch { /* fallback to built-ins */ }
  }

  // Load project presets (override everything)
  if (existsSync(projectPath)) {
    try {
      const content = readFileSync(projectPath, "utf-8");
      const projectPresets: PresetManifest = JSON.parse(content);
      merged = { ...merged, ...projectPresets };
    } catch { /* keep current */ }
  }

  return merged;
}

// ── Export ────────────────────────────────────────────────────────────────

export default function IMALEPresetExtension(pi: ExtensionAPI) {
  let presets: PresetManifest = {};
  let activeKey: string | undefined;
  let activePreset: Preset | undefined;

  // ── Session start: load presets & restore state ───────────────────
  pi.on("session_start", async (_event, ctx) => {
    presets = loadPresets(ctx.cwd);

    // Restore preset from persisted session state
    const entries = ctx.sessionManager.getEntries();
    for (let i = entries.length - 1; i >= 0; i--) {
      const e = entries[i];
      if (e.type === "custom" && (e as any).customType === "IMALE-preset-state") {
        const data = (e as any).data as { name?: string } | undefined;
        if (data?.name && presets[data.name]) {
          activeKey = data.name;
          activePreset = presets[data.name];
        }
        break;
      }
    }

    // Update status indicator
    updateStatus(ctx);
  });

  // ── Persist preset state each turn ──────────────────────────────
  pi.on("turn_start", async () => {
    if (activeKey) {
      pi.appendEntry("IMALE-preset-state", { name: activeKey });
    }
  });

  // ── Inject preset instructions into system prompt each turn ────
  pi.on("before_agent_start", async (event) => {
    if (activePreset?.instructions) {
      return {
        systemPrompt: event.systemPrompt + `\n\n## Modo activo: ${activePreset.label}\n\n${activePreset.instructions}`,
      };
    }
    return undefined;
  });

  // ── Apply preset logic ──────────────────────────────────────────
  async function applyPreset(key: string, preset: Preset, ctx: ExtensionContext): Promise<void> {
    activeKey = key;
    activePreset = preset;

    // Apply thinking level
    if (preset.thinkingLevel) {
      pi.setThinkingLevel(preset.thinkingLevel);
    }

    // Apply tool restrictions (if specified)
    if (preset.tools && preset.tools.length > 0) {
      const allToolNames = pi.getAllTools().map((t) => t.name);
      const validTools = preset.tools.filter((t) => allToolNames.includes(t));
      if (validTools.length > 0) {
        pi.setActiveTools(validTools);
      }
    }

    // Emit event for header integration (IMALE-header.ts listens to this)
    pi.events.emit("IMALE:agent-mode", { mode: key });

    updateStatus(ctx);
  }

  // ── Clear preset and restore defaults ──────────────────────────
  async function clearPreset(ctx: ExtensionContext): Promise<void> {
    activeKey = undefined;
    activePreset = undefined;

    // Reset thinking to default
    pi.setThinkingLevel("medium");

    // Reset tools to all available
    const allTools = pi.getAllTools().map((t) => t.name);
    pi.setActiveTools(allTools);

    // Emit reset event
    pi.events.emit("IMALE:agent-mode", { mode: "general" });

    updateStatus(ctx);
  }

  // ── Status indicator ────────────────────────────────────────────
  function updateStatus(ctx: ExtensionContext) {
    if (activeKey && activePreset) {
      // Raw text sin ANSI: el footer custom lo formatea como botón
      ctx.ui.setStatus("IMALE-preset", `${activePreset.emoji} ${activePreset.footerLabel}`);
    } else {
      ctx.ui.setStatus("IMALE-preset", undefined);
    }
  }

  // ── Show preset selector TUI dialog ─────────────────────────────
  async function showPresetSelector(ctx: ExtensionContext): Promise<void> {
    const presetKeys = Object.keys(presets);

    if (presetKeys.length === 0) {
      ctx.ui.notify("No hay presets definidos. Revisa ~/.pi/agent/presets.json", "error");
      return;
    }

    const items: {
      value: string;
      label: string;
      description: string;
    }[] = presetKeys.map((key) => {
      const p = presets[key];
      const isActive = key === activeKey;
      return {
        value: key,
        label: isActive ? `${p.label} (activo)` : p.label,
        description: p.description,
      };
    });

    // Add "ninguno" option to clear
    items.push({
      value: "(ninguno)",
      label: "✕ Ninguno",
      description: "Limpiar preset activo, restaurar valores por defecto",
    });

    const result = await showSelectList(ctx, items, {
      title: "🎯 Seleccionar preset del agente",
      maxVisible: 10,
      navHint: "↑↓ navegar • enter seleccionar • esc cancelar",
    });

    if (!result) return;

    if (result === "(ninguno)") {
      await clearPreset(ctx);
      ctx.ui.notify("Preset limpiado, valores por defecto restaurados", "info");
      return;
    }

    const preset = presets[result];
    if (preset) {
      await applyPreset(result, preset, ctx);
      ctx.ui.notify(`Preset activado: ${preset.label}`, "info");
    }
  }

  // ── IMALE:preset command (con soporte para args directos) ────
  pi.registerCommand("IMALE:preset", {
    description: "Selector interactivo de presets del agente. Uso: /IMALE:preset [nombre]",
    handler: async (args, ctx) => {
      if (args?.trim()) {
        const name = args.trim();
        const preset = presets[name];
        if (!preset) {
          const available = Object.keys(presets).join(", ");
          ctx.ui.notify(`Preset desconocido: "${name}". Disponibles: ${available}`, "error");
          return;
        }
        await applyPreset(name, preset, ctx);
        ctx.ui.notify(`Preset activado: ${preset.label}`, "info");
        return;
      }
      await showPresetSelector(ctx);
    },
  });

  // ── Alias: /preset-IMALE for convenience ──────────────────────
  pi.registerCommand("preset-IMALE", {
    description: "Selector interactivo de presets del agente (alias de IMALE:preset)",
    handler: async (_args, ctx) => {
      await showPresetSelector(ctx);
    },
  });
}
