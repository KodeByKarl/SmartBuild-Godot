class_name ModuleContentRegistry
extends RefCounted

## Module 1 curated folders: res://assets/models/module_1/<part>/
## Prefer scene.gltf (Sketchfab) when present; otherwise model.tscn (procedural).
const MODEL_MOTHERBOARD := "res://assets/models/module_1/motherboard/scene.gltf"
const MODEL_CPU := "res://assets/models/module_1/cpu/scene.gltf"
const MODEL_RAM := "res://assets/models/module_1/ram/scene.gltf"
const MODEL_CHIPS := "res://assets/models/module_1/chips/model.tscn"
const MODEL_SSD := "res://assets/models/module_1/ssd/scene.gltf"
const MODEL_HDD := "res://assets/models/module_1/hdd/model.tscn"
const MODEL_FLASH := "res://assets/models/module_1/flash/scene.gltf"
const MODEL_PSU := "res://assets/models/module_1/psu/model.tscn"
const MODEL_ATX := "res://assets/models/module_1/atx/model.tscn"
const MODEL_CASE := "res://assets/models/module_1/case/scene.gltf"
const MODEL_FAN := "res://assets/models/module_1/fan/model.tscn"
const MODEL_ANTISTATIC := "res://assets/models/module_1/antistatic/model.tscn"
const MODEL_SCREWDRIVER := "res://assets/models/module_1/screwdriver/scene.gltf"
const MODEL_MONITOR := "res://assets/models/module_1/monitor/scene.gltf"
const MODEL_KEYBOARD := "res://assets/models/module_1/keyboard/scene.gltf"
const MODEL_MOUSE := "res://assets/models/module_1/mouse/scene.gltf"
const MODEL_LAPTOP_M1 := "res://assets/models/module_1/laptop/scene.gltf"
const MODEL_ROUTER := "res://assets/models/module_1/router/model.tscn"
const MODEL_GPU := "res://assets/models/module_1/gpu/model.tscn"

## Module 2 network devices — prefer scene.gltf when present; else model.tscn
const MODEL_MODEM := "res://assets/models/module_2/modem/scene.gltf"
const MODEL_SWITCH := "res://assets/models/module_2/switch/model.tscn"
const MODEL_ACCESS_POINT := "res://assets/models/module_2/access_point/model.tscn"
const MODEL_ETHERNET_CABLE := "res://assets/models/module_2/ethernet_cable/model.tscn"
const MODEL_ROUTER_M2 := "res://assets/models/module_2/router/scene.gltf"
const MODEL_HUB := "res://assets/models/module_2/hub/model.tscn"
const MODEL_NIC := "res://assets/models/module_2/nic/model.tscn"
const MODEL_REPEATER := "res://assets/models/module_2/repeater/model.tscn"
const MODEL_FIREWALL := "res://assets/models/module_2/firewall/model.tscn"
const MODEL_FIBER_CABLE := "res://assets/models/module_2/fiber_cable/model.tscn"
const MODEL_PATCH_PANEL := "res://assets/models/module_2/patch_panel/model.tscn"
const MODEL_RJ45 := "res://assets/models/module_2/rj45/model.tscn"
const MODEL_CRIMPER := "res://assets/models/module_2/crimper/model.tscn"
const MODEL_CABLE_TESTER := "res://assets/models/module_2/cable_tester/model.tscn"
const MODEL_WORKSTATION_M2 := "res://assets/models/module_1/laptop/scene.gltf"
const MODEL_MONITOR_M2 := "res://assets/models/module_2/monitor/model.tscn"
const MODEL_KEYBOARD_M2 := "res://assets/models/module_2/keyboard/model.tscn"

## Module 3 server devices — Sketchfab glTF uploads
const MODEL_SERVER := "res://assets/models/module_3/server/scene.gltf"
const MODEL_NAS := "res://assets/models/module_3/nas/scene.gltf"
const MODEL_WORKSTATION_M3 := "res://assets/models/module_1/laptop/scene.gltf"
const MODEL_SSD_M3 := "res://assets/models/module_3/ssd/scene.gltf"

## Module 4 maintenance references
const MODEL_TOOLKIT_M4 := "res://assets/models/module_4/toolkit/model.tscn"
const MODEL_DIAG_PC_M4 := "res://assets/models/module_4/diagnostic_pc/model.tscn"

## Shared models still used by Module 0 / other lessons
const MODEL_LAPTOP := "res://assets/models/module_1/laptop/scene.gltf"
const MODEL_TABLET := "res://assets/models/shared/ipad/scene.gltf"
const MODEL_MAINFRAME := "res://assets/models/module_3/mainframe/scene.gltf"
const MODEL_SUPERCOMPUTER := "res://assets/models/shared/super_computer/scene.gltf"
const MODEL_MINI_COMPUTER := "res://assets/models/shared/mini_computer/mini_computer.glb"


static func get_module(module_id: int) -> Dictionary:
	match module_id:
		1:
			return _build_module_1()
		2:
			return _build_module_2()
		3:
			return _build_module_3()
		4:
			return _build_module_4()
		_:
			return {}


static func get_supported_module_ids() -> Array[int]:
	return [1, 2, 3, 4]


static func _step(id: String, label: String, instruction: String, question: String = "", tip: String = "") -> Dictionary:
	return {
		"id": id,
		"label": label,
		"instruction": instruction,
		"question": question if question != "" else instruction,
		"tip": tip if tip != "" else instruction,
		"action": "tap",
		"target": id,
		"destination": ""
	}


## Crimping bench steps. `act` is CrimpLab's shared action vocabulary, so the
## straight-through and crossover stations can keep distinct step ids while
## driving the same bench.
static func _crimp_step(
	id: String,
	label: String,
	instruction: String,
	act: String,
	question: String = "",
	tip: String = ""
) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"instruction": instruction,
		"question": question if question != "" else instruction,
		"tip": tip if tip != "" else instruction,
		"action": "crimp",
		"target": act,
		"destination": ""
	}


static func _install_step(
	id: String,
	label: String,
	instruction: String,
	part_id: String,
	slot_id: String,
	question: String = "",
	tip: String = ""
) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"instruction": instruction,
		"question": question if question != "" else instruction,
		"tip": tip if tip != "" else instruction,
		"action": "install",
		"target": part_id,
		"destination": slot_id
	}


static func _remove_step(
	id: String,
	label: String,
	instruction: String,
	part_id: String,
	slot_id: String,
	question: String = "",
	tip: String = ""
) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"instruction": instruction,
		"question": question if question != "" else instruction,
		"tip": tip if tip != "" else instruction,
		"action": "remove",
		"target": part_id,
		"destination": slot_id
	}


static func _net_step(
	id: String,
	label: String,
	instruction: String,
	action: String,
	target: String,
	destination: String,
	question: String = "",
	tip: String = ""
) -> Dictionary:
	# Connect endpoints must be alphabetical to match NetworkLab ordering.
	var t := target
	var d := destination
	if action == "connect" and t > d:
		var tmp := t
		t = d
		d = tmp
	return {
		"id": id,
		"label": label,
		"instruction": instruction,
		"question": question if question != "" else instruction,
		"tip": tip if tip != "" else instruction,
		"action": action,
		"target": t,
		"destination": d
	}


static func _topo_step(
	id: String,
	label: String,
	instruction: String,
	action: String,
	target: String,
	destination: String,
	question: String = "",
	tip: String = ""
) -> Dictionary:
	var t := target
	var d := destination
	if action == "connect" and t > d:
		var tmp := t
		t = d
		d = tmp
	return {
		"id": id,
		"label": label,
		"instruction": instruction,
		"question": question if question != "" else instruction,
		"tip": tip if tip != "" else instruction,
		"action": action,
		"target": t,
		"destination": d
	}


static func _srv_step(
	id: String,
	label: String,
	instruction: String,
	action: String,
	target: String,
	destination: String = "",
	question: String = "",
	tip: String = ""
) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"instruction": instruction,
		"question": question if question != "" else instruction,
		"tip": tip if tip != "" else instruction,
		"action": action,
		"target": target,
		"destination": destination
	}


static func module_1_build_parts() -> Array:
	return [
		{"id": "psu", "label": "PSU", "scene_path": MODEL_PSU},
		{"id": "motherboard", "label": "Motherboard", "scene_path": MODEL_MOTHERBOARD},
		{"id": "cpu", "label": "CPU", "scene_path": MODEL_CPU},
		{"id": "cooler", "label": "CPU Cooler", "scene_path": MODEL_FAN},
		{"id": "ram", "label": "RAM", "scene_path": MODEL_RAM},
		{"id": "ssd", "label": "SSD", "scene_path": MODEL_SSD},
		{"id": "gpu", "label": "GPU", "scene_path": MODEL_GPU},
		{"id": "atx_24pin", "label": "24-pin ATX", "scene_path": MODEL_ATX},
		{"id": "cpu_power", "label": "CPU Power", "scene_path": MODEL_ATX},
		{"id": "fan_cable", "label": "Fan Cable", "scene_path": MODEL_FAN},
		{"id": "front_wires", "label": "Front Panel", "scene_path": MODEL_SCREWDRIVER},
		{"id": "side_panel", "label": "Side Panel", "scene_path": MODEL_CASE}
	]


static func _model_item(
	title: String,
	summary: String,
	details: String,
	scene_path: String,
	status: String,
	source_label: String,
	source_url: String = "",
	category: String = "Hardware",
	fun_fact: String = "",
	tip: String = ""
) -> Dictionary:
	return {
		"title": title,
		"summary": summary,
		"details": details,
		"scene_path": scene_path,
		"status": status,
		"source_label": source_label,
		"source_url": source_url,
		"category": category,
		"fun_fact": fun_fact if fun_fact != "" else details,
		"tip": tip if tip != "" else "Follow ESD safety and check orientation markers before installing."
	}


