# Module 2 Models

**One folder = one teaching item.**

```
assets/models/module_2/
  _factory/           # procedural builders (not a part)
  modem/
  router/
  switch/
  hub/
  firewall/
  nic/
  access_point/
  repeater/
  ethernet_cable/
  fiber_cable/
  patch_panel/
  rj45/
  crimper/
  cable_tester/
  workstation/
  monitor/
  keyboard/
```

Each part folder contains:

| File | Purpose |
| --- | --- |
| `model.tscn` | Scene entry (`part_model.gd` + `part_id`) |
| `PART.txt` | Human label + category |
| `scene.gltf` | Optional Sketchfab replacement later |

## By category

### WAN Edge
| Folder | Item | Asset |
| --- | --- | --- |
| `modem/` | Modem / WAN CPE | `scene.gltf` (Sketchfab) |

### Core Network
| Folder | Item | Asset |
| --- | --- | --- |
| `router/` | Router | `scene.gltf` (Sketchfab) |
| `switch/` | Ethernet switch | `model.tscn` |
| `hub/` | Legacy hub | `model.tscn` |
| `firewall/` | Firewall appliance | `model.tscn` |
| `nic/` | Network interface card | `model.tscn` |

### Wireless
| Folder | Item |
| --- | --- |
| `access_point/` | Wireless AP |
| `repeater/` | Wi-Fi extender / repeater |

### Cabling
| Folder | Item |
| --- | --- |
| `ethernet_cable/` | Cat UTP + RJ45 |
| `fiber_cable/` | Fiber optic patch |
| `patch_panel/` | Patch panel |
| `rj45/` | RJ45 connector |

### Tools
| Folder | Item |
| --- | --- |
| `crimper/` | RJ45 crimper |
| `cable_tester/` | Cable / wire-map tester |

### Endpoints
| Folder | Item |
| --- | --- |
| `workstation/` | Client PC / laptop |
| `monitor/` | Display |
| `keyboard/` | Keyboard |

## Registry paths

`scripts/module_content_registry.gd` uses:

`res://assets/models/module_2/<folder>/model.tscn`
