import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

type CapabilityState = {
  cwd: string;
  repoType: "javascript-typescript" | "generic";
  subagentsInstalled: boolean;
  subagentsSource?: string;
  contextModeConfigured: boolean;
  contextModeConfigPath?: string;
};

type PromptMode = "general" | "structural" | "debug-heavy" | "review" | "implement";

type RouterState = {
  lastPromptMode: PromptMode;
  lastPrompt?: string;
};

const ROUTER_STATUS_PARAMS = Type.Object({});

export default function aiRouterExtension(pi: ExtensionAPI) {
  let capabilities: CapabilityState = createCapabilityState(process.cwd());
  const routerState: RouterState = {
    lastPromptMode: "general",
  };

  async function refreshCapabilities(cwd: string): Promise<CapabilityState> {
    const contextModeConfig = detectContextModeConfig(cwd);
    const subagents = detectInstalledPiPackage(cwd, "pi-subagents");

    capabilities = {
      cwd,
      repoType: detectRepoType(cwd),
      subagentsInstalled: subagents.installed,
      subagentsSource: subagents.source,
      contextModeConfigured: Boolean(contextModeConfig),
      contextModeConfigPath: contextModeConfig ?? undefined,
    };

    return capabilities;
  }

  function setStatus(ctx: ExtensionContext) {
    if (!ctx.hasUI) return;

    const parts: string[] = [];
    parts.push(capabilities.repoType === "javascript-typescript" ? "js/ts repo" : "generic repo");
    parts.push(capabilities.subagentsInstalled ? "subagents ready" : "subagents missing");
    parts.push(capabilities.contextModeConfigured ? "context-mode ready" : "context-mode missing");
    parts.push(`mode:${routerState.lastPromptMode}`);
    ctx.ui.setStatus("ai-router", parts.join(" · "));
  }

  function formatRouterStatus(): string {
    const lines = [
      `Repository type: ${capabilities.repoType}`,
      `Prompt mode: ${routerState.lastPromptMode}`,
      `Subagents package: ${capabilities.subagentsInstalled ? "installed" : "missing"}`,
      `Subagents source: ${capabilities.subagentsSource ?? "not detected"}`,
      `context-mode MCP: ${capabilities.contextModeConfigured ? `configured (${capabilities.contextModeConfigPath})` : "not configured"}`,
      `Routing policy: ${describeRoutingPolicy()}`,
    ];

    return lines.join("\n");
  }

  function describeRoutingPolicy(): string {
    if (routerState.lastPromptMode === "structural") {
      return "Use focused built-in tools; narrow the search before broad repo exploration";
    }

    if (routerState.lastPromptMode === "debug-heavy") {
      return capabilities.contextModeConfigured
        ? "Prefer context-mode for large outputs/logs, then inspect targeted files"
        : "Use focused commands; context-mode is not configured";
    }

    if (routerState.lastPromptMode === "review") {
      return "Read targeted files, then expand only where the change is risky";
    }

    if (routerState.lastPromptMode === "implement") {
      return "Prefer one scripted workflow (subagent workflowScript), or /prompt-workflow generic-implement-safe";
    }

    return "Use built-in tools normally; prefer context-mode when output may be large";
  }

  pi.on("session_start", async (_event, ctx) => {
    routerState.lastPromptMode = "general";
    pi.events.emit("imale:agent-mode", { mode: routerState.lastPromptMode });
    routerState.lastPrompt = undefined;
    await refreshCapabilities(ctx.cwd);
    setStatus(ctx);
    if (ctx.hasUI) {
      ctx.ui.setStatus("ai-router-output", undefined);
    }
  });

  pi.on("before_agent_start", async (event, ctx) => {
    await refreshCapabilities(ctx.cwd);

    const promptText = typeof event.prompt === "string" ? event.prompt : "";
    routerState.lastPrompt = promptText;
    routerState.lastPromptMode = classifyPrompt(promptText);
    pi.events.emit("imale:agent-mode", { mode: routerState.lastPromptMode });
    setStatus(ctx);

    const parts: string[] = [];
    parts.push("## Hybrid Routing");
    parts.push(`- Repository type: ${capabilities.repoType}.`);
    parts.push(`- Detected prompt mode: ${routerState.lastPromptMode}.`);
    parts.push(`- pi-subagents package installed: ${capabilities.subagentsInstalled ? "yes" : "no"}.`);
    parts.push(`- context-mode MCP configured: ${capabilities.contextModeConfigured ? "yes" : "no"}.`);
    parts.push("");
    parts.push("Routing rules:");

    if (routerState.lastPromptMode === "debug-heavy" && capabilities.contextModeConfigured) {
      parts.push(
        "- This prompt may produce large output. Prefer the `mcp` tool to discover `ctx_` tools from `context-mode` before dumping long logs or test output into the conversation.",
      );
    }

    if (capabilities.contextModeConfigured) {
      parts.push(
        "- When a task may produce large logs, snapshots, wide searches, or heavy intermediate output, prefer the `mcp` tool to search for `ctx_` tools from the `context-mode` server.",
      );
    }

    if (capabilities.subagentsInstalled) {
      const subagentInstructions = getSubagentInstructions(promptText, routerState.lastPromptMode);
      if (subagentInstructions.length > 0) {
        parts.push("");
        parts.push(...subagentInstructions);
      }
    }

    parts.push("- Once you know the relevant files, switch to the built-in `read`, `edit`, `write`, and focused `bash` commands.");
    parts.push("- Keep responses concise and prefer targeted reads over broad repo exploration.");

    return {
      systemPrompt: `${event.systemPrompt}\n\n${parts.join("\n")}`,
    };
  });

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return undefined;

    await refreshCapabilities(ctx.cwd);
    const command = typeof event.input.command === "string" ? event.input.command : "";
    if (!command) return undefined;

    if (ctx.hasUI) {
      if (shouldWarnAboutLargeOutput(command, capabilities)) {
        ctx.ui.setStatus("ai-router-output", "Prefer context-mode for large output/log-heavy commands");
      } else {
        ctx.ui.setStatus("ai-router-output", undefined);
      }
    }

    return undefined;
  });

  pi.registerCommand("router-status", {
    description: "Show hybrid routing status for subagents and context-mode",
    handler: async (_args, ctx) => {
      await refreshCapabilities(ctx.cwd);
      setStatus(ctx);
      if (ctx.hasUI) {
        ctx.ui.notify(formatRouterStatus(), "info");
      }
    },
  });

  pi.registerCommand("router-refresh", {
    description: "Refresh hybrid routing capability detection",
    handler: async (_args, ctx) => {
      await refreshCapabilities(ctx.cwd);
      setStatus(ctx);
      if (ctx.hasUI) {
        ctx.ui.notify("Hybrid routing capabilities refreshed", "info");
      }
    },
  });

  pi.registerTool({
    name: "router_status",
    label: "Router Status",
    description: "Inspect subagents and context-mode readiness for the current repository.",
    promptSnippet: "Check whether subagents and context-mode are ready before a repository exploration task.",
    promptGuidelines: [
      "Use router_status at the start of a structural or review task when you need to know whether subagents and context-mode are available.",
    ],
    parameters: ROUTER_STATUS_PARAMS,
    async execute() {
      await refreshCapabilities(capabilities.cwd);
      return {
        content: [{ type: "text", text: formatRouterStatus() }],
        details: {
          ...capabilities,
          ...routerState,
          routingPolicy: describeRoutingPolicy(),
        },
      };
    },
  });
}