static func _module_1_models() -> Array:
	return [
		_model_item("Motherboard", "Central board connecting CPU, RAM, storage, and peripherals.", "Houses chipset, BIOS/UEFI, power regulation, and expansion slots.", MODEL_MOTHERBOARD, "ready", "Sketchfab — tommy.grzembke", "https://sketchfab.com/3d-models/motherboard-09eada6916bd438489a73a7e1326e8e1", "Core Parts", "Every component in the PC talks through the motherboard first.", "Align the rear I/O shield before seating the board on standoffs."),
		_model_item("CPU", "The processor that fetches, decodes, and executes instructions.", "Performance depends on cores, clock speed, cache, and cooling.", MODEL_CPU, "ready", "Sketchfab — AquaEquinox (Intel 486DX)", "https://sketchfab.com/3d-models/intel-486dx-50mhz-cpu-bd937cf82d0e4da18d9a73759b2995fa", "Core Parts", "A CPU can perform billions of cycles per second while staying smaller than a cookie.", "Match the socket type and never force the lever closed."),
		_model_item("Memory (RAM)", "High-speed temporary storage for active programs and data.", "Must match motherboard generation and slot configuration.", MODEL_RAM, "ready", "Existing repo asset", "", "Core Parts", "RAM forgets everything the moment power is removed.", "Seat modules until both side latches click firmly."),
		_model_item("Chips", "Controllers and firmware chips that manage board features.", "Includes chipset and BIOS storage on the motherboard.", MODEL_CHIPS, "ready", "SmartBuild procedural", "", "Core Parts", "Tiny black chips quietly manage USB, SATA, audio, and boot firmware.", "Never pry chips off the board; they are soldered permanently."),
		_model_item("SSD", "Fast solid-state storage for OS and applications.", "No moving parts; SATA or NVMe interfaces are common.", MODEL_SSD, "ready", "Sketchfab — isnainul", "https://sketchfab.com/3d-models/ssd-solid-state-drive-ad215e54c381456895e21db5062f8714", "Storage", "An SSD can feel several times snappier than a spinning hard drive.", "Secure the drive before connecting SATA power and data cables."),
		_model_item("Graphics Card (GPU)", "Discrete expansion card for display output and acceleration.", "Installs in a PCIe x16 slot and may need dedicated PSU connectors.", MODEL_GPU, "ready", "SmartBuild procedural", "", "Core Parts", "A GPU can draw more power than the rest of the board combined.", "Seat the card fully, lock the retention clip, then secure the rear bracket."),
		_model_item("HDD", "Magnetic storage for bulk capacity at lower cost per GB.", "Slower than SSD and more sensitive to physical shock.", MODEL_HDD, "ready", "SmartBuild procedural", "", "Storage", "Inside an HDD, a read head floats on a cushion of air above spinning platters.", "Handle carefully — drops can destroy the drive instantly."),
		_model_item("Flash Drive", "Portable USB storage used for OS installers and file transfer.", "Shock-resistant and easy to lose because of its small size.", MODEL_FLASH, "ready", "Sketchfab — trashbinkr", "https://sketchfab.com/3d-models/simple-virus-usb-flash-fcbe5f15b47446de92e9f7053818cae5", "Storage", "Technicians often keep a trusted bootable USB for installations and repairs.", "Label installer sticks so the wrong image is never used."),
		_model_item("Power Supply", "Converts AC mains power into regulated DC rails.", "Wattage and connector layout must support the build.", MODEL_PSU, "ready", "SmartBuild procedural", "", "Power & Case", "The PSU is the heart of power delivery for every rail in the system.", "Mount with the fan facing the correct airflow direction."),
		_model_item("24-pin ATX Connector", "Primary motherboard power connector.", "Delivers multiple voltage rails and standby power.", MODEL_ATX, "ready", "SmartBuild procedural", "", "Power & Case", "A loose 24-pin connector can cause random shutdowns that look like software bugs.", "Push until the latch clicks — then tug-test gently."),
		_model_item("Computer Case", "Enclosure that mounts and protects internal components.", "Form factor must match motherboard and cooling needs.", MODEL_CASE, "ready", "Sketchfab — Meilov", "https://sketchfab.com/3d-models/pc-model-ef80b29ad9f94dfc9af23db81e09de2b", "Power & Case", "Good cable routing inside the case can drop temperatures by improving airflow.", "Install standoffs that match the motherboard holes exactly."),
		_model_item("Cooling Fan", "Moves air across heatsinks and chassis vents.", "Proper airflow prevents thermal throttling and failure.", MODEL_FAN, "ready", "SmartBuild procedural", "", "Power & Case", "Fans can spin thousands of RPM while staying quieter than a conversation.", "Connect the CPU fan header before first power-on."),
		_model_item("Anti-static Kit", "Wrist strap and mat for ESD protection during handling.", "Required before touching boards, CPU, or RAM.", MODEL_ANTISTATIC, "ready", "SmartBuild detailed procedural", "", "Tools", "A tiny static spark you cannot feel can silently kill a CPU or RAM stick.", "Clip the strap to unpainted metal and wear it for the whole build."),
		_model_item("Screwdriver", "Essential hand tool for case screws and brackets.", "Flathead and Phillips are both common in PC work.", MODEL_SCREWDRIVER, "ready", "Sketchfab — lonesomeducky", "https://sketchfab.com/3d-models/flathead-screwdriver-47caeec407594d4b8995f4c046e047f4", "Tools", "Most PC builds still come down to careful screwdriver work and patience.", "Use the right bit size to avoid stripping motherboard screws."),
		_model_item("Monitor", "Display output used during BIOS and OS setup.", "Needed to verify POST and installer progress.", MODEL_MONITOR, "ready", "Sketchfab — Charckes", "https://sketchfab.com/3d-models/psx-monitor-09c0a050919f42248e3848d5bd837fbe", "Peripherals", "No display after power-on is one of the most common first-boot troubleshooting cases.", "Try the motherboard video output before assuming GPU failure."),
		_model_item("Keyboard", "Primary input device for BIOS and OS installation.", "Required before firmware and installer navigation.", MODEL_KEYBOARD, "ready", "Sketchfab — Flexryhe", "https://sketchfab.com/3d-models/mechanical-keyboard-95d050e7a5954ff6ac7fbe4ac5301b3c", "Peripherals", "BIOS keys differ by brand — Del, F2, and Esc are the usual suspects.", "Keep a wired keyboard handy for firmware setup."),
		_model_item("Mouse", "Pointing device used after the desktop environment loads.", "Useful for GUI setup and driver installation.", MODEL_MOUSE, "ready", "Sketchfab — WeSVa", "https://sketchfab.com/3d-models/computer-mouse-bdf0433b65d943eebb35598e4f155150", "Peripherals", "Optical mice track surface texture thousands of times per second.", "Have one ready once the OS installer reaches the desktop stage."),
		_model_item("Laptop Reference", "Portable form factor sharing the same core concepts.", "Useful for comparing desktop assembly concepts to notebooks.", MODEL_LAPTOP_M1, "ready", "Sketchfab — Gonsaku", "https://sketchfab.com/3d-models/laptop-603062a9eae348b99c8f34533c201964", "Peripherals", "Laptops pack CPU, RAM, storage, and cooling into a much tighter thermal envelope.", "Use this as a reminder that the same parts appear in different form factors.")
	]


## Fast Parts Lab — one tiny procedural scene + part_id (no Sketchfab glTF).
const MODEL_LAB_PART := "res://assets/models/module_1/_factory/part_model.tscn"


static func _lab_item(
	title: String,
	summary: String,
	details: String,
	part_id: String,
	category: String,
	fun_fact: String,
	tip: String
) -> Dictionary:
	var item := _model_item(
		title, summary, details, MODEL_LAB_PART, "ready",
		"SmartBuild procedural", "", category, fun_fact, tip
	)
	item["part_id"] = part_id
	return item


static func _module_1_lab_models() -> Array:
	return [
		_lab_item("Motherboard", "Central board connecting CPU, RAM, storage, and peripherals.", "Houses chipset, BIOS/UEFI, power regulation, and expansion slots.", "motherboard", "Core Parts", "Every component in the PC talks through the motherboard first.", "Align the rear I/O shield before seating the board on standoffs."),
		_lab_item("CPU", "The processor that fetches, decodes, and executes instructions.", "Performance depends on cores, clock speed, cache, and cooling.", "cpu", "Core Parts", "A CPU can perform billions of cycles per second while staying smaller than a cookie.", "Match the socket type and never force the lever closed."),
		_lab_item("Memory (RAM)", "High-speed temporary storage for active programs and data.", "Must match motherboard generation and slot configuration.", "ram", "Core Parts", "RAM forgets everything the moment power is removed.", "Seat modules until both side latches click firmly."),
		_lab_item("Chips", "Controllers and firmware chips that manage board features.", "Includes chipset and BIOS storage on the motherboard.", "chips", "Core Parts", "Tiny black chips quietly manage USB, SATA, audio, and boot firmware.", "Never pry chips off the board; they are soldered permanently."),
		_lab_item("SSD", "Fast solid-state storage for OS and applications.", "No moving parts; SATA or NVMe interfaces are common.", "ssd", "Storage", "An SSD can feel several times snappier than a spinning hard drive.", "Secure the drive before connecting SATA power and data cables."),
		_lab_item("Graphics Card (GPU)", "Discrete expansion card for display output and acceleration.", "Installs in a PCIe x16 slot and may need dedicated PSU connectors.", "gpu", "Core Parts", "A GPU can draw more power than the rest of the board combined.", "Seat the card fully, lock the retention clip, then secure the rear bracket."),
		_lab_item("HDD", "Magnetic storage for bulk capacity at lower cost per GB.", "Slower than SSD and more sensitive to physical shock.", "hdd", "Storage", "Inside an HDD, a read head floats on a cushion of air above spinning platters.", "Handle carefully — drops can destroy the drive instantly."),
		_lab_item("Flash Drive", "Portable USB storage used for OS installers and file transfer.", "Shock-resistant and easy to lose because of its small size.", "flash", "Storage", "Technicians often keep a trusted bootable USB for installations and repairs.", "Label installer sticks so the wrong image is never used."),
		_lab_item("Power Supply", "Converts AC mains power into regulated DC rails.", "Wattage and connector layout must support the build.", "psu", "Power & Case", "The PSU is the heart of power delivery for every rail in the system.", "Mount with the fan facing the correct airflow direction."),
		_lab_item("24-pin ATX Connector", "Primary motherboard power connector.", "Delivers multiple voltage rails and standby power.", "atx", "Power & Case", "A loose 24-pin connector can cause random shutdowns that look like software bugs.", "Push until the latch clicks — then tug-test gently."),
		_lab_item("Computer Case", "Enclosure that mounts and protects internal components.", "Form factor must match motherboard and cooling needs.", "case", "Power & Case", "Good cable routing inside the case can drop temperatures by improving airflow.", "Install standoffs that match the motherboard holes exactly."),
		_lab_item("Cooling Fan", "Moves air across heatsinks and chassis vents.", "Proper airflow prevents thermal throttling and failure.", "fan", "Power & Case", "Fans can spin thousands of RPM while staying quieter than a conversation.", "Connect the CPU fan header before first power-on."),
		_lab_item("Anti-static Kit", "Wrist strap and mat for ESD protection during handling.", "Required before touching boards, CPU, or RAM.", "antistatic", "Tools", "A tiny static spark you cannot feel can silently kill a CPU or RAM stick.", "Clip the strap to unpainted metal and wear it for the whole build."),
		_lab_item("Screwdriver", "Essential hand tool for case screws and brackets.", "Flathead and Phillips are both common in PC work.", "screwdriver", "Tools", "Most PC builds still come down to careful screwdriver work and patience.", "Use the right bit size to avoid stripping motherboard screws."),
		_lab_item("Monitor", "Display output used during BIOS and OS setup.", "Needed to verify POST and installer progress.", "monitor", "Peripherals", "No display after power-on is one of the most common first-boot troubleshooting cases.", "Try the motherboard video output before assuming GPU failure."),
		_lab_item("Keyboard", "Primary input device for BIOS and OS installation.", "Required before firmware and installer navigation.", "keyboard", "Peripherals", "BIOS keys differ by brand — Del, F2, and Esc are the usual suspects.", "Keep a wired keyboard handy for firmware setup."),
		_lab_item("Mouse", "Pointing device used after the desktop environment loads.", "Useful for GUI setup and driver installation.", "mouse", "Peripherals", "Optical mice track surface texture thousands of times per second.", "Have one ready once the OS installer reaches the desktop stage."),
		_lab_item("Laptop Reference", "Portable form factor sharing the same core concepts.", "Useful for comparing desktop assembly concepts to notebooks.", "laptop", "Peripherals", "Laptops pack CPU, RAM, storage, and cooling into a much tighter thermal envelope.", "Use this as a reminder that the same parts appear in different form factors.")
	]


