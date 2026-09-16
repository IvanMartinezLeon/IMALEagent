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
    Write-Host "  Desinstalando rpiv-ask-user-question..." -ForegroundColor $Yellow
    & $piExecutable remove npm:@juicesharp/rpiv-ask-user-question >$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ rpiv-ask-user-question desinstalado" -ForegroundColor $Green
    } else {
        Write-Host "  ⚠ rpiv-ask-user-question no estaba instalado" -ForegroundColor $Yellow
    }

    Write-Host "  Desinstalando rpiv-todo..." -ForegroundColor $Yellow
    & $piExecutable remove npm:@juicesharp/rpiv-todo >$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ rpiv-todo desinstalado" -ForegroundColor $Green
    } else {
        Write-Host "  ⚠ rpiv-todo no estaba instalado" -ForegroundColor $Yellow
    }

    Write-Host "  Desinstalando pi-lens..." -ForegroundColor $Yellow
    & $piExecutable remove npm:pi-lens >$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ pi-lens desinstalado" -ForegroundColor $Green
    } else {
        Write-Host "  ⚠ pi-lens no estaba instalado" -ForegroundColor $Yellow
    }

    Write-Host "  Desinstalando Context Mode..." -ForegroundColor $Yellow
    & $piExecutable remove npm:context-mode >$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Context Mode desinstalado" -ForegroundColor $Green
    } else {
        Write-Host "  ⚠ Context Mode no estaba instalado" -ForegroundColor $Yellow
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

# El binario global de context-mode lo instala IMALEagent para el servidor MCP.
npm uninstall -g context-mode >$null 2>$null

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
