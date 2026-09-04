# Module 1 PC Build Simulation

Practical assembly bench (not AAA polish): pick a part → place on the correct slot.

## How to play

1. Open **Module 1**
2. Go to **Phase 02 · Build** (or Assessment)
3. Tap a part in the bottom tray
4. Tap the matching slot button (or glowing 3D socket)
5. Wrong placements bounce with feedback; correct ones snap in

Guided mode highlights the next slot in yellow. Assessment has **no** yellow hints.

## Files

- `core/simulation/PcBuildBench.tscn` + `pc_build_bench.gd`
- `core/simulation/build_slot.gd`
- Module content: `sim_mode: "pc_build"` + `_install_step(...)` in `module_content_registry.gd`
- Shell wiring: `module_shell.gd`

## Controls

- Part tray: select part
- Slot buttons: reliable on phones
- 3D sockets: also clickable
- Right-drag / two-finger feel: orbit camera (mouse right/middle or screen drag)