function createCapabilityState(cwd: string): CapabilityState {
  return {
    cwd,
    repoType: "generic",
    subagentsInstalled: false,
    subagentsSource: undefined,
    contextModeConfigured: false,
    contextModeConfigPath: undefined,
  };
}

function detectRepoType(cwd: string): CapabilityState["repoType"] {
  const markers = [
    "package.json",
    "tsconfig.json",
    "jsconfig.json",
    "pnpm-workspace.yaml",
    "bun.lockb",
    "bun.lock",
  ];

  return markers.some((marker) => existsSync(join(cwd, marker))) ? "javascript-typescript" : "generic";
}

function detectInstalledPiPackage(cwd: string, packageName: string): { installed: boolean; source: string | null } {
  const candidates = [
    join(cwd, ".pi", "settings.json"),
    join(homedir(), ".pi", "agent", "settings.json"),
  ];

  for (const candidate of candidates) {
    try {
      if (!existsSync(candidate)) continue;
      const content = readFileSync(candidate, "utf8");
      const parsed = JSON.parse(content) as {
        packages?: Array<string | { source?: string }>;
      };
      const packages = parsed.packages ?? [];
      for (const entry of packages) {
        const source = typeof entry === "string" ? entry : entry?.source;
        if (!source) continue;
        if (source.includes(packageName)) {
          return { installed: true, source };
        }
      }
    } catch {
      // ignore invalid settings
    }
  }

  return { installed: false, source: null };
}