static func _build_module_1() -> Dictionary:
	return {
		"id": 1,
		"title": "Installing and Configuring Computer Systems",
		"subtitle": "Module 1",
		"pages": [
			{
				"type": "hero",
				"eyebrow": "Module 1 · CSS NC II Unit 1",
				"title": "Installing and Configuring Computer Systems",
				"subtitle": "From an ESD-safe bench to a tested office workstation.",
				"description": "Follow the TESDA CSS NC II Unit 1 path: prepare safely, assemble hardware, configure BIOS, install the OS, then validate and document. Guided Simulation uses yellow hints; Assessment Simulation is the same pages without guides.",
				"bullets": [
					"Phase 01 — Prep an ESD-safe bench and verify parts before handling silicon.",
					"Phase 02 — Assemble the tower in technician-safe order on the live build bench.",
					"Phase 03 — Confirm BIOS detection and set boot priority for the installer.",
					"Phase 04 — Install the OS from media and create the first user profile.",
					"Phase 05 — Load drivers, test I/O, and document a deployment-ready PC.",
					"Finish Guided to unlock Assessment (same path, no guides)."
				]
			},
			{
				"type": "model_library",
				"eyebrow": "Parts Lab",
				"title": "Inspect the Hardware First",
				"description": "Orbit each part’s own model from its folder (gltf / procedural). Filter by category and read technician tips as you explore.",
				"items": _module_1_models()
			},
			{
				"type": "guided_simulation",
				"eyebrow": "Phase 01 · Prep",
				"title": "ESD-Safe Preparation",
				"description": "Protect the hardware before assembly. Ground yourself, clear the bench, and confirm tools and parts are ready.",
				"completion_message": "Bench is ESD-safe. Move on to hardware assembly.",
				"related_models": ["Anti-static Kit", "Screwdriver"],
				"steps": [
					_step("wear_strap", "Wear anti-static wrist strap", "Clip the strap to unpainted metal and wear it before touching boards.", "You arrive at the bench with a sealed motherboard. What do you put on first to discharge static safely?", "ESD damage is invisible — strap on before silicon."),
					_step("prepare_mat", "Lay out the anti-static mat", "Create a dissipative surface for the motherboard, CPU, and RAM.", "Where should boards and modules rest while you work?", "Never rest a board on a painted desk or cardboard alone."),
					_step("gather_tools", "Stage screwdriver and fasteners", "Keep the correct bits and screws within reach before opening the case.", "Which tool set should already be on the bench before you open the chassis?", "Wrong bit size strips motherboard screws."),
					_step("inspect_parts", "Inspect delivered components", "Look for bent pins, cracked PCB edges, and missing accessories.", "What visual check comes before any installation?", "Catch DOA damage before you seat expensive parts."),
					_step("verify_compat", "Confirm compatibility", "Match CPU socket, RAM generation, form factor, and PSU wattage.", "What must match the board and case before you start mounting?", "Socket and RAM generation mistakes waste the whole build."),
					_step("prep_workspace", "Organize the workspace", "Clear clutter and arrange parts in install order.", "How should the bench look before Phase 02 assembly?", "A clear bench reduces dropped screws and ESD risk.")
				]
			},
			{
				"type": "guided_simulation",
				"sim_mode": "pc_build",
				"eyebrow": "Phase 02 · Build",
				"title": "Hardware Assembly",
				"description": "Build the PC on the bench: select each part, then place it on the correct slot. Yellow marks the next guided step.",
				"completion_message": "Tower assembly complete. Connect peripherals and enter firmware next.",
				"related_models": ["Computer Case", "Motherboard", "CPU", "Graphics Card (GPU)"],
				"build_parts": module_1_build_parts(),
				"steps": [
					_install_step("install_psu", "Install the power supply", "Mount the PSU in the PSU bay with airflow facing the vent.", "psu", "psu_bay", "Where does the power supply mount in the chassis?", "Seat the PSU before the board so cables have room."),
					_install_step("mount_board", "Seat the motherboard", "Lower the motherboard onto the board mount / standoff tray.", "motherboard", "board_mount", "Where does the motherboard sit?", "Standoffs must match every mounting hole."),
					_install_step("install_cpu", "Install the CPU", "Match the triangle marker and seat the CPU in the socket.", "cpu", "cpu_socket", "Where does the processor go?", "Never force the lever — alignment first."),
					_install_step("install_cooler", "Install the CPU cooler", "Mount the cooler evenly over the CPU.", "cooler", "cooler_mount", "What cools the processor after it is seated?", "Even pressure prevents socket damage."),
					_install_step("connect_fan", "Connect CPU fan header", "Plug the cooler fan into the CPU_FAN header.", "fan_cable", "fan_header", "Where does the fan cable attach on the board?", "CPU_FAN keeps the cooler spinning at POST."),
					_install_step("install_ram", "Install RAM modules", "Click the RAM into the DIMM slot until both latches catch.", "ram", "dimm_slot", "Where do memory sticks go?", "Both latches must click — half-seated RAM fails POST."),
					_install_step("install_storage", "Install storage drive", "Mount the SSD in the storage bay.", "ssd", "storage_bay", "Where does permanent storage mount?", "Secure the drive before data/power cables."),
					_install_step("install_gpu", "Install the graphics card", "Seat the GPU in the PCIe x16 slot and lock the retention clip.", "gpu", "pcie_slot", "Which expansion slot takes a discrete graphics card?", "Push until the PCIe latch clicks, then screw the bracket."),
					_install_step("main_power", "Connect 24-pin ATX", "Seat the main board power connector until it clicks.", "atx_24pin", "atx_socket", "What is the primary motherboard power plug?", "A loose 24-pin causes random shutdowns."),
					_install_step("cpu_power", "Connect CPU power", "Plug the 4/8-pin CPU power near the socket.", "cpu_power", "eps_socket", "Which extra power lead does the CPU need?", "Missing EPS power often means no POST."),
					_install_step("front_panel", "Wire front-panel headers", "Connect Power SW / Reset / LED wires to the front-panel header.", "front_wires", "front_panel", "What connects case buttons to the board?", "Check the board silkscreen for pin order."),
					_install_step("close_case", "Close the case", "Reinstall the side panel after internals and power are done.", "side_panel", "side_panel", "When do you close the chassis?", "Close only after power cables and cooling are finished.")
				]
			},
			{
				"type": "guided_simulation",
				"eyebrow": "Phase 03 · Firmware",
				"title": "BIOS Configuration",
				"description": "Power on with display and input attached. Confirm CPU, RAM, and storage detection, then set boot priority for the installer.",
				"completion_message": "Firmware is set. Boot the OS installer next.",
				"related_models": ["Monitor", "Keyboard", "Mouse"],
				"steps": [
					_step("connect_peripherals", "Connect display and input", "Attach monitor, keyboard, and mouse before first power-on.", "Before first power-on, which three peripherals must be connected to see and control POST?", "No display means you cannot confirm firmware at all."),
					_step("power_on", "Power on the system", "Confirm fans spin, lights respond, and the board attempts POST.", "What confirms the build has basic power after you press the power button?", "Fans and board LEDs are your first live checks."),
					_step("enter_bios", "Enter BIOS/UEFI setup", "Press the board's setup key (often Del or F2) at the prompt.", "How do you open firmware settings during POST?", "Setup keys differ by brand — watch the splash screen."),
					_step("verify_cpu", "Verify CPU detection", "Confirm the processor model appears on the main info page.", "In firmware, what should you verify first about the processor?", "Wrong or missing CPU info means seating or power issues."),
					_step("verify_ram", "Verify RAM detection", "Check total capacity and that all modules are recognized.", "What memory detail must look correct in BIOS?", "Half the expected capacity often means a stick is not latched."),
					_step("verify_storage", "Verify storage detection", "Confirm the target SSD/HDD is visible to firmware.", "Which drive must appear before you can install an OS?", "If storage is missing, check power/data cables first."),
					_step("boot_priority", "Set boot priority", "Place USB installer ahead of the internal OS drive.", "What boot order do you set for installation media?", "Installer media must outrank the blank internal drive."),
					_step("save_bios", "Save and exit", "Write changes and reboot into the installer path.", "How do you keep the new firmware settings?", "Save & Exit — otherwise boot order resets.")
				]
			},
			{
				"type": "guided_simulation",
				"eyebrow": "Phase 04 · OS",
				"title": "Operating System Install",
				"description": "Boot from installer media, prepare the target volume, and finish first-run account setup.",
				"completion_message": "OS is installed. Continue with drivers and validation.",
				"related_models": ["Flash Drive", "SSD"],
				"steps": [
					_step("insert_usb", "Insert bootable USB", "Use a known-good installer stick in a rear USB port.", "Which media starts the OS installer for this deployment?", "Prefer a rear motherboard USB port for installers."),
					_step("boot_media", "Boot from the USB", "Confirm the installer splash loads from removable media.", "After reboot with correct boot order, what should appear?", "If the desktop of an old OS loads, boot priority is wrong."),
					_step("install_settings", "Choose install options", "Set language, region, and edition before partitioning.", "Which installer choices come before the disk step?", "Edition and region affect licensing and locale."),
					_step("partitions", "Prepare partitions", "Select or create the target system volume.", "Where will the OS files live on the drive?", "Choose the intended system volume carefully."),
					_step("format_drive", "Format the target volume", "Create a clean filesystem for a fresh install.", "What prepares a clean destination for the OS files?", "Formatting wipes the selected volume — confirm the drive."),
					_step("install_os", "Run OS installation", "Copy system files and allow the reboot cycle to finish.", "Which step copies the operating system onto the volume?", "Do not remove media until the installer finishes reboots."),
					_step("create_user", "Create user account", "Set the initial local admin or standard profile.", "Who is the first account created on the machine?", "Use a strong password for the deployment account."),
					_step("initial_settings", "Finish first-run setup", "Complete privacy, network, and region prompts.", "What wraps up the out-of-box experience?", "Finish OOBE before driver and app packaging.")
				]
			},
			{
				"type": "guided_simulation",
				"eyebrow": "Phase 05 · Validate",
				"title": "Drivers and System Testing",
				"description": "Install board and device drivers, then prove display, network, and storage work before handover.",
				"completion_message": "Workstation validated. Ready for the assessment scenario.",
				"related_models": ["Monitor", "Laptop Reference"],
				"steps": [
					_step("mb_drivers", "Install motherboard drivers", "Chipset and board utilities first for stable device detection.", "Which driver pack should land first on a new board?", "Chipset first — other devices depend on it."),
					_step("gpu_drivers", "Install graphics drivers", "Stabilize resolution, refresh rate, and acceleration.", "What improves display output quality after the OS install?", "Vendor GPU drivers beat generic basic display."),
					_step("net_drivers", "Install network drivers", "Restore Ethernet/Wi-Fi so updates and apps can download.", "What restores LAN or Wi-Fi on a fresh install?", "Without NIC drivers you cannot pull updates."),
					_step("apps", "Install baseline applications", "Add the required productivity package for the user role.", "Which software set belongs on a new office PC?", "Install only licensed apps required by the client."),
					_step("test_display", "Test the display", "Confirm a stable image at the expected resolution.", "How do you prove the monitor path works?", "Check resolution and that the image stays stable."),
					_step("test_internet", "Test internet access", "Ping gateway/DNS and open an external page.", "How do you prove network connectivity before handover?", "Gateway ping plus a real page load."),
					_step("test_storage", "Test storage access", "Create and open a sample file on the system drive.", "How do you prove the drive is healthy for the user?", "Write and reopen a test file on the system volume."),
					_step("document_results", "Document the build", "Record serials, OS edition, and pass/fail checks for handover.", "What closes a professional deployment?", "Serials, OS edition, and test results for the client.")
				]
			},
			{
				"type": "assessment",
				"sim_mode": "pc_build",
				"eyebrow": "Capstone · Assessment",
				"title": "Fix the Assembly",
				"description": "A trainee rushed this build. The side panel is on, the PSU is still loose in the tray, RAM and storage are swapped, and CPU power was never connected. Open the case and fix every fault — no yellow hints.",
				"objectives": [
					"Open the case and remove every mis-seated part.",
					"Secure the PSU, reseat RAM in A1, and mount storage in the drive bay.",
					"Connect CPU power and close the case only when the build is correct."
				],
				"pitfalls": [
					"Trying to fix internals with the side panel still on",
					"Leaving RAM in the drive bay or storage in a DIMM slot",
					"Closing the case before CPU power is connected"
				],
				"completion_message": "Assessment passed. The faulty build is corrected and ready for POST.",
				"related_models": ["Computer Case", "Motherboard", "Memory (RAM)"],
				"build_parts": module_1_build_parts(),
				"seed_state": [
					{"part": "motherboard", "slot": "board_mount"},
					{"part": "cpu", "slot": "cpu_socket"},
					{"part": "cooler", "slot": "cooler_mount"},
					{"part": "fan_cable", "slot": "fan_header"},
					{"part": "ram", "slot": "storage_bay", "faulty": true},
					{"part": "ssd", "slot": "dimm_slot", "faulty": true},
					{"part": "atx_24pin", "slot": "atx_socket"},
					{"part": "front_wires", "slot": "front_panel"},
					{"part": "side_panel", "slot": "side_panel", "faulty": true}
				],
				"steps": [
					_remove_step("fix_open", "Open the case", "Remove the side panel before touching any internal part.", "side_panel", "side_panel", "", "The panel blocks every other bay."),
					_remove_step("fix_ram_wrong", "Remove misplaced RAM", "The module is sitting in the drive bay — pull it out.", "ram", "storage_bay", "", "RAM belongs in the A1 DIMM slot."),
					_remove_step("fix_ssd_wrong", "Remove SSD from the RAM slot", "Storage does not belong in a DIMM slot.", "ssd", "dimm_slot", "", "Clear A1 before reseating RAM."),
					_install_step("fix_psu", "Secure the PSU", "Mount the loose power supply in the PSU bay.", "psu", "psu_bay", "", "PSU must be screwed down before power leads."),
					_install_step("fix_ram", "Reseat RAM in A1", "Latch the module in the primary DIMM slot.", "ram", "dimm_slot", "", "Both latches must click."),
					_install_step("fix_ssd", "Mount the SSD", "Install storage in the drive cage.", "ssd", "storage_bay", "", "Secure the drive before closing up."),
					_install_step("fix_eps", "Connect CPU power", "Seat the EPS lead near the socket.", "cpu_power", "eps_socket", "", "Missing EPS often means no POST."),
					_install_step("fix_close", "Close the case", "Reinstall the side panel when every fault is corrected.", "side_panel", "side_panel", "", "Close only after power and cooling are finished.")
				]
			},
			{
				"type": "model_library",
				"eyebrow": "Parts Museum",
				"title": "Revisit Any Component",
				"description": "Filter Core Parts, Storage, Power & Case, Tools, or Peripherals and keep exploring the same uploaded models.",
				"items": _module_1_models()
			},
			{
				"type": "completion",
				"eyebrow": "Module 1 complete",
				"title": "Congratulations!",
				"subtitle": "You finished Installing and Configuring Computer Systems.",
				"description": "You prepared an ESD-safe bench, assembled a PC, configured BIOS, installed an OS, and validated the workstation for deployment — aligned with CSS NC II Unit 1 practice.",
				"achievements_title": "What you completed",
				"achievements": [
					"ESD-safe preparation and parts inspection",
					"Hardware assembly in technician-safe order",
					"BIOS detection and boot priority setup",
					"Operating system install and first user",
					"Drivers, testing, and handover documentation"
				],
				"button_label": "Back to Home"
			}
		]
	}


