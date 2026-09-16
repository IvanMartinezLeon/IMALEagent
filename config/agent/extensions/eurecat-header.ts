import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import { showSelectList } from "./lib/shared-ui";
import { readFileSync, existsSync, readdirSync } from "fs";
import { join, sep } from "path";
import { homedir } from "os";

export default function (pi: ExtensionAPI) {
  let cachedFramework: string | null = null;
  let projectVersion: string | null = null;
  let projectName: string | null = null;
  let sessionCtx: ExtensionContext | null = null;
  let totalInput = 0;
  let totalOutput = 0;
  let currentMode = "general";

  pi.on("message_end", (_event, _ctx) => {
    const msg = _event.message as Record<string, unknown>;
    const usage = msg?.usage as Record<string, unknown> | undefined;
    if (usage && typeof usage.input === "number" && typeof usage.output === "number") {
      totalInput += usage.input as number;
      totalOutput += usage.output as number;
    }
  });

  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;

    if (cachedFramework === null) {
      const detected = detectFramework(ctx.cwd);
      cachedFramework = detected.framework;
      projectVersion = detected.projectVersion;
    }
    if (projectName === null) {
      projectName = ctx.cwd.split("/").pop() || ctx.cwd.split("\\").pop() || null;
    }
    sessionCtx = ctx;
    currentMode = "general";
    pi.events.on("IMALE:agent-mode", (data: { mode: string }) => {
      currentMode = data.mode;
    });
    const framework = cachedFramework;
    const logo = loadLogo();

    // ── Custom Header ──────────────────────────────────────────────
    ctx.ui.setHeader((_tui, theme) => ({
      render(width: number): string[] {
        if (!logo) return [""];
        return logo.map(l => truncateToWidth(theme.fg("accent", l), width));
      },
      invalidate() { },
    }));

    // ── Custom Footer (2 líneas) ───────────────────────────────────
    ctx.ui.setFooter((_tui, theme, footerData) => {
      return {
        invalidate() { },
        render(width: number): string[] {
          // ── LÍNEA 1: Versión + Framework + Runtime ────────────
          const versionParts: string[] = [];

          // Project name + version
          const pkgVersion = projectVersion || "";
          if (projectName && pkgVersion) {
            versionParts.push(theme.fg("muted", `${projectName} v${pkgVersion}`));
          } else if (projectName) {
            versionParts.push(theme.fg("muted", projectName));
          } else if (pkgVersion) {
            versionParts.push(theme.fg("muted", `v${pkgVersion}`));
          }

          // Git branch
          const branch = footerData.getGitBranch();
          if (branch) {
            versionParts.push(theme.fg("muted", `Branch: ${branch}`));
          }

          // Framework detectado (incluye su versión)
          if (framework) {
            versionParts.push(theme.fg("muted", framework));
          }

          const versionLine = versionParts.length > 0
            ? versionParts.join(` ${theme.fg("dim", "│")} `)
            : "";

          // ── LÍNEA 2: Info personalizada ───────────────────────
          const infoParts: { text: string; color: string }[] = [];

          // Modo del agente
          const modeColors: Record<string, string> = {
            general: "muted",
            structural: "accent",
            "debug-heavy": "warning",
            review: "success",
            implement: "accent",
          };
          const modeLabels: Record<string, string> = {
            general: "general",
            structural: "structural",
            "debug-heavy": "debug",
            review: "review",
            implement: "implement",
          };
          infoParts.push({
            text: modeLabels[currentMode] || currentMode,
            color: modeColors[currentMode] || "muted",
          });

          // Modelo
          const modelId = sessionCtx?.model?.id;
          if (modelId) {
            infoParts.push({ text: modelId, color: "muted" });
          }

          // Tokens + Credits
          if (totalInput + totalOutput > 0) {
            const mid = sessionCtx?.model?.id || "";
            const credits = calcCredits(mid, totalInput, totalOutput);
            infoParts.push({
              text: `↑${fmt(totalInput)} ↓${fmt(totalOutput)}`,
              color: "muted",
            });
            if (credits > 0.001) {
              infoParts.push({
                text: credits < 0.01
                  ? `<0.01¢`
                  : `${credits.toFixed(2)}¢`,
                color: "muted",
              });
            }
          }

          const leftInfo = infoParts
            .map(p => theme.fg(p.color, p.text))
            .join(` ${theme.fg("dim", "|")} `);

          // ── Context bar (barra en lugar del texto simple) ──────
          const ctxUsage = sessionCtx?.getContextUsage();
          const ctxPct = ctxUsage?.percent;
          let infoLine = leftInfo;
          if (ctxPct != null) {
            const ctxStr = `${theme.fg("muted", "ctx")} ${theme.fg("muted", ctxPct.toFixed(0))}${theme.fg("muted", "%")}`;
            infoLine = leftInfo ? `${leftInfo} ${theme.fg("muted", "|")} ${theme.fg("muted", ctxStr)}` : theme.fg("muted", ctxStr);
          }

          // ── Ensamblar (ambas líneas alineadas a la derecha) ────
          const lines: string[] = [];
          if (versionLine) {
            lines.push(padLeft(versionLine, width));
          }
          lines.push(padLeft(infoLine, width));

          // Truncate each line to terminal width
          return lines.map(l => truncateToWidth(l, width));
        },
      };
    });

    // ── Custom Working Indicator ──────────────────────────────────────
    ctx.ui.setWorkingIndicator({
      frames: [
        ctx.ui.theme.fg("thinkingLow", "◇"),
        ctx.ui.theme.fg("accent", "◆"),
        ctx.ui.theme.fg("thinkingMedium", "◇"),
        ctx.ui.theme.fg("accent", "◆"),
      ],
      intervalMs: 120,
    });

  });

  pi.registerCommand("builtin-header", {
    description: "Restore built-in header with keybinding hints",
    handler: async (_args, ctx) => {
      ctx.ui.setHeader(undefined);
      ctx.ui.setFooter(undefined);
      ctx.ui.notify("Built-in header restored", "info");
    },
  });

  // ── Mode Selector ───────────────────────────────────────────────────
  const MODES: { value: string; label: string; description: string }[] = [
    { value: "general", label: "General", description: "Default mode – balanced capabilities" },
    { value: "structural", label: "Structural", description: "Architecture and codebase exploration" },
    { value: "debug-heavy", label: "Debug", description: "Deep debugging with verbose output" },
    { value: "review", label: "Review", description: "Code review and quality checks" },
    { value: "implement", label: "Implement", description: "Focused implementation tasks" },
  ];

  pi.registerCommand("mode", {
    description: "Switch agent mode via interactive selector",
    handler: async (_args, ctx) => {
      const items = MODES.map((m) => ({
        value: m.value,
        label: m.value === currentMode ? `${m.label} (active)` : m.label,
        description: m.description,
      }));

      const result = await showSelectList(ctx, items, {
        title: "Select Agent Mode",
        maxVisible: 8,
        navHint: "↑↓ navigate • enter select • esc cancel",
      });

      if (result && result !== currentMode) {
        currentMode = result;
        pi.events.emit("IMALE:agent-mode", { mode: result });
        ctx.ui.notify(`Mode switched to: ${result}`, "info");
      }
    },
  });
}

