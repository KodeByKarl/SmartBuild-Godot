#Requires -Version 5.1
<#
.SYNOPSIS
  Export SmartBuildGodot.pck for the embedded Godot runtime in the Android app.

.DESCRIPTION
  Output: SmartBuild/app/src/main/assets/SmartBuildGodot.pck
  Required by MainActivity.getCommandLine() -> "--main-pack", "res://SmartBuildGodot.pck"

.EXAMPLE
  .\tools\export_android_pck.ps1
  .\tools\export_android_pck.ps1 -GodotExe "C:\Users\Administrator\Desktop\Godot_v4.7.2-stable_win64.exe"
#>
param(
	[string]$GodotExe = "",
	[string]$ProjectRoot = "",
	[string]$OutputPck = ""
)

$ErrorActionPreference = "Stop"

if ($ProjectRoot -eq "") {
	$ProjectRoot = Split-Path -Parent $PSScriptRoot
}

if ($OutputPck -eq "") {
	$OutputPck = Join-Path $ProjectRoot "..\SmartBuild\app\src\main\assets\SmartBuildGodot.pck"
}

if ($GodotExe -eq "") {
	$candidates = @(
		$env:GODOT_BIN,
		"C:\Users\Administrator\Desktop\Godot_v4.7.2-stable_win64.exe",
		"C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe",
		"godot"
	)
	foreach ($c in $candidates) {
		if (-not $c) { continue }
		if (Get-Command $c -ErrorAction SilentlyContinue) {
			$GodotExe = (Get-Command $c).Source
			break
		}
		if (Test-Path $c) {
			$GodotExe = $c
			break
		}
	}
}

if (-not $GodotExe -or -not (Test-Path $GodotExe)) {
	Write-Error "Godot executable not found. Pass -GodotExe or set GODOT_BIN."
}

$outDir = Split-Path -Parent $OutputPck
if (-not (Test-Path $outDir)) {
	New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

Write-Host "Godot:   $GodotExe"
Write-Host "Project: $ProjectRoot"
Write-Host "Output:  $OutputPck"
Write-Host "Exporting Android pack..."

& $GodotExe --headless --path $ProjectRoot --export-pack "Android" $OutputPck | Out-Host

if (-not (Test-Path $OutputPck)) {
	Write-Error "Export failed - PCK not created at $OutputPck"
}

$sizeMb = [math]::Round((Get-Item $OutputPck).Length / 1MB, 1)
Write-Host "Done - SmartBuildGodot.pck ($sizeMb MB)"
