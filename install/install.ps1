# Instalador de IMALEagent para Windows PowerShell

$Green = [System.ConsoleColor]::Green
$Red = [System.ConsoleColor]::Red
$Yellow = [System.ConsoleColor]::Yellow
$Blue = [System.ConsoleColor]::Blue

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor $Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor $Blue
}

function Backup-ExistingConfig {
    param([string]$SourceDir, [string]$TargetDir, [string]$BackupDir)
    $copied = 0
    foreach ($item in Get-ChildItem -Path $SourceDir -Force) {
        $target = Join-Path $TargetDir $item.Name
        if (-not (Test-Path $target)) { continue }
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        Copy-Item -Path $target -Destination $BackupDir -Recurse -Force
        $copied++
    }
    if ($copied -gt 0) {
        Write-Success "Copia de seguridad de la config previa: $BackupDir ($copied elemento(s))"
    } else {
        Remove-Item -Path $BackupDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Fusiona un JSON del repo con el previo del usuario en lugar de sobrescribirlo.
# Imprescindible para no perder `packages`, provider/model ni MCPs propios.
function Merge-JsonConfig {
    param([string]$RelativePath, [string]$SourceDir, [string]$TargetDir, [string]$BackupDir, [string]$MergeHelper)
    $incoming = Join-Path $SourceDir $RelativePath
    $previous = Join-Path $BackupDir $RelativePath
    $target = Join-Path $TargetDir $RelativePath
    if (-not (Test-Path $incoming) -or -not (Test-Path $previous)) { return }

    $merged = [System.IO.Path]::GetTempFileName()
    & node $MergeHelper $incoming $previous $merged
    if ($LASTEXITCODE -eq 0 -and (Get-Item $merged).Length -gt 0) {
        Move-Item -Path $merged -Destination $target -Force
        Write-Success "$RelativePath fusionado con la configuración previa"
    } else {
        Remove-Item -Path $merged -Force -ErrorAction SilentlyContinue
        Write-Warning-Custom "$RelativePath`: no se pudo fusionar, se instaló la versión del repo (copia previa: $previous)"
    }
}

Write-Header "IMALEagent Installer (Windows PowerShell)"
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Warning-Custom "Este script se está ejecutando en modo usuario."
    Write-Info "Nota: npm puede solicitar privilegios de administrador."
    Write-Host ""
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "Node.js no está instalado."
    Write-Info "Instala Node.js v18.0.0 o superior desde https://nodejs.org/"
    Write-Host ""
    exit 1
}
Write-Success "Node.js $(node --version) detectado"

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "npm no está instalado."
    exit 1
}
Write-Success "npm $(npm --version) detectado"
Write-Host ""

$configSourceDir = Join-Path (Split-Path -Parent $PSScriptRoot) "config\agent"
$templateDir = Join-Path $PSScriptRoot "templates"
$agentConfigDir = Join-Path $HOME ".pi\agent"
$mergeHelper = Join-Path $PSScriptRoot "lib\merge-config.mjs"
$manifestHelper = Join-Path $PSScriptRoot "lib\write-manifest.mjs"
$manifestPath = Join-Path $agentConfigDir ".imale-manifest"
$backupDir = Join-Path $agentConfigDir (".backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
$agentBinDir = Join-Path $agentConfigDir "bin"
$wrapperPath = Join-Path $agentBinDir "pi.cmd"

function Resolve-RealPiExecutable {
    param([string]$WrapperPath)

    $piCommand = Get-Command pi -ErrorAction SilentlyContinue
    if ($piCommand -and $piCommand.Source -ne $WrapperPath) {
        return $piCommand.Source
    }

    $npmGlobalPrefix = (npm prefix -g).Trim()
    $candidate = Join-Path $npmGlobalPrefix "pi.cmd"
    if (Test-Path $candidate) {
        return $candidate
    }

    return $null
}

function Ensure-AgentBinOnUserPath {
    param([string]$AgentBinDir)

    $currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $segments = @()
    if ($currentUserPath) {
        $segments = $currentUserPath.Split(';') | Where-Object { $_ -and $_.Trim() -ne '' }
    }

    if ($segments -contains $AgentBinDir) {
        return
    }

    $newUserPath = @($AgentBinDir) + $segments
    [Environment]::SetEnvironmentVariable("Path", ($newUserPath -join ';'), "User")
}

Write-Info "Instalando IMALEagent..."
Write-Host ""
npm install -g --loglevel=error --ignore-scripts @earendil-works/pi-coding-agent
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Pi installation failed."
    exit $LASTEXITCODE
}

# context-mode se instala globalmente porque el servidor MCP de mcp.json usa su
# binario `context-mode`. Sin --ignore-scripts: better-sqlite3 necesita su prebuild
# y el paquete ejecuta su propio postinstall.
Write-Info "Instalando context-mode (global)..."
npm install -g --loglevel=error context-mode
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Error al instalar context-mode globalmente."
    exit $LASTEXITCODE
}

Write-Info "Copiando la configuración de IMALEagent a $agentConfigDir..."
if (-not (Test-Path $configSourceDir)) {
    Write-Error-Custom "No se encontró la carpeta de configuración en $configSourceDir"
    exit 1
}