// ── Helpers ────────────────────────────────────────────────────────────

function loadLogo(): string[] | null {
  try {
    const p = join(homedir(), ".pi", "agent", "logo.txt");
    return readFileSync(p, "utf8").split("\n");
  } catch {
    return null;
  }
}

// ── Model Pricing Table ──────────────────────────────────────────
// Cost per 1K tokens in USD (input / output) for common models.
// 1 AI Credit = $0.01 USD → credits = totalCost * 100
interface ModelPricing {
  inputPer1K: number;  // USD per 1K input tokens
  outputPer1K: number; // USD per 1K output tokens
}

const MODEL_PRICING: Record<string, ModelPricing> = {
  // Anthropic Claude
  "claude-sonnet-4":     { inputPer1K: 0.003,  outputPer1K: 0.015 },
  "claude-4-sonnet":     { inputPer1K: 0.003,  outputPer1K: 0.015 },
  "claude-3.5-sonnet":   { inputPer1K: 0.003,  outputPer1K: 0.015 },
  "claude-3-opus":       { inputPer1K: 0.015,  outputPer1K: 0.075 },
  "claude-3-haiku":      { inputPer1K: 0.00025, outputPer1K: 0.00125 },
  "claude-opus-4":       { inputPer1K: 0.015,  outputPer1K: 0.075 },
  // OpenAI / Azure OpenAI
  "gpt-4o":              { inputPer1K: 0.0025, outputPer1K: 0.01 },
  "gpt-4o-mini":         { inputPer1K: 0.00015, outputPer1K: 0.0006 },
  "gpt-4":               { inputPer1K: 0.03,   outputPer1K: 0.06 },
  "gpt-4-turbo":         { inputPer1K: 0.01,   outputPer1K: 0.03 },
  "gpt-3.5-turbo":       { inputPer1K: 0.0005, outputPer1K: 0.0015 },
  "o1":                  { inputPer1K: 0.015,  outputPer1K: 0.06 },
  "o1-mini":             { inputPer1K: 0.003,  outputPer1K: 0.012 },
  "o3":                  { inputPer1K: 0.01,   outputPer1K: 0.04 },
  "o3-mini":             { inputPer1K: 0.0011, outputPer1K: 0.0044 },
  "gpt-5":               { inputPer1K: 0.0025, outputPer1K: 0.01 },
  "gpt-5-mini":          { inputPer1K: 0.00015, outputPer1K: 0.0006 },
  // Google Gemini
  "gemini-2.0-flash":    { inputPer1K: 0.0001, outputPer1K: 0.0004 },
  "gemini-2.5-flash":    { inputPer1K: 0.00015, outputPer1K: 0.0006 },
  "gemini-1.5-flash":    { inputPer1K: 0.000075, outputPer1K: 0.0003 },
  "gemini-1.5-pro":      { inputPer1K: 0.00125, outputPer1K: 0.005 },
  "gemini-2.0-pro":      { inputPer1K: 0.002,   outputPer1K: 0.005 },
  // DeepSeek
  "deepseek-chat":       { inputPer1K: 0.00027, outputPer1K: 0.0011 },
  "deepseek-reasoner":   { inputPer1K: 0.00055, outputPer1K: 0.00219 },
  // Meta Llama (via providers)
  "llama-3.1-8b":        { inputPer1K: 0.00005, outputPer1K: 0.00005 },
  "llama-3.1-70b":       { inputPer1K: 0.0003,  outputPer1K: 0.0003 },
  "llama-3.1-405b":      { inputPer1K: 0.001,   outputPer1K: 0.001 },
};

