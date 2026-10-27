extends Control

## Practical PC assembly bench: drag a part from the right tray onto a bay.
## Works with SimulationManager via install actions (target + destination).

signal action_submitted(action: SimulationAction)
signal coach_message(correct: bool, title: String, detail: String)
## A part left the tray under the finger (host can slide the tray away).
signal part_drag_started(part_id: String)

const SLOT_SCRIPT := preload("res://core/simulation/build_slot.gd")

## Physical build order — a bay refuses a part until these bays are filled.
## Removal reads the same table backwards, so nothing can be pulled out from
## under a part that sits on top of it. "board_mount" also counts as met while
## the board lies on the bench (see BENCH_PREP_SLOTS).
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
## Hide Case Cover for now — giant blue lid bay blocked the internals (panelist).
## Chassis stays open; open/close cover steps auto-complete. Visual inspired by
## Jack Saussy mATX-16 standing open-side case (https://github.com/Saussy1/mATX-16).
const HIDE_CASE_COVER := true
## Show all seeded parts once the motherboard is centered in the case.
const ONLY_CASE_AND_MOTHERBOARD := false
## Compact mid-tower shell (meters). Open face is +Z; motherboard on the back tray.
const CASE_CX := 0.0
const CASE_CY := 0.85
const CASE_CZ := 0.0
const CASE_W := 1.05
const CASE_H := 1.5
const CASE_D := 1.05
const CASE_T := 0.045

const PART_ICON_DIR := "res://assets/ui/parts"
## Home bay for each tray part — used when stacked slots overlap on screen.
const PART_HOME := {
	"psu": "psu_bay",
	"motherboard": "board_mount",
	"cpu": "cpu_socket",
	"cooler": "cooler_mount",
	"ram": "dimm_slot",
	"ssd": "storage_bay",
	"optical": "optical_bay",
	"gpu": "pcie_slot",
	"atx_24pin": "atx_socket",
	"cpu_power": "eps_socket",
	"sata_power": "sata_power_port",
	"fan_cable": "fan_header",
	"front_wires": "front_panel",
	"side_panel": "side_panel",
}
## Bays that sit on the motherboard. They travel with the board whenever it is
## out of the case: TESDA teardown pulls the board before RAM, CPU fan and CPU,
## and assembly fits those parts before the board goes in.
const BOARD_CARRIED_SLOTS := [
	"cpu_socket", "cooler_mount", "dimm_slot", "fan_header",
	"atx_socket", "eps_socket", "pcie_slot", "front_panel",
]
## Board bays that can be filled while the board lies on the bench.
const BENCH_PREP_SLOTS := ["cpu_socket", "cooler_mount", "fan_header", "dimm_slot"]
## CSS NC II assembly: CPU, CPU fan and RAM go on the board outside the case,
## then the board is installed in the case.
const BOARD_MOUNT_REQUIRES := ["cpu_socket", "cooler_mount", "dimm_slot"]
## A board that is not mounted rests just outside the case's open face (+Z).
const BOARD_BENCH_OFFSET := Vector3(0.0, -0.08, 1.1)
const DETACHED_BOARD_NODE := "DetachedBoard"

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
var _orbit_pitch: float = -0.12
var _orbit_distance: float = 2.35
const ZOOM_MIN := 1.35
const ZOOM_MAX := 6.5
var _dragging_camera := false
var _last_mouse := Vector2.ZERO
var _pinch_active := false
var _pinch_start_dist := 0.0
var _pinch_start_orbit := 3.6
var _touch_points: Dictionary = {} # index -> Vector2
var _zoom_bar: HBoxContainer = null
var _last_attempt_part: String = ""
var _last_attempt_slot: String = ""
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
var _drag_ghost_viewport: SubViewport = null
var _press_part_id: String = ""
var _press_pos := Vector2.ZERO
var _pending_seed: Array = []
var _interaction_locked := false
## Cooler cold plate height above the CPU socket plane (CPU lid thickness).
const COOLER_PLATE_ABOVE_SOCKET := 0.02
const TAP_MOVE_SLOP_PX := 16.0
const TAP_MAX_MS := 600
const TAP_DUPLICATE_MS := 350
const TAP_NEAREST_PX := 60.0
const TAP_SNAP_MIN_PX := 70.0
const TAP_SNAP_FRACTION := 0.12
var _tap_armed := false
var _tap_moved := false
var _tap_down_pos := Vector2.ZERO
var _tap_down_msec := 0
var _last_tap_msec := -100000
var _hint_bar: PanelContainer = null
var _glowing_visual: Node3D = null
var _glow_tween: Tween = null
## Current guided action: "remove" | "install" | "" — drives Drop vs Tap copy.
var _hint_action: String = ""
## One-shot guard so case-cover auto-complete cannot re-queue forever.
var _case_cover_auto_queued := false
var _case_cover_auto_emitted_for: String = ""
var _empty_remove_key: String = ""
var _board_on_bench := false
var _bench_board_anchor: Node3D = null


func _ready() -> void:
	# Container-sized when embedded in SimulationPage — full-rect anchors collapse height.
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
	_clear_viewport_card_chrome()
	if not USE_IMAGE_BOARD:
		_ensure_case_visual()
	_ensure_image_board()
	if USE_IMAGE_BOARD:
		if _viewport_container != null:
			_viewport_container.visible = false
			_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _subviewport != null:
			_subviewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
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
			_hint_label.text = "Standing open case · drag parts onto yellow bays · Zoom +/− or pinch."
	_ensure_zoom_controls()
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


func _clear_viewport_card_chrome() -> void:
	## Drop every blue/cyan tint over the working area — case must read clear.
	var viewport_card := get_node_or_null("Root/ViewportCard") as PanelContainer
	if viewport_card != null:
		var clear := StyleBoxEmpty.new()
		viewport_card.add_theme_stylebox_override("panel", clear)
	var tray_card := get_node_or_null("Root/TrayCard") as PanelContainer
	if tray_card != null:
		var tray_style := StyleBoxFlat.new()
		tray_style.bg_color = Color(0.03, 0.08, 0.12, 0.92)
		tray_style.border_color = Color(0.25, 0.55, 0.7, 0.25)
		tray_style.set_border_width_all(1)
		tray_style.set_corner_radius_all(10)
		tray_card.add_theme_stylebox_override("panel", tray_style)
	if _viewport_margin != null:
		_viewport_margin.add_theme_constant_override("margin_left", 2)
		_viewport_margin.add_theme_constant_override("margin_top", 2)
		_viewport_margin.add_theme_constant_override("margin_right", 2)
		_viewport_margin.add_theme_constant_override("margin_bottom", 2)
	_relayout_hint_as_top_bar()


func _relayout_hint_as_top_bar() -> void:
	## HintLabel previously shared the MarginContainer full rect and washed a
	## blue-looking overlay over the 3D case. Keep it as a compact top strip.
	_bind_nodes()
	if _viewport_margin == null or _hint_label == null:
		return
	if _hint_bar != null and is_instance_valid(_hint_bar):
		return
	var viewport_card := get_node_or_null("Root/ViewportCard") as PanelContainer
	if viewport_card == null:
		return

	# Detach margin (holds SubViewport) and hint from the card.
	if _viewport_margin.get_parent() != null:
		_viewport_margin.get_parent().remove_child(_viewport_margin)
	if _hint_label.get_parent() != null:
		_hint_label.get_parent().remove_child(_hint_label)

	var stage := VBoxContainer.new()
	stage.name = "StageStack"
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_theme_constant_override("separation", 4)
	viewport_card.add_child(stage)

	_hint_bar = PanelContainer.new()
	_hint_bar.name = "HintBar"
	_hint_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.04, 0.07, 0.1, 0.92)
	bar_style.border_color = Color(0.95, 0.78, 0.2, 0.5)
	bar_style.set_border_width_all(1)
	bar_style.set_corner_radius_all(6)
	bar_style.content_margin_left = 8
	bar_style.content_margin_right = 8
	bar_style.content_margin_top = 3
	bar_style.content_margin_bottom = 3
	_hint_bar.add_theme_stylebox_override("panel", bar_style)
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(11))
	_hint_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.72, 1))
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_bar.add_child(_hint_label)
	stage.add_child(_hint_bar)

	_ensure_zoom_controls_on(stage)

	_viewport_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_viewport_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(_viewport_margin)


## Full-screen mode (SimulationPage): hands the parts tray, the yellow hint
## strip and the zoom bar to the host so they can float over the 3D view as
## slide-in panels. The 3D stage then fills the whole bench. Nodes keep their
## state and signal wiring — only their parent changes.
func take_overlay_panels() -> Dictionary:
	_bind_nodes()
	var out := {}
	var tray := get_node_or_null("Root/TrayCard") as Control
	if tray != null:
		tray.get_parent().remove_child(tray)
		out["tray"] = tray
	if _hint_bar != null and is_instance_valid(_hint_bar) and _hint_bar.get_parent() != null:
		_hint_bar.get_parent().remove_child(_hint_bar)
		out["hint"] = _hint_bar
	if _zoom_bar != null and is_instance_valid(_zoom_bar) and _zoom_bar.get_parent() != null:
		_zoom_bar.get_parent().remove_child(_zoom_bar)
		out["zoom"] = _zoom_bar
	return out


func _ensure_zoom_controls() -> void:
	var stage := get_node_or_null("Root/ViewportCard/StageStack") as VBoxContainer
	if stage != null:
		_ensure_zoom_controls_on(stage)