static func _module_2_models() -> Array:
	return [
		_model_item("Modem", "Brings WAN/internet service into the office.", "Converts ISP link (fiber/cable/DSL) into Ethernet for the router.", MODEL_MODEM, "ready", "Sketchfab — sinemmbagcioglu", "https://sketchfab.com/3d-models/modem-a91492359e664c3f8010a041b2d05de8", "WAN Edge", "The modem is the first box after the ISP drop — without it, nothing reaches the LAN.", "Confirm link lights before blaming the router."),
		_model_item("Router", "Routes traffic between the LAN and WAN.", "Often hosts DHCP, NAT, firewall, and sometimes Wi-Fi.", MODEL_ROUTER_M2, "ready", "Sketchfab — Gabriel_515", "https://sketchfab.com/3d-models/router-7f1319c36b9b4498b6ce726a22f78637", "Core Network", "Home and small-office routers combine routing, switching, and wireless in one box.", "Change the default admin password before going live."),
		_model_item("Switch", "Expands wired LAN ports for workstations and printers.", "Forwards frames between devices in the same broadcast domain.", MODEL_SWITCH, "ready", "SmartBuild procedural", "", "Core Network", "Unmanaged switches are plug-and-play; managed switches add VLANs and monitoring.", "Use straight-through cables from PC to switch in modern Auto-MDIX gear."),
		_model_item("Hub", "Legacy multiport repeater sharing one collision domain.", "Useful for comparing hubs versus modern switches.", MODEL_HUB, "ready", "SmartBuild procedural", "", "Core Network", "Hubs flood every port — prefer a switch for new installs.", "Replace hubs during office upgrades."),
		_model_item("Firewall", "Filters traffic based on security rules.", "Protects LAN services while allowing required ports.", MODEL_FIREWALL, "ready", "SmartBuild procedural", "", "Core Network", "Open only the ports the office actually needs.", "Document every rule change with the ticket."),
		_model_item("NIC", "Network interface that gives a host its Ethernet port.", "Onboard or PCIe/USB adapter with a unique MAC address.", MODEL_NIC, "ready", "SmartBuild procedural", "", "Core Network", "No link light often means cable, port, or driver — not always the router.", "Update NIC drivers after OS install."),
		_model_item("Access Point", "Extends wireless coverage for laptops and phones.", "Clients associate to an SSID and are bridged onto the LAN.", MODEL_ACCESS_POINT, "ready", "SmartBuild procedural", "", "Wireless", "A dedicated AP often covers better than a single router radio alone.", "Place APs high and clear of thick walls when possible."),
		_model_item("Repeater", "Regenerates a signal to extend wired or wireless reach.", "Wi-Fi extenders rebroadcast coverage when cabling a second AP is hard.", MODEL_REPEATER, "ready", "SmartBuild procedural", "", "Wireless", "Extenders can cut throughput — prefer a wired AP when possible.", "Place mid-way, not at the far dead zone."),
		_model_item("Ethernet Cable", "Physical medium for 100/1000 Mbps copper links.", "Terminated with RJ45 using T568A or T568B pinouts.", MODEL_ETHERNET_CABLE, "ready", "SmartBuild procedural", "", "Cabling", "A bad crimp looks fine until intermittent drops appear under load.", "Always continuity-test before dressing cables into a rack."),
		_model_item("Fiber Cable", "Glass strands that carry data as light.", "Used for long, high-speed, EMI-resistant uplinks.", MODEL_FIBER_CABLE, "ready", "SmartBuild procedural", "", "Cabling", "Dirty ferrules cause unexplained loss.", "Never look into live fiber; cap unused ports."),
		_model_item("Patch Panel", "Organizes horizontal cabling into labeled front ports.", "Techs patch panel-to-switch instead of hardwiring every drop.", MODEL_PATCH_PANEL, "ready", "SmartBuild procedural", "", "Cabling", "Mislabeling creates the longest troubleshooting delays.", "Update the port map whenever you move a patch."),
		_model_item("RJ45", "8P8C plug that terminates Ethernet cable ends.", "Gold contacts pierce conductors when crimped.", MODEL_RJ45, "ready", "SmartBuild procedural", "", "Cabling", "Wires must seat fully against the plug front before crimping.", "Use quality plugs matched to the cable category."),
		_model_item("Crimper", "Tool that terminates RJ45 plugs onto Cat cable.", "Locks contacts and optional strain relief in one press.", MODEL_CRIMPER, "ready", "SmartBuild procedural", "", "Tools", "Wrong die or incomplete crimp fails the wire map.", "Test every cable after crimping."),
		_model_item("Cable Tester", "Verifies pinout and continuity on Ethernet cables.", "Maps opens, shorts, and crossed pairs end-to-end.", MODEL_CABLE_TESTER, "ready", "SmartBuild procedural", "", "Tools", "Never install an untested field-terminated cable.", "Label both ends after a pass."),
		_model_item("Workstation", "Client endpoint used during setup and validation.", "Represents the desktop or laptop joining the office LAN.", MODEL_WORKSTATION_M2, "ready", "Sketchfab — Gonsaku", "https://sketchfab.com/3d-models/laptop-603062a9eae348b99c8f34533c201964", "Endpoints", "Every validation ping starts from a correctly addressed workstation.", "Note the NIC MAC if DHCP reservations are required."),
		_model_item("Monitor", "Display used while configuring network settings.", "Needed when validating IP configuration and connectivity.", MODEL_MONITOR_M2, "ready", "SmartBuild procedural", "", "Endpoints", "No display means you cannot confirm GUI router settings or Windows IP dialogs.", "Keep a spare HDMI/DP cable in the toolkit."),
		_model_item("Keyboard", "Input device for addressing and router setup.", "Used for CLI and GUI configuration tasks.", MODEL_KEYBOARD_M2, "ready", "SmartBuild procedural", "", "Endpoints", "BIOS and router recovery screens often need a wired keyboard.", "Prefer wired input when troubleshooting wireless issues.")
	]


