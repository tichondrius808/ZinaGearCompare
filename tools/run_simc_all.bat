@echo off
:: ============================================================
:: run_simc_all.bat — ZinaGearCompare stat weight generator
:: Corre SimC en todos los perfiles base de MID1 con scale
:: factors activados, para Patchwerk (raid) y DungeonSlice (M+).
:: Output: tools\simc_output\<spec>_raid.json y _dungeon.json
::
:: Uso: edita SIMC_DIR y PROFILES_DIR, luego ejecuta este .bat
::      desde cualquier directorio.
:: ============================================================

set SIMC_DIR=C:\XXX\simc-1201.01.bf5d0bc-win64
set PROFILES_DIR=%SIMC_DIR%\profiles\MID1
set OUTPUT_DIR=%~dp0simc_output
set SIMC_EXE=%SIMC_DIR%\simc.exe
set ITERATIONS=10000

:: Crear carpeta de output
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo === ZinaGearCompare: SimC scale factors ===
echo SIMC:     %SIMC_EXE%
echo Perfiles: %PROFILES_DIR%
echo Output:   %OUTPUT_DIR%
echo Iter:     %ITERATIONS% por sim
echo.

:: Perfiles base (uno por spec, sin variantes hero talent)
:: Formato: ALIAS FICHERO_SIMC
:: ALIAS se usa como nombre de fichero JSON de output.

set SPECS=^
  250_DK_Blood:MID1_Death_Knight_Blood ^
  251_DK_Frost:MID1_Death_Knight_Frost ^
  252_DK_Unholy:MID1_Death_Knight_Unholy ^
  581_DH_Vengeance:MID1_Demon_Hunter_Vengeance ^
  1480_DH_Devourer:MID1_Demon_Hunter_Devourer ^
  103_Druid_Feral:MID1_Druid_Feral ^
  1467_Evoker_Devastation:MID1_Evoker_Devastation ^
  62_Mage_Arcane:MID1_Mage_Arcane ^
  63_Mage_Fire:MID1_Mage_Fire ^
  64_Mage_Frost:MID1_Mage_Frost ^
  268_Monk_Brewmaster:MID1_Monk_Brewmaster ^
  269_Monk_Windwalker:MID1_Monk_Windwalker ^
  258_Priest_Shadow:MID1_Priest_Shadow ^
  260_Rogue_Outlaw:MID1_Rogue_Outlaw ^
  261_Rogue_Subtlety:MID1_Rogue_Subtlety ^
  262_Shaman_Elemental:MID1_Shaman_Elemental ^
  263_Shaman_Enhancement:MID1_Shaman_Enhancement ^
  265_Warlock_Affliction:MID1_Warlock_Affliction ^
  267_Warlock_Destruction:MID1_Warlock_Destruction ^
  73_Warrior_Protection:MID1_Warrior_Protection

for %%S in (%SPECS%) do (
    for /f "tokens=1,2 delims=:" %%A in ("%%S") do (
        set ALIAS=%%A
        set PROFILE=%%B
        call :run_spec "!ALIAS!" "!PROFILE!"
    )
)

echo.
echo === Listo. Ejecuta ahora: py simc_to_lua.py ===
echo.
pause
goto :eof

:run_spec
set ALIAS=%~1
set PROFILE=%~2
set PROFILE_PATH=%PROFILES_DIR%\%PROFILE%.simc

if not exist "%PROFILE_PATH%" (
    echo [SKIP] %ALIAS% — no encontrado: %PROFILE_PATH%
    goto :eof
)

echo.
echo [Raid]    %ALIAS%
"%SIMC_EXE%" "%PROFILE_PATH%" calculate_scale_factors=1 scale_only=str,agi,int,crit,haste,mastery,versatility iterations=%ITERATIONS% fight_style=Patchwerk json2="%OUTPUT_DIR%\%ALIAS%_raid.json" > nul 2>&1
if errorlevel 1 (
    echo   ERROR en Patchwerk
) else (
    echo   OK
)

echo [M+]     %ALIAS%
"%SIMC_EXE%" "%PROFILE_PATH%" calculate_scale_factors=1 scale_only=str,agi,int,crit,haste,mastery,versatility iterations=%ITERATIONS% fight_style=DungeonSlice json2="%OUTPUT_DIR%\%ALIAS%_dungeon.json" > nul 2>&1
if errorlevel 1 (
    echo   ERROR en DungeonSlice
) else (
    echo   OK
)
goto :eof
