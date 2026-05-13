$ErrorActionPreference = "Stop"

$ROOT = Resolve-Path "$PSScriptRoot\.."

$EXPORT = "$ROOT\exports"
$SCH_EXPORT = "$EXPORT\schematics"

New-Item -ItemType Directory -Force -Path $EXPORT | Out-Null
New-Item -ItemType Directory -Force -Path $SCH_EXPORT | Out-Null

$PCB = "$ROOT\raylar_v1_00.kicad_pcb"
$SCH = "$ROOT\raylar_v1_00.kicad_sch"

# Temporary SVG directory
$SVG_DIR = "$SCH_EXPORT\svg"

Remove-Item $SVG_DIR -Recurse -Force -ErrorAction Ignore
New-Item -ItemType Directory -Force -Path $SVG_DIR | Out-Null

Write-Host "=== Exporting schematic sheets ==="

kicad-cli sch export svg `
    --output "$SVG_DIR" `
    "$SCH"

Write-Host "=== Converting schematic SVGs to PNGs ==="

Get-ChildItem "$SVG_DIR\*.svg" | ForEach-Object {

    $png = Join-Path $SCH_EXPORT ($_.BaseName + ".png")

    magick `
        $_.FullName `
        -background white `
        -alpha remove `
        -density 300 `
        $png

    Write-Host "Created:" $png
}

Write-Host "=== Exporting PCB top view ==="

kicad-cli pcb render `
    --side top `
    --zoom 0.92 `
    --width 2400 `
    --height 2400 `
    --output "$EXPORT\board_top.png" `
    "$PCB"

Write-Host "=== Exporting PCB bottom view ==="

kicad-cli pcb render `
    --side bottom `
    --zoom 0.92 `
    --width 2400 `
    --height 2400 `
    --output "$EXPORT\board_bottom.png" `
    "$PCB"

Write-Host "=== Exporting PCB perspective view ==="

kicad-cli pcb render `
    --rotate=-30,0,45 `
    --perspective `
    --floor `
    --zoom 0.92 `
    --width 2400 `
    --height 2400 `
    --output "$EXPORT\board_perspective.png" `
    "$PCB"

Write-Host "=== Generating rotating GIF ==="

python "$PSScriptRoot\make_gif.py" `
    "$PCB" `
    "$EXPORT"

Write-Host "=== Complete ==="