func _ensure_zoom_controls_on(stage: VBoxContainer) -> void:
	if stage == null:
		return
	if _zoom_bar != null and is_instance_valid(_zoom_bar):
		return
	_zoom_bar = HBoxContainer.new()
	_zoom_bar.name = "ZoomBar"
	_zoom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_zoom_bar.add_theme_constant_override("separation", 10)
	_zoom_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var zin := Button.new()
	zin.text = "Zoom +"
	zin.focus_mode = Control.FOCUS_NONE
	zin.custom_minimum_size = Vector2(88, 30)
	zin.pressed.connect(func() -> void: _zoom_by(0.82))
	_style_zoom_btn(zin)
	var zout := Button.new()
	zout.text = "Zoom −"
	zout.focus_mode = Control.FOCUS_NONE
	zout.custom_minimum_size = Vector2(88, 30)
	zout.pressed.connect(func() -> void: _zoom_by(1.22))
	_style_zoom_btn(zout)
	var tip := Label.new()
	tip.text = "Orbit · pinch"
	tip.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(10))
	tip.add_theme_color_override("font_color", Color(0.7, 0.85, 0.95, 0.85))
	_zoom_bar.add_child(zin)
	_zoom_bar.add_child(zout)
	_zoom_bar.add_child(tip)
	# Insert under hint bar, above the 3D viewport.
	stage.add_child(_zoom_bar)
	if _hint_bar != null and is_instance_valid(_hint_bar):
		stage.move_child(_zoom_bar, _hint_bar.get_index() + 1)


func _style_zoom_btn(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.22, 0.32, 0.95)
	style.border_color = Color(0.35, 0.78, 0.95, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0, 1))
	btn.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(13))


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
	if _viewport_margin == null or not is_instance_valid(_viewport_margin):
		_viewport_margin = get_node_or_null("Root/ViewportCard/StageStack/ViewportMargin") as MarginContainer
		if _viewport_margin == null:
			_viewport_margin = get_node_or_null("Root/ViewportCard/ViewportMargin") as MarginContainer
	if _viewport_container == null or not is_instance_valid(_viewport_container):
		if _viewport_margin != null:
			_viewport_container = _viewport_margin.get_node_or_null("SubViewportContainer") as SubViewportContainer
	if _subviewport == null or not is_instance_valid(_subviewport):
		if _viewport_container != null:
			_subviewport = _viewport_container.get_node_or_null("SubViewport") as SubViewport
	if _camera == null or not is_instance_valid(_camera):
		if _subviewport != null:
			_camera = _subviewport.get_node_or_null("World/Camera") as Camera3D
	if _slots_root == null or not is_instance_valid(_slots_root):
		if _subviewport != null:
			_slots_root = _subviewport.get_node_or_null("World/Bench/Slots") as Node3D
	if _installed_root == null or not is_instance_valid(_installed_root):
		if _subviewport != null:
			_installed_root = _subviewport.get_node_or_null("World/Bench/Installed") as Node3D
	if _case_frame == null or not is_instance_valid(_case_frame):
		if _subviewport != null:
			_case_frame = _subviewport.get_node_or_null("World/Bench/CaseFrame") as MeshInstance3D
	if _tray == null or not is_instance_valid(_tray):
		_tray = get_node_or_null("Root/TrayCard/TrayMargin/TrayVBox/TrayScroll/TrayList") as VBoxContainer
	if _hint_label == null or not is_instance_valid(_hint_label):
		_hint_label = get_node_or_null("Root/ViewportCard/StageStack/HintBar/HintLabel") as Label
		if _hint_label == null:
			_hint_label = get_node_or_null("Root/ViewportCard/ViewportMargin/HintLabel") as Label
	if _selected_label == null or not is_instance_valid(_selected_label):
		_selected_label = get_node_or_null("Root/TrayCard/TrayMargin/TrayVBox/SelectedLabel") as Label


func _bench_root() -> Node3D:
	_bind_nodes()
	if _slots_root != null and is_instance_valid(_slots_root):
		return _slots_root.get_parent() as Node3D
	if _case_frame != null and is_instance_valid(_case_frame):
		return _case_frame.get_parent() as Node3D
	if _subviewport != null and is_instance_valid(_subviewport):
		return _subviewport.get_node_or_null("World/Bench") as Node3D
	return null


var _viewports_released := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PREDELETE:
		_release_viewports()


func shutdown_lab() -> void:
	_interaction_locked = true
	_clear_part_glow()
	_release_viewports()


func _release_viewports() -> void:
	if _viewports_released:
		return
	_viewports_released = true
	_dispose_drag_ghost()
	# Stop drawing, but keep the World3D. Clearing own_world_3d here drops the
	# scenario, then freeing the viewport calls scenario_remove_viewport_visibility_mask
	# with a null scenario and logs "Parameter scenario is null".
	_silence_viewport(_subviewport)
	if _viewport_container != null and is_instance_valid(_viewport_container):
		_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _silence_viewport(sv: SubViewport) -> void:
	if sv == null or not is_instance_valid(sv):
		return
	sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
	for node in sv.find_children("*", "Camera3D", true, false):
		var cam := node as Camera3D
		if cam != null:
			cam.current = false


func _dispose_drag_ghost() -> void:
	if _drag_ghost_viewport != null and is_instance_valid(_drag_ghost_viewport):
		_drag_ghost_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if _drag_ghost != null and is_instance_valid(_drag_ghost):
		_drag_ghost.queue_free()
	_drag_ghost = null
	_drag_ghost_viewport = null


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
	# Re-arm 3D world if a prior shutdown released it (pooled / reused bench).
	if not USE_IMAGE_BOARD and _subviewport != null and is_instance_valid(_subviewport):
		_viewports_released = false
		_subviewport.own_world_3d = true
		_subviewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		if _camera != null and is_instance_valid(_camera):
			_camera.current = true
		_ensure_case_visual()
	if not USE_IMAGE_BOARD and _viewport_container != null and is_instance_valid(_viewport_container):
		_viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
		_viewport_container.visible = true
	parts = part_defs.duplicate(true)
	guided_hints = use_guided_hints
	_hint_action = ""
	_case_cover_auto_queued = false
	_case_cover_auto_emitted_for = ""
	_empty_remove_key = ""
	_rebuild_tray()
	_clear_installed()
	set_step_hint("", "", "")
	if not _pending_seed.is_empty():
		apply_seed_state(_pending_seed)
	else:
		_seed_state.clear()
		_graded_removals = false
	if USE_IMAGE_BOARD:
		_rebuild_slot_buttons()
	if HIDE_CASE_COVER and not installed_parts.has("side_panel"):
		# Bookkeeping only — chassis stays visually open (no blue cover mesh).
		installed_parts["side_panel"] = LID_SLOT
	_has_pending_setup = false


func ensure_open_chassis_bookkeeping() -> void:
	## Called after seed so remove "side_panel" steps still have a part to grade
	## even though the physical slot/mesh is hidden (HIDE_CASE_COVER).
	if not HIDE_CASE_COVER:
		return
	if not installed_parts.has("side_panel"):
		installed_parts["side_panel"] = LID_SLOT


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
	# Re-arm the one-shot guards, otherwise the hidden Case Cover step never
	# auto-completes again after a reset and the run stalls on "remove the cover".
	_case_cover_auto_queued = false
	_case_cover_auto_emitted_for = ""
	_empty_remove_key = ""
	set_step_hint("", "", "")
	if _seed_state.is_empty():
		_clear_installed()
		_graded_removals = false
	else:
		apply_seed_state(_seed_state)
	ensure_open_chassis_bookkeeping()


func _place_part(part_id: String, slot_id: String, faulty: bool = false) -> void:
	if not slots.has(slot_id):
		return
	if slot_id == "board_mount":
		_return_board_home()
	installed_parts[part_id] = slot_id
	if faulty:
		_faulty_installs[part_id] = true
	slots[slot_id].set_occupied(true)
	_spawn_part_visual(part_id, slot_id, faulty)
	_refresh_tray_states()
	_refresh_selected_label()
	_rebuild_slot_buttons()


func set_step_hint(target: String, destination: String, action: String = "") -> void:
	var prev_target := _hint_target
	var prev_destination := _hint_destination
	var prev_action := _hint_action
	_hint_target = target
	_hint_destination = destination
	# Explicit action from the shell wins; otherwise keep the last known mode.
	if action != "":
		_hint_action = action
	elif _hint_action == "" and _graded_removals and target != "" and str(installed_parts.get(target, "")) == destination:
		_hint_action = "remove"
	var remove_mode := _hint_action == "remove"
	var hint_changed := (
		target != prev_target
		or destination != prev_destination
		or _hint_action != prev_action
	)
	if HIDE_CASE_COVER and (destination == LID_SLOT or target == "side_panel"):
		_queue_case_cover_auto_complete()
	if remove_mode and target != "" and target != "side_panel":
		if not installed_parts.has(target):
			# Only auto-complete when this remove step is newly assigned.
			# Refreshing the same hint after an Incorrect warn must NOT advance.
			if hint_changed:
				_queue_empty_remove(target, destination)
		elif _find_installed_visual(target) == null:
			var home := str(installed_parts.get(target, destination))
			if home != "":
				_spawn_part_visual(target, home, false)
	var highlight_ok := false
	for slot_id in slots.keys():
		var slot: Area3D = slots[slot_id] as Area3D
		if slot == null:
			continue
		var highlight := guided_hints and destination != "" and str(slot_id) == destination
		if slot.has_method("set_highlighted"):
			# Install: yellow empty bay. Disassemble: yellow rim on the occupied target.
			slot.call("set_highlighted", highlight)
			if highlight:
				highlight_ok = true
	_rebuild_slot_buttons()
	highlight_part(target)
	if _hint_label != null:
		if remove_mode:
			_hint_label.text = _remove_cue(_part_title(target) if target != "" else "part")
		elif destination == "":
			_hint_label.text = "Drag a part onto its named slot (Power Supply Unit, Motherboard, CPU, CPU Fan, Random Access Memory, Hard Disk Drive)."
		elif highlight_ok:
			_hint_label.text = "Drop %s onto the yellow highlighted %s bay%s." % [
				_part_title(target) if target != "" else "the part",
				_slot_title(destination),
				_bay_location(destination)
			]
		else:
			_hint_label.text = "Drop %s onto the %s bay%s." % [
				_part_title(target) if target != "" else "the part",
				_slot_title(destination),
				_bay_location(destination)
			]
		_hint_label.add_theme_color_override(
			"font_color",
			Color(1.0, 0.82, 0.35, 1) if remove_mode else Color(0.98, 0.94, 0.72, 1)
		)