function detectContextModeConfig(cwd: string): string | null {
  const candidates = [
    join(cwd, ".pi", "mcp.json"),
    join(cwd, ".mcp.json"),
    join(homedir(), ".pi", "agent", "mcp.json"),
    join(homedir(), ".config", "mcp", "mcp.json"),
  ];

  for (const candidate of candidates) {
    try {
      if (!existsSync(candidate)) continue;
      const content = readFileSync(candidate, "utf8");
      const parsed = JSON.parse(content) as {
        mcpServers?: Record<string, unknown>;
      };
      if (parsed.mcpServers && "context-mode" in parsed.mcpServers) {
        return candidate;
      }
    } catch {
      // ignore unreadable or invalid files
    }
  }

  return null;
}

function classifyPrompt(prompt: string): PromptMode {
  const normalized = prompt.toLowerCase();

  if (/(where|dónde|which files|qué archivos|who calls|quién usa|flow|flujo|navigate|naviga|symbol|símbolo|architecture|arquitectura|entry point|entrypoint|impact|related files|callers|tests? affected)/.test(normalized)) {
    return "structural";
  }

  if (/(log|trace|stacktrace|test output|snapshot|stderr|stdout|failing tests|integration test|e2e|crash|crashlytics)/.test(normalized)) {
    return "debug-heavy";
  }

  if (/(review|revisa|audit|audita|security|seguridad|quality|calidad|pull request|pr\b)/.test(normalized)) {
    return "review";
  }

  if (/(implement|implementar|refactor|refactorizar|fix|arregla|bug|feature|change|cambio|modify|modificar|update|actualizar|build|crear)/.test(normalized)) {
    return "implement";
  }

  return "general";
}