static func _build_module_2() -> Dictionary:
	return {
		"id": 2,
		"title": "Setting Up Computer Networks",
		"subtitle": "Module 2",
		"pages": [
			{
				"type": "hero",
				"eyebrow": "Module 2 · Network Path",
				"title": "Setting Up Computer Networks",
				"subtitle": "A clean path from parts → cables → live topology.",
				"description": "Work through five stations: identify gear, build copper, wire a Packet Tracer–style LAN, then secure Wi-Fi. Guided Simulation uses hints; Assessment Simulation is the same pages without guides.",
				"bullets": [
					"01 Identify — modem, router, switch, AP, NIC, and cabling parts",
					"02 Straight-through — terminate and test T568B copper",
					"03 Crossover — build T568A/B and verify the wire map",
					"04 Network Workstation — cable, address, and ping the LAN",
					"05 Wireless — secure Wi-Fi and prove clients can join",
					"Finish Guided to unlock Assessment (same path, no guides)."
				]
			},
			{
				"type": "model_library",
				"eyebrow": "Station 0 · Parts Bench",
				"title": "Inspect Network Gear",
				"description": "Orbit each device before the guided stations. Learn the visual cues technicians use on the rack.",
				"items": _module_2_models()
			},
			{
				"type": "guided_simulation",
				"eyebrow": "Station 01 · Identify",
				"title": "Identify Network Components",
				"description": "Name each box and cabling part and state its job before any cable is made.",
				"completion_message": "Parts are clear. Move to Station 02 — straight-through cable.",
				"related_models": ["Modem", "Router", "Switch", "Access Point"],
				"steps": [
					_step("identify_modem", "Identify the modem", "Find the WAN edge device that terminates the ISP circuit.", "Which device brings internet service into the office?"),
					_step("identify_router", "Identify the router", "This device routes between LAN and WAN and usually runs DHCP/NAT.", "Which device decides how traffic leaves the local network?"),
					_step("identify_switch", "Identify the switch", "Use the multi-port box that expands wired LAN ports.", "Which device adds more Ethernet ports for PCs and printers?"),
					_step("identify_ap", "Identify the access point", "Wireless clients join through this radio bridge onto the LAN.", "Which device extends Wi-Fi coverage for mobile clients?"),
					_step("identify_nic", "Identify the network interface card", "Find the NIC or onboard Ethernet port that connects the workstation to copper.", "Which component gives the PC its wired network port?"),
					_step("identify_utp", "Identify UTP cable", "Select unshielded twisted-pair Cat cable used for Ethernet runs.", "Which cable type carries typical office Ethernet?"),
					_step("identify_rj45", "Identify RJ45 connectors", "Recognize the 8P8C plugs that terminate Ethernet ends.", "What connector terminates each end of the cable?"),
					_step("map_roles", "Match roles on the topology sketch", "Label modem → router → switch → AP before physical install.", "What order should the core boxes appear on your sketch?")
				]
			},
			{
				"type": "guided_simulation",
				"sim_mode": "crimp_lab",
				"end_a": "t568b",
				"end_b": "t568b",
				"eyebrow": "Station 02 · Straight-Through",
				"title": "Create a Straight-Through Cable",
				"description": "Terminate Cat cable to T568B on both ends, crimp, and prove continuity.",
				"completion_message": "Straight-through ready. Move to Station 03 — crossover cable.",
				"related_models": ["Ethernet Cable", "Switch", "Workstation"],
				"steps": [
					_crimp_step("select_utp", "Select UTP cable", "Pick the Cat 6 stock for the workstation-to-switch run.", "select_cable", "Which cable stock do you start with?"),
					_crimp_step("strip_jacket", "Strip the cable jacket", "Take about 25 mm of jacket off without nicking the conductors.", "strip_jacket", "What do you remove first from the Cat cable?"),
					_crimp_step("untwist_pairs", "Untwist and fan the pairs", "Separate the four pairs so the eight conductors can be ordered.", "untwist_pairs", "What has to happen before the wires can be laid in order?"),
					_crimp_step("order_end_a", "Lay End A out to T568B", "Pin 1 white/orange, 2 orange, 3 white/green, 4 blue, 5 white/blue, 6 green, 7 white/brown, 8 brown. Tap a conductor, then tap its pin.", "order_end_a", "Which wiring standard does a straight-through use on both ends?"),
					_crimp_step("insert_end_a", "Seat End A in the RJ45", "Push all eight conductors to the front of the plug with the jacket inside the shell.", "insert_end_a", "Where do the ordered conductors go before crimping?"),
					_crimp_step("crimp_end_a", "Crimp End A", "Squeeze until the contacts pierce the insulation and the strain relief bites.", "crimp_end_a", "What tool permanently attaches the connector?"),
					_crimp_step("order_end_b", "Lay End B out to T568B", "Switch to End B and repeat the same T568B sequence — that is what makes it straight-through.", "order_end_b", "How should the second plug be wired?"),
					_crimp_step("insert_end_b", "Seat End B in the RJ45", "Same seating check on the far plug: eight conductors flush to the front.", "insert_end_b", "What do you verify before crimping the second plug?"),
					_crimp_step("crimp_end_b", "Crimp End B", "Lock the second plug so both ends are finished.", "crimp_end_b", "What completes the physical cable?"),
					_crimp_step("test_cable", "Test the cable", "Run the wire map. Every pin must land on the same pin at the far end.", "test_cable", "What proves the cable is safe to install?")
				]
			},
			{
				"type": "guided_simulation",
				"sim_mode": "crimp_lab",
				"end_a": "t568a",
				"end_b": "t568b",
				"eyebrow": "Station 03 · Crossover",
				"title": "Create a Crossover Cable",
				"description": "Build T568A on one end and T568B on the other, then verify the crossed wire map.",
				"completion_message": "Crossover ready. Open Station 04 — Network Workstation.",
				"related_models": ["Ethernet Cable", "Switch", "Workstation"],
				"steps": [
					_crimp_step("x_select_utp", "Select UTP cable", "Same Cat 6 stock — only the pin order changes for a crossover.", "select_cable", "What is different about the cable stock for a crossover?"),
					_crimp_step("x_strip_jacket", "Strip the cable jacket", "Expose the pairs cleanly before arranging two different standards.", "strip_jacket", "What preparation is shared with straight-through builds?"),
					_crimp_step("x_untwist_pairs", "Untwist and fan the pairs", "Separate the four pairs on the end you are about to terminate.", "untwist_pairs", "What has to happen before the wires can be laid in order?"),
					_crimp_step("x_order_a", "Lay End A out to T568A", "Pin 1 white/green, 2 green, 3 white/orange, 4 blue, 5 white/blue, 6 orange, 7 white/brown, 8 brown.", "order_end_a", "Which standard goes on the first end of a crossover?"),
					_crimp_step("x_insert_a", "Seat End A in the RJ45", "Eight conductors to the front of the plug, jacket inside the shell.", "insert_end_a", "What do you check before crimping the A end?"),
					_crimp_step("x_crimp_a", "Crimp the T568A end", "Lock the A sequence into the plug.", "crimp_end_a", "What finishes the first crossover end?"),
					_crimp_step("x_order_b", "Lay End B out to T568B", "Switch to End B and swap the orange and green pairs relative to the A end.", "order_end_b", "Which standard goes on the second end of a crossover?"),
					_crimp_step("x_insert_b", "Seat End B in the RJ45", "Seat the B sequence the same way before crimping.", "insert_end_b", "What do you verify on the second plug?"),
					_crimp_step("x_crimp_b", "Crimp the T568B end", "Finish the B end so transmit and receive pairs are crossed.", "crimp_end_b", "What completes the physical crossover cable?"),
					_crimp_step("x_test_cable", "Test the crossover cable", "The wire map must show 1–3, 2–6, 3–1 and 6–2, not a straight path.", "test_cable", "What proves the crossover is wired correctly?")
				]
			},
			{
				"type": "guided_simulation",
				"sim_mode": "network_lab",
				"eyebrow": "Station 04 · Network Workstation",
				"title": "Small-Office Network Lab",
				"description": "Cable the topology, apply PC1 addressing, then ping the gateway.",
				"completion_message": "LAN path validated. Continue to Station 05 — wireless concepts.",
				"related_models": ["Workstation", "Switch", "Router", "Modem", "Access Point"],
				"steps": [
					_net_step("modem_to_router", "Cable modem to router", "Link the modem to the router WAN/edge side.", "connect", "modem", "router", "Which two devices start the WAN edge path?", "Straight-through: click Modem, then Router."),
					_net_step("router_to_switch", "Cable router to switch", "Uplink the router LAN side into the switch.", "connect", "router", "switch", "How does the switch join the router LAN?", "Straight-through: Router ↔ Switch."),
					_net_step("pc_to_switch", "Cable PC1 to switch", "Patch the workstation into an access port on the switch.", "connect", "pc1", "switch", "Where does the workstation Ethernet land?", "Straight-through: PC1 ↔ Switch."),
					_net_step("ap_to_switch", "Cable AP to switch", "Connect the access point onto the LAN switch.", "connect", "ap", "switch", "How does the AP join the wired LAN?", "Straight-through: Access Point ↔ Switch."),
					_net_step("pc_to_pc_crossover", "Bench-test PC1 to PC2 directly", "Two end devices with no switch between them need the crossover you built in Station 03.", "connect", "pc1", "pc2", "Which cable joins two end devices back to back?", "Set cable type to Crossover, then click PC1 and PC2."),
					_net_step("set_host_ip", "Apply PC1 addressing", "Select PC1 and Apply IP 192.168.1.10 / mask / gateway 192.168.1.1 / DNS.", "configure", "pc1", "addressing", "Which host needs IP, mask, gateway, and DNS?", "Select PC1 → Apply to Selected PC."),
					_net_step("ping_gateway", "Ping the default gateway", "From PC1, ping 192.168.1.1.", "ping", "pc1", "192.168.1.1", "What first ICMP target validates local routing?", "Keep all cables in place, then Ping.")
				]
			},
			{
				"type": "guided_simulation",
				"eyebrow": "Station 05 · Wireless",
				"title": "Wireless Configuration",
				"description": "Set SSID and security, then join a client to the office Wi-Fi.",
				"completion_message": "Wireless covered. Ready for the office assessment.",
				"related_models": ["Access Point", "Router", "Workstation"],
				"steps": [
					_step("access_router_wifi", "Access router / AP settings", "Open the admin page for wireless configuration.", "Where do you change SSID and security settings?"),
					_step("set_ssid", "Configure the SSID", "Choose a clear network name that matches office standards.", "What is the wireless network name clients will see?"),
					_step("set_wifi_password", "Set the wireless password", "Use a strong passphrase that meets office policy.", "What credential do clients need to join?"),
					_step("set_wifi_security", "Configure wireless security", "Use WPA2-Personal or WPA3 — never leave the SSID open.", "Which wireless security mode should you apply?"),
					_step("join_client", "Connect a wireless device", "Associate a laptop/phone and confirm it receives an address.", "How do you prove Wi-Fi clients can join?")
				]
			},
			{
				"type": "assessment",
				"sim_mode": "crossover_task",
				"end_a": "t568a",
				"end_b": "t568b",
				"eyebrow": "Capstone · Assessment",
				"title": "Create a Crossover Connector",
				"description": "Two workstations need a direct link with no switch between them. Build the connector, cable them, and prove the link — no reference colours, no guided highlights.",
				"objectives": [
					"Terminate one plug to T568A and the other to T568B from memory.",
					"Prove the wire map crosses before leaving the bench.",
					"Cable PC1 to PC2 with that crossover, address both hosts, and ping across."
				],
				"pitfalls": [
					"Same standard on both plugs",
					"Crimping before every pin is seated",
					"Straight-through between two end devices",
					"Pinging before both hosts are addressed"
				],
				"completion_message": "Assessment passed. You built a crossover connector and proved it carries traffic between two workstations.",
				"related_models": ["Ethernet Cable", "Workstation", "Switch"],
				"steps": [
					_crimp_step("xt_select", "Select UTP cable", "Take the Cat 6 stock to the bench.", "select_cable", "", "Start at tool 1."),
					_crimp_step("xt_strip", "Strip the cable jacket", "Expose the pairs without nicking a conductor.", "strip_jacket", "", "Tool 2."),
					_crimp_step("xt_fan", "Untwist and fan the pairs", "Separate all four pairs.", "untwist_pairs", "", "Tool 3."),
					_crimp_step("xt_order_a", "Terminate End A", "One plug of a crossover uses T568A. Lay the eight conductors from memory.", "order_end_a", "", "Green pair leads on this end."),
					_crimp_step("xt_insert_a", "Seat End A", "All eight conductors flush to the front of the plug.", "insert_end_a", "", "Tool 4."),
					_crimp_step("xt_crimp_a", "Crimp End A", "Lock the first plug.", "crimp_end_a", "", "Tool 5."),
					_crimp_step("xt_order_b", "Terminate End B", "The other plug uses T568B — the orange and green pairs swap.", "order_end_b", "", "Switch to End B first."),
					_crimp_step("xt_insert_b", "Seat End B", "Same seating check on the far plug.", "insert_end_b", "", "Tool 4."),
					_crimp_step("xt_crimp_b", "Crimp End B", "Lock the second plug.", "crimp_end_b", "", "Tool 5."),
					_crimp_step("xt_test", "Certify the cable", "The tester must report a crossover, not a straight-through.", "test_cable", "", "Tool 6."),
					_net_step("xt_link", "Cable PC1 to PC2", "Take the finished cable to the site and join the two workstations directly.", "connect", "pc1", "pc2", "", "Set the cable type to Crossover, then click PC1 and PC2."),
					_net_step("xt_ip_pc1", "Address PC1", "Give PC1 a host address on the link.", "configure", "pc1", "addressing", "", "Select PC1, then Apply to Selected PC."),
					_net_step("xt_ip_pc2", "Address PC2", "PC2 needs an address in the same subnet or nothing will answer.", "configure", "pc2", "addressing", "", "Select PC2, then Apply to Selected PC."),
					_net_step("xt_ping", "Prove the link", "Ping PC2 from PC1.", "ping", "pc1", "192.168.1.11", "", "Ping 192.168.1.11 from PC1.")
				]
			},
			{
				"type": "model_library",
				"eyebrow": "Reference · Device Museum",
				"title": "Revisit Any Network Device",
				"description": "Filter WAN Edge, Core Network, Wireless, Cabling, or Endpoints anytime.",
				"items": _module_2_models()
			},
			{
				"type": "completion",
				"eyebrow": "Module 2 complete",
				"title": "Congratulations!",
				"subtitle": "You finished Setting Up Computer Networks.",
				"description": "You identified network gear, built copper cables, wired a small-office topology, configured addressing and Wi-Fi, and proved connectivity.",
				"achievements_title": "Stations completed",
				"achievements": [
					"01 Identify — devices and cabling parts",
					"02–03 Copper — straight-through and crossover",
					"04 Network Workstation — cable, IP, ping",
					"05 Wireless",
					"Capstone practice + museum"
				],
				"button_label": "Back to Home"
			}
		]
	}


