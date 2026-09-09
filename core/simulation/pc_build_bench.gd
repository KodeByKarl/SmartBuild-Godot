extends Control

## Practical PC assembly bench: drag a part from the right tray onto a bay.
## Works with SimulationManager via install actions (target + destination).

signal action_submitted(action: SimulationAction)

const SLOT_SCRIPT := preload("res://core/simulation/build_slot.gd")

## Physical build order — a bay refuses a part until these bays are filled.
## Removal reads the same table backwards, so nothing can be pulled out from
## under a part that sits on top of it.
const SLOT_PREREQS := {
	"cpu_socket": ["board_mount"],
	"cooler_mount": ["cpu_socket"],
	"fan_header": ["cooler_mount"],
	"dimm_slot": ["board_mount"],
	"pcie_slot": ["board_mount"],
	"atx_socket": ["board_mount", "psu_bay"],
	"eps_socket": ["board_mount", "psu_bay"],
	"front_panel": ["board_mount"],
}
## The side panel is the lid: it goes on last and blocks every other bay.
const LID_SLOT := "side_panel"
## Optional expansion bays — empty is fine when closing the case.
const OPTIONAL_SLOTS := ["pcie_slot"]

const PART_ICON_DIR := "res://assets/ui/parts"
## Home bay for each tray part — used when stacked slots overlap on screen.
const PART_HOME := {
	"psu": "psu_bay",
	"motherboard": "board_mount",
	"cpu": "cpu_socket",
	"cooler": "cooler_mount",
	"ram": "dimm_slot",
	"ssd": "storage_bay",
	"gpu": "pcie_slot",
	"atx_24pin": "atx_socket",
	"cpu_power": "eps_socket",
	"fan_cable": "fan_header",
	"front_wires": "front_panel",
	"side_panel": "side_panel",
}

@onready var _viewport_container: SubViewportContainer = $Root/ViewportCard/ViewportMargin/SubViewportContainer
@onready var _subviewport: SubViewport = $Root/ViewportCard/ViewportMargin/SubViewportContainer/SubViewport
@onready var _camera: Camera3D = $Root/ViewportCard/ViewportMargin/SubViewportContainer/SubViewport/World/Camera
@onready var _slots_root: Node3D = $Root/ViewportCard/ViewportMargin/SubViewportContainer/SubViewport/World/Bench/Slots
@onready var _installed_root: Node3D = $Root/ViewportCard/ViewportMargin/SubViewportContainer/SubViewport/World/Bench/Installed
@onready var _case_frame: MeshInstance3D = $Root/ViewportCard/ViewportMargin/SubViewportContainer/SubViewport/World/Bench/CaseFrame
@onready var _tray: VBoxContainer = $Root/TrayCard/TrayMargin/TrayVBox/TrayScroll/TrayList
@onready var _hint_label: Label = $Root/ViewportCard/ViewportMargin/HintLabel
@onready var _selected_label: Label = $Root/TrayCard/TrayMargin/TrayVBox/SelectedLabel
@onready var _slot_buttons: HFlowContainer = null
@onready var _viewport_margin: MarginContainer = $Root/ViewportCard/ViewportMargin

## 3D bench for guided/assessment simulations. Catalogs stay 2D images.
const USE_IMAGE_BOARD := false

var _case_board: GridContainer = null
var _bay_buttons: Dictionary = {} # slot_id -> Button
var _bay_icons: Dictionary = {} # slot_id -> TextureRect

var parts: Array = []
var slots: Dictionary = {}
var selected_part_id: String = ""
var installed_parts: Dictionary = {}
var guided_hints: bool = true
var _hint_target: String = ""
var _hint_destination: String = ""
var _orbit_yaw: float = 0.35
var _orbit_pitch: float = -0.72
var _dragging_camera := false
var _last_mouse := Vector2.ZERO
var _part_buttons: Dictionary = {}
var _pending_parts: Array = []
var _has_pending_setup := false
## Part → slot pairs the simulation already graded, so a teardown can be rebuilt
## without re-submitting an answer the run has moved past.
var _verified: Dictionary = {}
## Scenario pages seed a pre-built machine; removals there are graded actions.
var _seed_state: Array = []
var _graded_removals: bool = false
var _faulty_installs: Dictionary = {}
var _dragging_part := false
var _drag_part_id: String = ""
var _drag_ghost: Control = null
var _press_part_id: String = ""
var _press_pos := Vector2.ZERO
var _pending_seed: Array = []
var _interaction_locked := false


func _ready() -> void:
	# Container-sized when embedded in ModuleShell — full-rect anchors collapse height.
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	if custom_minimum_size.y < 360.0:
		custom_minimum_size.y = 480.0
	_bind_nodes()
	var root := get_node_or_null("Root") as Control
	if root != null:
		root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if not USE_IMAGE_BOARD:
		_ensure_case_visual()
	_ensure_image_board()
	if USE_IMAGE_BOARD:
		if _viewport_container != null:
			_viewport_container.visible = false
			_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _subviewport != null:
			_subviewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
			_subviewport.own_world_3d = false
	elif _viewport_container != null:
		_viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
		if not _viewport_container.gui_input.is_connected(_on_viewport_gui_input):
			_viewport_container.gui_input.connect(_on_viewport_gui_input)
		if _subviewport != null:
			_subviewport.own_world_3d = true
			_subviewport.transparent_bg = false
			_subviewport.handle_input_locally = true
			_subviewport.physics_object_picking = true
			var profile := get_node_or_null("/root/PerformanceProfile")
			if profile != null and profile.has_method("apply_to_subviewport"):
				profile.call("apply_to_subviewport", _subviewport, _viewport_container)
			else:
				_subviewport.size = Vector2i(960, 540)
	_build_default_slots()
	if not USE_IMAGE_BOARD:
		_update_camera()
	_refresh_selected_label()
	set_process_input(true)
	if _hint_label != null:
		_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if USE_IMAGE_BOARD:
			_hint_label.text = "Drag a part image from the tray onto a bay. Tap a filled bay to remove it."
		else:
			_hint_label.text = "Drag a 3D part from the tray onto its bay. Tap a seated part to remove it."
	var tray_scroll := get_node_or_null("Root/TrayCard/TrayMargin/TrayVBox/TrayScroll") as ScrollContainer
	if tray_scroll != null:
		tray_scroll.scroll_deadzone = 18
		tray_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		tray_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		TouchDragScroll.attach(tray_scroll)
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	modulate.a = 1.0
	visible = true
	if _has_pending_setup:
		_apply_setup(_pending_parts, guided_hints)
		_has_pending_setup = false
		_pending_parts.clear()
	elif USE_IMAGE_BOARD:
		_rebuild_slot_buttons()


