# Updated `export_release.bat`

```bat
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

set "RAW_BOM=%BOM%\%PROJECT%_bom.csv"
set "QUICK_TECK_BOM=%BOM%\QUICK_TECK.csv"


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
    -OutputCsv "%POS%\%PROJECT%_pos_jlc_pcb.csv"

if errorlevel 1 (
    echo JLPCB conversion failed.
    exit /b 1
)


echo === Exporting BOM CSV ===
kicad-cli sch export bom "%ROOT%%PROJECT%.kicad_sch"  --output "%RAW_BOM%"  --fields "Reference,Value,Footprint,Description,Q_SUPPLIER,Q_SUPPLIER_PN,MF,MP,LCSC" --field-delimiter "," --string-delimiter "\"" --sort-field "Reference" --sort-asc

if errorlevel 1 (
    echo BOM export failed.
    exit /b 1
)


echo === Generating QUICK_TECK.csv ===
powershell -NoProfile -ExecutionPolicy Bypass -Command "$bom = Import-Csv '%RAW_BOM%'; $grouped = $bom | Group-Object Value,Footprint | ForEach-Object { $first = $_.Group[0]; [PSCustomObject]@{ 'QTY' = $_.Count; 'REFERENCE DESIGNATOR' = ($_.Group.Reference -join ','); 'ITEM DESCRIPTION' = $first.Description; 'SUPPLIER' = $first.Q_SUPPLIER; 'SUPPLIER PART NO' = $first.Q_SUPPLIER_PN; 'MANUFACTURER' = $first.MF; 'MANUFACTURER PART NUMBER' = $first.MP;'LCSC PART NO' = $first.LCSC } }; $grouped | Export-Csv '%QUICK_TECK_BOM%' -NoTypeInformation"
if errorlevel 1 (
    echo QUICK_TECK BOM generation failed.
    exit /b 1
)


echo === Exporting Assembly PDF ===
kicad-cli pcb export pdf "%ROOT%%PROJECT%.kicad_pcb" --mode-single --layers F.Fab,F.SilkS,Edge.Cuts -o "%PDF%\%PROJECT%_assembly.pdf"


echo === Zipping Release ===
powershell -NoProfile -Command "Compress-Archive -Path '%OUT%\*' -DestinationPath '%OUT%\%PROJECT%_release.zip' -Force"


echo === DONE ===
pause

