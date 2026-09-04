#Requires -Version 5.1
param(
	[string]$GodotExe = "",
	[string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"

if ($ProjectRoot -eq "") {
	$ProjectRoot = Split-Path -Parent $PSScriptRoot
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

Write-Host "Godot: $GodotExe"
Write-Host "Project: $ProjectRoot"
Write-Host "Running regress_probe..."

# Godot may return non-zero when engine warnings fire; judge pass/fail from the report.
& $GodotExe --headless --path $ProjectRoot --script "res://tools/regress_probe.gd" | Out-Host

$report = Join-Path $env:APPDATA "Godot\app_userdata\SmartBuildGodot\regress_probe.txt"
if (-not (Test-Path $report)) {
	Write-Error "Missing report: $report"
	exit 1
}

$tail = Get-Content $report -Tail 5
$pass = $tail | Where-Object { $_ -match "^problems:\s*0\s*$" }
if (-not $pass) {
	Write-Host ($tail -join "`n")
	Write-Error "regress_probe reported failures (see $report)"
	exit 1
}

Write-Host "CI OK - problems: 0"
exit 0