func _ensure_image_board() -> void:
	if not USE_IMAGE_BOARD:
		return
	_bind_nodes()
	if _viewport_margin == null:
		_viewport_margin = get_node_or_null("Root/ViewportCard/ViewportMargin") as MarginContainer
	if _viewport_margin == null:
		return
	if _case_board != null and is_instance_valid(_case_board):
		return
	_case_board = GridContainer.new()
	_case_board.name = "ImageCaseBoard"
	_case_board.columns = 3
	_case_board.add_theme_constant_override("h_separation", 8)
	_case_board.add_theme_constant_override("v_separation", 8)
	_case_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_case_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_viewport_margin.add_child(_case_board)
	# Keep hint on top of the board.
	if _hint_label != null:
		_viewport_margin.move_child(_hint_label, _viewport_margin.get_child_count() - 1)


func _bind_nodes() -> void:
	if _viewport_container == null:
		_viewport_container = get_node_or_null("Root/ViewportCard/ViewportMargin/SubViewportContainer") as SubViewportContainer
	if _subviewport == null:
		_subviewport = get_node_or_null("Root/ViewportCard/ViewportMargin/SubViewportContainer/SubViewport") as SubViewport
	if _camera == null:
		_camera = get_node_or_null("Root/ViewportCard/ViewportMargin/SubViewportContainer/SubViewport/World/Camera") as Camera3D
	if _slots_root == null:
		_slots_root = get_node_or_null("Root/ViewportCard/ViewportMargin/SubViewportContainer/SubViewport/World/Bench/Slots") as Node3D
	if _installed_root == null:
		_installed_root = get_node_or_null("Root/ViewportCard/ViewportMargin/SubViewportContainer/SubViewport/World/Bench/Installed") as Node3D
	if _case_frame == null:
		_case_frame = get_node_or_null("Root/ViewportCard/ViewportMargin/SubViewportContainer/SubViewport/World/Bench/CaseFrame") as MeshInstance3D
	if _tray == null:
		_tray = get_node_or_null("Root/TrayCard/TrayMargin/TrayVBox/TrayScroll/TrayList") as VBoxContainer
	if _hint_label == null:
		_hint_label = get_node_or_null("Root/ViewportCard/ViewportMargin/HintLabel") as Label
	if _selected_label == null:
		_selected_label = get_node_or_null("Root/TrayCard/TrayMargin/TrayVBox/SelectedLabel") as Label


func setup(part_defs: Array, use_guided_hints: bool = true, seed: Array = []) -> void:
	guided_hints = use_guided_hints
	_pending_seed = seed.duplicate(true)
	_interaction_locked = false
	# setup() is often called before this node enters the tree (page root still orphaned),
	# so @onready refs are still null — defer until _ready.
	if not is_inside_tree() or _tray == null:
		_pending_parts = part_defs.duplicate(true)
		_has_pending_setup = true
		if is_inside_tree():
			call_deferred("_apply_setup", _pending_parts, guided_hints)
		return
	_apply_setup(part_defs, use_guided_hints)


func _apply_setup(part_defs: Array, use_guided_hints: bool = true) -> void:
	_bind_nodes()
	parts = part_defs.duplicate(true)
	guided_hints = use_guided_hints
	_rebuild_tray()
	_clear_installed()
	set_step_hint("", "")
	if not _pending_seed.is_empty():
		apply_seed_state(_pending_seed)
	else:
		_seed_state.clear()
		_graded_removals = false
	if USE_IMAGE_BOARD:
		_rebuild_slot_buttons()


func set_interaction_locked(on: bool) -> void:
	_interaction_locked = on
	if USE_IMAGE_BOARD:
		_rebuild_slot_buttons()


## Load a pre-built machine for fix-the-assembly scenarios. Parts marked
## `faulty` render with a warning tint so the student can spot mistakes.
func apply_seed_state(seed: Array) -> void:
	_bind_nodes()
	_graded_removals = not seed.is_empty()
	_clear_installed()
	_seed_state = seed.duplicate(true)
	_faulty_installs.clear()
	for entry_variant in _seed_state:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		var part_id: String = str(entry.get("part", ""))
		var slot_id: String = str(entry.get("slot", ""))
		if part_id == "" or slot_id == "":
			continue
		_place_part(part_id, slot_id, bool(entry.get("faulty", false)))
	if _hint_label != null:
		_hint_label.text = "Faulty build loaded — open the case and fix every mistake."
		_hint_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35, 1))


func reset_scenario() -> void:
	if _seed_state.is_empty():
		_clear_installed()
		_graded_removals = false
		return
	apply_seed_state(_seed_state)


func _place_part(part_id: String, slot_id: String, faulty: bool = false) -> void:
	if not slots.has(slot_id):
		return
	installed_parts[part_id] = slot_id
	if faulty:
		_faulty_installs[part_id] = true
	slots[slot_id].set_occupied(true)
	_spawn_part_visual(part_id, slot_id, faulty)
	_refresh_tray_states()
	_refresh_selected_label()
	_rebuild_slot_buttons()


func set_step_hint(target: String, destination: String) -> void:
	_hint_target = target
	_hint_destination = destination
	for slot_id in slots.keys():
		var slot: Area3D = slots[slot_id] as Area3D
		if slot == null:
			continue
		var highlight := guided_hints and destination != "" and str(slot_id) == destination
		if slot.has_method("set_highlighted"):
			slot.call("set_highlighted", highlight and not bool(slot.call("is_occupied")))
	_rebuild_slot_buttons()
	highlight_part(target)
	if _hint_label != null:
		if destination == "":
			_hint_label.text = "Drag a part from the right onto its bay. Tap a seated part to remove it."
		else:
			_hint_label.text = "Next: drag %s onto %s" % [
				target.replace("_", " "),
				destination.replace("_", " ")
			]
			_hint_label.add_theme_color_override("font_color", Color(0.75, 0.9, 0.98, 0.95))


func highlight_part(part_id: String) -> void:
	_hint_target = part_id if part_id != "" else _hint_target
	_refresh_tray_states()


func mark_installed(part_id: String, slot_id: String) -> void:
	installed_parts[part_id] = slot_id
	_verified[part_id] = slot_id
	_faulty_installs.erase(part_id)
	if slots.has(slot_id):
		slots[slot_id].set_occupied(true)
		slots[slot_id].set_highlighted(false)
	_spawn_part_visual(part_id, slot_id)
	selected_part_id = ""
	_refresh_tray_states()
	_refresh_selected_label()
	_rebuild_slot_buttons()
	if _hint_label != null:
		_hint_label.text = "Installed %s — good seating." % part_id.replace("_", " ")
		_hint_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.7, 1))


