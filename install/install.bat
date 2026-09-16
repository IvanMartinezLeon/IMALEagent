@echo off
REM Instalador de IMALEagent para Windows CMD

setlocal enabledelayedexpansion

echo.
echo === IMALEagent Installer (Windows CMD) ===
echo.

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Node.js no está instalado.
    echo.
    echo Instala Node.js v18.0.0 o superior desde https://nodejs.org/
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo [OK] Node.js %NODE_VERSION% detectado

where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: npm no está instalado.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
echo [OK] npm %NPM_VERSION% detectado
echo.

set "SCRIPT_DIR=%~dp0"
set "CONFIG_SOURCE_DIR=%SCRIPT_DIR%..\config\agent"
set "TEMPLATE_DIR=%SCRIPT_DIR%templates"
set "AGENT_CONFIG_DIR=%USERPROFILE%\.pi\agent"
set "AGENT_BIN_DIR=%AGENT_CONFIG_DIR%\bin"
set "WRAPPER_PATH=%AGENT_BIN_DIR%\pi.cmd"
set "MERGE_HELPER=%SCRIPT_DIR%lib\merge-config.mjs"
set "MANIFEST_HELPER=%SCRIPT_DIR%lib\write-manifest.mjs"
set "MANIFEST_PATH=%AGENT_CONFIG_DIR%\.imale-manifest"
set "BACKUP_DIR=%AGENT_CONFIG_DIR%\.backup-%DATE:~-4%%DATE:~3,2%%DATE:~0,2%-%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "BACKUP_DIR=%BACKUP_DIR: =0%"

echo Instalando IMALEagent...
echo.
call npm install -g --loglevel=error --ignore-scripts @earendil-works/pi-coding-agent 
if errorlevel 1 (
    echo [FAIL] IMALEagent installation failed
    pause
    exit /b 1
)

REM context-mode se instala globalmente porque el servidor MCP de mcp.json usa su
REM binario `context-mode`. Sin --ignore-scripts: better-sqlite3 necesita su prebuild
REM y el paquete ejecuta su propio postinstall.
echo [INFO] Instalando context-mode (global)...
call npm install -g --loglevel=error context-mode
if errorlevel 1 (
    echo [FAIL] Error al instalar context-mode globalmente
    pause
    exit /b 1
)

echo Copiando la configuración de IMALEagent a %AGENT_CONFIG_DIR%...
if not exist "%CONFIG_SOURCE_DIR%" (
    echo [FAIL] No se encontró la carpeta de configuración en %CONFIG_SOURCE_DIR%
    pause
    exit /b 1
)

if not exist "%AGENT_CONFIG_DIR%" mkdir "%AGENT_CONFIG_DIR%"
call :BackupExistingConfig
xcopy "%CONFIG_SOURCE_DIR%\*" "%AGENT_CONFIG_DIR%\" /E /I /Y >nul
if %errorlevel% geq 4 (
    echo [FAIL] Could not copy configuration files
    pause
    exit /b 1
)
if exist "%MERGE_HELPER%" (
    call :MergeJsonConfig "settings.json"
    call :MergeJsonConfig "mcp.json"
) else (
    echo [WARN] No se encontro %MERGE_HELPER%; settings.json y mcp.json se sobrescriben sin fusionar.
)
if exist "%MANIFEST_HELPER%" (
    call node "%MANIFEST_HELPER%" "%CONFIG_SOURCE_DIR%" "%MANIFEST_PATH%" "bin/pi.cmd" "bin/imaleagent.cmd" >nul
    if errorlevel 1 (
        echo [WARN] No se pudo escribir el manifiesto de instalacion.
    ) else (
        echo [OK] Manifiesto de instalacion: %MANIFEST_PATH%
    )
) else (
    echo [WARN] No se encontro %MANIFEST_HELPER%; el desinstalador no eliminara con precision.
)
echo [OK] Configuración copiada en %AGENT_CONFIG_DIR%

echo Instalando y activando paquetes...
set "PI_CMD="
where pi >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('where pi') do (
        if /I not "%%~fi"=="%WRAPPER_PATH%" (
            set "PI_CMD=%%~fi"
            goto :pi_command_resolved
        )
    )
)
for /f "tokens=*" %%i in ('npm prefix -g') do set "NPM_GLOBAL_PREFIX=%%i"
if not defined PI_CMD if exist "%NPM_GLOBAL_PREFIX%\pi.cmd" set "PI_CMD=%NPM_GLOBAL_PREFIX%\pi.cmd"

:pi_command_resolved
if not defined PI_CMD (
    echo [FAIL] No se pudo localizar el ejecutable de pi después de la instalación
    pause
    exit /b 1
)