func _bay_location(slot_id: String) -> String:
	if not _board_on_bench:
		return ""
	if BENCH_PREP_SLOTS.has(slot_id):
		return " on the motherboard outside the case"
	if slot_id == "board_mount":
		return " inside the case"
	return ""


func _is_remove_hint() -> bool:
	# An explicit install step stays install even if that part is still seated.
	if _hint_action == "install":
		return false
	if _hint_action == "remove":
		return true
	return _graded_removals and _hint_target != "" and str(installed_parts.get(_hint_target, "")) == _hint_destination


func _remove_cue(part_name: String) -> String:
	# Assessment has no yellow glow. Don't tell the student to tap a glow that isn't there.
	if guided_hints:
		return "Tap the glowing %s to remove it — do not drop parts yet." % part_name
	return "Tap the %s in the case to remove it — do not drop parts yet." % part_name


func _queue_empty_remove(part_id: String, slot_id: String) -> void:
	var key := "remove:%s:%s" % [part_id, slot_id]
	if _empty_remove_key == key:
		return
	_empty_remove_key = key
	call_deferred("_emit_empty_remove", part_id, slot_id)


func _emit_empty_remove(part_id: String, slot_id: String) -> void:
	if _hint_action != "remove":
		return
	if installed_parts.has(part_id):
		return
	_clear_part_glow()
	var dest := slot_id if slot_id != "" else str(PART_HOME.get(part_id, ""))
	action_submitted.emit(SimulationAction.new("remove", part_id, dest))


func clear_step_guides() -> void:
	_hint_target = ""
	_hint_destination = ""
	_hint_action = ""
	_clear_part_glow()
	for slot_id in slots.keys():
		var slot: Node = slots[slot_id]
		if slot != null and is_instance_valid(slot) and slot.has_method("set_highlighted"):
			slot.set_highlighted(false)


func _queue_case_cover_auto_complete() -> void:
	if _case_cover_auto_queued:
		return
	var key := "%s:%s" % [_hint_action, _hint_target]
	if _case_cover_auto_emitted_for == key:
		return
	_case_cover_auto_queued = true
	call_deferred("_auto_complete_case_cover_step")


func _auto_complete_case_cover_step() -> void:
	_case_cover_auto_queued = false
	if not HIDE_CASE_COVER:
		return
	if str(_hint_destination) != LID_SLOT and str(_hint_target) != "side_panel":
		return
	# Match the guided step action — never emit install during a remove step
	# (that used to fail validation, re-hint, and freeze the app).
	var want_remove := _hint_action == "remove" or _is_remove_hint()
	var key := "%s:%s" % [("remove" if want_remove else "install"), "side_panel"]
	if _case_cover_auto_emitted_for == key:
		return
	_case_cover_auto_emitted_for = key
	if want_remove:
		installed_parts.erase("side_panel")
		_faulty_installs.erase("side_panel")
		if slots.has(LID_SLOT) and slots[LID_SLOT].has_method("set_occupied"):
			slots[LID_SLOT].set_occupied(false)
		action_submitted.emit(SimulationAction.new("remove", "side_panel", LID_SLOT))
		if _hint_label != null:
			_hint_label.text = "Case Cover skipped — chassis open for a clear bay view."
	else:
		installed_parts["side_panel"] = LID_SLOT
		if slots.has(LID_SLOT) and slots[LID_SLOT].has_method("set_occupied"):
			slots[LID_SLOT].set_occupied(true)
		action_submitted.emit(SimulationAction.new("install", "side_panel", LID_SLOT))
		if _hint_label != null:
			_hint_label.text = "Case Cover step auto-done — panel stays off so you can see inside."
	if _hint_label != null:
		_hint_label.add_theme_color_override("font_color", Color(0.55, 0.9, 0.75, 1))
	_refresh_tray_states()


func highlight_part(part_id: String) -> void:
	_hint_target = part_id if part_id != "" else _hint_target
	_clear_part_glow()
	if guided_hints and part_id != "":
		var visual := _find_installed_visual(part_id)
		if visual != null:
			_glowing_visual = visual
			_apply_part_glow(visual, true)
			_start_part_glow_pulse(visual)
	_refresh_tray_states()


func _find_installed_visual(part_id: String) -> Node3D:
	var slot_id := str(installed_parts.get(part_id, ""))
	if slot_id == "" or not slots.has(slot_id):
		return null
	var slot: Node = slots[slot_id] as Node
	if slot == null:
		return null
	var named := slot.get_node_or_null("Installed_%s" % part_id) as Node3D
	if named != null:
		return named
	for child in slot.get_children():
		if child is Node3D and bool(child.get_meta("sb_installed_part", false)):
			if str(child.get_meta("sb_part_id", "")) == part_id or child.name.begins_with("Installed_"):
				return child as Node3D
	return null


func _apply_part_glow(root: Node, on: bool) -> void:
	if root == null or not is_instance_valid(root):
		return
	if root is GeometryInstance3D:
		var gi := root as GeometryInstance3D
		if on:
			var overlay := StandardMaterial3D.new()
			overlay.albedo_color = Color(1.0, 0.85, 0.15, 0.35)
			overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			overlay.emission_enabled = true
			overlay.emission = Color(1.0, 0.9, 0.2)
			overlay.emission_energy_multiplier = 2.4
			gi.material_overlay = overlay
		else:
			gi.material_overlay = null
	for child in root.get_children():
		_apply_part_glow(child, on)


func _start_part_glow_pulse(visual: Node3D) -> void:
	# Node3D has no modulate (CanvasItem only) — tweening it crashes with
	# "Type mismatch … Nil and Color" then SIGSEGV on Android Vulkan.
	if visual == null or not is_instance_valid(visual):
		return
	if _glow_tween != null and _glow_tween.is_valid():
		_glow_tween.kill()
	if not visual.has_meta("sb_glow_base_scale"):
		visual.set_meta("sb_glow_base_scale", visual.scale)
	var base: Vector3 = visual.get_meta("sb_glow_base_scale") as Vector3
	_glow_tween = create_tween()
	_glow_tween.set_loops()
	_glow_tween.tween_property(visual, "scale", base * 1.1, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_property(visual, "scale", base, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _clear_part_glow() -> void:
	if _glow_tween != null and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = null
	if _glowing_visual != null and is_instance_valid(_glowing_visual):
		_apply_part_glow(_glowing_visual, false)
		if _glowing_visual.has_meta("sb_glow_base_scale"):
			_glowing_visual.scale = _glowing_visual.get_meta("sb_glow_base_scale") as Vector3
			_glowing_visual.remove_meta("sb_glow_base_scale")
	_glowing_visual = null


func mark_installed(part_id: String, slot_id: String) -> void:
	if slot_id == "board_mount":
		_return_board_home()
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
		_hint_label.text = "Seated %s into %s." % [_part_title(part_id), _slot_title(slot_id)]
		_hint_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.7, 1))


func flash_incorrect(placed_part: String = "", placed_slot: String = "") -> void:
	var part_id: String = placed_part if placed_part != "" else _last_attempt_part
	if part_id == "" and selected_part_id != "":
		part_id = selected_part_id
	if part_id == "" and _hint_target != "":
		part_id = _hint_target
	var slot_id: String = placed_slot if placed_slot != "" else _last_attempt_slot
	var expected_part: String = _hint_target
	var expected_slot: String = _hint_destination
	if expected_slot == "" and part_id != "":
		expected_slot = str(PART_HOME.get(part_id, ""))
	if expected_part == "":
		expected_part = part_id
	var detail: String
	if _is_remove_hint() or _hint_action == "remove":
		var cue := "the glowing part" if guided_hints else "the part this step asks for"
		detail = "You removed: %s → %s\nExpected: remove %s from %s\nTap only %s." % [
			_part_title(part_id) if part_id != "" else "—",
			_slot_title(slot_id) if slot_id != "" else "—",
			_part_title(expected_part) if expected_part != "" else "the highlighted part",
			_slot_title(expected_slot) if expected_slot != "" else "its bay",
			cue,
		]
	else:
		detail = _format_wrong_placement(part_id, slot_id, expected_part, expected_slot)
	# Shell already opened the Incorrect panel for manager refusals.
	_warn(detail, false)
	if guided_hints and _hint_target != "" and _hint_destination != "":
		if not (HIDE_CASE_COVER and (_hint_target == "side_panel" or _hint_destination == LID_SLOT)):
			set_step_hint(_hint_target, _hint_destination, _hint_action)
	get_tree().create_timer(2.2).timeout.connect(_restore_hint_after_flash)


func _format_wrong_placement(
	placed_part: String, placed_slot: String, expected_part: String, expected_slot: String
) -> String:
	var you_placed := "—"
	if placed_part != "":
		you_placed = _part_title(placed_part)
		if placed_slot != "":
			you_placed += " → %s" % _slot_title(placed_slot)
	var expected := "—"
	if expected_part != "" or expected_slot != "":
		var exp_part := _part_title(expected_part) if expected_part != "" else "part"
		var exp_slot := _slot_title(expected_slot) if expected_slot != "" else "its bay"
		expected = "%s → %s" % [exp_part, exp_slot]
	var why := _tesda_why(expected_part if expected_part != "" else placed_part, expected_slot)
	var why_not := _tesda_why_not(placed_part, placed_slot, expected_slot)
	return "You placed: %s\nExpected: %s\nWhy? %s\nWhy not %s? %s" % [
		you_placed,
		expected,
		why,
		_part_title(placed_part) if placed_part != "" else "that",
		why_not
	]