func flash_incorrect() -> void:
	if _hint_label != null:
		_hint_label.text = "Wrong part or wrong slot — try again."
		_hint_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1))
		get_tree().create_timer(0.9).timeout.connect(func() -> void:
			if is_instance_valid(_hint_label):
				_hint_label.add_theme_color_override("font_color", Color(0.75, 0.9, 0.98, 0.95))
				set_step_hint(_hint_target, _hint_destination)
		)


func _on_resized() -> void:
	_bind_nodes()
	var tray_card := get_node_or_null("Root/TrayCard") as Control
	if tray_card != null:
		if size.x > 0.0 and size.x < 720.0:
			tray_card.custom_minimum_size.x = 188.0
			tray_card.size_flags_stretch_ratio = 0.95
		else:
			tray_card.custom_minimum_size.x = 220.0
			tray_card.size_flags_stretch_ratio = 0.58
	if USE_IMAGE_BOARD:
		return
	var profile := get_node_or_null("/root/PerformanceProfile")
	if profile != null and _subviewport != null and profile.has_method("apply_to_subviewport"):
		profile.call("apply_to_subviewport", _subviewport, _viewport_container)


func _ensure_case_visual() -> void:
	_bind_nodes()
	if _case_frame == null:
		return
	# Mid-tower floor (looking down into an open case).
	var box := BoxMesh.new()
	box.size = Vector3(2.2, 0.05, 1.7)
	_case_frame.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.09, 0.1, 0.13)
	mat.metallic = 0.2
	mat.roughness = 0.7
	_case_frame.material_override = mat
	_case_frame.position = Vector3(0, 0, 0)
	_ensure_case_structure()


func _ensure_case_walls() -> void:
	_ensure_case_structure()


func _ensure_case_structure() -> void:
	var bench := get_node_or_null("Root/ViewportCard/ViewportMargin/SubViewportContainer/SubViewport/World/Bench") as Node3D
	if bench == null:
		return
	# Rebuild if an older CaseWalls-only version exists.
	var old_walls := bench.get_node_or_null("CaseWalls")
	if old_walls != null:
		old_walls.queue_free()
	if bench.get_node_or_null("CaseStructure") != null:
		return
	var root := Node3D.new()
	root.name = "CaseStructure"
	bench.add_child(root)

	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.18, 0.2, 0.24)
	metal.roughness = 0.8
	var accent := StandardMaterial3D.new()
	accent.albedo_color = Color(0.12, 0.14, 0.18)
	accent.roughness = 0.75

	var wall_specs := [
		{"size": Vector3(2.2, 0.55, 0.06), "pos": Vector3(0, 0.28, -0.85)},
		{"size": Vector3(2.2, 0.55, 0.06), "pos": Vector3(0, 0.28, 0.85)},
		{"size": Vector3(0.06, 0.55, 1.7), "pos": Vector3(-1.1, 0.28, 0)},
		{"size": Vector3(0.06, 0.55, 1.7), "pos": Vector3(1.1, 0.28, 0)},
	]
	for spec in wall_specs:
		root.add_child(_make_box_mesh(spec["size"], spec["pos"], metal))
	# Motherboard tray, PSU shelf, drive cage — readable ATX zones.
	root.add_child(_make_box_mesh(Vector3(1.15, 0.04, 1.0), Vector3(0.2, 0.05, -0.05), accent))
	root.add_child(_make_box_mesh(Vector3(0.55, 0.08, 0.55), Vector3(-0.75, 0.06, 0.45), accent))
	root.add_child(_make_box_mesh(Vector3(0.4, 0.12, 0.28), Vector3(0.75, 0.08, 0.5), accent))


func _make_box_mesh(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi


func _build_default_slots() -> void:
	_bind_nodes()
	if _slots_root == null:
		return
	for child in _slots_root.get_children():
		child.queue_free()
	slots.clear()
	# Mid-tower map — installs must land inside these bays.
	_add_slot("psu_bay", "PSU", Vector3(-0.75, 0.14, 0.45), Vector3(0.5, 0.05, 0.5))
	_add_slot("board_mount", "Motherboard", Vector3(0.2, 0.1, -0.05), Vector3(1.05, 0.03, 0.9))
	_add_slot("cpu_socket", "CPU", Vector3(0.05, 0.16, -0.15), Vector3(0.22, 0.03, 0.22))
	_add_slot("cooler_mount", "Cooler", Vector3(0.05, 0.24, -0.15), Vector3(0.3, 0.03, 0.3))
	_add_slot("dimm_slot", "RAM · A1", Vector3(0.48, 0.16, -0.1), Vector3(0.1, 0.03, 0.5))
	_add_slot("pcie_slot", "PCIe · GPU", Vector3(0.12, 0.18, 0.32), Vector3(0.55, 0.04, 0.28))
	_add_slot("storage_bay", "SSD/HDD", Vector3(0.75, 0.16, 0.5), Vector3(0.35, 0.04, 0.22))
	_add_slot("atx_socket", "24-pin", Vector3(0.55, 0.16, 0.28), Vector3(0.28, 0.03, 0.1))
	_add_slot("eps_socket", "CPU Power", Vector3(-0.22, 0.16, -0.35), Vector3(0.18, 0.03, 0.1))
	_add_slot("fan_header", "CPU_FAN", Vector3(0.22, 0.16, -0.38), Vector3(0.14, 0.03, 0.1))
	_add_slot("front_panel", "Front Panel", Vector3(0.75, 0.16, 0.22), Vector3(0.2, 0.03, 0.1))
	_add_slot("side_panel", "Side Panel", Vector3(0.0, 0.55, 0.0), Vector3(1.9, 0.04, 1.5))


func _add_slot(id: String, title: String, pos: Vector3, size: Vector3) -> void:
	if _slots_root == null:
		return
	var slot: Area3D = SLOT_SCRIPT.new()
	slot.name = id
	slot.input_ray_pickable = true
	_slots_root.add_child(slot)
	slot.position = pos
	slot.setup(id, title, size)
	slot.input_event.connect(_on_slot_input.bind(id))
	slots[id] = slot


func _rebuild_slot_buttons() -> void:
	if not USE_IMAGE_BOARD:
		if _slot_buttons != null:
			_slot_buttons.visible = false
		return
	_ensure_image_board()
	if _case_board == null:
		return
	# Stable bay order for the teaching board.
	var order: Array[String] = [
		"psu_bay", "board_mount", "storage_bay",
		"cpu_socket", "cooler_mount", "dimm_slot",
		"pcie_slot", "atx_socket", "eps_socket",
		"fan_header", "front_panel", "side_panel",
	]
	for slot_id in order:
		if not slots.has(slot_id):
			continue
		if not _bay_buttons.has(slot_id):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(0, 84)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.focus_mode = Control.FOCUS_NONE
			btn.clip_text = true
			btn.pressed.connect(_on_bay_pressed.bind(slot_id))
			var row := VBoxContainer.new()
			row.add_theme_constant_override("separation", 2)
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(row)
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(0, 40)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
			var caption := Label.new()
			caption.name = "BayCaption"
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			caption.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(11))
			caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(caption)
			_case_board.add_child(btn)
			_bay_buttons[slot_id] = btn
			_bay_icons[slot_id] = icon
		_refresh_bay_button(slot_id)


