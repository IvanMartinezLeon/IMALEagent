# IMALEagent Uninstaller for Windows (PowerShell)

$Blue = [System.ConsoleColor]::Blue
$Green = [System.ConsoleColor]::Green
$Red = [System.ConsoleColor]::Red
$Yellow = [System.ConsoleColor]::Yellow

Write-Host ""
Write-Host "=== IMALEagent Uninstaller (Windows PowerShell) ===" -ForegroundColor $Blue
Write-Host ""

$agentConfigDir = Join-Path $HOME ".pi\agent"

Write-Host "This will uninstall IMALEagent and remove its configuration from $agentConfigDir." -ForegroundColor $Yellow
Write-Host ""

$confirmation = Read-Host "Are you sure? (y/n)"
if ($confirmation -ne "y" -and $confirmation -ne "Y") {
    Write-Host "Uninstallation cancelled." -ForegroundColor $Yellow
    exit 0
}

Write-Host ""
Write-Host "Removing IMALE packages..." -ForegroundColor $Yellow
Write-Host ""

$piExecutable = $null
$piCommand = Get-Command pi -ErrorAction SilentlyContinue
if ($piCommand) {
    $piExecutable = $piCommand.Source
} else {
    $npmGlobalPrefix = (npm prefix -g 2>$null).Trim()
    $piCommandPath = Join-Path $npmGlobalPrefix "pi.cmd"
    if (Test-Path $piCommandPath) {
        $piExecutable = $piCommandPath
    }
}

if ($piExecutable) {
    Write-Host "  Desinstalando Ask User..." -ForegroundColor $Yellow
    & $piExecutable remove npm:pi-ask-user >$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Ask User desinstalado" -ForegroundColor $Green
    } else {
        Write-Host "  ⚠ Ask User no estaba instalado" -ForegroundColor $Yellow
    }

    Write-Host "  Desinstalando Web Access..." -ForegroundColor $Yellow
    & $piExecutable remove npm:pi-web-access >$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Web Access desinstalado" -ForegroundColor $Green
    } else {
        Write-Host "  ⚠ Web Access no estaba instalado" -ForegroundColor $Yellow
    }

    Write-Host "  Desinstalando Code Intelligence..." -ForegroundColor $Yellow
    & $piExecutable remove npm:@catdaemon/pi-code-intelligence >$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Code Intelligence desinstalado" -ForegroundColor $Green
    } else {
        Write-Host "  ⚠ Code Intelligence no estaba instalado" -ForegroundColor $Yellow
    }

    Write-Host "  Desinstalando MCP Adapter..." -ForegroundColor $Yellow
    & $piExecutable remove npm:pi-mcp-adapter >$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ MCP Adapter desinstalado" -ForegroundColor $Green
    } else {
        Write-Host "  ⚠ MCP Adapter no estaba instalado" -ForegroundColor $Yellow
    }

    Write-Host "  Desinstalando Coding Agent..." -ForegroundColor $Yellow
    & $piExecutable remove npm:pi-subagents >$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Coding Agent desinstalado" -ForegroundColor $Green
    } else {
        Write-Host "  ⚠ Coding Agent no estaba instalado" -ForegroundColor $Yellow
    }
}

Write-Host "Uninstalling IMALEagent..." -ForegroundColor $Yellow
Write-Host ""

# Uninstall the underlying agent using npm
npm uninstall -g @earendil-works/pi-coding-agent
if ($LASTEXITCODE -ne 0) {
    Write-Host "IMALEagent uninstallation failed." -ForegroundColor $Red
    Read-Host "Press Enter to close"
    exit $LASTEXITCODE
}

Write-Host "Removing IMALE configuration from $agentConfigDir..." -ForegroundColor $Yellow

# Un único helper Node para los tres desinstaladores: evita listas duplicadas
# y no borra nunca directorios completos (conserva el material propio del usuario).
$uninstallHelper = Join-Path $PSScriptRoot "lib\uninstall-config.mjs"
if (Test-Path $uninstallHelper) {
    & node $uninstallHelper $agentConfigDir
} else {
    Write-Error-Custom "No se encontró $uninstallHelper"
    Write-Warning-Custom "Elimina a mano la configuración de $agentConfigDir"
}

Write-Host ""
Write-Host "[OK] IMALEagent uninstalled" -ForegroundColor $Green
Write-Host "[OK] Configuration removed from $agentConfigDir" -ForegroundColor $Green
Write-Host ""
Write-Host "Other package managers: pnpm remove -g ... / yarn global remove ... / bun uninstall -g ..." -ForegroundColor $Yellow
Write-Host ""

Read-Host "Press Enter to close"
