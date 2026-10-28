class_name ModuleContentRegistry
extends RefCounted

## Content for Modules 1–4, served to ModuleFlow.
## Lesson pages live in scripts/content/module_N_content.gd (SMARTBUILD Figma);
## this file keeps the Module 1 simulation data (TESDA CSS NC II Unit 1 steps).
## The quiz-style "guided_simulation" phases were removed: Modules are assessed
## through the Guided Simulation → Assessment Simulation only.


static func get_module(module_id: int) -> Dictionary:
	match module_id:
		1:
			return Module1Content.build()
		2:
			return Module2Content.build()
		3:
			return Module3Content.build()
		4:
			return Module4Content.build()
		_:
			return {}


static func get_supported_module_ids() -> Array[int]:
	return [1, 2, 3, 4]


## Guided Simulation part 1 — strip the complete workstation in TESDA order.
static func module_1_disassembly_sim() -> Dictionary:
	return {
		"sim_mode": "pc_build",
		"eyebrow": "Guided Simulation · Disassemble",
		"title": "Safe Disassembly",
		"description": "TESDA CSS NC II Unit 1: open the case, disconnect power cables (24-pin → 4-pin 12V → SATA), remove Power Supply Unit, optical drive, Hard Disk Drive, graphics card, motherboard, then Random Access Memory, CPU fan, and CPU.",
		"completion_message": "Unit is stripped safely. Assemble the workstation next.",
		"done_button": "Proceed to Assembly",
		"build_parts": module_1_build_parts(),
		"seed_state": _complete_pc_seed(),
		"steps": _tesda_disassemble_steps(),
	}


## Guided Simulation part 2 — rebuild the tower in technician-safe order.
static func module_1_assembly_sim() -> Dictionary:
	return {
		"sim_mode": "pc_build",
		"eyebrow": "Guided Simulation · Assemble",
		"title": "Hardware Assembly",
		"description": "Build the PC on the bench: fit the CPU, CPU fan, and Random Access Memory on the motherboard while it is still outside the case, install the motherboard in the case, then the Hard Disk Drive, optical drive, and Power Supply Unit, and finally connect all cables. Select each part, then place it on the correct slot. Yellow marks the next guided step.",
		"completion_message": "Tower assembly complete. Guided Simulation finished — get ready for the assessment.",
		"done_button": "Continue",
		"build_parts": module_1_build_parts(),
		"steps": [

		_install_step("install_cpu", "Install the CPU (board outside the case)", "With the motherboard still outside the case, match the triangle marker and seat the CPU in the socket.", "cpu", "cpu_socket", "Where does the processor go while the board is on the bench?", "Fit the CPU before the board goes into the case — there is more room to align it."),
		_install_step("install_cooler", "Seat the CPU Fan (board outside the case)", "Mount the heatsink/fan over the CPU while the board is still outside the case. The fan cable is a separate step.", "cooler", "cooler_mount", "What cools the processor after it is seated?", "Even pressure prevents socket damage."),
		_install_step("connect_fan", "Connect the fan cable only", "Plug only the CPU fan cable into the fan header — do not place the whole cooler again.", "fan_cable", "fan_header", "Where does the fan cable attach on the board?", "CPU_FAN keeps the cooler spinning at POST."),
		_install_step("install_ram", "Install the Random Access Memory (board outside the case)", "Click the Random Access Memory into the DIMM slot until both latches catch, before the board goes into the case.", "ram", "dimm_slot", "Where do memory sticks go?", "Both latches must click — half-seated Random Access Memory fails POST."),
		_install_step("mount_board", "Install the motherboard in the case", "With the CPU, CPU fan, and Random Access Memory already on it, lower the motherboard into the case onto the standoffs.", "motherboard", "board_mount", "When does the motherboard go into the case?", "Only after the CPU, CPU fan, and Random Access Memory are on it. Standoffs must match every mounting hole."),
		_install_step("install_storage", "Install the Hard Disk Drive", "Mount the Hard Disk Drive in the storage bay.", "ssd", "storage_bay", "Where does permanent storage mount?", "Secure the drive before data/power cables."),
		_install_step("install_optical", "Install the optical drive", "Mount the optical drive in its bay.", "optical", "optical_bay", "Where does the optical drive mount?", "Optical Drive before power cables to the drives."),
		_install_step("install_psu", "Install the Power Supply Unit", "Mount the Power Supply Unit in its bay with airflow facing the vent.", "psu", "psu_bay", "Where does the power supply mount in the chassis?", ""),
		_install_step("install_gpu", "Install the graphics card", "Seat the Graphics Card in the PCIe x16 slot and lock the retention clip.", "gpu", "pcie_slot", "Which expansion slot takes a discrete graphics card?", "Push until the PCIe latch clicks, then screw the bracket."),
		_install_step("main_power", "Connect 24-pin Main Power (ATX)", "Seat the main board power connector until it clicks.", "atx_24pin", "atx_socket", "What is the primary motherboard power plug?", "A loose 24-pin causes random shutdowns."),
		_install_step("cpu_power", "Connect CPU power", "Plug the 4/8-pin CPU power near the socket.", "cpu_power", "eps_socket", "Which extra power lead does the CPU need?", "Missing EPS power often means no POST."),
		_install_step("sata_power", "Connect SATA power", "Plug SATA power into the drive connectors.", "sata_power", "sata_power_port", "Which lead powers Hard Disk Drive and optical drives?", "SATA power after the drives are mounted."),
		_install_step("front_panel", "Wire front-panel headers", "Connect Power SW / Reset / LED wires to the front-panel header.", "front_wires", "front_panel", "What connects case buttons to the board?", "Check the board silkscreen for pin order."),
		_install_step("close_case", "Close the Case Cover", "Reinstall the side panel after internals and power are done.", "side_panel", "side_panel", "When do you close the chassis?", "Close only after power cables and cooling are finished.")
		],
	}