/**
 * Look up pricing for a model ID by matching against known patterns.
 * Falls back to Claude Sonnet pricing if unknown.
 */
function getModelPricing(modelId: string): ModelPricing {
  const normalized = modelId.toLowerCase();

  for (const [key, price] of Object.entries(MODEL_PRICING)) {
    if (normalized.includes(key)) {
      return price;
    }
  }

  // Try prefix-based matching (e.g. "anthropic/claude-sonnet-4-20250101")
  for (const [key, price] of Object.entries(MODEL_PRICING)) {
    const prefix = key.split("-").slice(0, 3).join("-");
    if (prefix.length > 5 && normalized.includes(prefix)) {
      return price;
    }
  }

  // Provider prefix matching
  if (normalized.includes("anthropic")) {
    if (normalized.includes("opus")) return MODEL_PRICING["claude-3-opus"];
    if (normalized.includes("haiku")) return MODEL_PRICING["claude-3-haiku"];
    return MODEL_PRICING["claude-sonnet-4"];
  }
  if (normalized.includes("openai") || normalized.includes("azure")) {
    if (normalized.includes("mini")) return MODEL_PRICING["gpt-4o-mini"];
    if (normalized.includes("turbo")) return MODEL_PRICING["gpt-4-turbo"];
    return MODEL_PRICING["gpt-4o"];
  }
  if (normalized.includes("google") || normalized.includes("gemini")) {
    if (normalized.includes("pro")) return MODEL_PRICING["gemini-1.5-pro"];
    return MODEL_PRICING["gemini-2.0-flash"];
  }
  if (normalized.includes("deepseek")) {
    return MODEL_PRICING["deepseek-chat"];
  }

  // Default: Claude Sonnet pricing
  return MODEL_PRICING["claude-sonnet-4"];
}

/**
 * Calculate AI Credits consumed.
 * 1 Credit = $0.01 USD.
 */