func _refresh_bay_button(slot_id: String) -> void:
	var btn: Button = _bay_buttons.get(slot_id, null)
	if btn == null:
		return
	var filled := _is_filled(slot_id)
	var highlight := guided_hints and _hint_destination != "" and slot_id == _hint_destination and not filled
	var part_id := ""
	for pid in installed_parts.keys():
		if str(installed_parts[pid]) == slot_id:
			part_id = str(pid)
			break
	var caption: Label = btn.find_child("BayCaption", true, false) as Label
	if caption != null:
		if filled and part_id != "":
			caption.text = "%s\n%s" % [_slot_title(slot_id), part_id.replace("_", " ")]
		else:
			caption.text = _slot_title(slot_id)
	var icon: TextureRect = _bay_icons.get(slot_id, null)
	if icon != null:
		if filled and part_id != "":
			icon.texture = _part_icon(part_id)
			icon.modulate = Color(1.0, 0.55, 0.35, 1) if _faulty_installs.has(part_id) else Color.WHITE
		else:
			icon.texture = null
	_style_slot_button(btn, highlight)
	if filled:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.28, 0.18, 0.95)
		style.border_color = Color(0.35, 0.9, 0.55, 0.7)
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)


func _on_bay_pressed(slot_id: String) -> void:
	if _interaction_locked or _dragging_part:
		return
	if _is_filled(slot_id):
		_try_remove(slot_id)
	elif selected_part_id != "":
		_try_install(slot_id)


func _style_remove_button(button: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.09, 0.08, 0.95)
	style.border_color = Color(0.9, 0.45, 0.35, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", Color(1.0, 0.78, 0.7, 1))
	button.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))


func _style_slot_button(button: Button, highlight: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.65, 0.1, 0.9) if highlight else Color(0.04, 0.16, 0.22, 0.95)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", Color(0.05, 0.08, 0.1, 1) if highlight else Color(0.95, 0.98, 1, 1))
	button.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))


func _rebuild_tray() -> void:
	_bind_nodes()
	if _tray == null:
		return
	for child in _tray.get_children():
		child.queue_free()
	_part_buttons.clear()
	for part_variant in parts:
		if typeof(part_variant) != TYPE_DICTIONARY:
			continue
		var part: Dictionary = part_variant
		var part_id: String = str(part.get("id", ""))
		if part_id == "":
			continue
		var card := _make_part_card(part)
		_tray.add_child(card)
		_part_buttons[part_id] = card
	_refresh_tray_states()


func _make_part_card(part: Dictionary) -> Control:
	var part_id: String = str(part.get("id", ""))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 148)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_part_card_input.bind(part_id))

	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(0, 96)
	thumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.texture = _part_icon(part_id)
	row.add_child(thumb)
	card.set_meta("thumb", thumb)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)

	var title := Label.new()
	title.text = str(part.get("label", part_id))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(13))
	title.add_theme_color_override("font_color", Color(0.95, 0.98, 1, 1))
	copy.add_child(title)

	var hint := Label.new()
	hint.text = "Drag onto case"
	hint.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(10))
	hint.add_theme_color_override("font_color", Color(0.55, 0.82, 0.95, 0.85))
	copy.add_child(hint)
	card.set_meta("hint_label", hint)
	return card


func _on_part_pressed(part_id: String) -> void:
	if installed_parts.has(part_id):
		return
	selected_part_id = part_id
	_refresh_tray_states()
	_refresh_selected_label()


func _refresh_selected_label() -> void:
	if _selected_label == null:
		return
	if selected_part_id == "":
		_selected_label.text = "Scroll the parts, then drag one onto the case."
	else:
		_selected_label.text = "Dragging: %s — drop on its bay" % selected_part_id.replace("_", " ")


func _refresh_tray_states() -> void:
	for part_id in _part_buttons.keys():
		var card: Control = _part_buttons[part_id]
		if card == null or not is_instance_valid(card):
			continue
		var done: bool = installed_parts.has(part_id)
		var selected: bool = (part_id == selected_part_id) and not done
		var recommended: bool = guided_hints and part_id == _hint_target and not done
		_style_part_card(card, selected, recommended, done)


func _style_part_card(card: Control, selected: bool, recommended: bool = false, done: bool = false) -> void:
	var panel := StyleBoxFlat.new()
	if done:
		panel.bg_color = Color(0.04, 0.08, 0.1, 0.72)
	elif selected:
		panel.bg_color = Color(0.09, 0.65, 0.87, 0.38)
	elif recommended:
		panel.bg_color = Color(0.85, 0.65, 0.12, 0.32)
	else:
		panel.bg_color = Color(0.03, 0.12, 0.18, 0.95)
	panel.set_corner_radius_all(12)
	panel.set_border_width_all(1)
	if done:
		panel.border_color = Color(0.28, 0.42, 0.48, 0.35)
	elif selected:
		panel.border_color = Color(0.45, 0.9, 1.0, 0.85)
	elif recommended:
		panel.border_color = Color(1.0, 0.85, 0.25, 0.9)
	else:
		panel.border_color = Color(0.35, 0.78, 0.92, 0.25)
	panel.content_margin_left = 8
	panel.content_margin_right = 8
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", panel)
	card.modulate.a = 0.48 if done else 1.0
	if card.has_meta("hint_label"):
		var hint: Label = card.get_meta("hint_label")
		if hint != null:
			if done:
				hint.text = "Installed"
			elif recommended:
				hint.text = "Drag this next"
			else:
				hint.text = "Drag onto case"