static func _module_3_models() -> Array:
	return [
		_model_item("File Server", "Central host for shared folders, accounts, and print services.", "Represents the Windows/Linux file server you administer in this module.", MODEL_SERVER, "ready", "Sketchfab — David & 3D", "https://sketchfab.com/3d-models/data-center-rack-f178ec0a9c5f4605a5acbaaeb52dc721", "Servers", "One well-managed server can serve dozens of clients with consistent permissions.", "Keep a tested backup before changing share or ACL policies."),
		_model_item("NAS Appliance", "Dedicated storage box for department volumes.", "Useful when shares live on networked storage instead of local disks.", MODEL_NAS, "ready", "Sketchfab — karakocyunus", "https://sketchfab.com/3d-models/nas-storage-device-ade9536b36bf405e9fb91494d5dc506a", "Storage", "NAS devices often expose SMB/NFS shares with their own user databases.", "Map drive letters only after the share path and credentials are confirmed."),
		_model_item("Mainframe Reference", "Large multi-user systems introduce centralized computing ideas.", "Supports discussion of shared resources at enterprise scale.", MODEL_MAINFRAME, "ready", "Sketchfab — themighty808", "https://sketchfab.com/3d-models/servers-373409fcff8d4b48b34ea45b0891b691", "Servers", "Mainframes popularized the idea of many users sharing one controlled system.", "Use this as a concept model — focus on accounts and permissions, not the chassis."),
		_model_item("Workstation Client", "Endpoint used to test access and restrictions.", "Server changes are always validated from a client login.", MODEL_WORKSTATION_M3, "ready", "Sketchfab — Gonsaku", "https://sketchfab.com/3d-models/laptop-603062a9eae348b99c8f34533c201964", "Clients", "If the client cannot reach the share, the server config is incomplete.", "Test with both an authorized and an unauthorized account."),
		_model_item("Shared Storage (SSD)", "Fast volume behind department folders.", "Represents the media that holds Accounting and HR data.", MODEL_SSD, "ready", "Sketchfab — isnainul", "https://sketchfab.com/3d-models/ssd-solid-state-drive-ad215e54c381456895e21db5062f8714", "Storage", "Permissions protect files — backups protect against loss.", "Document volume letters and share UNC paths in the handover sheet."),
		_model_item("Server Enclosure", "Data-center rack / tower chassis for the departmental server.", "Physical access to the enclosure must be controlled like digital access.", MODEL_SERVER, "ready", "Sketchfab — David & 3D", "https://sketchfab.com/3d-models/data-center-rack-f178ec0a9c5f4605a5acbaaeb52dc721", "Servers", "Lock the rack/room after admin work is finished.", "Confirm power and network before leaving the floor.")
	]


static func _module_4_models() -> Array:
	return [
		_model_item("Diagnostic PC", "Workstation under service for PM and repair.", "Open, inspect, clean, reseat, and retest this chassis.", MODEL_DIAG_PC_M4, "ready", "SmartBuild / Module 1 case", "", "Hardware", "Most slow-PC tickets still start with dust, thermal paste age, and loose modules.", "Photograph cable routing before you unplug anything."),
		_model_item("Motherboard", "Inspect for loose connectors, dust, and damage.", "Visual inspection is the first maintenance step.", MODEL_MOTHERBOARD, "ready", "Sketchfab — tommy.grzembke", "https://sketchfab.com/3d-models/motherboard-09eada6916bd438489a73a7e1326e8e1", "Hardware", "Burn marks or bulging capacitors mean stop and escalate.", "Reseat power connectors firmly after cleaning."),
		_model_item("Memory (RAM)", "Reseat modules that cause random freezes.", "A common assessment fault for intermittent instability.", MODEL_RAM, "ready", "Existing repo asset", "", "Hardware", "One unlatched DIMM can look like a software crash loop.", "Clean contacts only with approved methods — never abrasives."),
		_model_item("Cooling Fan", "Check dust, bearings, and CPU cooler seating.", "Thermal throttling often appears as ‘everything is slow’.", MODEL_FAN, "ready", "SmartBuild procedural", "", "Hardware", "Blocked exhaust vents raise temps faster than a weak CPU.", "Confirm the fan header and spin after reassembly."),
		_model_item("Anti-static Kit", "Protect parts while the chassis is open.", "ESD protection remains required during maintenance.", MODEL_ANTISTATIC, "ready", "SmartBuild procedural", "", "Tools", "Maintenance without grounding risks silent component damage.", "Clip on before you touch boards or modules."),
		_model_item("Service Toolkit", "Screwdrivers and hand tools for case work.", "Keep fasteners organized during teardown.", MODEL_TOOLKIT_M4, "ready", "SmartBuild / screwdriver", "", "Tools", "Lost screws cause rattles and short risks later.", "Bag trays labeled ‘case’ and ‘drive’ help."),
		_model_item("Router", "Validate LAN/WAN during connectivity faults.", "Intermittent internet often traces to cabling or config.", MODEL_ROUTER_M2, "ready", "Sketchfab — Gabriel_515", "https://sketchfab.com/3d-models/router-7f1319c36b9b4498b6ce726a22f78637", "Network", "Ping the gateway before reinstalling the OS.", "Swap the patch cable early — it is a cheap test."),
		_model_item("Ethernet Cable", "Inspect and swap suspect patch leads.", "A crushed RJ45 tab causes flaky link lights.", MODEL_ETHERNET_CABLE, "ready", "SmartBuild procedural", "", "Network", "Wiggle-test cables while watching the NIC link LED.", "Replace any cable that fails a wire-map test.")
	]


