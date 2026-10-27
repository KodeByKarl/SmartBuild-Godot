# SmartBuild Godot — tools

## Android PCK export (required for phone Module 0–1)

```powershell
.\tools\export_android_pck.ps1
```

Writes `SmartBuild/app/src/main/assets/SmartBuildGodot.pck` (~75–80 MB after M2–M4 slim).  
Run after changing Godot content before rebuilding the Android app.

**Note:** Modules 2–4 run as Compose on Android — they are not packed into this `.pck`.

## CI regression suite

`regress_probe.gd` is the headless suite for **Module 1** (ModuleShell + PcBuildBench).  
It walks every page, drives the PC build sim to completion, and exits non-zero on stuck steps.

Module 0 (intro slides) is not part of `regress_probe` (no SimulationManager steps).

### Local (Windows)

```powershell
.\tools\run_ci.ps1
```

Or with an explicit Godot binary:

```powershell
.\tools\run_ci.ps1 -GodotExe "C:\path\to\Godot_v4.7.2-stable_win64.exe"
```

### Manual

```text
godot --headless --path . --script res://tools/regress_probe.gd
```

Report file: `%APPDATA%\Godot\app_userdata\SmartBuildGodot\regress_probe.txt`

## UI chrome probe

`UiChangeProbe.tscn` checks shared shell chrome for Module 0 and Module 1  
(Exit / Prev / page counter / Next, Assessment entry, scroll). Needs a scene:

```text
godot --headless --path . res://tools/UiChangeProbe.tscn
```

### GitHub Actions

`.github/workflows/godot-ci.yml` downloads Godot 4.7.2 and runs the same suite on push/PR to `main` / `master`.
