$Green = [System.ConsoleColor]::Green
$Red = [System.ConsoleColor]::Red
$Yellow = [System.ConsoleColor]::Yellow
$Blue = [System.ConsoleColor]::Blue

$checksPass = 0
$checksFail = 0

Write-Host ""
Write-Host "=== IMALEagent Verification ===" -ForegroundColor $Blue
Write-Host ""

function Check-Command {
    param([string]$Command, [string]$PrettyName = $Command)

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        try {
            $version = & $Command --version 2>$null
            Write-Host "✓ $PrettyName : $version" -ForegroundColor $Green
        } catch {
            Write-Host "✓ $PrettyName : Instalado" -ForegroundColor $Green
        }
        $global:checksPass++
    } else {
        Write-Host "✗ $PrettyName : No instalado" -ForegroundColor $Red
        $global:checksFail++
    }
}

Write-Host "== Verificaciones del Sistema ==" -ForegroundColor $Blue
Write-Host ""
Check-Command "node" "Node.js"
Check-Command "npm" "npm"
Check-Command "pi" "IMALEagent"
Check-Command "imaleagent" "IMALEagent CLI"

Write-Host ""
Write-Host "== Variables de Entorno (Opcional) ==" -ForegroundColor $Blue
Write-Host ""
if ($env:ANTHROPIC_API_KEY) {
    Write-Host "✓ ANTHROPIC_API_KEY : Configurada" -ForegroundColor $Green
    $global:checksPass++
} else {
    Write-Host "⚠ ANTHROPIC_API_KEY : No configurada (puedes usar /login en IMALEagent)" -ForegroundColor $Yellow
}

Write-Host ""
Write-Host "== Información de IMALEagent ==" -ForegroundColor $Blue
Write-Host ""