func _tesda_why(part_id: String, slot_id: String) -> String:
	match part_id:
		"psu":
			return "Mount the Power Supply Unit first so cables clear the tray (TESDA order)."
		"motherboard":
			return "Fit the CPU, CPU fan and Random Access Memory first, then match the standoffs to every hole."
		"cpu":
			return "Seat the CPU while the board is still outside the case — align the triangle marker."
		"cooler":
			return "Mount the CPU Fan on the board outside the case — even pressure prevents socket damage."
		"fan_cable":
			return "CPU_FAN keeps the cooler spinning at POST."
		"ram":
			return "Click the Random Access Memory in before the board goes into the case — the notch must face the right way."
		"ssd":
			return "Seat storage in the drive bay before closing the case."
		"gpu":
			return "PCIe latch must catch before you power on."
		"atx_24pin":
			return "Main board power latches until it clicks, then tug-test."
		"cpu_power":
			return "EPS near the socket feeds the CPU VRM."
		"front_wires":
			return "Front-panel header maps Power SW / LED correctly."
		"side_panel":
			return "Case cover goes on last after every bay is filled."
		_:
			if slot_id != "":
				return "Seat this part only in %s." % _slot_title(slot_id)
			return "Follow the guided bay for a safe TESDA build order."


func _tesda_why_not(placed_part: String, placed_slot: String, expected_slot: String) -> String:
	if placed_slot != "" and expected_slot != "" and placed_slot != expected_slot:
		return "%s is the wrong bay — that part belongs in %s." % [
			_slot_title(placed_slot), _slot_title(expected_slot)
		]
	if placed_part != "" and expected_slot != "":
		var home: String = str(PART_HOME.get(placed_part, ""))
		if home != "" and home != expected_slot:
			return "This step needs a different part; %s seats in %s." % [
				_part_title(placed_part), _slot_title(home)
			]
	return "Wrong part or wrong bay for this step — re-read the yellow guide."


func _warn(text: String, popup: bool = true) -> void:
	var body := text.trim_prefix("⚠ ").strip_edges()
	if _hint_label != null:
		_hint_label.text = text if (
			text.begins_with("You placed:") or text.begins_with("You removed:")
		) else ("⚠ %s" % text)
		_hint_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.35, 1))
		# Pulse so the rule feedback is impossible to miss on a live demo.
		_hint_label.modulate = Color(1.2, 1.0, 0.9, 1)
		var tween := create_tween()
		tween.tween_property(_hint_label, "modulate", Color.WHITE, 0.35)
	if popup and body != "":
		# Freeze the bench until the Incorrect dialog is dismissed so a follow-up
		# tap cannot complete the step while the modal is still open.
		_interaction_locked = true
		coach_message.emit(false, "Incorrect", body)


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
	if _case_frame != null:
		_case_frame.visible = false
	_ensure_case_structure()


func _ensure_case_walls() -> void:
	_ensure_case_structure()


func _ensure_case_structure() -> void:
	var bench := _bench_root()
	if bench == null:
		push_warning("PcBuildBench: Bench node missing — empty case cannot mount")
		return
	var old_walls := bench.get_node_or_null("CaseWalls")
	if old_walls != null:
		old_walls.queue_free()
	var existing := bench.get_node_or_null("CaseStructure")
	if existing != null:
		existing.name = "CaseStructure_OLD"
		existing.queue_free()
	var root := Node3D.new()
	root.name = "CaseStructure"
	bench.add_child(root)
	_mount_empty_case()


func _restore_hint_after_flash() -> void:
	if not is_instance_valid(_hint_label):
		return
	_hint_label.add_theme_color_override("font_color", Color(0.75, 0.9, 0.98, 0.95))
	if not (HIDE_CASE_COVER and (_hint_target == "side_panel" or _hint_destination == LID_SLOT)):
		set_step_hint(_hint_target, _hint_destination, _hint_action)


func _mount_empty_case() -> void:
	_bind_nodes()
	if _viewport_margin != null:
		var overlay := _viewport_margin.get_node_or_null("EmptyCaseImage")
		if overlay != null:
			overlay.queue_free()
	var bench := _bench_root()
	if bench == null:
		return
	var root := bench.get_node_or_null("CaseStructure") as Node3D
	if root == null:
		return
	var cx := CASE_CX
	var cy := CASE_CY
	var cz := CASE_CZ
	var w := CASE_W
	var h := CASE_H
	var d := CASE_D
	var t := CASE_T
	var shell := _case_mat(Color(0.18, 0.19, 0.22), 0.35, 0.48)
	var shell_hi := _case_mat(Color(0.28, 0.30, 0.34), 0.4, 0.42)
	var inner := _case_mat(Color(0.38, 0.40, 0.44), 0.08, 0.78)
	var trim := _case_mat(Color(0.08, 0.09, 0.1), 0.55, 0.35)
	var accent := _case_mat(Color(0.12, 0.55, 0.72), 0.2, 0.4)
	var foot_mat := _case_mat(Color(0.05, 0.05, 0.06), 0.05, 0.9)
	var mesh_mat := _case_mat(Color(0.14, 0.15, 0.17), 0.25, 0.7)
	# Floor / roof / back / sides (open +Z).
	root.add_child(_make_box_mesh(Vector3(w, t, d), Vector3(cx, cy - h * 0.5 + t * 0.5, cz), shell))
	root.add_child(_make_box_mesh(Vector3(w, t * 0.85, d), Vector3(cx, cy + h * 0.5 - t * 0.5, cz), shell_hi))
	root.add_child(_make_box_mesh(Vector3(w - t * 2.0, h - t * 2.0, 0.03), Vector3(cx, cy, cz - d * 0.5 + t + 0.02), inner))
	root.add_child(_make_box_mesh(Vector3(w, h, t), Vector3(cx, cy, cz - d * 0.5 + t * 0.5), shell))
	root.add_child(_make_box_mesh(Vector3(t, h, d), Vector3(cx - w * 0.5 + t * 0.5, cy, cz), shell))
	root.add_child(_make_box_mesh(Vector3(t, h, d), Vector3(cx + w * 0.5 - t * 0.5, cy, cz), shell))
	# Soft corner posts (curves).
	var post_r := 0.055
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			if sz > 0.0:
				continue # open face keeps airy corners
			root.add_child(_make_cyl_mesh(
				post_r, h - t * 2.2,
				Vector3(cx + sx * (w * 0.5 - t - 0.01), cy, cz + sz * (d * 0.5 - t - 0.01)),
				shell_hi, Vector3.ZERO
			))
	# Open-face bevel frame.
	var fz := cz + d * 0.5 - t * 0.45
	var rail := 0.07
	root.add_child(_make_box_mesh(Vector3(w, rail, t * 0.9), Vector3(cx, cy + h * 0.5 - rail * 0.5, fz), trim))
	root.add_child(_make_box_mesh(Vector3(w, rail, t * 0.9), Vector3(cx, cy - h * 0.5 + rail * 0.5, fz), trim))
	root.add_child(_make_box_mesh(Vector3(rail, h, t * 0.9), Vector3(cx - w * 0.5 + rail * 0.5, cy, fz), trim))
	root.add_child(_make_box_mesh(Vector3(rail, h, t * 0.9), Vector3(cx + w * 0.5 - rail * 0.5, cy, fz), trim))
	# Front panel (-X) with dual intake fans + power accent.
	var front_x := cx - w * 0.5 + t * 0.55
	root.add_child(_make_box_mesh(Vector3(0.04, h * 0.92, d * 0.72), Vector3(front_x, cy, cz + 0.02), trim))
	_add_case_fan(root, Vector3(front_x + 0.03, cy + 0.28, cz + 0.02), 0.2, mesh_mat, accent)
	_add_case_fan(root, Vector3(front_x + 0.03, cy - 0.18, cz + 0.02), 0.2, mesh_mat, accent)
	root.add_child(_make_box_mesh(Vector3(0.03, 0.04, 0.18), Vector3(front_x + 0.02, cy + h * 0.38, cz + 0.28), accent))
	# Top exhaust fan + mesh vent.
	var top_y := cy + h * 0.5 - t * 0.2
	root.add_child(_make_box_mesh(Vector3(w * 0.55, 0.02, d * 0.4), Vector3(cx - 0.08, top_y, cz - 0.05), mesh_mat))
	_add_case_fan(root, Vector3(cx - 0.08, top_y - 0.03, cz - 0.05), 0.16, mesh_mat, accent, true)
	# Rear slot cover strip (+X).
	var rear_x := cx + w * 0.5 - t * 0.55
	root.add_child(_make_box_mesh(Vector3(0.03, h * 0.55, 0.22), Vector3(rear_x, cy + 0.05, cz - d * 0.18), trim))
	for i in range(5):
		root.add_child(_make_box_mesh(
			Vector3(0.02, 0.06, 0.18),
			Vector3(rear_x - 0.01, cy + 0.28 - i * 0.1, cz - d * 0.18),
			shell_hi
		))
	# PSU shroud (bottom rear).
	root.add_child(_make_box_mesh(
		Vector3(w * 0.72, 0.22, d * 0.42),
		Vector3(cx + 0.04, cy - h * 0.5 + 0.16, cz - d * 0.18),
		shell_hi
	))
	# Feet.
	var fy := cy - h * 0.5 - 0.03
	for sx2 in [-1.0, 1.0]:
		for sz2 in [-1.0, 1.0]:
			root.add_child(_make_box_mesh(
				Vector3(0.14, 0.06, 0.16),
				Vector3(cx + sx2 * w * 0.34, fy, cz + sz2 * d * 0.28),
				foot_mat
			))
	if _subviewport != null and is_instance_valid(_subviewport):
		_subviewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	if _camera != null and is_instance_valid(_camera):
		_camera.current = true
	_update_camera()


