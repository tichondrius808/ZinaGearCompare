@echo off
echo ============================================
echo  ZinaGearCompare — Raidbots Import
echo ============================================
echo.
echo  Auto-detects ST vs AoE from the report:
echo    Patchwerk / LightMovement  = ST
echo    DungeonSlice               = AoE
echo.

if "%~1"=="" (
    set /p URL="Paste Raidbots report URL: "
) else (
    set URL=%~1
)

echo.
py "%~dp0raidbots_import.py" "%URL%"

echo.
pause