static func _build_module_3() -> Dictionary:
	return {
		"id": 3,
		"title": "Setting Up Computer Servers",
		"subtitle": "Module 3",
		"pages": [
			{
				"type": "hero",
				"eyebrow": "Module 3 · Server Path",
				"title": "Setting Up Computer Servers",
				"subtitle": "Stand up a departmental file server with least privilege.",
				"description": "Inspect the gear, then run the Server Workstation: folders, groups, NTFS, shares, and client access tests. Guided Simulation uses hints; Assessment Simulation is the same pages without guides.",
				"bullets": [
					"01 Parts Bench — file server, NAS, SSD, laptop client",
					"02 Topology Builder — add switch, server, and client; cable and ping",
					"03 Server Workstation — build shares and lock down access",
					"04 Network Capstone — client–server LAN proven end to end",
					"05 Permissions Capstone — NTFS, shares, and allow/deny proof",
					"Finish Guided to unlock Assessment (same path, no guides)."
				]
			},
			{
				"type": "model_library",
				"eyebrow": "Station 01 · Parts Bench",
				"title": "Inspect Server & Client Gear",
				"description": "Orbit the file server, NAS, SSD, and client laptop before the admin workstation.",
				"items": _module_3_models()
			},
			{
				"type": "guided_simulation",
				"sim_mode": "network_lab",
				"topology": {"mode": "topology", "seed_devices": [], "palette": ["switch", "server", "pc"]},
				"eyebrow": "Station 02 · Topology Builder",
				"title": "Client–Server LAN Topology",
				"description": "Start from an empty canvas: add a switch, file server, and client PC; patch them; address both hosts; ping the server.",
				"completion_message": "Topology validated. Continue to the Server Workstation.",
				"related_models": ["File Server", "Switch", "Workstation Client"],
				"steps": [
					_topo_step("add_switch", "Add a switch", "Place a LAN switch from the palette — it connects clients and the server.", "add_device", "switch", "switch", "What device connects multiple hosts on the LAN?", "+ Switch on the palette toolbar."),
					_topo_step("add_server", "Add the file server", "Add the server that will host department shares.", "add_device", "server", "server", "Which device stores shared files?", "+ File Server on the palette."),
					_topo_step("add_pc", "Add a client PC", "Add the workstation that will access the server.", "add_device", "pc", "pc1", "Which endpoint represents the user workstation?", "+ PC on the palette."),
					_topo_step("pc_to_switch", "Cable PC to switch", "Patch the client into an access port on the switch.", "connect", "pc1", "switch", "How does the workstation join the LAN?", "Straight-through: PC1 ↔ Switch."),
					_topo_step("server_to_switch", "Cable server to switch", "Uplink the file server to the same switch.", "connect", "server", "switch", "How does the server reach the client subnet?", "Straight-through: File Server ↔ Switch."),
					_topo_step("addr_server", "Address the file server", "Select the server and apply IP 192.168.10.10 / mask 255.255.255.0.", "configure", "server", "addressing", "What IP will clients use to reach the server?", "Select File Server → Apply to Selected Host."),
					_topo_step("addr_pc", "Address the client PC", "Select PC1 and apply IP 192.168.10.20 / mask / gateway 192.168.10.10.", "configure", "pc1", "addressing", "Which host needs gateway pointing at the server?", "Select PC1 → Apply to Selected Host."),
					_topo_step("ping_server", "Ping the file server", "From PC1, ping 192.168.10.10 to prove L3 reachability.", "ping", "pc1", "192.168.10.10", "What ICMP target validates client–server connectivity?", "Keep cables in place, then Ping.")
				]
			},
			{
				"type": "guided_simulation",
				"sim_mode": "server_lab",
				"eyebrow": "Station 03 · Server Workstation",
				"title": "Department File Server Lab",
				"description": "Identify roles, create folders and groups, apply NTFS, publish shares, then prove allow/deny from a client.",
				"completion_message": "Server path validated. Continue to the network capstone.",
				"related_models": ["File Server", "NAS Appliance", "Workstation Client", "Shared Storage (SSD)"],
				"steps": [
					_srv_step("id_server", "Identify the file server", "Click File Server in Roles.", "identify", "server", "", "Which machine hosts the shares?", "Roles → File Server."),
					_srv_step("id_storage", "Identify storage", "Click NAS / Storage in Roles.", "identify", "storage", "", "Where do department files live?", "Roles → NAS / Storage."),
					_srv_step("mkdir_root", "Create D:\\Shares", "Create the data root folder.", "mkdir", "shares_root", "", "Where should shared data start?", "Storage → Create D:\\Shares."),
					_srv_step("mkdir_acct", "Create Accounting folder", "Add Accounting under Shares.", "mkdir", "accounting", "", "Which folder is for Accounting?", "Storage → Create Accounting."),
					_srv_step("mkdir_hr", "Create HR folder", "Add HumanResources under Shares.", "mkdir", "hr", "", "Which folder is for HR?", "Storage → Create HumanResources."),
					_srv_step("group_acct", "Create G_Accounting", "Create the Accounting security group.", "create_group", "g_accounting", "", "Which group gets Accounting rights?", "Groups & Users → Create G_Accounting."),
					_srv_step("group_hr", "Create G_HR", "Create the HR security group.", "create_group", "g_hr", "", "Which group gets HR rights?", "Groups & Users → Create G_HR."),
					_srv_step("user_anna", "Create user Anna", "Add Accounting user Anna.", "create_user", "anna", "g_accounting", "Who is the Accounting staff account?", "Create user Anna (Accounting)."),
					_srv_step("nest_anna", "Add Anna to G_Accounting", "Nest Anna into G_Accounting only.", "add_to_group", "anna", "g_accounting", "How do you avoid wrong-department access?", "Add Anna → G_Accounting."),
					_srv_step("ntfs_acct", "NTFS on Accounting", "Grant G_Accounting Modify on Accounting.", "set_ntfs", "accounting", "g_accounting", "Who may change Accounting files?", "NTFS: G_Accounting → Accounting."),
					_srv_step("ntfs_hr", "NTFS on HumanResources", "Grant G_HR Modify on HR.", "set_ntfs", "hr", "g_hr", "Who may change HR files?", "NTFS: G_HR → HumanResources."),
					_srv_step("share_acct", "Share Accounting", "Publish \\\\Server\\Accounting.", "share", "accounting", "", "What share name will Accounting clients see?", "Share Accounting."),
					_srv_step("share_hr", "Share HumanResources", "Publish \\\\Server\\HumanResources.", "share", "hr", "", "What share name will HR clients see?", "Share HumanResources."),
					_srv_step("test_allow", "Test authorized access", "As Anna, open Accounting — expect allow.", "access_test", "accounting", "allow", "How do you prove a valid user can collaborate?", "Client Test: Anna + Accounting → Test Access."),
					_srv_step("test_deny", "Test cross-department deny", "As Anna, open HR — expect deny.", "access_test", "hr", "deny", "How do you prove unauthorized access is blocked?", "Client Test: Anna + HumanResources → Test Access.")
				]
			},
			{
				"type": "assessment",
				"sim_mode": "network_lab",
				"topology": {"mode": "topology", "seed_devices": [], "palette": ["switch", "server", "pc"]},
				"eyebrow": "Station 04 · Network Capstone",
				"title": "Client–Server Network Setup",
				"description": "Build a small-office LAN from scratch: add devices, cable the switch, address hosts, and ping the file server — no guided highlights.",
				"objectives": [
					"Add switch, file server, and client PC.",
					"Patch PC and server into the switch.",
					"Address server at 192.168.10.10 and PC at 192.168.10.20.",
					"Ping the server from the client."
				],
				"pitfalls": [
					"Wrong cable type between like devices",
					"Server and PC on different subnets",
					"Missing gateway on the client",
					"Ping before addressing either host"
				],
				"completion_message": "Assessment passed. The client–server topology carries traffic end to end.",
				"related_models": ["File Server", "Switch", "Workstation Client"],
				"steps": [
					_topo_step("a_switch", "Add switch", "Place a LAN switch.", "add_device", "switch", "switch", "", "+ Switch."),
					_topo_step("a_server", "Add file server", "Add the server host.", "add_device", "server", "server", "", "+ File Server."),
					_topo_step("a_pc", "Add client PC", "Add the workstation.", "add_device", "pc", "pc1", "", "+ PC."),
					_topo_step("a_pc_sw", "Cable PC to switch", "Patch PC1 into the switch.", "connect", "pc1", "switch", "", "Straight-through: PC1 ↔ Switch."),
					_topo_step("a_srv_sw", "Cable server to switch", "Patch the server into the switch.", "connect", "server", "switch", "", "Straight-through: Server ↔ Switch."),
					_topo_step("a_ip_srv", "Address server", "Apply 192.168.10.10 to the file server.", "configure", "server", "addressing", "", "Select server → Apply."),
					_topo_step("a_ip_pc", "Address PC", "Apply 192.168.10.20 / GW 192.168.10.10 to PC1.", "configure", "pc1", "addressing", "", "Select PC1 → Apply."),
					_topo_step("a_ping", "Ping server", "From PC1, ping 192.168.10.10.", "ping", "pc1", "192.168.10.10", "", "Ping from PC1.")
				]
			},
			{
				"type": "assessment",
				"sim_mode": "server_lab",
				"eyebrow": "Station 05 · Permissions Capstone",
				"title": "Company File Server Setup",
				"description": "Accounting and HR need isolated shares. Complete the milestones without guided highlights — identify roles, build folders and groups, apply NTFS, publish shares, and prove Anna can open Accounting but is denied HR.",
				"objectives": [
					"Identify the file server role.",
					"Create Shares root and department folders.",
					"Create G_Accounting and nest Anna.",
					"Apply NTFS and publish both shares.",
					"Prove authorized access to Accounting and deny HR."
				],
				"pitfalls": [
					"Wrong folder permissions",
					"Users in the wrong group",
					"Missing share",
					"Cross-department access left open"
				],
				"completion_message": "Assessment passed. The file server enforces least privilege.",
				"related_models": ["File Server", "Workstation Client", "Shared Storage (SSD)"],
				"steps": [
					_srv_step("a_server", "Identify file server", "Select the file server role.", "identify", "server", "", "", "Roles → File Server."),
					_srv_step("a_root", "Create D:\\Shares", "Create the data root.", "mkdir", "shares_root", "", "", "Create D:\\Shares."),
					_srv_step("a_acct", "Create Accounting", "Create the Accounting folder.", "mkdir", "accounting", "", "", "Create Accounting."),
					_srv_step("a_hr", "Create HumanResources", "Create the HR folder.", "mkdir", "hr", "", "", "Create HumanResources."),
					_srv_step("a_g_acct", "Create G_Accounting", "Create the Accounting group.", "create_group", "g_accounting", "", "", "Create G_Accounting."),
					_srv_step("a_g_hr", "Create G_HR", "Create the HR group.", "create_group", "g_hr", "", "", "Create G_HR."),
					_srv_step("a_anna", "Create Anna", "Create Accounting user Anna.", "create_user", "anna", "g_accounting", "", "Create user Anna."),
					_srv_step("a_nest", "Nest Anna", "Add Anna to G_Accounting.", "add_to_group", "anna", "g_accounting", "", "Add Anna → G_Accounting."),
					_srv_step("a_ntfs_a", "NTFS Accounting", "G_Accounting on Accounting.", "set_ntfs", "accounting", "g_accounting", "", "Set NTFS Accounting."),
					_srv_step("a_ntfs_h", "NTFS HR", "G_HR on HumanResources.", "set_ntfs", "hr", "g_hr", "", "Set NTFS HR."),
					_srv_step("a_share_a", "Share Accounting", "Publish Accounting.", "share", "accounting", "", "", "Share Accounting."),
					_srv_step("a_share_h", "Share HR", "Publish HumanResources.", "share", "hr", "", "", "Share HumanResources."),
					_srv_step("a_allow", "Authorized access", "Anna → Accounting allow.", "access_test", "accounting", "allow", "", "Anna + Accounting."),
					_srv_step("a_deny", "Denied access", "Anna → HR deny.", "access_test", "hr", "deny", "", "Anna + HumanResources.")
				]
			},
			{
				"type": "completion",
				"eyebrow": "Module 3 complete",
				"title": "Congratulations!",
				"subtitle": "You finished Setting Up Computer Servers.",
				"description": "You built a client–server LAN, identified server roles, applied least-privilege NTFS, published shares, and proved allow/deny from a client.",
				"achievements_title": "Stations completed",
				"achievements": [
					"01 Parts Bench — server, NAS, SSD, client",
					"02 Topology Builder — switch, server, client, ping",
					"03 Server Workstation — folders, groups, NTFS, shares",
					"04 Network Capstone — client–server LAN proven",
					"05 Permissions Capstone — Accounting vs HR isolation proven"
				],
				"button_label": "Back to Home"
			}
		]
	}