func _add_case_fan(
	root: Node3D,
	pos: Vector3,
	radius: float,
	frame_mat: Material,
	blade_mat: Material,
	flat_on_xz: bool = false
) -> void:
	var frame := _make_cyl_mesh(radius, 0.04, pos, frame_mat, Vector3(0, 0, 90) if not flat_on_xz else Vector3.ZERO)
	root.add_child(frame)
	var hub := _make_cyl_mesh(radius * 0.28, 0.05, pos, blade_mat, frame.rotation_degrees)
	root.add_child(hub)
	for i in range(4):
		var blade := _make_box_mesh(
			Vector3(radius * 1.5, 0.015, radius * 0.28),
			pos,
			blade_mat
		)
		blade.rotation_degrees = frame.rotation_degrees + Vector3(0, 45.0 * i, 0)
		if flat_on_xz:
			blade.rotation_degrees = Vector3(0, 45.0 * i, 0)
		else:
			blade.rotation_degrees = Vector3(0, 0, 90) + Vector3(45.0 * i, 0, 0)
		root.add_child(blade)


func _case_mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = rough
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _make_box_mesh(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi


func _make_cyl_mesh(radius: float, height: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi


func _build_default_slots() -> void:
	_bind_nodes()
	if _slots_root == null:
		return
	for child in _slots_root.get_children():
		child.queue_free()
	slots.clear()
	_board_on_bench = false
	_bench_board_anchor = null
	# Motherboard centered on the back tray. Board parts share that ATX plane.
	var mb_x := CASE_CX
	var mb_y := CASE_CY + 0.06
	var back_inner := CASE_CZ - CASE_D * 0.5 + CASE_T + 0.04
	var mb_face_z := back_inner + 0.05
	_add_slot("board_mount", "Motherboard", Vector3(mb_x, mb_y, back_inner), Vector3(0.78, 0.72, 0.04))
	# Slots are calibrated to the Sketchfab motherboard (I/O on -X, DIMMs on +X).
	# CPU socket (cream square) sits upper-center; nudge +X/+Y until the die sits inside it.
	_add_slot("cpu_socket", "CPU", Vector3(mb_x + 0.05, mb_y + 0.20, mb_face_z), Vector3(0.11, 0.11, 0.04))
	_add_slot("cooler_mount", "CPU Fan", Vector3(mb_x + 0.05, mb_y + 0.20, mb_face_z + 0.07), Vector3(0.15, 0.15, 0.12))
	# DIMM slots run vertically (along +Y) on the right side of the board.
	_add_slot("dimm_slot", "Random Access Memory", Vector3(mb_x + 0.26, mb_y + 0.02, mb_face_z + 0.02), Vector3(0.05, 0.30, 0.05))
	_add_slot("atx_socket", "24-pin Main Power", Vector3(mb_x + 0.30, mb_y - 0.10, mb_face_z + 0.02), Vector3(0.12, 0.07, 0.05))
	_add_slot("eps_socket", "CPU Power", Vector3(mb_x - 0.28, mb_y + 0.24, mb_face_z + 0.02), Vector3(0.13, 0.09, 0.08))
	_add_slot("fan_header", "Fan Header", Vector3(mb_x + 0.06, mb_y + 0.24, mb_face_z + 0.02), Vector3(0.06, 0.04, 0.04))
	_add_slot("pcie_slot", "PCIe · Graphics Card", Vector3(mb_x + 0.01, mb_y - 0.22, mb_face_z + 0.02), Vector3(0.52, 0.07, 0.16))
	_add_slot("psu_bay", "Power Supply Unit", Vector3(CASE_CX + 0.04, CASE_CY - CASE_H * 0.5 + 0.2, CASE_CZ - 0.12), Vector3(0.36, 0.18, 0.36))
	_add_slot("storage_bay", "Hard Disk Drive", Vector3(CASE_CX + 0.28, CASE_CY - 0.22, CASE_CZ + 0.1), Vector3(0.22, 0.1, 0.14))
	_add_slot("optical_bay", "Optical Drive", Vector3(CASE_CX - 0.22, CASE_CY + 0.32, CASE_CZ + 0.08), Vector3(0.28, 0.1, 0.2))
	_add_slot("sata_power_port", "SATA Power", Vector3(CASE_CX + 0.22, CASE_CY - 0.14, CASE_CZ + 0.02), Vector3(0.1, 0.06, 0.08))
	_add_slot("front_panel", "Front Panel", Vector3(mb_x + 0.28, mb_y - 0.28, mb_face_z + 0.02), Vector3(0.08, 0.1, 0.05))
	if not HIDE_CASE_COVER:
		_add_slot("side_panel", "Case Cover", Vector3(CASE_CX, CASE_CY, CASE_CZ + CASE_D * 0.5), Vector3(CASE_W * 0.95, CASE_H * 0.95, 0.04))
	_ensure_case_visual()


func _add_slot(id: String, title: String, pos: Vector3, size: Vector3) -> void:
	if _slots_root == null:
		return
	var slot: Area3D = SLOT_SCRIPT.new()
	slot.name = id
	slot.input_ray_pickable = true
	_slots_root.add_child(slot)
	slot.position = pos
	slot.setup(id, title, size)
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
		if HIDE_CASE_COVER and part_id == "side_panel":
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
	# Normalize cooler / cpu_fan naming so tray matches the bay label.
	var tray_label: String = str(part.get("label", part_id))
	if part_id == "cooler" or part_id == "cpu_fan":
		tray_label = "CPU Fan"
	title.text = tray_label
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(13))
	title.add_theme_color_override("font_color", Color(0.95, 0.98, 1, 1))
	copy.add_child(title)

	var hint := Label.new()
	hint.text = _tray_hint_for(part_id)
	hint.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(10))
	hint.add_theme_color_override("font_color", Color(0.55, 0.82, 0.95, 0.85))
	copy.add_child(hint)
	card.set_meta("hint_label", hint)
	card.set_meta("part_id", part_id)
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
		_selected_label.text = "Scroll parts, then drag onto the named slot."
	else:
		_selected_label.text = "Selected: %s — %s" % [
			_part_title(selected_part_id),
			_tray_hint_for(selected_part_id)
		]


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
		panel.bg_color = Color(0.04, 0.08, 0.1, 1.0)
	elif selected:
		panel.bg_color = Color(0.07, 0.36, 0.50, 1.0)
	elif recommended:
		panel.bg_color = Color(0.40, 0.33, 0.07, 1.0)
	else:
		panel.bg_color = Color(0.03, 0.12, 0.18, 1.0)
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
	# Keep completed card labels readable on Android displays.
	card.modulate.a = 0.82 if done else 1.0
	if card.has_meta("hint_label"):
		var hint: Label = card.get_meta("hint_label")
		var part_id: String = str(card.get_meta("part_id", ""))
		if hint != null:
			if done:
				hint.text = "Seated ✓"
			elif recommended:
				hint.text = "▶ %s" % _tray_hint_for(part_id)
			else:
				hint.text = _tray_hint_for(part_id)


func _tray_hint_for(part_id: String) -> String:
	var home: String = str(PART_HOME.get(part_id, ""))
	if home == "":
		return "→ named slot"
	return "→ %s" % _slot_title(home)


func _handle_slot_tap(slot_id: String) -> void:
	if _interaction_locked or _dragging_part:
		return
	# Tapping a seated part pulls it back out. Empty bays wait for a drop.
	if _is_filled(slot_id):
		_try_remove(slot_id)
		return
	if _is_remove_hint():
		# Empty bay during teardown (e.g. the spot a part was just pulled from).
		return
	if selected_part_id != "":
		_try_install(slot_id)


func _is_teardown_tap() -> bool:
	return _hint_target != "" and _hint_destination != "" and _is_remove_hint()


## Resolve a screen tap to a bay. Small seated parts (CPU Power, fan cable) sit
## deep in the case, so a tap near the glowing part counts as that part unless a
## different seated part is clearly closer to the finger.
func _resolve_tap_slot(global_pos: Vector2) -> String:
	if _viewport_container == null or _subviewport == null or _camera == null:
		return ""
	var rect := _viewport_container.get_global_rect()
	if not rect.has_point(global_pos):
		return ""
	var ranked: Dictionary = _rank_slots_on_screen(global_pos, rect)
	var dist: Dictionary = ranked.get("dist", {}) as Dictionary
	var hit := _raycast_slot(global_pos, rect)
	if hit != "" and not _is_filled(hit) and _is_teardown_tap():
		hit = ""
	if guided_hints and _is_teardown_tap() and dist.has(_hint_destination):
		var dest_dist: float = float(dist[_hint_destination])
		var snap_px: float = maxf(TAP_SNAP_MIN_PX, rect.size.y * TAP_SNAP_FRACTION)
		if hit == _hint_destination:
			return hit
		if dest_dist <= snap_px:
			if hit == "" or hit == "board_mount" or not dist.has(hit) or dest_dist <= float(dist[hit]):
				return _hint_destination
	if hit != "":
		return hit
	var best := ""
	var best_dist := TAP_NEAREST_PX
	for slot_id in dist.keys():
		var id := str(slot_id)
		if id == LID_SLOT or not _is_filled(id):
			continue
		if float(dist[id]) < best_dist:
			best_dist = float(dist[id])
			best = id
	return best


func _handle_viewport_tap(event: InputEvent) -> void:
	var pressed := false
	var released := false
	if event is InputEventScreenTouch and event.index == 0:
		pressed = event.pressed
		released = not event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		released = not event.pressed
	elif event is InputEventScreenDrag and event.index == 0:
		if (event.position - _tap_down_pos).length() > TAP_MOVE_SLOP_PX:
			_tap_moved = true
		return
	elif event is InputEventMouseMotion and _tap_armed:
		if (event.position - _tap_down_pos).length() > TAP_MOVE_SLOP_PX:
			_tap_moved = true
		return
	else:
		return
	var now := Time.get_ticks_msec()
	if pressed:
		# Touch arrives twice on Android (touch + emulated mouse); keep the first.
		if _tap_armed and now - _tap_down_msec < TAP_DUPLICATE_MS:
			return
		_tap_armed = true
		_tap_moved = false
		_tap_down_pos = event.position
		_tap_down_msec = now
		return
	if not released or not _tap_armed:
		return
	_tap_armed = false
	if _tap_moved or _pinch_active or now - _tap_down_msec > TAP_MAX_MS:
		return
	if now - _last_tap_msec < TAP_DUPLICATE_MS:
		return
	_last_tap_msec = now
	var global_pos: Vector2 = _viewport_container.get_global_rect().position + event.position
	var slot_id := _resolve_tap_slot(global_pos)
	if slot_id != "":
		_handle_slot_tap(slot_id)


