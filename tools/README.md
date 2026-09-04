# SmartBuild Godot — tools

## Android PCK export (required for phone modules)

```powershell
.\tools\export_android_pck.ps1
```

Writes `SmartBuild/app/src/main/assets/SmartBuildGodot.pck` (~200+ MB). Run after changing Godot content before rebuilding the Android app.

## CI regression suite

`regress_probe.gd` is the single headless suite for Modules 1–4. It walks every page, drives interactive sims to completion, and exits non-zero on stuck or unhandled steps.

Module 0 (intro slides) uses a separate shell with the same **Search** / **Help** header chrome; it is not part of `regress_probe` because it has no SimulationManager steps.

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

### GitHub Actions

`.github/workflows/godot-ci.yml` downloads Godot 4.7.2 and runs the same suite on push/PR to `main` / `master`.