echo [INFO] Instalando Coding Agent...
call "%PI_CMD%" install npm:pi-subagents >nul 2>nul
if errorlevel 1 (
    echo [FAIL] Error al instalar Coding Agent (pi-subagents)
    pause
    exit /b 1
) else (
    echo [OK] Paquete Coding Agent instalado
)
echo [INFO] Instalando MCP Adapter...
call "%PI_CMD%" install npm:pi-mcp-adapter >nul 2>nul
if errorlevel 1 (
    echo [FAIL] Error al instalar MCP Adapter (pi-mcp-adapter)
    pause
    exit /b 1
) else (
    echo [OK] Paquete MCP Adapter instalado
)
echo [INFO] Instalando Context Mode...
call "%PI_CMD%" install npm:context-mode >nul 2>nul
if errorlevel 1 (
    echo [FAIL] Error al instalar Context Mode (context-mode)
    pause
    exit /b 1
) else (
    echo [OK] Paquete Context Mode instalado
)
echo [INFO] Instalando pi-lens...
call "%PI_CMD%" install npm:pi-lens >nul 2>nul
if errorlevel 1 (
    echo [FAIL] Error al instalar pi-lens
    pause
    exit /b 1
) else (
    echo [OK] Paquete pi-lens instalado
)
echo [INFO] Instalando rpiv-todo...
call "%PI_CMD%" install npm:@juicesharp/rpiv-todo >nul 2>nul
if errorlevel 1 (
    echo [FAIL] Error al instalar rpiv-todo
    pause
    exit /b 1
) else (
    echo [OK] Paquete rpiv-todo instalado
)
echo [INFO] Instalando rpiv-ask-user-question...
call "%PI_CMD%" install npm:@juicesharp/rpiv-ask-user-question >nul 2>nul
if errorlevel 1 (
    echo [FAIL] Error al instalar rpiv-ask-user-question
    pause
    exit /b 1
) else (
    echo [OK] Paquete rpiv-ask-user-question instalado
)

if not exist "%TEMPLATE_DIR%\pi.cmd" (
    echo [FAIL] No se encontró la plantilla del wrapper en %TEMPLATE_DIR%\pi.cmd
    pause
    exit /b 1
)

if not exist "%AGENT_BIN_DIR%" mkdir "%AGENT_BIN_DIR%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$template = Get-Content -Path '%TEMPLATE_DIR%\pi.cmd' -Raw; $content = $template.Replace('__PI_REAL_BIN__', '%PI_CMD%'); Set-Content -Path '%WRAPPER_PATH%' -Value $content -Encoding ASCII"
if errorlevel 1 exit /b 1

REM Crear comando imaleagent
if exist "%TEMPLATE_DIR%\imaleagent.cmd" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$template = Get-Content -Path '%TEMPLATE_DIR%\imaleagent.cmd' -Raw; $content = $template.Replace('__PI_REAL_BIN__', '%PI_CMD%'); Set-Content -Path '%AGENT_BIN_DIR%\imaleagent.cmd' -Value $content -Encoding ASCII"
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$dir = '%AGENT_BIN_DIR%'; $userPath = [Environment]::GetEnvironmentVariable('Path', 'User'); $parts = @(); if ($userPath) { $parts = $userPath.Split(';') | Where-Object { $_ -and $_.Trim() -ne '' } }; if (-not ($parts -contains $dir)) { [Environment]::SetEnvironmentVariable('Path', (($dir + ';' + ($parts -join ';')).Trim(';')), 'User') }"
set "PATH=%AGENT_BIN_DIR%;%PATH%"

echo [OK] IMALEagent installed at %WRAPPER_PATH%

echo.

where pi >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] IMALEagent is available in your PATH
) else (
    echo [WARN] Restart your terminal to refresh PATH.
)

echo.
echo Next steps:
echo   1. Start: cd /your/project  ^&^&  imaleagent
echo   2. Auth:  /login  or  set ANTHROPIC_API_KEY=your-key
echo   3. Docs:  https://pi.dev/docs/latest
echo.
echo Config: %AGENT_CONFIG_DIR%
echo.

pause
exit /b 0

REM ── Subrutinas ──────────────────────────────────────────────────

:BackupExistingConfig
set "BACKUP_COUNT=0"
for /f "delims=" %%i in ('dir /b /a "%CONFIG_SOURCE_DIR%" 2^>nul') do (
    if exist "%AGENT_CONFIG_DIR%\%%i" (
        if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
        xcopy "%AGENT_CONFIG_DIR%\%%i" "%BACKUP_DIR%\%%i" /E /I /Y >nul 2>&1
        set /a BACKUP_COUNT+=1
    )
)
if %BACKUP_COUNT% gtr 0 (
    echo [OK] Copia de seguridad de la config previa: %BACKUP_DIR% ^(%BACKUP_COUNT% elemento^(s^)^)
) else (
    if exist "%BACKUP_DIR%" rd /s /q "%BACKUP_DIR%"
)
exit /b 0

REM Fusiona un JSON del repo con el previo del usuario en lugar de sobrescribirlo.
REM Imprescindible para no perder packages, provider/model ni MCPs propios.
:MergeJsonConfig
set "MERGE_REL=%~1"
set "MERGE_INCOMING=%CONFIG_SOURCE_DIR%\%MERGE_REL%"
set "MERGE_PREVIOUS=%BACKUP_DIR%\%MERGE_REL%"
set "MERGE_TARGET=%AGENT_CONFIG_DIR%\%MERGE_REL%"
if not exist "%MERGE_INCOMING%" exit /b 0
if not exist "%MERGE_PREVIOUS%" exit /b 0
set "MERGE_OUT=%TEMP%\imale-merge-%RANDOM%-%RANDOM%.json"
call node "%MERGE_HELPER%" "%MERGE_INCOMING%" "%MERGE_PREVIOUS%" "%MERGE_OUT%"
if errorlevel 1 (
    if exist "%MERGE_OUT%" del /f /q "%MERGE_OUT%"
    echo [WARN] %MERGE_REL%: no se pudo fusionar, se instalo la version del repo ^(copia previa: %MERGE_PREVIOUS%^)
    exit /b 0
)
move /y "%MERGE_OUT%" "%MERGE_TARGET%" >nul
if errorlevel 1 (
    echo [WARN] %MERGE_REL%: no se pudo escribir %MERGE_TARGET% ^(version fusionada en %MERGE_OUT%^)
    exit /b 0
)
echo [OK] %MERGE_REL% fusionado con la configuracion previa
exit /b 0