function calcCredits(modelId: string, inputTokens: number, outputTokens: number): number {
  const pricing = getModelPricing(modelId);
  const inputCost = (inputTokens / 1000) * pricing.inputPer1K;
  const outputCost = (outputTokens / 1000) * pricing.outputPer1K;
  const totalCost = inputCost + outputCost;
  // 1 credit = $0.01
  return totalCost / 0.01;
}

interface DetectionResult {
  framework: string;
  projectVersion: string | null;
}

function detectFramework(cwd: string): DetectionResult {
  let projectVersion: string | null = null;
  let framework = "";

  try {
    // ── Node.js ────────────────────────────────────────────────────
    if (existsSync(join(cwd, "package.json"))) {
      const pkg = JSON.parse(readFileSync(join(cwd, "package.json"), "utf-8"));
      projectVersion = pkg.version || null;

      const allDeps = { ...pkg.dependencies || {}, ...pkg.devDependencies || {} };
      const parts: string[] = [];

      const frameworks: [string, string][] = [
        ["next", "Next.js"],
        ["nuxt3", "Nuxt"], ["nuxt", "Nuxt"],
        ["@sveltejs/kit", "SvelteKit"], ["svelte", "Svelte"],
        ["@angular/core", "Angular"], ["angular", "Angular"],
        ["@remix-run/react", "Remix"], ["remix", "Remix"],
        ["@nestjs/core", "NestJS"], ["nestjs", "NestJS"],
        ["@solidjs/router", "SolidJS"], ["solid-js", "SolidJS"],
        ["react", "React"], ["preact", "Preact"],
        ["vue", "Vue"],
        ["astro", "Astro"],
        ["express", "Express"],
        ["fastify", "Fastify"],
        ["gatsby", "Gatsby"],
        ["electron", "Electron"],
        ["expo", "React Native"], ["react-native", "React Native"],
      ];

      for (const [pkgName, display] of frameworks) {
        const ver = allDeps[pkgName];
        if (ver) {
          const cleanVer = ver.replace(/^[~^>=<]+/, "");
          parts.push(`${display}${cleanVer && cleanVer !== "*" ? ` ${cleanVer}` : ""}`);
          break;
        }
      }

      // Node.js engine constraint (declarada en el proyecto, no del sistema)
      const nodeVer = pkg.engines?.node?.replace(/^[~^>=<]+/, "");
      if (nodeVer) {
        parts.push(`Node.js ${nodeVer}`);
      }

      framework = parts.join(" │ ");
      return { framework, projectVersion };
    }

    // ── Dart / Flutter ────────────────────────────────────────────
    if (existsSync(join(cwd, "pubspec.yaml"))) {
      const content = readFileSync(join(cwd, "pubspec.yaml"), "utf-8");
      projectVersion = content.match(/^version:\s*(.+)$/m)?.[1]?.trim() || null;

      // Extraer environment SDK y Flutter constraints
      const envSection = content.match(/environment:\s*\n([\s\S]*?)(?:^\w|\n\s*\n)/m)?.[1] || "";
      const dartVer = envSection.match(/sdk:\s*["']?([^"'\n]+)["']?\s*$/m)?.[1];
      const flutterVer = envSection.match(/flutter:\s*["']?([^"'\n]+)["']?\s*$/m)?.[1];

      const isFlutter = content.includes("flutter:");
      if (isFlutter) {
        const parts: string[] = [];
        if (flutterVer) {
          parts.push(`Flutter ${flutterVer}`);
        } else {
          parts.push("Flutter");
        }
        if (dartVer) parts.push(`Dart ${dartVer}`);
        framework = parts.join(" │ ");
      } else {
        framework = dartVer ? `Dart ${dartVer}` : "Dart";
      }
      return { framework, projectVersion };
    }

    // ── Rust ──────────────────────────────────────────────────────
    if (existsSync(join(cwd, "Cargo.toml"))) {
      const content = readFileSync(join(cwd, "Cargo.toml"), "utf-8");
      projectVersion = content.match(/^\[package\]\s*\n.*\n\s*version\s*=\s*"(.+?)"/m)?.[1] || null;
      const parts: string[] = [];

      const crates: [string, string][] = [
        ["axum", "Axum"], ["actix-web", "Actix Web"], ["rocket", "Rocket"],
        ["leptos", "Leptos"], ["yew", "Yew"], ["tauri", "Tauri"],
      ];

      for (const [crate, display] of crates) {
        if (content.includes(crate)) {
          const ver = content.match(new RegExp(`${crate}\\s*=\\s*"([^"]+)"`))?.[1];
          parts.push(`${display}${ver ? ` ${ver.replace(/^[~^>=<]+/, "")}` : ""}`);
          break;
        }
      }

      const edition = content.match(/edition\s*=\s*"(.+?)"/)?.[1];
      if (edition) parts.push(`Rust edition ${edition}`);
      framework = parts.length > 0 ? parts.join(" │ ") : "Rust";
      return { framework, projectVersion };
    }

    // ── Go ────────────────────────────────────────────────────────
    if (existsSync(join(cwd, "go.mod"))) {
      const content = readFileSync(join(cwd, "go.mod"), "utf-8");
      projectVersion = null;
      const goVer = content.match(/^go\s+(\d+\.\d+(?:\.\d+)?)$/m)?.[1];
      framework = goVer ? `Go ${goVer}` : "Go";
      return { framework, projectVersion };
    }

    // ── Python (pyproject.toml) ───────────────────────────────────
    if (existsSync(join(cwd, "pyproject.toml"))) {
      const content = readFileSync(join(cwd, "pyproject.toml"), "utf-8");
      projectVersion = content.match(/^version\s*=\s*"(.+)"$/m)?.[1] || null;
      const parts: string[] = [];

      const pyFrameworks: [string, string, RegExp][] = [
        ["django", "Django", /django[\s"']*(?:>=|==|~=)\s*"?([^"\s,\n]+)/im],
        ["flask", "Flask", /flask[\s"']*(?:>=|==|~=)\s*"?([^"\s,\n]+)/im],
        ["fastapi", "FastAPI", /fastapi[\s"']*(?:>=|==|~=)\s*"?([^"\s,\n]+)/im],
      ];

      for (const [key, display, regex] of pyFrameworks) {
        if (content.toLowerCase().includes(key)) {
          const ver = content.match(regex)?.[1];
          parts.push(`${display}${ver ? ` ${ver.replace(/^[~^>=<]+/, "")}` : ""}`);
          break;
        }
      }

      const pyVer = content.match(/requires-python\s*=\s*"(.+?)"/)?.[1];
      if (pyVer) parts.push(`Python ${pyVer}`);
      framework = parts.length > 0 ? parts.join(" │ ") : "Python";
      return { framework, projectVersion };
    }

    // ── Python (requirements.txt) ─────────────────────────────────
    if (existsSync(join(cwd, "requirements.txt"))) {
      const content = readFileSync(join(cwd, "requirements.txt"), "utf-8");
      const parts: string[] = [];
      projectVersion = null;

      const reqFrameworks: [string, string][] = [
        ["django", "Django"], ["flask", "Flask"], ["fastapi", "FastAPI"],
      ];

      for (const [key, display] of reqFrameworks) {
        const match = content.match(new RegExp(`^${key}[=~!<>]+\\s*([^\\s#]+)`, "im"));
        if (match) {
          parts.push(`${display} ${match[1]}`);
          break;
        } else if (content.toLowerCase().includes(key)) {
          parts.push(display);
          break;
        }
      }

      framework = parts.length > 0 ? parts.join(" │ ") : "Python";
      return { framework, projectVersion };
    }

    // ── PHP ───────────────────────────────────────────────────────
    if (existsSync(join(cwd, "composer.json"))) {
      const pkg = JSON.parse(readFileSync(join(cwd, "composer.json"), "utf-8"));
      projectVersion = null;
      const parts: string[] = [];
      const req = pkg.require || {};

      const phpFrameworks: [string, string][] = [
        ["laravel/framework", "Laravel"],
        ["symfony/framework-bundle", "Symfony"],
        ["cakephp/cakephp", "CakePHP"],
        ["codeigniter/framework", "CodeIgniter"],
      ];

      for (const [pkgName, display] of phpFrameworks) {
        if (req[pkgName]) {
          const ver = req[pkgName].replace(/^[~^><=]+/, "");
          parts.push(`${display} ${ver}`);
          break;
        }
      }

      const phpVer = req.php?.replace(/^[~^><=]+/, "");
      if (phpVer) parts.push(`PHP ${phpVer}`);
      framework = parts.length > 0 ? parts.join(" │ ") : "PHP";
      return { framework, projectVersion };
    }

    // ── Ruby ──────────────────────────────────────────────────────
    if (existsSync(join(cwd, "Gemfile"))) {
      const content = readFileSync(join(cwd, "Gemfile"), "utf-8");
      const parts: string[] = [];
      projectVersion = null;

      const rubyFrameworks: [string, string][] = [["rails", "Rails"], ["sinatra", "Sinatra"]];

      for (const [gem, display] of rubyFrameworks) {
        const match = content.match(new RegExp(`^\\s*gem\\s+['"]${gem}['"]\\s*,\\s*['"]([^'"]+)['"]`, "m"));
        if (match) {
          parts.push(`${display} ${match[1].replace(/^[~^><= ]+/, "")}`);
          break;
        } else if (content.match(new RegExp(`^\\s*gem\\s+['"]${gem}['"]`, "m"))) {
          parts.push(display);
          break;
        }
      }

      const rubyVer = content.match(/^ruby\s+['"](.+?)['"]/m)?.[1];
      if (rubyVer) parts.push(`Ruby ${rubyVer}`);
      framework = parts.length > 0 ? parts.join(" │ ") : "Ruby";
      return { framework, projectVersion };
    }

    // ── Java / Kotlin (Gradle) ────────────────────────────────────
    if (existsSync(join(cwd, "build.gradle")) || existsSync(join(cwd, "build.gradle.kts"))) {
      const f = existsSync(join(cwd, "build.gradle")) ? "build.gradle" : "build.gradle.kts";
      const content = readFileSync(join(cwd, f), "utf-8");
      const parts: string[] = [];
      projectVersion = null;

      if (content.includes("kotlin")) parts.push("Kotlin");

      const sbVer = content.match(/spring[\s_-]?boot\s+version\s*[=:]\s*['"](.+?)['"]/im)
        || content.match(/org\.springframework\.boot['"]?\s+version\s+['"](.+?)['"]/);

      if (sbVer?.[1]) {
        parts.push(`Spring Boot ${sbVer[1]}`);
      } else if (content.includes("spring")) {
        parts.push("Spring Boot");
      }

      if (content.includes("android")) {
        framework = parts.length > 0 ? `Android (${parts.join(" │ ")})` : "Android";
        return { framework, projectVersion };
      }
      parts.push("Gradle");
      framework = parts.join(" │ ");
      return { framework, projectVersion };
    }

    // ── Java (Maven) ──────────────────────────────────────────────
    if (existsSync(join(cwd, "pom.xml"))) {
      const content = readFileSync(join(cwd, "pom.xml"), "utf-8");
      const parts: string[] = [];
      projectVersion = content.match(/<version>\s*(.+?)\s*<\//)?.[1] || null;

      const sbVer = content.match(/<spring-boot[.\w-]*\.version>\s*(.+?)\s*<\//)?.[1]
        || content.match(/<parent>[\s\S]*?<groupId>org\.springframework\.boot[\s\S]*?<version>\s*(.+?)\s*<\//)?.[1];

      if (sbVer) {
        parts.push(`Spring Boot ${sbVer}`);
      } else if (content.includes("spring-boot")) {
        parts.push("Spring Boot");
      } else if (content.includes("quarkus")) {
        const qVer = content.match(/<quarkus\.version>\s*(.+?)\s*<\//)?.[1];
        parts.push(qVer ? `Quarkus ${qVer}` : "Quarkus");
      } else if (content.includes("micronaut")) {
        parts.push("Micronaut");
      }

      const javaVer = content.match(/<java\.version>\s*(.+?)\s*<\//)?.[1]
        || content.match(/<maven\.compiler\.(source|target)>\s*(.+?)\s*<\//)?.[2];
      if (javaVer) parts.push(`Java ${javaVer}`);
      framework = parts.length > 0 ? parts.join(" │ ") : "Java";
      return { framework, projectVersion };
    }

    // ── Swift ─────────────────────────────────────────────────────
    if (existsSync(join(cwd, "Package.swift"))) {
      const content = readFileSync(join(cwd, "Package.swift"), "utf-8");
      const parts: string[] = [];
      projectVersion = null;

      if (content.includes("vapor")) {
        const ver = content.match(/\.upToNextMajor\s*\(from:\s*"([^"]+)"/)?.[1];
        parts.push(ver ? `Vapor ${ver}` : "Vapor");
      } else if (content.includes("swift-nio")) {
        parts.push("NIO");
      }

      const swiftVer = content.match(/\/\/\s*swift-tools-version:\s*(\d+\.\d+)/)?.[1];
      if (swiftVer) parts.push(`Swift ${swiftVer}`);
      framework = parts.length > 0 ? parts.join(" │ ") : "Swift";
      return { framework, projectVersion };
    }

    // ── .NET (C#) ─────────────────────────────────────────────────
    const csprojFiles = readdirSync(cwd).filter(f => f.endsWith(".csproj"));
    if (csprojFiles.length > 0) {
      const content = readFileSync(join(cwd, csprojFiles[0]), "utf-8");
      const parts: string[] = [];
      projectVersion = null;

      if (content.includes("Microsoft.AspNetCore")) {
        const ver = content.match(/Microsoft\.AspNetCore\.App\s+Version="([^"]+)"/)?.[1]
          || content.match(/Microsoft\.AspNetCore(?:\.[\w.]+)?\s+Version="([^"]+)"/)?.[1];
        parts.push(ver ? `ASP.NET Core ${ver}` : "ASP.NET Core");
      } else if (content.includes("Microsoft.Maui")) {
        parts.push(".NET MAUI");
      } else if (content.includes("Blazor")) {
        parts.push("Blazor");
      }

      const tf = content.match(/<TargetFramework>\s*(.+?)\s*<\//)?.[1];
      if (tf) parts.push(`.NET ${tf}`);
      framework = parts.length > 0 ? parts.join(" │ ") : ".NET";
      return { framework, projectVersion };
    }

    // ── Elixir ────────────────────────────────────────────────────
    if (existsSync(join(cwd, "mix.exs"))) {
      const content = readFileSync(join(cwd, "mix.exs"), "utf-8");
      const parts: string[] = [];
      projectVersion = content.match(/version:\s*"(.+?)"/)?.[1] || null;

      if (content.includes("phoenix")) {
        const ver = content.match(/:phoenix\s*,\s*['"]~>\s*([^'"]+)['"]/)?.[1];
        parts.push(ver ? `Phoenix ${ver}` : "Phoenix");
      }

      framework = parts.length > 0 ? parts.join(" │ ") : "Elixir";
      return { framework, projectVersion };
    }

    // ── Haskell ───────────────────────────────────────────────────
    if (existsSync(join(cwd, "stack.yaml"))) {
      const content = readFileSync(join(cwd, "stack.yaml"), "utf-8");
      projectVersion = null;
      const resolver = content.match(/resolver:\s*(.+?)\s*$/m)?.[1];
      framework = resolver ? `Haskell (${resolver})` : "Haskell";
      return { framework, projectVersion };
    }
    if (existsSync(join(cwd, "cabal.project"))) {
      framework = "Haskell";
      return { framework, projectVersion: null };
    }

    // ── Docker ────────────────────────────────────────────────────
    if (existsSync(join(cwd, "Dockerfile"))) {
      const content = readFileSync(join(cwd, "Dockerfile"), "utf-8");
      projectVersion = null;
      const from = content.match(/^FROM\s+(.+?)(?:\s+AS\s+\w+)?\s*$/im)?.[1];
      framework = from ? `Docker (${from})` : "Docker";
      return { framework, projectVersion };
    }

    return { framework: "", projectVersion: null };
  } catch {
    return { framework: "", projectVersion: null };
  }
}

function fmt(n: number): string {
  return n >= 1000 ? `${(n / 1000).toFixed(1)}k` : `${n}`;
}

/** Longitud visible de un string ANSI (sin los códigos de escape). */
function visibleWidth(str: string): number {
  return str.replace(/\x1B\[[0-9;]*[a-zA-Z]/g, "").length;
}

/** Rellena con espacios a la izquierda para alinear a la derecha. */
function padLeft(str: string, width: number): string {
  const len = visibleWidth(str);
  if (len >= width) return str;
  return " ".repeat(width - len) + str;
}


