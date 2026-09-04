# Module 3 Content Map

Runtime is defined by `scripts/module_content_registry.gd` (`_build_module_3`)
and loaded through `modules/module_3/Main.tscn` → `ModuleShell`.

## Page flow

1. `hero` — server intro + numbered learning path  
2. `model_library` — Server Lab  
3. `guided_simulation` — Phase 01 Roles · File Server, NAS, Workstation  
4. `guided_simulation` — Phase 02 Storage Layout · folders & UNC paths  
5. `guided_simulation` — Phase 03 Accounts · users & groups  
6. `guided_simulation` — Phase 04 Permissions · NTFS + share ACLs  
7. `guided_simulation` — Phase 05 Share & Validate · client access tests  
8. `assessment` — Company File Server Setup  
9. `model_library` — Server Museum  

## Models

| Folder | Device |
| --- | --- |
| `assets/models/module_3/server/` | File server tower |
| `assets/models/module_3/nas/` | NAS appliance |
| `assets/models/module_3/workstation/` | Client (laptop procedural) |

## Host contract

- Android `moduleId == 3` loads `modules/module_3/Main.tscn`
- `simulationType == 0` starts at intro; `1` jumps to assessment