func _try_install(slot_id: String) -> void:
	if _interaction_locked:
		return
	if _is_remove_hint():
		_warn("Disassembly step — tap the %s in the case to remove it. Do not drop from the tray yet." % (
			"glowing part" if guided_hints else "part this step asks for"
		))
		_restore_step_hint()
		return
	if selected_part_id == "":
		if _hint_label != null:
			_hint_label.text = "Pick a part from the tray, then drop it on its named slot."
		return
	if installed_parts.has(selected_part_id):
		return
	_last_attempt_part = selected_part_id
	_last_attempt_slot = slot_id
	if slots.has(slot_id) and slots[slot_id].is_occupied():
		_warn("That slot is already filled — tap the seated part to remove it first.")
		_restore_step_hint()
		return
	# Guided assemble: only the current step's part + yellow bay count.
	# Wrong tray picks used to retarget the yellow bay and mix up HDD/GPU/RAM.
	if guided_hints and _hint_target != "" and selected_part_id != _hint_target:
		_warn(
			"This step needs %s — you picked %s. Put it back and take the highlighted part." % [
				_part_title(_hint_target), _part_title(selected_part_id)
			]
		)
		_restore_step_hint()
		return
	if guided_hints and _hint_destination != "" and slot_id != _hint_destination:
		_warn(
			"Drop %s onto the yellow %s bay — not %s." % [
				_part_title(selected_part_id),
				_slot_title(_hint_destination),
				_slot_title(slot_id)
			]
		)
		_restore_step_hint()
		return
	# Unguided / assessment: still refuse physically wrong homes.
	var home_slot: String = str(PART_HOME.get(selected_part_id, ""))
	if home_slot != "" and home_slot != slot_id:
		_warn(_format_wrong_placement(selected_part_id, slot_id, selected_part_id, home_slot))
		_restore_step_hint()
		return
	var blocked: String = _install_block_reason(slot_id)
	if blocked != "":
		_warn(blocked)
		_restore_step_hint()
		return
	if str(_verified.get(selected_part_id, "")) == slot_id:
		mark_installed(selected_part_id, slot_id)
		return
	var action := SimulationAction.new("install", selected_part_id, slot_id)
	action_submitted.emit(action)


func _restore_step_hint() -> void:
	if not guided_hints:
		return
	if _hint_target == "" and _hint_destination == "":
		return
	set_step_hint(_hint_target, _hint_destination, _hint_action if _hint_action != "" else "install")


func _slot_title(slot_id: String) -> String:
	var slot = slots.get(slot_id, null)
	if slot != null and is_instance_valid(slot):
		return str(slot.label_text)
	return slot_id.replace("_", " ")


func _part_title(part_id: String) -> String:
	for part_variant in parts:
		var part: Dictionary = part_variant as Dictionary
		if str(part.get("id", "")) == part_id:
			var label: String = str(part.get("label", part_id))
			if part_id == "cooler" or part_id == "cpu_fan":
				return "CPU Fan"
			return label
	match part_id:
		"cooler", "cpu_fan":
			return "CPU Fan"
		"ssd":
			return "Hard Disk Drive"
		"side_panel":
			return "Case Cover"
		"motherboard":
			return "Motherboard"
		_:
			return part_id.replace("_", " ")


func _is_filled(slot_id: String) -> bool:
	var slot = slots.get(slot_id, null)
	return slot != null and is_instance_valid(slot) and slot.is_occupied()


func _install_block_reason(slot_id: String) -> String:
	if not HIDE_CASE_COVER and slot_id != LID_SLOT and _is_filled(LID_SLOT):
		return "Remove the side panel before working inside the case."
	if slot_id == LID_SLOT:
		if HIDE_CASE_COVER:
			return ""
		for other_id in slots.keys():
			if str(other_id) == LID_SLOT:
				continue
			if OPTIONAL_SLOTS.has(str(other_id)) and not _is_filled(str(other_id)):
				continue
			if not _is_filled(str(other_id)):
				return "Finish the internals first — %s is still empty." % _slot_title(str(other_id))
		return ""
	if slot_id == "board_mount":
		for prep_slot in BOARD_MOUNT_REQUIRES:
			if not _is_filled(str(prep_slot)):
				return "Install the CPU, CPU fan, and Random Access Memory on the motherboard first, while it is still outside the case — %s is still empty." % _slot_title(str(prep_slot))
		return ""
	if _board_on_bench and BOARD_CARRIED_SLOTS.has(slot_id) and not BENCH_PREP_SLOTS.has(slot_id):
		return "Install the motherboard in the case first — %s connects once the board is inside." % _slot_title(slot_id)
	for required in SLOT_PREREQS.get(slot_id, []):
		if str(required) == "board_mount" and _board_on_bench:
			continue
		if not _is_filled(str(required)):
			return "Install the %s first — %s mounts onto it." % [
				_slot_title(str(required)), _slot_title(slot_id)
			]
	return ""


func _remove_block_reason(slot_id: String) -> String:
	if not HIDE_CASE_COVER and slot_id != LID_SLOT and _is_filled(LID_SLOT):
		return "Take the side panel off before removing internals."
	# Graded TESDA path: curriculum step order is the authority
	# (cables → PSU → drives → motherboard → RAM → cooler → CPU).
	if _graded_removals:
		return ""
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
		_restore_step_hint()
		return
	var part_id: String = ""
	for candidate in installed_parts.keys():
		if str(installed_parts[candidate]) == slot_id:
			part_id = str(candidate)
			break
	if part_id == "":
		return
	# Graded / guided disassemble: refuse wrong taps BEFORE pulling the part.
	# Previously we removed first then scored — Incorrect dialog but part already gone.
	if _graded_removals and (_hint_action == "remove" or _is_remove_hint()) and _hint_target != "":
		if part_id != _hint_target:
			var which := "glowing " if guided_hints else ""
			_warn(
				"Remove the %s%s first — you tapped %s. Part stays in the case." % [
					which, _part_title(_hint_target), _part_title(part_id)
				]
			)
			_restore_step_hint()
			return
		if _hint_destination != "" and slot_id != _hint_destination:
			_warn(
				"That is not the %s bay — tap the %s." % [
					_slot_title(_hint_destination),
					("glowing " if guided_hints else "") + _part_title(_hint_target)
				]
			)
			_restore_step_hint()
			return
	_clear_part_glow()
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
	if slot_id == "board_mount":
		_move_board_to_bench()
	selected_part_id = part_id
	_refresh_tray_states()
	_refresh_selected_label()
	_rebuild_slot_buttons()
	if _graded_removals:
		action_submitted.emit(SimulationAction.new("remove", part_id, slot_id))
		# The manager already applied the next hint inside the emit.
		# Forcing "remove" here turned the following install step back into
		# "tap the PSU" on a bay that was just emptied.
		if _interaction_locked:
			clear_step_guides()
			if _hint_label != null:
				_hint_label.text = "Removed %s — back in the tray (disassemble)." % _part_title(part_id)
				_hint_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45, 1))
	else:
		set_step_hint(_hint_target, _hint_destination, _hint_action)
		if _hint_label != null:
			_hint_label.text = "Removed %s — back in the tray (disassemble)." % _part_title(part_id)
			_hint_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45, 1))


func _move_board_to_bench() -> void:
	if _board_on_bench or _is_filled("board_mount") or _slots_root == null:
		return
	var board_slot := slots.get("board_mount", null) as Node3D
	if board_slot == null or not is_instance_valid(board_slot):
		return
	_board_on_bench = true
	for slot_id in BOARD_CARRIED_SLOTS:
		var slot := slots.get(slot_id, null) as Node3D
		if slot != null and is_instance_valid(slot):
			slot.position += BOARD_BENCH_OFFSET
	# The empty board_mount bay stays in the case as the drop target for
	# installing the board; the board itself waits out on the bench.
	_bench_board_anchor = Node3D.new()
	_bench_board_anchor.name = "BenchBoardAnchor"
	_slots_root.add_child(_bench_board_anchor)
	_bench_board_anchor.position = board_slot.position + BOARD_BENCH_OFFSET
	# Display-only board: no sb_installed_part meta, and board_mount stays
	# unoccupied, so it is never counted as installed or picked by taps.
	var visual: Node3D = _make_model_part("motherboard")
	var used_model := visual != null
	if visual == null:
		visual = _make_placeholder_part("motherboard")
	visual.name = DETACHED_BOARD_NODE
	visual.set_meta("sb_used_model", used_model)
	visual.set_meta("sb_part_id", "motherboard")
	visual.set_meta("sb_slot_id", "board_mount")
	_bench_board_anchor.add_child(visual)
	visual.rotation_degrees = _slot_part_rotation("board_mount")
	visual.position = Vector3.ZERO
	visual.scale = Vector3.ONE
	call_deferred("_animate_snap_local", visual)


func _return_board_home() -> void:
	if not _board_on_bench:
		return
	_board_on_bench = false
	for slot_id in BOARD_CARRIED_SLOTS:
		var slot := slots.get(slot_id, null) as Node3D
		if slot != null and is_instance_valid(slot):
			slot.position -= BOARD_BENCH_OFFSET
	if _bench_board_anchor != null and is_instance_valid(_bench_board_anchor):
		var parent := _bench_board_anchor.get_parent()
		if parent != null:
			parent.remove_child(_bench_board_anchor)
		_bench_board_anchor.queue_free()
	_bench_board_anchor = null


