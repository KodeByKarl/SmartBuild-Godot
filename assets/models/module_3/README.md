# Module 3 Models

Prefer Sketchfab `scene.gltf` when present; procedural `model.tscn` is fallback only.

| Folder | Device | Source |
| --- | --- | --- |
| server/ | File server / data-center rack | Sketchfab — David & 3D |
| nas/ | NAS appliance | Sketchfab — karakocyunus |
| mainframe/ | Multi-user server cluster reference | Sketchfab — themighty808 |
| ssd/ | Shared storage SSD | Sketchfab — isnainul |
| workstation/ | Client laptop (procedural fallback; registry uses Module 1 laptop glTF) | — |

Upload drop zone: `modules/module_3/models/` — copy into these folders, then point `ModuleContentRegistry` constants at `scene.gltf`.