function getSubagentInstructions(prompt: string, mode: PromptMode): string[] {
  const normalized = prompt.toLowerCase();
  const recipes: string[] = [];

  if (mode === "structural") {
    recipes.push(
      ...scriptedRecipe("Structural discovery", "/prompt-workflow generic-discovery", [
        "const scout = await runs.run('scout', { agent: 'scout', task: '<original request>' });",
        "return runs.run('context', { agent: 'generic-context-builder', task: '<original request>' + ' Scout findings: ' + scout.output });",
      ]),
    );
  }

  if (mode === "review") {
    recipes.push(
      ...scriptedRecipe("Code review", "/parallel-review", [
        "return runs.run('review', { agent: 'generic-parallel-review', task: '<original request>' });",
      ]),
    );
  }

  if (BUGFIX_RE.test(normalized)) {
    recipes.push(
      ...scriptedRecipe("Bug fix", "/prompt-workflow generic-fix-bug", [
        "const scout = await runs.run('scout', { agent: 'scout', task: '<original request>' });",
        "const fix = await runs.run('fix', { agent: 'generic-fixer', task: '<original request>' + ' Diagnosis: ' + scout.output });",
        "return runs.run('review', { agent: 'generic-reviewer', task: '<original request>' + ' Diagnosis: ' + scout.output + ' Fix: ' + fix.output });",
      ]),
    );
  } else if (IMPLEMENT_RE.test(normalized)) {
    recipes.push(
      ...scriptedRecipe("Implementation / changes", "/prompt-workflow generic-implement-safe", [
        "const scout = await runs.run('scout', { agent: 'scout', task: '<original request>' });",
        "const plan = await runs.run('plan', { agent: 'generic-planner', task: '<original request>' + ' Scout findings: ' + scout.output });",
        "const work = await runs.run('work', { agent: 'generic-worker', task: '<original request>' + ' Plan: ' + plan.output });",
        "return runs.run('review', { agent: 'generic-reviewer', task: '<original request>' + ' Plan: ' + plan.output + ' Result: ' + work.output });",
      ]),
    );
  }

  if (RESEARCH_RE.test(normalized)) {
    recipes.push(
      ...scriptedRecipe("Research / investigation", "/prompt-workflow generic-research-and-plan", [
        "const external = await runs.run('research', { agent: 'researcher', task: '<original request>' });",
        "const local = await runs.run('scout', { agent: 'scout', task: '<original request>' });",
        "return runs.run('plan', { agent: 'generic-planner', task: '<original request>' + ' External evidence: ' + external.output + ' Local context: ' + local.output });",
      ]),
    );
  }

  if (recipes.length === 0) {
    return [];
  }

  const instructions: string[] = [];
  instructions.push("### Subagent Dispatch");
  instructions.push("You have the `subagent` tool available. Delegate only when the operator's request authorizes it.");
  instructions.push("If you do delegate, use exactly one scripted workflow shaped like one of these patterns:");
  instructions.push("");
  instructions.push(...recipes);
  instructions.push("**Fallback**: if no pattern fits, handle the request directly with built-in tools.");
  instructions.push("");
  instructions.push("Dispatch rules:");
  instructions.push("- Pass the operator's original request as the child `task`; never paraphrase it into a weaker request.");
  instructions.push("- Keep one writer per working tree. Reviewer and scout steps are read-only.");
  instructions.push("- After the workflow returns, present the result to the user. Do NOT re-implement what the child already did.");
  instructions.push("- If a child reports a blocker or asks a question, relay it to the user instead of silently switching execution mode.");

  return instructions;
}

const IMPLEMENT_RE = /(implement|implementation|implementar|refactor|refactorizar|fix|arregla|bug|feature|change|cambio|modify|modificar|update|actualizar|build|crear)/;
const BUGFIX_RE = /(bug|arregla|arreglar|fix|fallo|regres|crash|error|broken|roto)/;
const RESEARCH_RE = /(research|investiga|documentation|documentación|docs|compare|comparar|library|librer|framework|best practice|patrón|approach|enfoque)/;

/**
 * Render a delegation pattern as a copy-ready `workflowScript` call.
 *
 * `runs.run(key, { agent, task })` is the only supported orchestration surface in
 * pi-subagents; durable `.chain.md` files and `chainName` are rejected at runtime.
 */
function scriptedRecipe(heading: string, humanHint: string, scriptLines: string[]): string[] {
  return [
    `**${heading}** → one scripted workflow (human equivalent: \`${humanHint}\`):`,
    "",
    "```js",
    "subagent({ async: true, workflowScript: [",
    ...scriptLines.map((line) => `  ${JSON.stringify(line)},`),
    '].join("\\n") });',
    "```",
    "",
  ];
}

function shouldWarnAboutLargeOutput(command: string, capabilities: CapabilityState): boolean {
  if (!capabilities.contextModeConfigured) {
    return false;
  }

  const normalized = command.toLowerCase();
  return /(npm test|pnpm test|yarn test|bun test|pytest|go test|cargo test|mvn test|gradle test|xcodebuild|flutter test|jest|vitest|playwright|cypress|tail -f|cat .*log|rg .* -n|grep .* -r)/.test(normalized);
}
