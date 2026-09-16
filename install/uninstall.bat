@echo off
REM IMALEagent Uninstaller for Windows (Batch)

setlocal enabledelayedexpansion

echo.
echo === IMALEagent Uninstaller (Windows CMD) ===
echo.

set "AGENT_CONFIG_DIR=%USERPROFILE%\.pi\agent"
set "SCRIPT_DIR=%~dp0"

echo This will uninstall IMALEagent and remove its configuration from %AGENT_CONFIG_DIR%.
set /p confirmation="Are you sure? (y/n): "

if /i not "%confirmation%"=="y" (
    echo Uninstallation cancelled.
    pause
    exit /b 0
)

echo.
echo Removing IMALE packages...
echo.

set "PI_CMD="
where pi >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('where pi') do (
        set "PI_CMD=%%i"
        goto :pi_remove_ready
    )
)
for /f "tokens=*" %%i in ('npm prefix -g') do set "NPM_GLOBAL_PREFIX=%%i"
if exist "%NPM_GLOBAL_PREFIX%\pi.cmd" set "PI_CMD=%NPM_GLOBAL_PREFIX%\pi.cmd"

:pi_remove_ready
if defined PI_CMD (
    echo [INFO] Desinstalando Ask User...
    call "%PI_CMD%" remove npm:pi-ask-user >nul 2>nul
    if errorlevel 1 (
        echo [WARN] Ask User no estaba instalado
    ) else (
        echo [OK] Ask User desinstalado
    )
    echo [INFO] Desinstalando Web Access...
    call "%PI_CMD%" remove npm:pi-web-access >nul 2>nul
    if errorlevel 1 (
        echo [WARN] Web Access no estaba instalado
    ) else (
        echo [OK] Web Access desinstalado
    )
    echo [INFO] Desinstalando Code Intelligence...
    call "%PI_CMD%" remove npm:@catdaemon/pi-code-intelligence >nul 2>nul
    if errorlevel 1 (
        echo [WARN] Code Intelligence no estaba instalado
    ) else (
        echo [OK] Code Intelligence desinstalado
    )
    echo [INFO] Desinstalando MCP Adapter...
    call "%PI_CMD%" remove npm:pi-mcp-adapter >nul 2>nul
    if errorlevel 1 (
        echo [WARN] MCP Adapter no estaba instalado
    ) else (
        echo [OK] MCP Adapter desinstalado
    )
    echo [INFO] Desinstalando Coding Agent...
    call "%PI_CMD%" remove npm:pi-subagents >nul 2>nul
    if errorlevel 1 (
        echo [WARN] Coding Agent no estaba instalado
    ) else (
        echo [OK] Coding Agent desinstalado
    )
)

echo.
echo Uninstalling IMALEagent...
echo.

call npm uninstall -g @earendil-works/pi-coding-agent
if errorlevel 1 (
    echo IMALEagent uninstallation failed.
    pause
    exit /b 1
)

echo Removing IMALE configuration from %AGENT_CONFIG_DIR%...
REM Un unico helper Node para los tres desinstaladores: evita listas duplicadas
REM y no borra nunca directorios completos (conserva el material propio del usuario).
set "UNINSTALL_HELPER=%SCRIPT_DIR%lib\uninstall-config.mjs"
if exist "%UNINSTALL_HELPER%" (
    call node "%UNINSTALL_HELPER%" "%AGENT_CONFIG_DIR%"
    if errorlevel 1 echo [WARN] El helper de desinstalacion devolvio un error.
) else (
    echo [FAIL] No se encontro %UNINSTALL_HELPER%
    echo [WARN] Elimina a mano la configuracion de %AGENT_CONFIG_DIR%
)

echo.
echo [OK] IMALEagent uninstalled
echo [OK] Configuration removed from %AGENT_CONFIG_DIR%
echo.
echo [WARN] Other package managers: pnpm remove -g ... / yarn global remove ... / bun uninstall -g ...
echo.

pause