## Put a wrongly scored removal back into the case (safety net).
func restore_removed_part(part_id: String, slot_id: String) -> void:
	if part_id == "" or slot_id == "":
		return
	if installed_parts.has(part_id):
		return
	if not slots.has(slot_id):
		return
	_place_part(part_id, slot_id, false)
	_restore_step_hint()


func _spawn_part_visual(part_id: String, slot_id: String, faulty: bool = false) -> void:
	if USE_IMAGE_BOARD:
		_rebuild_slot_buttons()
		return
	# Case + motherboard pass — hide every other part mesh for now.
	if ONLY_CASE_AND_MOTHERBOARD and part_id != "motherboard":
		return
	_bind_nodes()
	if not slots.has(slot_id) or _installed_root == null:
		return
	var slot: Node3D = slots[slot_id]
	# Drop any prior mesh for this part in this bay.
	var old := slot.get_node_or_null("Installed_%s" % part_id)
	if old != null:
		old.queue_free()
	var visual: Node3D = _make_model_part(part_id, faulty)
	var used_model := visual != null
	if visual == null:
		visual = _make_placeholder_part(part_id, faulty)
	visual.name = "Installed_%s" % part_id
	visual.set_meta("sb_installed_part", true)
	visual.set_meta("sb_used_model", used_model)
	visual.set_meta("sb_part_id", part_id)
	visual.set_meta("sb_slot_id", slot_id)
	# Parent to the slot so alignment always matches the bay.
	slot.add_child(visual)
	visual.rotation_degrees = _slot_part_rotation(slot_id)
	visual.position = Vector3.ZERO
	visual.scale = Vector3.ONE
	call_deferred("_animate_snap_local", visual)


func _slot_part_rotation(slot_id: String) -> Vector3:
	# Motherboard on back tray: component face (+Y) → open face (+Z).
	match slot_id:
		"board_mount", "cpu_socket", "cooler_mount", \
		"atx_socket", "eps_socket", "fan_header", "front_panel":
			return Vector3(90, 0, 0)
		"dimm_slot":
			# Factory RAM is length-X / height-Y / thin-Z. Stand it out of the board
			# (height → +Z) and align length with the vertical DIMM slots (+Y).
			return Vector3(90, 0, 90)
		"pcie_slot":
			# The factory GPU already uses the physical X/Z card plane: its long
			# edge runs across the PCIe slot and its height faces the open case.
			return Vector3.ZERO
		_:
			return Vector3.ZERO


func _animate_snap_local(visual: Node3D) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	await get_tree().process_frame
	if not is_instance_valid(visual) or not visual.is_inside_tree():
		return
	var part_id := str(visual.get_meta("sb_part_id", ""))
	var slot_id := str(visual.get_meta("sb_slot_id", ""))
	var used_model: bool = bool(visual.get_meta("sb_used_model", false))
	if used_model:
		_fit_visual(visual, _fit_size_for_part(part_id))
	else:
		visual.position = Vector3.ZERO
		visual.scale = Vector3.ONE
	_seat_part_in_slot(visual, part_id, slot_id)
	var target_scale: Vector3 = visual.scale
	var target_pos: Vector3 = visual.position
	visual.scale = target_scale * 0.2
	visual.position = target_pos
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", target_scale, 0.28)


func _pin_flat_on_board(visual: Node3D) -> void:
	## Center on the bay in X/Y, then press the back face onto the motherboard (local z = 0).
	var aabb := _combined_aabb(visual)
	var center := aabb.get_center()
	visual.position.x -= center.x
	visual.position.y -= center.y
	aabb = _combined_aabb(visual)
	visual.position.z += 0.01 - aabb.position.z


func _seat_ram_in_slot(visual: Node3D) -> void:
	## Keep the stick centered in the DIMM bay and standing out of the board.
	var aabb := _combined_aabb(visual)
	var center := aabb.get_center()
	visual.position.x -= center.x
	visual.position.y -= center.y
	aabb = _combined_aabb(visual)
	# Contact edge sits on the board; the module body stands toward the camera.
	visual.position.z += 0.015 - aabb.position.z


func _seat_cooler_on_cpu(visual: Node3D) -> void:
	## Center over the CPU, cold-plate against the board / IHS.
	var aabb := _combined_aabb(visual)
	var center := aabb.get_center()
	visual.position.x -= center.x
	visual.position.y -= center.y
	aabb = _combined_aabb(visual)
	# The cooler bay's pick box floats in front of the board; the cold plate
	# must still land on the CPU lid, which sits on the socket plane.
	var plate_z := COOLER_PLATE_ABOVE_SOCKET
	var cooler_slot: Node3D = slots.get("cooler_mount", null) as Node3D
	var cpu_slot: Node3D = slots.get("cpu_socket", null) as Node3D
	if cooler_slot != null and cpu_slot != null:
		plate_z += cpu_slot.position.z - cooler_slot.position.z
	visual.position.z += plate_z - aabb.position.z


func _seat_part_in_slot(visual: Node3D, part_id: String, slot_id: String) -> void:
	## Keep every part inside the case and seated on the correct face.
	if visual == null or not is_instance_valid(visual):
		return
	if slot_id == "dimm_slot" or part_id == "ram":
		_seat_ram_in_slot(visual)
		return
	if slot_id == "cooler_mount" or part_id == "cooler" or part_id == "cpu_fan":
		_seat_cooler_on_cpu(visual)
		return
	var on_board := {
		"cpu_socket": true,
		"atx_socket": true,
		"eps_socket": true,
		"fan_header": true,
		"front_panel": true,
	}
	if on_board.has(slot_id) or part_id in [
		"cpu", "atx_24pin", "cpu_power", "fan_cable", "front_wires"
	]:
		_pin_flat_on_board(visual)
		return
	if slot_id == "board_mount" or part_id == "motherboard":
		var aabb := _combined_aabb(visual)
		var center := aabb.get_center()
		visual.position.x -= center.x
		visual.position.y -= center.y
		aabb = _combined_aabb(visual)
		visual.position.z += 0.03 - aabb.position.z
		return
	if slot_id == "pcie_slot" or part_id == "gpu":
		# Seat the PCIe edge against the board face; card body extends into the case.
		var aabb := _combined_aabb(visual)
		var center := aabb.get_center()
		visual.position.x -= center.x
		visual.position.y -= center.y
		aabb = _combined_aabb(visual)
		visual.position.z += 0.02 - aabb.position.z
		return
	if slot_id == "psu_bay" or part_id == "psu":
		var aabb := _combined_aabb(visual)
		var center := aabb.get_center()
		visual.position.x -= center.x
		visual.position.z -= center.z
		aabb = _combined_aabb(visual)
		visual.position.y += 0.01 - aabb.position.y
		return
	if slot_id in ["storage_bay", "optical_bay"] or part_id in ["ssd", "hdd", "optical"]:
		var aabb := _combined_aabb(visual)
		var center := aabb.get_center()
		visual.position.x -= center.x
		visual.position.z -= center.z
		aabb = _combined_aabb(visual)
		visual.position.y += 0.01 - aabb.position.y
		return
	if slot_id == "sata_power_port" or part_id == "sata_power":
		_pin_flat_on_board(visual)
		return


func _fit_size_for_part(part_id: String) -> float:
	# Sized to the centered mid-tower motherboard (~0.78).
	match part_id:
		"motherboard":
			return 0.78
		"psu":
			return 0.34
		"side_panel":
			return 1.2
		"cpu":
			return 0.10
		"cooler", "cpu_fan":
			return 0.16
		"ram":
			return 0.22
		"ssd", "hdd", "optical":
			return 0.2
		"gpu":
			return 0.3
		"fan_cable", "atx_24pin", "cpu_power", "sata_power", "front_wires":
			return 0.1
		_:
			return 0.18