if (Get-Command pi -ErrorAction SilentlyContinue) {
    $agentConfigDir = Join-Path $HOME ".pi\agent"
    if (Test-Path (Join-Path $agentConfigDir "settings.json")) {
        Write-Host "✓ Configuración IMALE : $agentConfigDir" -ForegroundColor $Green
        $global:checksPass++
    } else {
        Write-Host "⚠ Configuración IMALE : No encontrada en $agentConfigDir" -ForegroundColor $Yellow
    }

    $piPackages = pi list 2>$null
    if ($piPackages -match "pi-subagents") {
        Write-Host "✓ Coding Agent : Instalado y activo" -ForegroundColor $Green
        $global:checksPass++
    } else {
        Write-Host "✗ Coding Agent : No detectado en 'pi list'" -ForegroundColor $Red
        $global:checksFail++
    }

    if ($piPackages -match "pi-mcp-adapter") {
        Write-Host "✓ MCP Adapter : Instalado y activo" -ForegroundColor $Green
        $global:checksPass++
    } else {
        Write-Host "✗ MCP Adapter : No detectado en 'pi list'" -ForegroundColor $Red
        $global:checksFail++
    }

    if ($piPackages -match "context-mode") {
        Write-Host "✓ Context Mode : Instalado y activo" -ForegroundColor $Green
        $global:checksPass++
    } else {
        Write-Host "✗ Context Mode : No detectado en 'pi list'" -ForegroundColor $Red
        $global:checksFail++
    }

    if (Get-Command context-mode -ErrorAction SilentlyContinue) {
        Write-Host "✓ Binario context-mode : Disponible en PATH" -ForegroundColor $Green
        $global:checksPass++
    } else {
        Write-Host "✗ Binario context-mode : No encontrado en PATH (el servidor MCP no arrancara)" -ForegroundColor $Red
        $global:checksFail++
    }

    $agentMcpConfig = Join-Path $agentConfigDir "mcp.json"
    if ((Test-Path $agentMcpConfig) -and ((Get-Content $agentMcpConfig -Raw) -match '"context-mode"')) {
        Write-Host "✓ context-mode MCP : Configurado en $agentMcpConfig" -ForegroundColor $Green
        $global:checksPass++
    } else {
        Write-Host "⚠ context-mode MCP : No detectado en $agentMcpConfig" -ForegroundColor $Yellow
    }

    $imaleExtensions = @(
        (Join-Path $agentConfigDir "extensions\ai-router.ts"),
        (Join-Path $agentConfigDir "extensions\imale-header.ts"),
        (Join-Path $agentConfigDir "extensions\imale-preset.ts"),
        (Join-Path $agentConfigDir "extensions\lib\shared-ui.ts")
    )
    $missingExtensions = ($imaleExtensions | Where-Object { -not (Test-Path $_) }).Count
    if ($missingExtensions -eq 0) {
        Write-Host "✓ Extensiones IMALE : Instaladas en $agentConfigDir\extensions" -ForegroundColor $Green
        $global:checksPass++
    } else {
        Write-Host "✗ Extensiones IMALE : Faltan $missingExtensions archivo(s)" -ForegroundColor $Red
        $global:checksFail++
    }

    $genericAgents = @(
        (Join-Path $agentConfigDir "agents\generic-context-builder.md"),
        (Join-Path $agentConfigDir "agents\generic-planner.md"),
        (Join-Path $agentConfigDir "agents\generic-worker.md"),
        (Join-Path $agentConfigDir "agents\generic-reviewer.md"),
        (Join-Path $agentConfigDir "agents\generic-parallel-review.md")
    )
    $missingGenericAgents = ($genericAgents | Where-Object { -not (Test-Path $_) }).Count
    if ($missingGenericAgents -eq 0) {
        Write-Host "✓ Subagentes genéricos : Instalados en $agentConfigDir\agents" -ForegroundColor $Green
        $global:checksPass++
    } else {
        Write-Host "✗ Subagentes genéricos : Faltan $missingGenericAgents archivo(s) en $agentConfigDir\agents" -ForegroundColor $Red
        $global:checksFail++
    }

    $guidesAndTemplates = @(
        (Join-Path $agentConfigDir "GENERIC_RULES.md"),
        (Join-Path $agentConfigDir "MOBILE_GUIDELINES.md"),
        (Join-Path $agentConfigDir "templates\SPEC_TEMPLATE.md"),
        (Join-Path $agentConfigDir "templates\PLAN_TEMPLATE.md"),
        (Join-Path $agentConfigDir "skills\flutter-guidelines\SKILL.md"),
        (Join-Path $agentConfigDir "skills\dart-guidelines\SKILL.md"),
        (Join-Path $agentConfigDir "prompts\spec-mobile.md")
    )
    $missingGuides = ($guidesAndTemplates | Where-Object { -not (Test-Path $_) }).Count
    if ($missingGuides -eq 0) {
        Write-Host "✓ Guías y plantillas : Instaladas en $agentConfigDir" -ForegroundColor $Green
        $global:checksPass++
    } else {
        Write-Host "✗ Guías y plantillas : Faltan $missingGuides archivo(s) en $agentConfigDir" -ForegroundColor $Red
        $global:checksFail++
    }

    $genericPrompts = @(
        (Join-Path $agentConfigDir "prompts\generic-discovery.md"),
        (Join-Path $agentConfigDir "prompts\generic-fix-bug.md"),
        (Join-Path $agentConfigDir "prompts\generic-implement-safe.md"),
        (Join-Path $agentConfigDir "prompts\generic-research-and-plan.md"),
        (Join-Path $agentConfigDir "prompts\step-scout.md"),
        (Join-Path $agentConfigDir "prompts\step-planner.md"),
        (Join-Path $agentConfigDir "prompts\step-worker.md"),
        (Join-Path $agentConfigDir "prompts\step-reviewer.md")
    )
    $missingGenericPrompts = ($genericPrompts | Where-Object { -not (Test-Path $_) }).Count
    if ($missingGenericPrompts -eq 0) {
        Write-Host "✓ Prompt workflows genéricos : Instalados en $agentConfigDir\prompts" -ForegroundColor $Green
        $global:checksPass++
    } else {
        Write-Host "✗ Prompt workflows genéricos : Faltan $missingGenericPrompts archivo(s) en $agentConfigDir\prompts" -ForegroundColor $Red
        $global:checksFail++
    }
} else {
    Write-Host "IMALEagent no está instalado" -ForegroundColor $Red
    Write-Host "Ejecuta: .\install.ps1"
}

Write-Host ""
Write-Host "== Summary ==" -ForegroundColor $Blue
Write-Host ""
if ($checksFail -eq 0) {
    Write-Host "✓ All checks passed" -ForegroundColor $Green
} else {
    Write-Host "✗ $checksFail check(s) failed — run install.ps1 first" -ForegroundColor $Red
}
Write-Host ""

# Exit code real: sin esto el verificador siempre devolvía 0 y no podía
# poner en rojo un pipeline ni la comprobación manual del usuario.
if ($checksFail -gt 0) { exit 1 }
exit 0
