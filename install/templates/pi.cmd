@echo off
setlocal

set "PI_REAL_BIN=__PI_REAL_BIN__"

call "%PI_REAL_BIN%" %*
set "EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %EXIT_CODE%