static func _build_module_4() -> Dictionary:
	return {
		"id": 4,
		"title": "Maintaining Computer Systems and Networks",
		"subtitle": "Module 4",
		"pages": [
			{
				"type": "hero",
				"eyebrow": "Module 4 · Maintenance Path",
				"title": "Maintaining Computer Systems and Networks",
				"subtitle": "From ticket intake to a documented, validated fix.",
				"description": "Run a full service cycle: prepare tools, perform preventive maintenance, check software and network health, diagnose faults, repair, and document. Guided Simulation uses hints; Assessment Simulation is the same pages without guides.",
				"bullets": [
					"Intake the ticket and stage ESD-safe tools before opening the PC.",
					"Clean, inspect, and reseat hardware that causes heat or instability.",
					"Apply updates, malware checks, and storage cleanup.",
					"Verify cables, switch/router links, and adapter settings.",
					"Repair the root cause and close with clear documentation.",
					"Finish Guided to unlock Assessment (same path, no guides)."
				]
			},
			{
				"type": "model_library",
				"eyebrow": "Service Lab",
				"title": "Inspect Maintenance References First",
				"description": "Orbit the diagnostic PC, coolers, RAM, toolkit, and network gear used across the phases.",
				"items": _module_4_models()
			},
			{
				"type": "guided_simulation",
				"sim_mode": "maintenance_bench",
				"eyebrow": "Phase 01 · Intake",
				"title": "Review the Request and Stage Tools",
				"description": "Understand symptoms, gather the right tools, and protect the bench before teardown.",
				"completion_message": "Intake complete. Begin preventive hardware maintenance.",
				"related_models": ["Diagnostic PC", "Service Toolkit", "Anti-static Kit"],
				"steps": [
					_step("read_ticket", "Read the service request", "Note slow performance, intermittent internet, and dust reports.", "What symptoms are listed on the ticket?"),
					_step("ask_clarify", "Clarify with the user if needed", "Confirm when the issue started and any recent changes.", "What extra detail helps narrow the fault?"),
					_step("stage_tools", "Stage toolkit and ESD gear", "Screwdrivers, strap/mat, compressed air, and spare cable ready.", "Which tools must be on the bench before opening the case?"),
					_step("backup_note", "Check for backup needs", "Flag user data risks before invasive repair.", "What should you protect before risky changes?"),
					_step("plan_order", "Plan the service order", "Hardware PM → software → network → repair → document.", "What sequence keeps the visit efficient and safe?")
				]
			},
			{
				"type": "guided_simulation",
				"sim_mode": "maintenance_bench",
				"eyebrow": "Phase 02 · Hardware PM",
				"title": "Inspect and Clean Hardware",
				"description": "Open the chassis, remove dust, check fans, and reseat modules that cause instability.",
				"completion_message": "Hardware PM done. Continue with software maintenance.",
				"related_models": ["Diagnostic PC", "Cooling Fan", "Memory (RAM)", "Motherboard", "Anti-static Kit"],
				"steps": [
					_step("ground_up", "Wear ESD protection", "Clip the strap before touching boards or RAM.", "What do you put on before handling internals?"),
					_step("open_case_pm", "Open the case safely", "Remove the side panel and photograph cable layout.", "How do you access the internals for cleaning?"),
					_step("dust_out", "Remove dust and debris", "Clear fans, heatsinks, and filters with approved methods.", "What physical contaminant often causes overheating?"),
					_step("check_fans", "Inspect cooling fans", "Confirm spin, mounting, and CPU cooler seating.", "Which parts keep the CPU from thermal throttling?"),
					_step("reseat_ram", "Reseat RAM modules", "Unlatch, clean contacts if needed, and click both sides.", "What module often causes random freezes when loose?"),
					_step("check_cables_int", "Check internal power/data cables", "Reseat SATA and power connectors that look loose.", "Which connections should get a tug-test?")
				]
			},
			{
				"type": "guided_simulation",
				"sim_mode": "maintenance_bench",
				"eyebrow": "Phase 03 · Software PM",
				"title": "Apply Software Maintenance",
				"description": "Update the OS, scan for malware, and free storage that slows the machine.",
				"completion_message": "Software PM complete. Inspect the network path next.",
				"related_models": ["Diagnostic PC"],
				"steps": [
					_step("os_updates", "Install OS and security updates", "Patch known issues before deeper troubleshooting.", "What software step closes common vulnerability tickets?"),
					_step("malware_scan", "Run a malware scan", "Quarantine threats that cause slowness or pop-ups.", "How do you check for infection?"),
					_step("startup_trim", "Review startup apps", "Disable unnecessary autostart entries that waste RAM/CPU.", "What slows boot after hardware is already clean?"),
					_step("disk_cleanup", "Free disk space", "Open Disk Cleanup on C:, select Temporary files, then run cleanup.", "Which storage condition mimics ‘PC is dying’?"),
					_step("driver_health", "Check critical drivers", "Chipset, storage, and network drivers should be current.", "Which driver class often restores stability after PM?")
				]
			},
			{
				"type": "guided_simulation",
				"sim_mode": "maintenance_bench",
				"eyebrow": "Phase 04 · Network Check",
				"title": "Inspect Cables and Connectivity",
				"description": "Rule out patch cables, switch/router links, IP settings, and disabled adapters.",
				"completion_message": "Network path verified. Diagnose and repair remaining faults.",
				"related_models": ["Router", "Ethernet Cable", "Diagnostic PC"],
				"steps": [
					_step("check_nic", "Confirm the adapter is enabled", "Re-enable a disabled NIC if present.", "What OS setting silently kills internet?"),
					_step("swap_patch", "Inspect/swap the patch cable", "Replace any cable with a broken latch or no link light.", "What cheap part often causes intermittent internet?"),
					_step("check_switch_port", "Check switch/router link lights", "Move ports if the wall jack or LAN port looks dead.", "Where do you look for physical link status?"),
					_step("verify_ip", "Verify IP, gateway, and DNS", "Fix invalid static config or renew DHCP.", "Which settings must match the office network plan?"),
					_step("ping_path", "Ping gateway then external", "Prove local routing before blaming the ISP.", "What two ICMP targets validate the path?")
				]
			},
			{
				"type": "guided_simulation",
				"sim_mode": "maintenance_bench",
				"eyebrow": "Phase 05 · Repair & Close",
				"title": "Diagnose, Repair, and Document",
				"description": "Pick the root cause, apply the fix, retest performance, and write the service record.",
				"completion_message": "Service request closed. Continue to the capstone, then finish the module.",
				"related_models": ["Diagnostic PC", "Service Toolkit", "Memory (RAM)", "Router"],
				"steps": [
					_step("pick_root", "Select the root cause", "Match evidence to dust/thermal, RAM, cable, IP, or malware.", "What is the primary fault behind the ticket?"),
					_step("apply_fix", "Apply the corrective action", "Complete the repair tied to that root cause.", "Which action actually resolves the chosen fault?"),
					_step("retest_perf", "Retest performance", "Confirm the PC is responsive after cool, clean operation.", "How do you prove slowness is gone?"),
					_step("retest_net", "Retest internet", "Browse and ping to confirm stable connectivity.", "How do you prove the network issue is gone?"),
					_step("write_report", "Document findings and actions", "Record symptoms, cause, fix, parts used, and time.", "What closes a professional maintenance ticket?")
				]
			},
			{
				"type": "assessment",
				"sim_mode": "maintenance_bench",
				"eyebrow": "Capstone Assessment",
				"title": "IT Support Service Request",
				"description": "A workstation has slow performance, intermittent internet, and heavy dust. Resolve the issues and document the final state.",
				"objectives": [
					"Intake the ticket and stage ESD-safe tools.",
					"Perform preventive hardware maintenance.",
					"Apply software maintenance and cleanup.",
					"Restore network connectivity.",
					"Validate the fix and complete documentation."
				],
				"pitfalls": [
					"Loose RAM module",
					"Incorrect IP configuration",
					"Faulty network cable",
					"Malware infection",
					"Full storage drive",
					"Disabled network adapter"
				],
				"completion_message": "Assessment passed. The workstation has been cleaned, repaired, and returned to service.",
				"related_models": ["Diagnostic PC", "Memory (RAM)", "Ethernet Cable", "Router"],
				"steps": [
					_step("stage_tools", "Stage toolkit and ESD gear", "Screwdrivers, strap/mat, compressed air, and spare cable ready.", "What must be on the bench before the case is opened?"),
					_step("ground_up", "Wear ESD protection", "Clip the strap before touching boards or RAM.", "What do you put on before handling internals?"),
					_step("open_case_pm", "Open the case safely", "Remove the side panel and photograph cable layout.", "How do you access the internals for cleaning?"),
					_step("dust_out", "Remove dust and debris", "Clear fans, heatsinks, and filters with approved methods.", "What physical contaminant is overheating this PC?"),
					_step("reseat_ram", "Reseat RAM modules", "Unlatch, clean contacts if needed, and click both sides.", "What module often causes random freezes when loose?"),
					_step("os_updates", "Install OS and security updates", "Patch known issues before deeper troubleshooting.", "What software step closes known vulnerabilities?"),
					_step("malware_scan", "Run a malware scan", "Quarantine threats that cause slowness or pop-ups.", "How do you check for infection?"),
					_step("disk_cleanup", "Free disk space", "Open Disk Cleanup on C:, select Temporary files, then run cleanup.", "Which storage condition mimics a dying PC?"),
					_step("check_nic", "Confirm the adapter is enabled", "Re-enable a disabled NIC if present.", "What OS setting silently kills internet?"),
					_step("swap_patch", "Inspect/swap the patch cable", "Replace any cable with a broken latch or no link light.", "What cheap part often causes intermittent internet?"),
					_step("verify_ip", "Verify IP, gateway, and DNS", "Fix invalid static config or renew DHCP.", "Which settings must match the office network plan?"),
					_step("ping_path", "Ping gateway then external", "Prove local routing before blaming the ISP.", "What two ICMP targets validate the path?"),
					_step("pick_root", "Confirm the root cause", "Match the evidence you gathered to the primary fault.", "What is the primary fault behind the ticket?"),
					_step("apply_fix", "Apply the corrective action", "Complete the repair tied to that root cause.", "Which action actually resolves the chosen fault?"),
					_step("retest_perf", "Retest performance", "Confirm the PC is responsive after cool, clean operation.", "How do you prove slowness is gone?"),
					_step("retest_net", "Retest internet", "Browse and ping to confirm stable connectivity.", "How do you prove the network issue is gone?"),
					_step("write_report", "Document findings and actions", "Record symptoms, cause, fix, parts used, and time.", "What closes a professional maintenance ticket?")
				]
			},
			{
				"type": "model_library",
				"eyebrow": "Service Museum",
				"title": "Revisit Any Maintenance Reference",
				"description": "Filter Hardware, Tools, or Network and keep exploring the same teaching models.",
				"items": _module_4_models()
			},
			{
				"type": "completion",
				"eyebrow": "Module 4 complete",
				"title": "Congratulations!",
				"subtitle": "You finished Maintaining Computer Systems and Networks.",
				"description": "You took in a service request, performed preventive maintenance, restored connectivity, repaired the root cause, and documented the work.",
				"achievements_title": "What you completed",
				"achievements": [
					"Ticket intake and ESD-safe tool staging",
					"Hardware preventive maintenance",
					"Software updates, malware checks, and cleanup",
					"Network cable / IP / connectivity restoration",
					"Root-cause repair and service documentation"
				],
				"button_label": "Back to Home"
			}
		]
	}