func _on_slot_input(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int, slot_id: String) -> void:
	if _interaction_locked:
		return
	var tapped: bool = (
		(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if not tapped:
		return
	if _dragging_part:
		return
	# Tapping a seated part pulls it back out. Empty bays wait for a drop.
	if _is_filled(slot_id):
		_try_remove(slot_id)
	elif selected_part_id != "":
		_try_install(slot_id)


func _try_install(slot_id: String) -> void:
	if _interaction_locked:
		return
	if selected_part_id == "":
		if _hint_label != null:
			_hint_label.text = "Drag a part from the right tray onto this bay."
		return
	if installed_parts.has(selected_part_id):
		return
	if slots.has(slot_id) and slots[slot_id].is_occupied():
		_warn("That slot is already filled.")
		return
	var blocked: String = _install_block_reason(slot_id)
	if blocked != "":
		# A physically impossible order is coached, not scored — the student
		# never submits it, so the run keeps a clean accuracy record.
		_warn(blocked)
		return
	if str(_verified.get(selected_part_id, "")) == slot_id:
		# Putting back a part that was already graded — refit it in place rather
		# than answering the current step with it.
		mark_installed(selected_part_id, slot_id)
		return
	var action := SimulationAction.new("install", selected_part_id, slot_id)
	action_submitted.emit(action)


func _slot_title(slot_id: String) -> String:
	var slot = slots.get(slot_id, null)
	if slot != null and is_instance_valid(slot):
		return str(slot.label_text)
	return slot_id.replace("_", " ")


func _is_filled(slot_id: String) -> bool:
	var slot = slots.get(slot_id, null)
	return slot != null and is_instance_valid(slot) and slot.is_occupied()


func _install_block_reason(slot_id: String) -> String:
	if slot_id != LID_SLOT and _is_filled(LID_SLOT):
		return "Remove the side panel before working inside the case."
	if slot_id == LID_SLOT:
		for other_id in slots.keys():
			if str(other_id) == LID_SLOT:
				continue
			if OPTIONAL_SLOTS.has(str(other_id)) and not _is_filled(str(other_id)):
				continue
			if not _is_filled(str(other_id)):
				return "Finish the internals first — %s is still empty." % _slot_title(str(other_id))
		return ""
	for required in SLOT_PREREQS.get(slot_id, []):
		if not _is_filled(str(required)):
			return "Install the %s first — %s mounts onto it." % [
				_slot_title(str(required)), _slot_title(slot_id)
			]
	return ""


func _remove_block_reason(slot_id: String) -> String:
	if slot_id != LID_SLOT and _is_filled(LID_SLOT):
		return "Take the side panel off before removing internals."
	for dependent_variant in SLOT_PREREQS.keys():
		var dependent: String = str(dependent_variant)
		if not _is_filled(dependent):
			continue
		if SLOT_PREREQS[dependent].has(slot_id):
			return "Remove the %s first — it sits on the %s." % [
				_slot_title(dependent), _slot_title(slot_id)
			]
	return ""


## Teardown mirrors assembly: pull the part out, hand it back to the tray, and
## leave the bay free to be rebuilt.
func _try_remove(slot_id: String) -> void:
	if _interaction_locked:
		return
	var blocked: String = _remove_block_reason(slot_id)
	if blocked != "":
		_warn(blocked)
		return
	var part_id: String = ""
	for candidate in installed_parts.keys():
		if str(installed_parts[candidate]) == slot_id:
			part_id = str(candidate)
			break
	if part_id == "":
		return
	installed_parts.erase(part_id)
	_verified.erase(part_id)
	_faulty_installs.erase(part_id)
	var slot = slots.get(slot_id, null)
	if slot != null and is_instance_valid(slot):
		for child in slot.get_children():
			if child.has_meta("sb_installed_part") or str(child.name).begins_with("Installed_"):
				child.queue_free()
		if slot.has_method("set_occupied"):
			slot.set_occupied(false)
	selected_part_id = part_id
	_refresh_tray_states()
	_refresh_selected_label()
	_rebuild_slot_buttons()
	set_step_hint(_hint_target, _hint_destination)
	if _hint_label != null:
		_hint_label.text = "Removed %s — back in the tray." % part_id.replace("_", " ")
		_hint_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45, 1))
	if _graded_removals:
		action_submitted.emit(SimulationAction.new("remove", part_id, slot_id))


func _warn(text: String) -> void:
	if _hint_label == null:
		return
	_hint_label.text = text
	_hint_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35, 1))


func _spawn_part_visual(part_id: String, slot_id: String, faulty: bool = false) -> void:
	if USE_IMAGE_BOARD:
		_rebuild_slot_buttons()
		return
	_bind_nodes()
	if not slots.has(slot_id) or _installed_root == null:
		return
	var slot: Node3D = slots[slot_id]
	var visual: Node3D = _make_model_part(part_id, faulty)
	var used_model := visual != null
	if visual == null:
		visual = _make_placeholder_part(part_id, faulty)
	visual.name = "Installed_%s" % part_id
	visual.set_meta("sb_installed_part", true)
	visual.set_meta("sb_used_model", used_model)
	visual.set_meta("sb_part_id", part_id)
	# Parent to the slot so alignment always matches the bay.
	slot.add_child(visual)
	visual.rotation = Vector3.ZERO
	visual.position = Vector3.ZERO
	visual.scale = Vector3.ONE * 0.2
	call_deferred("_animate_snap_local", visual)


func _animate_snap_local(visual: Node3D) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	await get_tree().process_frame
	if not is_instance_valid(visual):
		return
	var used_model: bool = bool(visual.get_meta("sb_used_model", false))
	if used_model:
		_fit_visual(visual, _fit_size_for_part(str(visual.get_meta("sb_part_id", ""))))
	else:
		visual.position = Vector3.ZERO
		visual.scale = Vector3.ONE
	var target_scale: Vector3 = visual.scale
	var target_pos: Vector3 = visual.position
	visual.scale = target_scale * 0.2
	visual.position = target_pos
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", target_scale, 0.28)


func _fit_size_for_part(part_id: String) -> float:
	match part_id:
		"motherboard":
			return 0.95
		"psu":
			return 0.48
		"side_panel":
			return 1.4
		"ram", "ssd":
			return 0.28
		"gpu":
			return 0.42
		"cpu", "cooler":
			return 0.28
		"fan_cable", "atx_24pin", "cpu_power", "front_wires":
			return 0.16
		_:
			return 0.26


func _fit_visual(root: Node3D, target: float) -> void:
	root.scale = Vector3.ONE
	root.position = Vector3.ZERO
	var aabb := _combined_aabb(root)
	var longest: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if longest < 0.0001:
		return
	var s: float = target / longest
	root.scale = Vector3.ONE * s
	root.position = -aabb.get_center() * s


func _combined_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var started := false
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			if mi.mesh != null:
				var xf: Transform3D = root.global_transform.affine_inverse() * mi.global_transform
				var box: AABB = xf * mi.get_aabb()
				if not started:
					result = box
					started = true
				else:
					result = result.merge(box)
		for child in node.get_children():
			stack.append(child)
	return result