## Assessment Simulation — disassemble, then rebuild, with no hints.
static func module_1_assessment_sim() -> Dictionary:
	return {
		"sim_mode": "pc_build",
		"eyebrow": "Assessment Simulation",
		"title": "Disassemble, Then Rebuild",
		"description": "TESDA CSS NC II: start from a complete workstation. Strip it in the official Unit 1 order, then assemble it again — no yellow hints.",
		"objectives": [
			"Open the case, then disconnect 24-pin Main Power (ATX), 4-pin 12V, and SATA power.",
			"Remove Power Supply Unit, optical drive, Hard Disk Drive, graphics card, motherboard, then Random Access Memory, CPU fan, and CPU.",
			"Rebuild: fit the CPU, CPU fan, and Random Access Memory on the motherboard outside the case, then install the motherboard in the case.",
			"Close the case only when every part is seated correctly."
		],
		"pitfalls": [
			"Trying to pull internals with the side panel still on",
			"Removing the Power Supply Unit before all power cables are disconnected",
			"Pulling Random Access Memory or the CPU before the motherboard is out",
			"Installing the motherboard in the case before the CPU, CPU fan, and Random Access Memory are on it",
			"Closing the case before CPU power and cooling are connected"
		],
		"completion_message": "Assessment passed. You disassembled then rebuilt the workstation correctly.",
		"done_button": "View Results",
		"build_parts": module_1_build_parts(),
		"seed_state": _complete_pc_seed(),
		"steps": _tesda_disassemble_then_rebuild_steps(),
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


static func module_1_build_parts() -> Array:
	# scene_path left blank → bench uses Module1PartFactory teaching meshes
	# (front_wires previously pointed at screwdriver GLTF — wrong model in disassembly).
	return [
		{"id": "psu", "label": "Power Supply Unit", "scene_path": ""},
		{"id": "motherboard", "label": "Motherboard", "scene_path": "res://assets/models/module_1/motherboard/model.tscn"},
		{"id": "cpu", "label": "CPU", "scene_path": ""},
		{"id": "cooler", "label": "CPU Fan", "scene_path": "res://assets/models/module_1/cooler/model.tscn"},
		{"id": "ram", "label": "Random Access Memory", "scene_path": ""},
		{"id": "ssd", "label": "Hard Disk Drive", "scene_path": ""},
		{"id": "optical", "label": "Optical Drive", "scene_path": ""},
		{"id": "gpu", "label": "Graphics Card", "scene_path": ""},
		{"id": "atx_24pin", "label": "24-pin Main Power (ATX)", "scene_path": ""},
		{"id": "cpu_power", "label": "CPU Power", "scene_path": ""},
		{"id": "sata_power", "label": "SATA Power", "scene_path": ""},
		{"id": "fan_cable", "label": "Fan Cable", "scene_path": ""},
		{"id": "front_wires", "label": "Front Panel", "scene_path": ""},
		{"id": "side_panel", "label": "Case Cover", "scene_path": ""}
	]


static func _complete_pc_seed() -> Array:
	# TESDA-ready workstation. side_panel omitted — chassis open (HIDE_CASE_COVER).
	return [
		{"part": "motherboard", "slot": "board_mount"},
		{"part": "cpu", "slot": "cpu_socket"},
		{"part": "cooler", "slot": "cooler_mount"},
		{"part": "ram", "slot": "dimm_slot"},
		{"part": "ssd", "slot": "storage_bay"},
		{"part": "optical", "slot": "optical_bay"},
		{"part": "psu", "slot": "psu_bay"},
		{"part": "gpu", "slot": "pcie_slot"},
		{"part": "atx_24pin", "slot": "atx_socket"},
		{"part": "cpu_power", "slot": "eps_socket"},
		{"part": "sata_power", "slot": "sata_power_port"}
	]


static func _tesda_disassemble_steps(prefix: String = "") -> Array:
	## CSS NC II Unit 1 order: open case → disconnect cables → PSU → ODD → HDD →
	## GPU → motherboard → RAM → CPU fan → CPU.
	var p := prefix
	return [
		_remove_step("%sopen_case" % p, "Remove the side panel", "Open the computer case and remove the side panels before touching internals.", "side_panel", "side_panel", "", "The panel blocks every bay."),
		_remove_step("%spull_atx" % p, "Disconnect 24-pin Main Power (ATX)", "Unplug the 24-pin Main Power (ATX) power connector from the motherboard first.", "atx_24pin", "atx_socket", "", "Main board power comes off before the 4-pin lead."),
		_remove_step("%spull_eps" % p, "Disconnect 4-pin 12V", "Unplug the 4-pin / EPS 12V CPU power connector next.", "cpu_power", "eps_socket", "", "CPU power lead after the 24-pin."),
		_remove_step("%spull_sata" % p, "Disconnect SATA power", "Unplug the SATA power connectors from the drives.", "sata_power", "sata_power_port", "", "Free drive power before pulling the Power Supply Unit."),
		_remove_step("%spull_psu" % p, "Remove the Power Supply Unit", "Unscrew and lift the Power Supply Unit out of the bay.", "psu", "psu_bay", "", "Power Supply Unit out once every power lead is free."),
		_remove_step("%spull_optical" % p, "Remove the optical drive", "Unmount the optical drive from its bay.", "optical", "optical_bay", "", "Optical drive before the hard disk."),
		_remove_step("%spull_hdd" % p, "Remove the Hard Disk Drive", "Unmount the Hard Disk Drive from the storage bay.", "ssd", "storage_bay", "", "Hard Disk Drive out before the motherboard."),
		_remove_step("%spull_gpu" % p, "Remove the graphics card", "Release the PCIe retention clip and lift the graphics card from the PCIe x16 slot.", "gpu", "pcie_slot", "", "Remove expansion cards before lifting the motherboard."),
		_remove_step("%spull_board" % p, "Remove the motherboard", "Unscrew and lift the motherboard from the standoff tray.", "motherboard", "board_mount", "", "Board comes out with the Random Access Memory, CPU fan and CPU still on it — remove those next."),
		_remove_step("%spull_ram" % p, "Remove the Random Access Memory", "Open both DIMM latches and lift the memory module from the board.", "ram", "dimm_slot", "", "Random Access Memory off the board after the motherboard is free."),
		_remove_step("%spull_cooler" % p, "Remove the CPU fan", "Unscrew the heatsink evenly and lift the CPU fan off the processor.", "cooler", "cooler_mount", "", "Cooler off before lifting the CPU."),
		_remove_step("%spull_cpu" % p, "Remove the CPU", "Open the socket lever and lift the processor carefully.", "cpu", "cpu_socket", "", "Never pry on pins — last internal remove.")
	]


static func _tesda_disassemble_then_rebuild_steps() -> Array:
	var steps: Array = _tesda_disassemble_steps("as_")
	steps.append_array([
		_install_step("as_install_cpu", "Install the CPU (board outside the case)", "With the motherboard still outside the case, match the triangle marker and seat the CPU in the socket.", "cpu", "cpu_socket"),
		_install_step("as_install_cooler", "Seat the CPU Fan (board outside the case)", "Mount the heatsink/fan over the CPU while the board is still outside the case. The fan cable is a separate step.", "cooler", "cooler_mount"),
		_install_step("as_connect_fan", "Connect the fan cable only", "Plug only the CPU fan cable into the fan header — do not place the whole cooler again.", "fan_cable", "fan_header"),
		_install_step("as_install_ram", "Install the Random Access Memory (board outside the case)", "Click the Random Access Memory into the DIMM slot until both latches catch, before the board goes into the case.", "ram", "dimm_slot"),
		_install_step("as_mount_board", "Install the motherboard in the case", "With the CPU, CPU fan, and Random Access Memory already on it, lower the motherboard into the case onto the standoffs.", "motherboard", "board_mount"),
		_install_step("as_install_storage", "Install the Hard Disk Drive", "Mount the Hard Disk Drive in the storage bay.", "ssd", "storage_bay"),
		_install_step("as_install_optical", "Install the optical drive", "Mount the optical drive in its bay.", "optical", "optical_bay"),
		_install_step("as_install_psu", "Install the Power Supply Unit", "Mount the Power Supply Unit in its bay with airflow facing the vent.", "psu", "psu_bay"),
		_install_step("as_install_gpu", "Install the graphics card", "Seat the Graphics Card in the PCIe x16 slot and lock the retention clip.", "gpu", "pcie_slot"),
		_install_step("as_main_power", "Connect 24-pin Main Power (ATX)", "Seat the main board power connector until it clicks.", "atx_24pin", "atx_socket"),
		_install_step("as_cpu_power", "Connect CPU power", "Plug the 4/8-pin CPU power near the socket.", "cpu_power", "eps_socket"),
		_install_step("as_sata_power", "Connect SATA power", "Plug SATA power into the drive connectors.", "sata_power", "sata_power_port"),
		_install_step("as_front_panel", "Wire front-panel headers", "Connect Power SW / Reset / LED wires to the front-panel header.", "front_wires", "front_panel"),
		_install_step("as_close_case", "Close the Case Cover", "Reinstall the side panel after internals and power are done.", "side_panel", "side_panel")
	])
	return steps