func _fit_visual(root: Node3D, target: float) -> void:
	if root == null or not is_instance_valid(root):
		return
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
	## Local-space AABB so fitting works before the visual enters the scene tree
	## (drag ghost) and after SubViewport worlds are released.
	var result := AABB()
	var started := false
	var stack: Array = [[root, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var node: Node = item[0]
		var parent_xf: Transform3D = item[1]
		var xf := parent_xf
		if node is Node3D:
			xf = parent_xf * (node as Node3D).transform
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			if mi.mesh != null:
				var box: AABB = xf * mi.get_aabb()
				if not started:
					result = box
					started = true
				else:
					result = result.merge(box)
		for child in node.get_children():
			stack.append([child, xf])
	return result


func _make_model_part(part_id: String, faulty: bool = false) -> Node3D:
	# Prefer an authored scene when the build list provides one (e.g. motherboard GLTF).
	var path := ""
	for part_variant in parts:
		if typeof(part_variant) != TYPE_DICTIONARY:
			continue
		var part: Dictionary = part_variant
		if str(part.get("id", "")) == part_id:
			path = str(part.get("scene_path", ""))
			break
	if path != "" and ResourceLoader.exists(path):
		# Guard: case GLTF must never install into a bay (nested case-in-case).
		if path.find("/case/") >= 0 and part_id != "case":
			path = ""
		elif path.find("screwdriver") >= 0 or path.find("/toolkit/") >= 0:
			path = ""
	if path != "" and ResourceLoader.exists(path):
		var res: Resource = null
		# Use the threaded prefetch cache so attaching never blocks on a glTF decode.
		var warmup := get_node_or_null("/root/ResourceWarmup")
		if warmup != null and warmup.has_method("get_packed"):
			res = warmup.get_packed(path)
		if res == null:
			res = load(path)
		if res is PackedScene:
			var inst := (res as PackedScene).instantiate()
			if inst != null and inst is Node3D:
				var wrapped := Node3D.new()
				wrapped.name = part_id
				wrapped.add_child(inst)
				if faulty:
					_tint_model(wrapped, Color(1.0, 0.55, 0.25, 1))
				return wrapped
			if inst != null:
				inst.queue_free()

	# Prefer teaching meshes so every bay shows the real part shape (no wrong GLTF).
	var factory_id := _factory_part_id(part_id)
	if factory_id != "":
		var taught := Node3D.new()
		taught.name = part_id
		Module1PartFactory.build_into(taught, factory_id)
		if faulty:
			_tint_model(taught, Color(1.0, 0.55, 0.25, 1))
		return taught

	return null


func _factory_part_id(part_id: String) -> String:
	match part_id:
		# Motherboard uses the authored Sketchfab GLTF (model.tscn), not the box factory.
		"cpu", "ram", "ssd", "hdd", "optical", "psu", "gpu", "cooler", "cpu_fan", \
		"side_panel", "atx", "atx_24pin", "cpu_power", "sata_power", "fan_cable", "front_wires":
			return part_id
		_:
			return ""


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
	_clear_part_glow()
	_return_board_home()
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
	# An empty build starts with the motherboard out on the bench.
	_move_board_to_bench()
	selected_part_id = ""
	_refresh_tray_states()
	_refresh_selected_label()
	_rebuild_slot_buttons()


func _part_icon(part_id: String) -> Texture2D:
	var candidates: Array[String] = [
		"%s/part_%s.png" % [PART_ICON_DIR, part_id],
	]
	if part_id == "cooler" or part_id == "cpu_fan":
		candidates.append("%s/part_cooler.png" % PART_ICON_DIR)
		candidates.append("res://assets/images/parts/cpu_fan.png")
		candidates.append("res://assets/images/parts/cooler.png")
	for icon_path in candidates:
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
	if _is_remove_hint():
		_warn("Disassembly step — tap the %s in the case. Tray drops come later in assemble." % (
			"glowing part" if guided_hints else "part this step asks for"
		))
		_restore_step_hint()
		_press_part_id = ""
		return
	_dragging_part = true
	_drag_part_id = part_id
	selected_part_id = part_id
	_dragging_camera = false
	_refresh_selected_label()
	_refresh_tray_states()
	_dispose_drag_ghost()
	part_drag_started.emit(part_id)
	_drag_ghost = _make_3d_drag_ghost(part_id)
	add_child(_drag_ghost)
	_move_drag_ghost(get_global_mouse_position())
	if _hint_label != null:
		_hint_label.text = "Drop %s on its bay" % _part_title(part_id)


func _make_3d_drag_ghost(part_id: String) -> Control:
	## Floating SubViewport that shows the real 3D part while dragging.
	var host := SubViewportContainer.new()
	host.custom_minimum_size = Vector2(110, 110)
	host.size = Vector2(110, 110)
	host.stretch = true
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.z_index = 80
	host.modulate = Color(1, 1, 1, 0.95)

	var sv := SubViewport.new()
	sv.size = Vector2i(160, 160)
	sv.transparent_bg = true
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.add_child(sv)
	_drag_ghost_viewport = sv

	var world := Node3D.new()
	sv.add_child(world)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.1
	light.rotation_degrees = Vector3(-40, 35, 0)
	world.add_child(light)
	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 35.0
	cam.position = Vector3(0.9, 0.7, 1.35)
	# look_at() needs the node in the tree — host is not added yet. Use from_position.
	cam.look_at_from_position(cam.position, Vector3(0, 0.1, 0), Vector3.UP)
	world.add_child(cam)

	var visual: Node3D = _make_model_part(part_id, false)
	if visual == null:
		visual = _make_placeholder_part(part_id, false)
	world.add_child(visual)
	visual.position = Vector3.ZERO
	_fit_visual(visual, 0.85)
	return host


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
	_dispose_drag_ghost()
	if part_id == "" or installed_parts.has(part_id):
		_refresh_selected_label()
		return
	if was_dragging:
		if _is_remove_hint():
			_warn("Disassembly step — tap the %s to remove it." % (
				"glowing part" if guided_hints else "part this step asks for"
			))
			_restore_step_hint()
		else:
			var slot_id: String = _slot_under_pointer(global_pos)
			if slot_id != "":
				selected_part_id = part_id
				if _is_filled(slot_id):
					_warn("That bay already has a part. Tap it to remove first.")
				else:
					_try_install(slot_id)
			else:
				var expected_slot := _hint_destination
				if expected_slot == "" and PART_HOME.has(part_id):
					expected_slot = str(PART_HOME[part_id])
				if expected_slot != "":
					_warn(
						"Drop %s onto the %s bay — that drop missed the step." % [
							_part_title(part_id), _slot_title(expected_slot)
						]
					)
				else:
					_warn("Drop the part on its named bay in the case.")
	_refresh_selected_label()
	_refresh_tray_states()


func _slot_under_pointer(global_pos: Vector2) -> String:
	if USE_IMAGE_BOARD:
		for slot_id in _bay_buttons.keys():
			var btn: Control = _bay_buttons[slot_id]
			if btn != null and is_instance_valid(btn) and btn.get_global_rect().has_point(global_pos):
				return str(slot_id)
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
	var part_id: String = _drag_part_id if _drag_part_id != "" else selected_part_id
	var ranked: Dictionary = _rank_slots_on_screen(global_pos, rect)
	var hinted_id: String = str(ranked.get("hinted", ""))
	var hinted_dist: float = float(ranked.get("hinted_dist", 9999.0))
	# Snap to yellow bay only when the part in hand is the current step target.
	# Otherwise HDD/GPU/RAM magnet into each other and the step logic looks "mixed".
	if (
		guided_hints
		and hinted_id != ""
		and part_id != ""
		and part_id == _hint_target
		and hinted_dist <= 180.0
	):
		return hinted_id
	var home_id: String = str(PART_HOME.get(part_id, ""))
	if home_id != "" and ranked.has("dist") and (ranked["dist"] as Dictionary).has(home_id):
		var home_dist: float = float((ranked["dist"] as Dictionary)[home_id])
		# In guided mode, only accept home if it is also the current yellow bay.
		if guided_hints and _hint_destination != "" and home_id != _hint_destination:
			pass
		elif home_dist <= 100.0:
			return home_id
	var hit_id := _raycast_slot(global_pos, rect)
	if hit_id != "" and hit_id != LID_SLOT:
		if guided_hints and _hint_destination != "" and hit_id != _hint_destination:
			# Ignore accidental hits on neighboring bays during guided assemble.
			if part_id == _hint_target and hinted_id == _hint_destination and hinted_dist <= 220.0:
				return hinted_id
			return ""
		return hit_id
	var nearest := str(ranked.get("nearest", ""))
	var nearest_dist := 9999.0
	if nearest != "" and ranked.has("dist") and (ranked["dist"] as Dictionary).has(nearest):
		nearest_dist = float((ranked["dist"] as Dictionary)[nearest])
	# Tight nearest radius — large radius mixed storage/PCIe/DIMM drops.
	if nearest != "" and nearest_dist <= 52.0:
		if guided_hints and _hint_destination != "" and nearest != _hint_destination:
			return ""
		return nearest
	return ""


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
	if _camera == null or not is_instance_valid(_camera) or not _camera.is_inside_tree():
		return result
	var vp_size := Vector2(_subviewport.size)
	if vp_size.x <= 1.0 or vp_size.y <= 1.0 or rect.size.x <= 1.0:
		return result
	var lid_ok := _is_lid_pickable()
	var best_id := ""
	var best_dist := 56.0
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
		_tap_armed = false
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_track_pinch_event(event)
		if _pinch_active:
			_tap_armed = false
			accept_event()
			return
	_handle_viewport_tap(event)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging_camera = event.pressed
			_last_mouse = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_by(0.88)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_by(1.12)
			accept_event()
	elif event is InputEventMouseMotion and _dragging_camera:
		var delta: Vector2 = event.position - _last_mouse
		_last_mouse = event.position
		_orbit_yaw -= delta.x * 0.01
		_orbit_pitch = clampf(_orbit_pitch - delta.y * 0.01, -0.85, 0.4)
		_update_camera()
	elif event is InputEventMagnifyGesture:
		# Trackpad pinch.
		_zoom_by(1.0 / maxf(event.factor, 0.05))
		accept_event()
	elif event is InputEventScreenDrag and event.index == 0 and not _pinch_active:
		_orbit_yaw -= event.relative.x * 0.01
		_orbit_pitch = clampf(_orbit_pitch - event.relative.y * 0.01, -0.85, 0.4)
		_update_camera()


func _zoom_by(factor: float) -> void:
	_orbit_distance = clampf(_orbit_distance * factor, ZOOM_MIN, ZOOM_MAX)
	_update_camera()


func _track_pinch_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
		else:
			_touch_points.erase(event.index)
			if _touch_points.size() < 2:
				_pinch_active = false
	elif event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
	if _touch_points.size() >= 2:
		var vals: Array = _touch_points.values()
		var dist: float = (vals[0] as Vector2).distance_to(vals[1] as Vector2)
		if not _pinch_active:
			_pinch_active = true
			_pinch_start_dist = maxf(dist, 1.0)
			_pinch_start_orbit = _orbit_distance
		else:
			var ratio: float = _pinch_start_dist / maxf(dist, 1.0)
			_orbit_distance = clampf(_pinch_start_orbit * ratio, ZOOM_MIN, ZOOM_MAX)
			_update_camera()
	else:
		_pinch_active = false


func _update_camera() -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	if not _camera.is_inside_tree():
		return
	# Orbit a standing open-side tower (look into the open face).
	var dist := clampf(_orbit_distance, ZOOM_MIN, ZOOM_MAX)
	var focus := Vector3(CASE_CX, CASE_CY, CASE_CZ)
	var pos := Vector3(
		focus.x + sin(_orbit_yaw) * cos(_orbit_pitch) * dist,
		focus.y + sin(-_orbit_pitch) * dist + 0.15,
		focus.z + cos(_orbit_yaw) * cos(_orbit_pitch) * dist
	)
	_camera.look_at_from_position(pos, focus, Vector3.UP)
	var t: float = inverse_lerp(ZOOM_MIN, ZOOM_MAX, dist)
	_camera.fov = clampf(lerpf(30.0, 46.0, t), 30.0, 46.0)