func _make_model_part(part_id: String, faulty: bool = false) -> Node3D:
	var path := ""
	for part_variant in parts:
		if typeof(part_variant) != TYPE_DICTIONARY:
			continue
		var part: Dictionary = part_variant
		if str(part.get("id", "")) == part_id:
			path = str(part.get("scene_path", ""))
			break
	if path == "" or not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if not (res is PackedScene):
		return null
	var inst := (res as PackedScene).instantiate()
	if inst == null or not (inst is Node3D):
		if inst != null:
			inst.queue_free()
		return null
	var root := Node3D.new()
	root.name = part_id
	root.add_child(inst)
	if faulty:
		_tint_model(root, Color(1.0, 0.55, 0.25, 1))
	return root


func _tint_model(node: Node, color: Color) -> void:
	if node is GeometryInstance3D:
		var overlay := StandardMaterial3D.new()
		overlay.albedo_color = Color(color.r, color.g, color.b, 0.42)
		overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		overlay.emission_enabled = true
		overlay.emission = Color(color.r, color.g, color.b) * 0.35
		(node as GeometryInstance3D).material_overlay = overlay
	for child in node.get_children():
		_tint_model(child, color)


func _make_placeholder_part(part_id: String, faulty: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = part_id
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	# Fit snugly inside each bay (readable mid-tower layout).
	match part_id:
		"psu":
			box.size = Vector3(0.46, 0.18, 0.46)
		"motherboard":
			box.size = Vector3(0.98, 0.035, 0.82)
		"cpu":
			box.size = Vector3(0.18, 0.045, 0.18)
		"cooler":
			box.size = Vector3(0.26, 0.14, 0.26)
		"fan_cable":
			box.size = Vector3(0.1, 0.04, 0.1)
		"ram":
			box.size = Vector3(0.08, 0.16, 0.42)
		"gpu":
			box.size = Vector3(0.52, 0.12, 0.26)
		"ssd":
			box.size = Vector3(0.3, 0.05, 0.18)
		"atx_24pin", "cpu_power":
			box.size = Vector3(0.22, 0.05, 0.08)
		"front_wires":
			box.size = Vector3(0.16, 0.04, 0.08)
		"side_panel":
			box.size = Vector3(1.85, 0.03, 1.45)
		_:
			box.size = Vector3(0.25, 0.06, 0.25)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.metallic = 0.28
	mat.roughness = 0.42
	mat.emission_enabled = true
	if faulty:
		mat.albedo_color = Color(0.95, 0.42, 0.28)
		mat.emission = Color(1.0, 0.35, 0.2)
		mat.emission_energy_multiplier = 0.85
	elif part_id == "side_panel":
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.55, 0.7, 0.85, 0.35)
		mat.emission = mat.albedo_color * 0.2
		mat.emission_energy_multiplier = 0.15
	else:
		mat.albedo_color = _part_color(part_id)
		mat.emission = mat.albedo_color * 0.2
		mat.emission_energy_multiplier = 0.3
	if faulty and part_id == "side_panel":
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.95, 0.42, 0.28, 0.42)
	mi.material_override = mat
	mi.position = Vector3(0, box.size.y * 0.5 + 0.01, 0)
	root.add_child(mi)
	_add_part_detail(root, part_id, box.size)
	return root


func _add_part_detail(root: Node3D, part_id: String, size: Vector3) -> void:
	var detail := StandardMaterial3D.new()
	detail.albedo_color = Color(0.08, 0.09, 0.11)
	detail.roughness = 0.6
	match part_id:
		"motherboard":
			# Chipset / socket block near center.
			var chip := MeshInstance3D.new()
			var chip_box := BoxMesh.new()
			chip_box.size = Vector3(0.16, 0.04, 0.16)
			chip.mesh = chip_box
			chip.material_override = detail
			chip.position = Vector3(-0.12, size.y * 0.5 + 0.03, -0.08)
			root.add_child(chip)
			var dimm := MeshInstance3D.new()
			var dimm_box := BoxMesh.new()
			dimm_box.size = Vector3(0.06, 0.05, 0.45)
			dimm.mesh = dimm_box
			var dimm_mat := detail.duplicate() as StandardMaterial3D
			dimm_mat.albedo_color = Color(0.15, 0.35, 0.75)
			dimm.material_override = dimm_mat
			dimm.position = Vector3(0.28, size.y * 0.5 + 0.03, -0.05)
			root.add_child(dimm)
			var pcie := MeshInstance3D.new()
			var pcie_box := BoxMesh.new()
			pcie_box.size = Vector3(0.42, 0.03, 0.08)
			pcie.mesh = pcie_box
			var pcie_mat := detail.duplicate() as StandardMaterial3D
			pcie_mat.albedo_color = Color(0.75, 0.55, 0.15)
			pcie.material_override = pcie_mat
			pcie.position = Vector3(0.0, size.y * 0.5 + 0.02, 0.28)
			root.add_child(pcie)
		"psu":
			var fan := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.12
			cyl.bottom_radius = 0.12
			cyl.height = 0.02
			fan.mesh = cyl
			fan.material_override = detail
			fan.rotation_degrees = Vector3(90, 0, 0)
			fan.position = Vector3(0, size.y * 0.5 + 0.02, 0)
			root.add_child(fan)
		"cooler":
			var hub := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.1
			cyl.bottom_radius = 0.1
			cyl.height = 0.04
			hub.mesh = cyl
			hub.material_override = detail
			hub.position = Vector3(0, size.y * 0.5 + 0.02, 0)
			root.add_child(hub)
		"gpu":
			var fan_mat := detail.duplicate() as StandardMaterial3D
			fan_mat.albedo_color = Color(0.12, 0.14, 0.16)
			for offset_x in [-0.12, 0.12]:
				var fan := MeshInstance3D.new()
				var cyl := CylinderMesh.new()
				cyl.top_radius = 0.07
				cyl.bottom_radius = 0.07
				cyl.height = 0.02
				fan.mesh = cyl
				fan.material_override = fan_mat
				fan.rotation_degrees = Vector3(90, 0, 0)
				fan.position = Vector3(offset_x, size.y * 0.5 + 0.02, 0)
				root.add_child(fan)
			var bracket := MeshInstance3D.new()
			var bracket_box := BoxMesh.new()
			bracket_box.size = Vector3(0.04, 0.14, 0.28)
			bracket.mesh = bracket_box
			var bracket_mat := detail.duplicate() as StandardMaterial3D
			bracket_mat.albedo_color = Color(0.55, 0.58, 0.62)
			bracket.material_override = bracket_mat
			bracket.position = Vector3(size.x * 0.5 - 0.02, size.y * 0.35, 0)
			root.add_child(bracket)
		_:
			pass


