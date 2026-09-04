# Module 2 Content Map

Runtime is defined by `scripts/module_content_registry.gd` (`_build_module_2`)
and loaded through `modules/module_2/Main.tscn` → `ModuleShell`.

Aligned to client doc: Intro & Obj → Guided phases (incl. crossover) → SBA.

## Page flow

1. `hero` — network intro + numbered learning path  
2. `model_library` — Network Lab (modem, router, switch, AP, cable, endpoints)  
3. `guided_simulation` — Phase 01 Components · models: Modem, Router, Switch, Access Point  
4. `guided_simulation` — Phase 02 Straight-Through · T568B both ends + test  
5. `guided_simulation` — Phase 03 Crossover · T568A + T568B + test  
6. `guided_simulation` — Phase 04 Topology · Workstation, Switch, Router, Modem  
7. `guided_simulation` — Phase 05 Addressing · IP, mask, gateway, DNS  
8. `guided_simulation` — Phase 06 Wireless · SSID, password, security, join client  
9. `guided_simulation` — Phase 07 Validate · ping router/peer, internet, file share, docs  
10. `assessment` — Small Office Network Installation  
11. `model_library` — Device Museum  

## Phase UX

- Top brief + reference model gallery  
- Left coach panel (how-to / objectives + progress)  
- Right interactive station with question prompt + action cards  
- Assessment cards use shuffled A/B/C labels  
- Each step has a `question` string used as the station prompt  

## Models

**One folder = one item** under `assets/models/module_2/`.

Procedural meshes use `assets/models/module_2/_factory/part_model.gd` + `Module2PartFactory`.

| Category | Folders |
| --- | --- |
| WAN Edge | `modem/` |
| Core Network | `router/`, `switch/`, `hub/`, `firewall/`, `nic/` |
| Wireless | `access_point/`, `repeater/` |
| Cabling | `ethernet_cable/`, `fiber_cable/`, `patch_panel/`, `rj45/` |
| Tools | `crimper/`, `cable_tester/` |
| Endpoints | `workstation/`, `monitor/`, `keyboard/` |

Each folder has `model.tscn` + `PART.txt`. Drop Sketchfab `scene.gltf` later to replace procedural geometry.

See `assets/models/module_2/README.md` for the full catalog.

## Host contract

- Android `moduleId == 2` loads `modules/module_2/Main.tscn`
- `simulationType == 0` starts at the intro
- `simulationType == 1` starts on the assessment page
