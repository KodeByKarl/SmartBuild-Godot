# Module 4 Content Map

Runtime is defined by `scripts/module_content_registry.gd` (`_build_module_4`)
and loaded through `modules/module_4/Main.tscn` → `ModuleShell`.

## Page flow

1. `hero` — maintenance intro + numbered learning path  
2. `model_library` — Service Lab  
3. `guided_simulation` — Phase 01 Intake · ticket & tools  
4. `guided_simulation` — Phase 02 Hardware PM · dust, fans, reseat RAM  
5. `guided_simulation` — Phase 03 Software PM · updates, malware, disk  
6. `guided_simulation` — Phase 04 Network Check · cable, IP, ping  
7. `guided_simulation` — Phase 05 Repair & Close · root cause + docs  
8. `assessment` — IT Support Service Request  
9. `model_library` — Service Museum  

## Models

| Folder | Device |
| --- | --- |
| `assets/models/module_4/diagnostic_pc/` | Case under service |
| `assets/models/module_4/toolkit/` | Screwdriver toolkit |

Also reuses Module 1/2 parts (motherboard, RAM, fan, antistatic, router, cable).

## Host contract

- Android `moduleId == 4` loads `modules/module_4/Main.tscn`
- `simulationType == 0` starts at intro; `1` jumps to assessment
