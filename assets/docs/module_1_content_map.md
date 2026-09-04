# Module 1 Content Map

Runtime is defined by `scripts/module_content_registry.gd` and loaded through
`modules/module_1/Main.tscn` → `ModuleShell`.

Aligned to TESDA CSS NC II Unit 1 (`ELC724331` Install and Configure Computer Systems).
This app is a training aid (NC II–aligned), not a TESDA accreditation itself.

## Page flow

1. `hero` — Unit 1 intro + numbered learning path  
2. `model_library` — Interactive Hardware Lab (uploaded + procedural models)  
3. `guided_simulation` — Phase 01 Prep · **4-choice MCQ** per step  
4. `guided_simulation` — Phase 02 Build · **PC Build Bench** (`sim_mode: pc_build`)  
5. `guided_simulation` — Phase 03 Firmware · **4-choice MCQ**  
6. `guided_simulation` — Phase 04 OS · **4-choice MCQ**  
7. `guided_simulation` — Phase 05 Validate · **4-choice MCQ**  
8. `assessment` — Office Workstation Deployment · **PC Build Bench** (no yellow hints)  
9. `model_library` — Parts Museum  
10. `completion`

## Phase UX

### Quiz phases (01, 03, 04, 05)
- Left: reference 3D models for the phase
- Right: one scenario question + tip + **A/B/C/D** answers rebuilt each step
- Wrong answers flash red and stay retryable; correct advances

### PC Build phases (02 + assessment)
- Coach prompt shows part → slot
- Tray highlights the next part (guided); yellow pulse on next slot
- Select part → tap slot button (or 3D socket) → snap-in visual

## Host contract

- Android `moduleId == 1` loads `modules/module_1/Main.tscn`
- `simulationType == 0` starts at the intro
- `simulationType == 1` starts on the assessment page