func _part_color(part_id: String) -> Color:
	match part_id:
		"psu":
			return Color(0.32, 0.34, 0.38)
		"motherboard":
			return Color(0.1, 0.42, 0.26)
		"cpu":
			return Color(0.6, 0.6, 0.62)
		"cooler", "fan_cable":
			return Color(0.2, 0.55, 0.85)
		"ram":
			return Color(0.12, 0.32, 0.72)
		"gpu":
			return Color(0.18, 0.55, 0.28)
		"ssd":
			return Color(0.65, 0.67, 0.7)
		"atx_24pin", "cpu_power", "front_wires":
			return Color(0.85, 0.55, 0.15)
		"side_panel":
			return Color(0.4, 0.55, 0.7, 0.4)
		_:
			return Color(0.25, 0.7, 0.9)


func _find_part(part_id: String) -> Dictionary:
	for part_variant in parts:
		if typeof(part_variant) == TYPE_DICTIONARY and str(part_variant.get("id", "")) == part_id:
			return part_variant
	return {}


func _clear_installed() -> void:
	_bind_nodes()
	installed_parts.clear()
	_verified.clear()
	_faulty_installs.clear()
	if _installed_root != null:
		for child in _installed_root.get_children():
			child.queue_free()
	for slot_id in slots.keys():
		var slot: Node = slots[slot_id]
		if slot == null:
			continue
		# Remove only snapped install visuals (keep slot mesh/label/collision).
		var to_free: Array = []
		for child in slot.get_children():
			if child.has_meta("sb_installed_part") or str(child.name).begins_with("Installed_"):
				to_free.append(child)
		for child in to_free:
			child.queue_free()
		if slot.has_method("set_occupied"):
			slot.set_occupied(false)
		if slot.has_method("set_highlighted"):
			slot.set_highlighted(false)
	selected_part_id = ""
	_refresh_tray_states()
	_refresh_selected_label()
	_rebuild_slot_buttons()


func _part_icon(part_id: String) -> Texture2D:
	var icon_path := "%s/part_%s.png" % [PART_ICON_DIR, part_id]
	if ResourceLoader.exists(icon_path):
		var loaded: Resource = load(icon_path)
		if loaded is Texture2D:
			return loaded
	return _placeholder_icon(part_id)


func _placeholder_icon(part_id: String) -> Texture2D:
	var img := Image.create(160, 120, false, Image.FORMAT_RGBA8)
	var hue := float(abs(part_id.hash()) % 360) / 360.0
	var fill := Color.from_hsv(hue, 0.45, 0.38, 1.0)
	img.fill(fill)
	for y in range(18, 102):
		for x in range(22, 138):
			var edge := x == 22 or x == 137 or y == 18 or y == 101
			img.set_pixel(x, y, Color(0.88, 0.94, 1.0, 1.0) if edge else Color(0.12, 0.2, 0.26, 1.0))
	var tex := ImageTexture.create_from_image(img)
	return tex


func _pointer_global(event: InputEvent, host: Control = self) -> Vector2:
	if event is InputEventMouse:
		return (event as InputEventMouse).global_position
	var local := Vector2.ZERO
	if event is InputEventScreenTouch:
		local = (event as InputEventScreenTouch).position
	elif event is InputEventScreenDrag:
		local = (event as InputEventScreenDrag).position
	else:
		return get_global_mouse_position()
	if host != self:
		return host.to_global(local)
	return local


func _on_part_card_input(event: InputEvent, part_id: String) -> void:
	if _interaction_locked or installed_parts.has(part_id):
		return
	var card: Control = _part_buttons.get(part_id, null) as Control
	var host: Control = card if card != null else self
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_part_press(part_id, event.global_position)
		else:
			_finish_part_drag(event.global_position)
	elif event is InputEventScreenTouch:
		var pos := _pointer_global(event, host)
		if event.pressed:
			_begin_part_press(part_id, pos)
		else:
			_finish_part_drag(pos)
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and _press_part_id == part_id:
		var pos := _pointer_global(event, host)
		_update_part_drag(pos)
		if _dragging_part:
			accept_event()


func _begin_part_press(part_id: String, global_pos: Vector2) -> void:
	_press_part_id = part_id
	_press_pos = global_pos
	_on_part_pressed(part_id)


func _input(event: InputEvent) -> void:
	if _press_part_id == "" and not _dragging_part:
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		_update_part_drag(_pointer_global(event, self))
		if _dragging_part:
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_part_drag(_pointer_global(event, self))
	elif event is InputEventScreenTouch and not event.pressed:
		_finish_part_drag(_pointer_global(event, self))


func _update_part_drag(global_pos: Vector2) -> void:
	if _press_part_id == "" and not _dragging_part:
		return
	var delta: Vector2 = global_pos - _press_pos
	if not _dragging_part:
		if delta.length() < 22.0:
			return
		# Mostly vertical and not pulling toward the case → let the tray scroll.
		if absf(delta.y) > absf(delta.x) * 1.1 and delta.x > -18.0:
			return
		_start_part_drag(_press_part_id)
	if _dragging_part:
		_move_drag_ghost(global_pos)


func _start_part_drag(part_id: String) -> void:
	if installed_parts.has(part_id):
		return
	_dragging_part = true
	_drag_part_id = part_id
	selected_part_id = part_id
	_dragging_camera = false
	_refresh_selected_label()
	_refresh_tray_states()
	if _drag_ghost != null and is_instance_valid(_drag_ghost):
		_drag_ghost.queue_free()
	_drag_ghost = TextureRect.new()
	_drag_ghost.texture = _part_icon(part_id)
	_drag_ghost.custom_minimum_size = Vector2(88, 66)
	_drag_ghost.size = Vector2(88, 66)
	_drag_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_drag_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_ghost.z_index = 80
	_drag_ghost.modulate = Color(1, 1, 1, 0.92)
	add_child(_drag_ghost)
	_move_drag_ghost(get_global_mouse_position())
	if _hint_label != null:
		_hint_label.text = "Drop %s on its bay" % part_id.replace("_", " ")


func _move_drag_ghost(global_pos: Vector2) -> void:
	if _drag_ghost == null or not is_instance_valid(_drag_ghost):
		return
	_drag_ghost.global_position = global_pos - (_drag_ghost.size * 0.5)


