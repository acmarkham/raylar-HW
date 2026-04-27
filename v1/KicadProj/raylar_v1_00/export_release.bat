@echo off
setlocal

set "PROJECT=raylar_v1_00"
set "ROOT=%~dp0"
set "BUILD=%ROOT%build"
set "OUT=%BUILD%\release"

set "GERBERS=%OUT%\gerbers"
set "DRILL=%OUT%\drill"
set "POS=%OUT%\pos"
set "BOM=%OUT%\bom"
set "PDF=%OUT%\pdf"

echo === Cleaning previous build ===
rmdir /s /q "%OUT%" 2>nul

echo === Creating output directories ===
mkdir "%GERBERS%"
mkdir "%DRILL%"
mkdir "%POS%"
mkdir "%BOM%"
mkdir "%PDF%"

echo === Exporting Gerbers ===
kicad-cli pcb export gerbers "%ROOT%%PROJECT%.kicad_pcb" -o "%GERBERS%"

echo === Exporting Drill Files ===
kicad-cli pcb export drill "%ROOT%%PROJECT%.kicad_pcb"  -o "%DRILL%" --drill-origin absolute --excellon-units mm --excellon-zeros-format decimal

echo === Exporting Position File (CSV) ===
kicad-cli pcb export pos "%ROOT%%PROJECT%.kicad_pcb" --format csv --units mm --side both -o "%POS%\%PROJECT%_pos.csv"

echo === Converting Position File to JLPCB Format ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%convert_pos_jlpcb.ps1" ^
    -InputCsv "%POS%\%PROJECT%_pos.csv" ^
    -OutputCsv "%POS%\%PROJECT%_pos_jl.csv"

if errorlevel 1 (
    echo JLPCB conversion failed.
    exit /b 1
)


echo === Exporting BOM ===
echo === Exporting BOM CSV ===
echo === Exporting BOM CSV ===
kicad-cli sch export bom "%ROOT%%PROJECT%.kicad_sch" --output "%BOM%\%PROJECT%_bom.csv" --fields "*" --field-delimiter "," --string-delimiter "\"" --sort-field "Reference" --sort-asc

echo === Exporting Assembly PDF ===
kicad-cli pcb export pdf "%ROOT%%PROJECT%.kicad_pcb" --mode-single --layers F.Fab,F.SilkS,Edge.Cuts -o "%PDF%\%PROJECT%_assembly.pdf"

echo === Zipping Release ===
powershell -NoProfile -Command "Compress-Archive -Path '%OUT%\*' -DestinationPath '%OUT%\%PROJECT%_release.zip' -Force"

echo === DONE ===
pause