New-Item -ItemType Directory -Path $agentConfigDir -Force | Out-Null
if (-not (Test-Path $mergeHelper)) {
    Write-Warning-Custom "No se encontró $mergeHelper; settings.json y mcp.json se sobrescribirán sin fusionar."
}
Backup-ExistingConfig -SourceDir $configSourceDir -TargetDir $agentConfigDir -BackupDir $backupDir
Copy-Item -Path (Join-Path $configSourceDir "*") -Destination $agentConfigDir -Recurse -Force
if (Test-Path $mergeHelper) {
    Merge-JsonConfig -RelativePath "settings.json" -SourceDir $configSourceDir -TargetDir $agentConfigDir -BackupDir $backupDir -MergeHelper $mergeHelper
    Merge-JsonConfig -RelativePath "mcp.json" -SourceDir $configSourceDir -TargetDir $agentConfigDir -BackupDir $backupDir -MergeHelper $mergeHelper
}
if (Test-Path $manifestHelper) {
    & node $manifestHelper $configSourceDir $manifestPath "bin/pi.cmd" "bin/imaleagent.cmd" | Out-Null
    Write-Success "Manifiesto de instalación: $manifestPath"
} else {
    Write-Warning-Custom "No se encontró $manifestHelper; el desinstalador no eliminará con precisión."
}
Write-Success "Configuración copiada en $agentConfigDir"

Write-Info "Instalando y activando paquetes..."
$piExecutable = Resolve-RealPiExecutable -WrapperPath $wrapperPath

if (-not $piExecutable) {
    Write-Error-Custom "No se pudo localizar el ejecutable de pi después de la instalación."
    exit 1
}

Write-Info "Instalando Coding Agent..."
& $piExecutable install npm:pi-subagents >$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Paquete Coding Agent instalado"
} else {
    Write-Error-Custom "Error al instalar Coding Agent (pi-subagents)"
    exit $LASTEXITCODE
}

Write-Info "Instalando MCP Adapter..."
& $piExecutable install npm:pi-mcp-adapter >$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Paquete MCP Adapter instalado"
} else {
    Write-Error-Custom "Error al instalar MCP Adapter (pi-mcp-adapter)"
    exit $LASTEXITCODE
}

Write-Info "Instalando Context Mode..."
& $piExecutable install npm:context-mode >$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Paquete Context Mode instalado"
} else {
    Write-Error-Custom "Error al instalar Context Mode (context-mode)"
    exit $LASTEXITCODE
}

Write-Info "Instalando pi-lens..."
& $piExecutable install npm:pi-lens >$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Paquete pi-lens instalado"
} else {
    Write-Error-Custom "Error al instalar pi-lens"
    exit $LASTEXITCODE
}

Write-Info "Instalando rpiv-todo..."
& $piExecutable install npm:@juicesharp/rpiv-todo >$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Paquete rpiv-todo instalado"
} else {
    Write-Error-Custom "Error al instalar rpiv-todo"
    exit $LASTEXITCODE
}

Write-Info "Instalando rpiv-ask-user-question..."
& $piExecutable install npm:@juicesharp/rpiv-ask-user-question >$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Paquete rpiv-ask-user-question instalado"
} else {
    Write-Error-Custom "Error al instalar rpiv-ask-user-question"
    exit $LASTEXITCODE
}

$wrapperTemplatePath = Join-Path $templateDir "pi.cmd"
if (-not (Test-Path $wrapperTemplatePath)) {
    Write-Error-Custom "No se encontró la plantilla del wrapper en $wrapperTemplatePath"
    exit 1
}

New-Item -ItemType Directory -Path $agentBinDir -Force | Out-Null
$wrapperTemplate = Get-Content -Path $wrapperTemplatePath -Raw
$wrapperContent = $wrapperTemplate.Replace('__PI_REAL_BIN__', $piExecutable)
Set-Content -Path $wrapperPath -Value $wrapperContent -Encoding ASCII

# Crear comando imaleagent
$imaleWrapperTemplatePath = Join-Path $templateDir "imaleagent.cmd"
if (Test-Path $imaleWrapperTemplatePath) {
    $imaleAgentPath = Join-Path $agentBinDir "imaleagent.cmd"
    $imaleTemplate = Get-Content -Path $imaleWrapperTemplatePath -Raw
    $imaleContent = $imaleTemplate.Replace('__PI_REAL_BIN__', $piExecutable)
    Set-Content -Path $imaleAgentPath -Value $imaleContent -Encoding ASCII
}

Ensure-AgentBinOnUserPath -AgentBinDir $agentBinDir
$env:Path = "$agentBinDir;$env:Path"

Write-Success "IMALEagent installed at $wrapperPath"

Write-Host ""
Write-Header "IMALEagent installed successfully"
Write-Host ""

if (Get-Command pi -ErrorAction SilentlyContinue) {
    Write-Success "IMALEagent is available in your PATH"
} else {
    Write-Warning-Custom "Restart your terminal to refresh PATH."
}

Write-Host ""
Write-Info "Next steps:"
Write-Host "  1. Start: cd /your/project  &&  imaleagent"
Write-Host "  2. Auth:  /login  or  `$env:ANTHROPIC_API_KEY='your-key'"
Write-Host "  3. Docs:  https://pi.dev/docs/latest"
Write-Host ""
Write-Info "Config: $agentConfigDir"
Write-Host ""