func _finish_part_drag(global_pos: Vector2) -> void:
	var was_dragging := _dragging_part
	var part_id: String = _drag_part_id if _drag_part_id != "" else _press_part_id
	_press_part_id = ""
	_dragging_part = false
	_drag_part_id = ""
	if _drag_ghost != null and is_instance_valid(_drag_ghost):
		_drag_ghost.queue_free()
	_drag_ghost = null
	if part_id == "" or installed_parts.has(part_id):
		_refresh_selected_label()
		return
	if was_dragging:
		var slot_id: String = _slot_under_pointer(global_pos)
		if slot_id != "":
			selected_part_id = part_id
			if _is_filled(slot_id):
				_warn("That bay already has a part. Tap it to remove first.")
			else:
				_try_install(slot_id)
		elif _hint_label != null:
			_hint_label.text = "Drop the part on a highlighted bay in the case."
	_refresh_selected_label()
	_refresh_tray_states()


func _slot_under_pointer(global_pos: Vector2) -> String:
	if USE_IMAGE_BOARD:
		for slot_id in _bay_buttons.keys():
			var btn: Control = _bay_buttons[slot_id]
			if btn != null and is_instance_valid(btn) and btn.get_global_rect().has_point(global_pos):
				return str(slot_id)
		# Prefer home bay when dropping near the board.
		if _case_board != null and _case_board.get_global_rect().has_point(global_pos):
			var part_id: String = _drag_part_id if _drag_part_id != "" else selected_part_id
			var home_id: String = str(PART_HOME.get(part_id, ""))
			if home_id != "" and _bay_buttons.has(home_id):
				return home_id
		return ""
	if _viewport_container == null or _subviewport == null or _camera == null:
		return ""
	var rect := _viewport_container.get_global_rect()
	if not rect.has_point(global_pos):
		return ""
	var ranked: Dictionary = _rank_slots_on_screen(global_pos, rect)
	var hinted_id: String = str(ranked.get("hinted", ""))
	var hinted_dist: float = float(ranked.get("hinted_dist", 9999.0))
	if hinted_id != "" and hinted_dist <= 140.0:
		return hinted_id
	var part_id: String = _drag_part_id if _drag_part_id != "" else selected_part_id
	var home_id: String = str(PART_HOME.get(part_id, ""))
	if home_id != "" and ranked.has("dist") and (ranked["dist"] as Dictionary).has(home_id):
		var home_dist: float = float((ranked["dist"] as Dictionary)[home_id])
		if home_dist <= 120.0:
			return home_id
	var hit_id := _raycast_slot(global_pos, rect)
	if hit_id != "" and hit_id != LID_SLOT:
		return hit_id
	return str(ranked.get("nearest", ""))


func _is_lid_pickable() -> bool:
	if guided_hints and _hint_destination == LID_SLOT:
		return true
	return _install_block_reason(LID_SLOT) == ""


func _raycast_slot(global_pos: Vector2, rect: Rect2) -> String:
	var vp_size := Vector2(_subviewport.size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0 or vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return ""
	var local: Vector2 = global_pos - rect.position
	var vp_pos: Vector2 = local * (vp_size / rect.size)
	var origin: Vector3 = _camera.project_ray_origin(vp_pos)
	var direction: Vector3 = _camera.project_ray_normal(vp_pos)
	var world := _subviewport.world_3d
	if world == null:
		world = _camera.get_world_3d()
	if world == null:
		return ""
	var space := world.direct_space_state
	if space == null:
		return ""
	var exclude: Array[RID] = []
	if not _is_lid_pickable() and slots.has(LID_SLOT):
		var lid: Area3D = slots[LID_SLOT] as Area3D
		if lid != null:
			exclude.append(lid.get_rid())
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 24.0)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 2
	query.exclude = exclude
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return ""
	var node: Node = hit.get("collider") as Node
	while node != null:
		if node is Area3D and slots.has(str(node.name)):
			return str(node.name)
		if "slot_id" in node:
			var exported_id := str(node.get("slot_id"))
			if exported_id != "" and slots.has(exported_id):
				return exported_id
		node = node.get_parent()
	return ""


func _rank_slots_on_screen(global_pos: Vector2, rect: Rect2) -> Dictionary:
	var result := {
		"nearest": "",
		"hinted": "",
		"hinted_dist": 9999.0,
		"dist": {},
	}
	var vp_size := Vector2(_subviewport.size)
	if vp_size.x <= 1.0 or vp_size.y <= 1.0 or rect.size.x <= 1.0:
		return result
	var lid_ok := _is_lid_pickable()
	var best_id := ""
	var best_dist := 96.0
	var hinted := ""
	var hinted_dist := 9999.0
	var dist_map: Dictionary = {}
	for slot_id in slots.keys():
		if str(slot_id) == LID_SLOT and not lid_ok:
			continue
		var slot: Node3D = slots[slot_id] as Node3D
		if slot == null:
			continue
		var vp_pos: Vector2 = _camera.unproject_position(slot.global_position)
		var screen: Vector2 = rect.position + (vp_pos * (rect.size / vp_size))
		var dist: float = screen.distance_to(global_pos)
		dist_map[str(slot_id)] = dist
		if dist < best_dist:
			best_dist = dist
			best_id = str(slot_id)
		if guided_hints and _hint_destination == str(slot_id) and dist < hinted_dist:
			hinted = str(slot_id)
			hinted_dist = dist
	result["nearest"] = best_id
	result["hinted"] = hinted
	result["hinted_dist"] = hinted_dist
	result["dist"] = dist_map
	return result


func _on_viewport_gui_input(event: InputEvent) -> void:
	if _interaction_locked or _dragging_part:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging_camera = event.pressed
			_last_mouse = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.position *= 0.92
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.position *= 1.08
	elif event is InputEventMouseMotion and _dragging_camera:
		var delta: Vector2 = event.position - _last_mouse
		_last_mouse = event.position
		_orbit_yaw -= delta.x * 0.01
		_orbit_pitch = clampf(_orbit_pitch - delta.y * 0.01, -1.1, -0.15)
		_update_camera()
	elif event is InputEventScreenDrag and event.index == 0:
		_orbit_yaw -= event.relative.x * 0.01
		_orbit_pitch = clampf(_orbit_pitch - event.relative.y * 0.01, -1.1, -0.15)
		_update_camera()


func _update_camera() -> void:
	if _camera == null:
		return
	# Elevated orbit so the case tray layout is readable (not a label pile).
	var dist := 3.4
	_camera.position = Vector3(
		sin(_orbit_yaw) * cos(_orbit_pitch) * dist,
		sin(-_orbit_pitch) * dist + 0.55,
		cos(_orbit_yaw) * cos(_orbit_pitch) * dist
	)
	_camera.look_at(Vector3(0, 0.12, 0), Vector3.UP)
