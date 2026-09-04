extends Control

const CARD_VIEWER_PATH := "res://modules/module_0/assets/components/Card3DViewer/Card3DViewer.tscn"
const HARDWARE_LAB_PATH := "res://core/scenes/InteractiveHardwareLab.tscn"
const PC_BUILD_BENCH_PATH := "res://core/simulation/PcBuildBench.tscn"
const NETWORK_LAB_PATH := "res://core/simulation/NetworkLab.tscn"
const SERVER_LAB_PATH := "res://core/simulation/ServerLab.tscn"
const MAINTENANCE_BENCH_PATH := "res://core/simulation/MaintenanceBench.tscn"
const CRIMP_LAB_PATH := "res://core/simulation/CrimpLab.tscn"
const PARTS_SEARCH_OVERLAY := preload("res://core/ui/parts_search_overlay.gd")

var _packed_cache: Dictionary = {}
var _pending_preview_loads: Array = []
var _page_turn_busy := false

## Horizontal inset applied to the whole shell column, plus room for the page scrollbar.
const SHELL_INSET := 18.0
const PRESENTATION_MARGINS := SHELL_INSET * 2.0
const SCROLLBAR_ALLOWANCE := 14.0

@onready var module_label: Label = $Wrapper/Header/ModuleLabel
@onready var phase_label: Label = $Wrapper/Header/PhaseLabel
@onready var page_counter_label: Label = $Wrapper/Navigation/PageCounterLabel
@onready var content: VBoxContainer = $Wrapper/Presentation/PageScroll/Content
@onready var prev_btn: Button = $Wrapper/Navigation/Buttons/PreviousButton
@onready var next_btn: Button = $Wrapper/Navigation/Buttons/NextButton
@onready var exit_btn: Button = $Wrapper/Navigation/ExitButton

var module_id: int = 1
var simulation_type: int = 0
var progress: float = 0.0

var module_data: Dictionary = {}
var current_page_index: int = 0
var current_page_root: Control = null
var _is_ready := false
var _start_page_resolved := false
var _path_completion_emitted := false

var active_viewer: Control = null
var active_viewer_container: Node3D = null
var active_viewer_model: Node3D = null
var active_model_description: RichTextLabel = null
var active_hardware_lab: Control = null
var simulation_preview_container: Node3D = null
var simulation_preview_viewer: Control = null
var simulation_preview_model: Node3D = null
var simulation_preview_label: Label = null

var simulation_manager_instance: SimulationManager = null
var simulation_instruction_label: RichTextLabel = null
var simulation_feedback_label: Label = null
var simulation_progress_bar: ProgressBar = null
var simulation_progress_label: Label = null
var simulation_buttons: Dictionary = {}
var simulation_phase_steps: Array = []
var simulation_completed_ids: Dictionary = {}
var simulation_page_type: String = ""
var simulation_completion_message: String = ""
var simulation_total_steps: int = 0
var _pending_correct_tip: String = ""
var active_build_bench: Control = null
var active_network_lab: Control = null
var active_server_lab: Control = null
var active_maintenance_bench: Control = null
var active_crimp_lab: Control = null
var simulation_is_pc_build: bool = false
var simulation_is_network_lab: bool = false
var simulation_is_server_lab: bool = false
var simulation_is_maintenance_bench: bool = false
var simulation_is_crimp_lab: bool = false
var simulation_is_crossover_task: bool = false
var crossover_stage: String = "bench"
var crossover_bench_btn: Button = null
var crossover_site_btn: Button = null
var simulation_guided_hints: bool = true
var simulation_answer_grid: GridContainer = null
var simulation_split: Control = null
var simulation_tip_label: Label = null
var simulation_current_step_id: String = ""
var simulation_seed_state: Array = []
var _quiz_choice_locked := false
var _header_search_btn: Button = null
var _header_help_btn: Button = null
var _help_overlay: Control = null
var _help_body: RichTextLabel = null
var _search_overlay: Control = null


func configure(new_module_id: int, new_simulation_type: int = 0, new_progress: float = 0.0) -> void:
	module_id = new_module_id
	simulation_type = new_simulation_type
	progress = new_progress
	module_data = ModuleContentRegistry.get_module(module_id)
	_start_page_resolved = false
	_path_completion_emitted = false
	current_page_index = _resolve_start_page_index()
	_start_page_resolved = true

	if _is_ready:
		_render_page()


func _packed(path: String) -> PackedScene:
	if path == "":
		return null
	if _packed_cache.has(path):
		return _packed_cache[path] as PackedScene
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		return _take_threaded(path)
	# Never call sync load() while a threaded request is still running for the
	# same path — that blocks the main thread (Module 1 hero → Parts Lab freeze).
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		push_warning("ModuleShell: refusing sync load while threaded load runs: %s" % path)
		return null
	var scene := load(path) as PackedScene
	if scene != null:
		_packed_cache[path] = scene
	else:
		push_error("ModuleShell failed to load scene: %s" % path)
	return scene


func _take_threaded(path: String) -> PackedScene:
	var status := ResourceLoader.load_threaded_get_status(path)
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		return null
	var res: Resource = ResourceLoader.load_threaded_get(path)
	if res is PackedScene:
		_packed_cache[path] = res
		return res as PackedScene
	return null


func _prefetch(path: String) -> void:
	if path == "" or _packed_cache.has(path):
		return
	if not ResourceLoader.exists(path):
		return
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
		return
	ResourceLoader.load_threaded_request(path)


## Wait until critical page scenes are cached, without blocking via sync load().
func _await_critical_paths(paths: PackedStringArray, timeout_ms: int = 8000) -> void:
	for path in paths:
		_prefetch(path)
	var deadline := Time.get_ticks_msec() + timeout_ms
	for path in paths:
		if path == "" or _packed_cache.has(path):
			continue
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if Time.get_ticks_msec() > deadline:
				break
			await get_tree().process_frame
			if not is_instance_valid(self):
				return
		_take_threaded(path)


func _paths_for_page(page: Dictionary) -> PackedStringArray:
	var paths: PackedStringArray = []
	var ptype := str(page.get("type", ""))
	var mode := str(page.get("sim_mode", ""))
	match ptype:
		"model_library":
			paths.append(HARDWARE_LAB_PATH)
		"guided_simulation", "assessment":
			match mode:
				"pc_build":
					paths.append(PC_BUILD_BENCH_PATH)
				"network_lab":
					paths.append(NETWORK_LAB_PATH)
				"server_lab":
					paths.append(SERVER_LAB_PATH)
				"maintenance_bench":
					paths.append(MAINTENANCE_BENCH_PATH)
				"crimp_lab":
					paths.append(CRIMP_LAB_PATH)
				"crossover_task":
					paths.append(CRIMP_LAB_PATH)
					paths.append(NETWORK_LAB_PATH)
				_:
					paths.append(CARD_VIEWER_PATH)
	return paths


func _prefetch_page_assets(page: Dictionary) -> void:
	# Critical UI scenes first (Parts Lab shell, benches) — never bury them
	# behind a flood of Sketchfab glTF requests.
	for path in _paths_for_page(page):
		_prefetch(path)
	for title_variant in page.get("related_models", []):
		var item: Dictionary = _find_model_item_by_title(str(title_variant))
		if not item.is_empty():
			_prefetch(_safe_model_path(str(item.get("scene_path", ""))))
	# Skip library item glTF prefetch — Parts Lab is procedural and loads on tap.


func _prefetch_around_current() -> void:
	var pages: Array = module_data.get("pages", [])
	# Include offset 0 so the current page's critical scene starts loading
	# immediately on first render, rather than only on the next page turn.
	for offset in range(0, 3):
		var index: int = current_page_index + offset
		if index >= 0 and index < pages.size():
			_prefetch_page_assets(pages[index] as Dictionary)
	_drain_threaded_cache()


func _drain_threaded_cache() -> void:
	var pages: Array = module_data.get("pages", [])
	for offset in range(0, 3):
		var index: int = current_page_index + offset
		if index < 0 or index >= pages.size():
			continue
		for path in _paths_for_page(pages[index] as Dictionary):
			_take_threaded(path)


func _process(_delta: float) -> void:
	if _pending_preview_loads.is_empty():
		return
	var job: Dictionary = _pending_preview_loads.pop_front()
	var item: Dictionary = job.get("item", {})
	var container: Node3D = job.get("container") as Node3D
	var viewer: Control = job.get("viewer") as Control
	if container == null or not is_instance_valid(container):
		return
	_load_preview_model_into(item, container, viewer)


func _ready() -> void:
	_is_ready = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fit_shell_to_viewport()
	if content != null:
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Pack pages from the top; EXPAND left a tall empty band under Module 2 galleries.
		content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var presentation := get_node_or_null("Wrapper/Presentation") as Control
	if presentation != null:
		presentation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		presentation.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# The inset moves to Wrapper below so the header and nav share it.
		presentation.add_theme_constant_override("margin_left", 0)
		presentation.add_theme_constant_override("margin_right", 0)
	var page_scroll := get_node_or_null("Wrapper/Presentation/PageScroll") as Control
	if page_scroll != null:
		page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var navigation := get_node_or_null("Wrapper/Navigation") as Control
	if navigation != null:
		navigation.size_flags_vertical = Control.SIZE_SHRINK_END
		navigation.custom_minimum_size = Vector2(0, 72)
	var wrapper := get_node_or_null("Wrapper") as Control
	if wrapper != null:
		wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Inset the whole column so the module title and the nav buttons line up
		# with the page cards instead of sitting flush against the window edge.
		wrapper.offset_left = SHELL_INSET
		wrapper.offset_right = -SHELL_INSET

	prev_btn.pressed.connect(_on_prev_btn_pressed)
	next_btn.pressed.connect(_on_next_btn_pressed)
	exit_btn.pressed.connect(_on_exit_btn_pressed)
	var bg := get_node_or_null("Background") as Control
	if bg != null:
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_header_tools()

	if module_data.is_empty():
		module_data = ModuleContentRegistry.get_module(module_id)

	if not _start_page_resolved:
		current_page_index = _resolve_start_page_index()
		_start_page_resolved = true

	_apply_header_layout()
	_style_nav_buttons()
	_render_page()


func _apply_header_layout() -> void:
	if phase_label != null:
		phase_label.visible = not _viewport_narrow()
	if _header_search_btn != null:
		_header_search_btn.text = "Find" if _viewport_narrow() else "Search"
		_header_search_btn.custom_minimum_size = Vector2(56 if _viewport_narrow() else 72, 32)
	if _header_help_btn != null:
		_header_help_btn.custom_minimum_size = Vector2(52 if _viewport_narrow() else 72, 32)


func _style_nav_buttons() -> void:
	var cyan := Color(0.09, 0.65, 0.87, 1)
	var white := Color(0.95, 0.98, 0.99, 1)
	for btn in [prev_btn, next_btn, exit_btn]:
		if btn == null:
			continue
		btn.custom_minimum_size = Vector2(60, 60)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.focus_mode = Control.FOCUS_NONE
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.04, 0.18, 0.28, 0.95)
		normal.border_color = Color(0.35, 0.82, 0.95, 0.45)
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(16)
		normal.content_margin_left = 12
		normal.content_margin_right = 12
		normal.content_margin_top = 12
		normal.content_margin_bottom = 12
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.08, 0.32, 0.45, 0.98)
		hover.border_color = cyan
		var disabled := normal.duplicate() as StyleBoxFlat
		disabled.bg_color = Color(0.03, 0.1, 0.16, 0.7)
		disabled.border_color = Color(0.25, 0.5, 0.65, 0.25)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", hover)
		btn.add_theme_stylebox_override("disabled", disabled)
		btn.add_theme_color_override("icon_normal_color", cyan)
		btn.add_theme_color_override("icon_hover_color", white)
		btn.add_theme_color_override("icon_disabled_color", Color(0.45, 0.6, 0.7, 0.5))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit_shell_to_viewport()
		_apply_page_min_width()
		_apply_header_layout()


func _fit_shell_to_viewport() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	if vp_size.x < 2.0 or vp_size.y < 2.0:
		return
	if size.x < 64.0 or size.y < 64.0:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		size = vp_size


func _apply_page_min_width() -> void:
	# ScrollContainer needs an explicit child WIDTH. Never wipe HEIGHT — that
	# collapses Parts Lab / PC Build Bench (gallery + 3D viewport go blank).
	var page_scroll := get_node_or_null("Wrapper/Presentation/PageScroll") as ScrollContainer
	# Derive the width from the shell, never from the scroll container itself:
	# feeding the scroll's own width back into its child minimum re-added the
	# scrollbar allowance on every layout pass and inflated the page off-centre.
	var shell_w: float = size.x
	if shell_w < 64.0:
		shell_w = get_viewport().get_visible_rect().size.x
	var scroll_w: float = clampf(shell_w - PRESENTATION_MARGINS - SCROLLBAR_ALLOWANCE, 280.0, 1920.0)

	var lab_h := _embedded_lab_height()
	if content != null:
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.custom_minimum_size = Vector2(scroll_w, 0)
	if current_page_root != null and is_instance_valid(current_page_root):
		current_page_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		current_page_root.custom_minimum_size = Vector2(scroll_w, 0)
		current_page_root.modulate.a = 1.0
		current_page_root.visible = true
	if active_hardware_lab != null and is_instance_valid(active_hardware_lab):
		active_hardware_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		active_hardware_lab.size_flags_vertical = Control.SIZE_EXPAND_FILL
		active_hardware_lab.custom_minimum_size = Vector2(scroll_w, lab_h)
		active_hardware_lab.modulate.a = 1.0
		active_hardware_lab.visible = true
	if active_build_bench != null and is_instance_valid(active_build_bench):
		active_build_bench.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		active_build_bench.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# Fit to the space left under the mission strip, otherwise the 3D card
		# eats the page and pushes the tray and slot buttons below the fold.
		active_build_bench.custom_minimum_size = Vector2(
			scroll_w, _fitted_lab_height(active_build_bench, page_scroll, 380.0)
		)
		active_build_bench.modulate.a = 1.0
		active_build_bench.visible = true
	if active_network_lab != null and is_instance_valid(active_network_lab):
		active_network_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var net_visible := _lab_stage_visible(active_network_lab)
		active_network_lab.size_flags_vertical = (
			Control.SIZE_EXPAND_FILL if net_visible else Control.SIZE_SHRINK_BEGIN
		)
		active_network_lab.custom_minimum_size = Vector2(
			scroll_w,
			_fitted_lab_height(active_network_lab, page_scroll, _lab_floor(400.0)) if net_visible else 0.0
		)
		active_network_lab.modulate.a = 1.0
		active_network_lab.visible = net_visible
	if active_server_lab != null and is_instance_valid(active_server_lab):
		active_server_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		active_server_lab.size_flags_vertical = Control.SIZE_EXPAND_FILL
		active_server_lab.custom_minimum_size = Vector2(
			scroll_w, _fitted_lab_height(active_server_lab, page_scroll, _lab_floor(380.0))
		)
		active_server_lab.modulate.a = 1.0
		active_server_lab.visible = true
	if active_maintenance_bench != null and is_instance_valid(active_maintenance_bench):
		active_maintenance_bench.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		active_maintenance_bench.size_flags_vertical = Control.SIZE_EXPAND_FILL
		active_maintenance_bench.custom_minimum_size = Vector2(
			scroll_w, _fitted_lab_height(active_maintenance_bench, page_scroll, _lab_floor(380.0))
		)
		active_maintenance_bench.modulate.a = 1.0
		active_maintenance_bench.visible = true
	if active_crimp_lab != null and is_instance_valid(active_crimp_lab):
		active_crimp_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var crimp_visible := _lab_stage_visible(active_crimp_lab)
		active_crimp_lab.size_flags_vertical = (
			Control.SIZE_EXPAND_FILL if crimp_visible else Control.SIZE_SHRINK_BEGIN
		)
		active_crimp_lab.custom_minimum_size = Vector2(
			scroll_w,
			_fitted_lab_height(active_crimp_lab, page_scroll, _lab_floor(360.0)) if crimp_visible else 0.0
		)
		active_crimp_lab.modulate.a = 1.0
		active_crimp_lab.visible = crimp_visible
	if simulation_split != null and is_instance_valid(simulation_split):
		simulation_split.custom_minimum_size = Vector2(
			0, _fitted_lab_height(simulation_split, page_scroll, 320.0)
		)
	var navigation := get_node_or_null("Wrapper/Navigation") as Control
	if navigation != null:
		navigation.custom_minimum_size = Vector2(0, 72)


func _embedded_lab_height() -> float:
	var vp_h := get_viewport().get_visible_rect().size.y
	var chrome := 216.0 if _viewport_short() else 184.0
	var floor := 340.0 if _viewport_short() else 420.0
	return maxf(floor, vp_h - chrome)


func _viewport_short() -> bool:
	return get_viewport().get_visible_rect().size.y <= 760.0


func _viewport_narrow() -> bool:
	return get_viewport().get_visible_rect().size.x <= 1320.0


func _mission_inset() -> float:
	return 6.0 if _viewport_short() else 10.0


## Height left inside the page scroll once the siblings above the lab (mission
## strip, headers) have taken their share — keeps the lab from being clipped.
## The crossover task spends a row on the stage switcher, so its labs need a
## lower floor than a single-lab page to still land above the navigation bar.
func _lab_floor(default_floor: float) -> float:
	if simulation_is_crossover_task:
		return 280.0 if _viewport_short() else 340.0
	if _viewport_short():
		return minf(default_floor, 360.0)
	return default_floor


## On the crossover task two labs share the page, so the sizing pass must not
## force the off-stage one back into view.
func _lab_stage_visible(lab: Control) -> bool:
	if not simulation_is_crossover_task:
		return true
	if lab == active_crimp_lab:
		return crossover_stage == "bench"
	if lab == active_network_lab:
		return crossover_stage == "site"
	return true


func _fitted_lab_height(lab: Control, page_scroll: ScrollContainer, minimum: float) -> float:
	if page_scroll == null or page_scroll.size.y < 160.0 or current_page_root == null:
		return maxf(minimum, _embedded_lab_height())
	var siblings: float = 0.0
	var visible_children: int = 0
	for child in current_page_root.get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		visible_children += 1
		if control != lab:
			siblings += control.get_combined_minimum_size().y
	var separation: float = float(current_page_root.get_theme_constant("separation")) * float(maxi(visible_children - 1, 0))
	return maxf(minimum, page_scroll.size.y - siblings - separation - 4.0)


func _play_page_enter() -> void:
	if current_page_root == null or not is_instance_valid(current_page_root):
		return
	# Do not fade module pages: alpha=0 + deferred layout caused blank Page 1 / Parts Lab.
	current_page_root.visible = true
	current_page_root.modulate = Color(1, 1, 1, 1)
	_apply_page_min_width()


func _build_model_library_page(page: Dictionary) -> Control:
	var root := _base_page()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var packed: PackedScene = _packed(HARDWARE_LAB_PATH)
	if packed == null and ResourceLoader.exists(HARDWARE_LAB_PATH):
		# Safe cold path only — never sync-load while a threaded request is live.
		if ResourceLoader.load_threaded_get_status(HARDWARE_LAB_PATH) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			packed = load(HARDWARE_LAB_PATH) as PackedScene
			if packed != null:
				_packed_cache[HARDWARE_LAB_PATH] = packed
	if packed == null:
		# Await timed out; retry once the background load finishes.
		call_deferred("_retry_current_page_soon")
		return _build_empty_state(
			"Loading Parts Lab…",
			"Warming up the hardware viewer. This page will refresh automatically."
		)
	active_hardware_lab = packed.instantiate() as Control
	active_hardware_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_hardware_lab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Clear full-rect anchors so the VBox/ScrollContainer can assign real height.
	active_hardware_lab.anchor_left = 0.0
	active_hardware_lab.anchor_top = 0.0
	active_hardware_lab.anchor_right = 0.0
	active_hardware_lab.anchor_bottom = 0.0
	active_hardware_lab.offset_left = 0.0
	active_hardware_lab.offset_top = 0.0
	active_hardware_lab.offset_right = 0.0
	active_hardware_lab.offset_bottom = 0.0
	var lab_min_h := _embedded_lab_height()
	active_hardware_lab.custom_minimum_size = Vector2(0, lab_min_h)
	root.add_child(active_hardware_lab)

	var items: Array = page.get("items", [])
	if active_hardware_lab.has_method("setup"):
		active_hardware_lab.call_deferred("setup", items)

	return root


func _retry_current_page_soon() -> void:
	await get_tree().create_timer(0.35).timeout
	if not is_instance_valid(self) or _page_turn_busy:
		return
	var pages: Array = module_data.get("pages", [])
	if current_page_index < 0 or current_page_index >= pages.size():
		return
	if str(pages[current_page_index].get("type", "")) != "model_library":
		return
	await _await_critical_paths(_paths_for_page(pages[current_page_index] as Dictionary), 6000)
	if not is_instance_valid(self) or _page_turn_busy:
		return
	_render_page()


func _resolve_start_page_index() -> int:
	# Shared by Modules 1–4.
	# simulationType 0 = Guided (yellow hints on guided_simulation pages)
	# simulationType 1 = Assessment (same page list, hints off)
	# Both always start at page 0 — never jump to a lone assessment page.
	if module_data.is_empty():
		return 0
	return 0


func _render_page() -> void:
	if module_data.is_empty():
		module_label.text = "MODULE NOT AVAILABLE"
		phase_label.text = "Content missing"
		page_counter_label.text = "0 / 0"
		_clear_content()
		content.add_child(_build_empty_state(
			"Module Not Available",
			"The requested module has not been registered yet."
		))
		_update_navigation_state()
		return

	var pages: Array = module_data.get("pages", [])
	current_page_index = clampi(current_page_index, 0, max(pages.size() - 1, 0))

	module_label.text = "%s • %s" % [module_data.get("subtitle", "Module"), module_data.get("title", "")]
	page_counter_label.text = "%d / %d" % [current_page_index + 1, pages.size()]

	_clear_content()
	_reset_page_state()

	var page: Dictionary = pages[current_page_index]
	phase_label.text = page.get("eyebrow", "Lesson")

	# Assessment Simulation = same pages as Guided, but without yellow guides.
	var no_guides: bool = simulation_type == 1
	match page.get("type", ""):
		"hero":
			current_page_root = _build_hero_page(page)
		"checklist":
			current_page_root = _build_checklist_page(page)
		"guided_simulation":
			current_page_root = _build_simulation_page(page, no_guides)
		"assessment":
			current_page_root = _build_simulation_page(page, true)
		"model_library":
			current_page_root = _build_model_library_page(page)
		"completion":
			current_page_root = _build_completion_page(page)
		_:
			current_page_root = _build_empty_state("Unsupported Page", "This content page type is not implemented.")

	content.add_child(current_page_root)
	current_page_root.visible = true
	current_page_root.modulate.a = 1.0
	if not simulation_seed_state.is_empty():
		call_deferred("_finalize_seeded_simulation")
	var page_scroll := get_node_or_null("Wrapper/Presentation/PageScroll") as ScrollContainer
	if page_scroll != null:
		page_scroll.scroll_vertical = 0
		page_scroll.scroll_horizontal = 0
	_sync_page_progress_to_host()
	_update_navigation_state()
	# Finishing all pages unlocks Assessment (guided) or marks 100% (assessment).
	if str(page.get("type", "")) == "completion":
		_emit_path_completed_once()
	call_deferred("_apply_page_min_width")
	call_deferred("_play_page_enter")
	_refresh_help_context()
	call_deferred("_prefetch_around_current")


func _setup_header_tools() -> void:
	var header := get_node_or_null("Wrapper/Header") as HBoxContainer
	if header == null or _header_search_btn != null:
		return
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.move_child(spacer, 1)
	_header_search_btn = _header_tool_button("Search")
	_header_search_btn.pressed.connect(_open_module_search)
	header.add_child(_header_search_btn)
	_header_help_btn = _header_tool_button("Help")
	_header_help_btn.pressed.connect(_toggle_module_help)
	header.add_child(_header_help_btn)


func _header_tool_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 12)
	btn.custom_minimum_size = Vector2(72, 32)
	return btn


func _open_module_search() -> void:
	if _search_overlay != null and is_instance_valid(_search_overlay):
		_search_overlay.queue_free()
		_search_overlay = null
	var overlay: Control = PARTS_SEARCH_OVERLAY.new()
	overlay.open(self, module_id)
	_search_overlay = overlay
	overlay.closed.connect(func() -> void: _search_overlay = null)


func _toggle_module_help() -> void:
	if _help_overlay != null and is_instance_valid(_help_overlay):
		_close_module_help()
		return
	_open_module_help()


func _open_module_help() -> void:
	_close_module_help()
	_help_overlay = Control.new()
	_help_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_help_overlay.z_index = 75
	add_child(_help_overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.45)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close_module_help()
	)
	_help_overlay.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 56
	panel.offset_right = -56
	panel.offset_top = 48
	panel.offset_bottom = -48
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.10, 0.16, 0.98)
	style.border_color = Color(0.35, 0.82, 0.95, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	_help_overlay.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var top := HBoxContainer.new()
	col.add_child(top)
	var title := Label.new()
	title.text = "Module Help"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	top.add_child(title)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_close_module_help)
	top.add_child(close)

	_help_body = RichTextLabel.new()
	_help_body.bbcode_enabled = true
	_help_body.fit_content = true
	_help_body.scroll_active = true
	_help_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_help_body)
	_refresh_help_context()


func _close_module_help() -> void:
	if _help_overlay != null and is_instance_valid(_help_overlay):
		_help_overlay.queue_free()
	_help_overlay = null
	_help_body = null


func _refresh_help_context() -> void:
	if _help_body == null:
		return
	var pages: Array = module_data.get("pages", [])
	if pages.is_empty() or current_page_index >= pages.size():
		_help_body.text = "No help available for this module."
		return
	var page: Dictionary = pages[current_page_index]
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]%s[/b]" % str(page.get("title", "Lesson")))
	if str(page.get("description", "")) != "":
		lines.append(str(page.get("description", "")))
	if str(page.get("eyebrow", "")) != "":
		lines.append("\n[color=#7cf]Station:[/color] %s" % str(page.get("eyebrow", "")))
	if simulation_current_step_id != "":
		var step_data: Dictionary = _find_step_content(simulation_current_step_id)
		if not step_data.is_empty():
			lines.append("\n[b]Current step[/b]")
			lines.append(str(step_data.get("instruction", step_data.get("question", ""))))
			var tip := str(step_data.get("tip", ""))
			if tip != "":
				lines.append("\n[color=#fd8]Tip:[/color] %s" % tip)
	for pitfall in page.get("pitfalls", []):
		lines.append("\n[color=#f96]Watch out:[/color] %s" % str(pitfall))
	for bullet in page.get("bullets", []):
		lines.append("• %s" % str(bullet))
	lines.append("\n[color=#8cf]Search[/color] opens the Parts Encyclopedia filtered to this module.")
	_help_body.text = "\n".join(lines)


func _clear_content() -> void:
	_pending_preview_loads.clear()
	for child in content.get_children():
		child.visible = false
		child.queue_free()


func _reset_page_state() -> void:
	active_viewer = null
	active_viewer_container = null
	active_viewer_model = null
	active_model_description = null
	active_hardware_lab = null
	simulation_preview_container = null
	simulation_preview_model = null
	simulation_preview_label = null
	if simulation_manager_instance != null and is_instance_valid(simulation_manager_instance):
		simulation_manager_instance.queue_free()
	simulation_manager_instance = null
	simulation_instruction_label = null
	simulation_feedback_label = null
	simulation_progress_bar = null
	simulation_progress_label = null
	simulation_buttons = {}
	simulation_phase_steps = []
	simulation_completed_ids = {}
	simulation_page_type = ""
	simulation_completion_message = ""
	simulation_total_steps = 0
	_pending_correct_tip = ""
	active_build_bench = null
	active_network_lab = null
	active_server_lab = null
	active_maintenance_bench = null
	active_crimp_lab = null
	simulation_is_pc_build = false
	simulation_is_network_lab = false
	simulation_is_server_lab = false
	simulation_is_maintenance_bench = false
	simulation_is_crimp_lab = false
	simulation_is_crossover_task = false
	crossover_stage = "bench"
	crossover_bench_btn = null
	crossover_site_btn = null
	simulation_guided_hints = true
	simulation_answer_grid = null
	simulation_split = null
	simulation_tip_label = null
	simulation_current_step_id = ""
	simulation_seed_state = []
	_quiz_choice_locked = false


func _is_interactive_sim() -> bool:
	return (
		simulation_is_pc_build
		or simulation_is_network_lab
		or simulation_is_server_lab
		or simulation_is_maintenance_bench
		or simulation_is_crimp_lab
		or simulation_is_crossover_task
	)


## Labs that embed a full workstation panel under a mission strip.
func _is_workstation_sim() -> bool:
	return (
		simulation_is_network_lab
		or simulation_is_server_lab
		or simulation_is_maintenance_bench
		or simulation_is_crimp_lab
		or simulation_is_crossover_task
	)


func _build_hero_page(page: Dictionary) -> Control:
	var root := _base_page()
	var hero := _card_panel(Color(0.06, 0.14, 0.22, 0.92))
	root.add_child(hero)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	hero.add_child(layout)

	layout.add_child(_eyebrow_label(page.get("eyebrow", "Overview")))
	layout.add_child(_title_label(page.get("title", "")))
	layout.add_child(_subtitle_label(page.get("subtitle", "")))
	layout.add_child(_body_label(page.get("description", "")))

	var bullets: Array = page.get("bullets", [])
	if not bullets.is_empty():
		var grid := GridContainer.new()
		grid.columns = 1
		grid.add_theme_constant_override("v_separation", 10)
		layout.add_child(_section_title("Learning path"))
		layout.add_child(grid)
		for index in bullets.size():
			grid.add_child(_step_label(index + 1, str(bullets[index])))

	# Pre-warm Parts Lab shell (+ first model only) while the user reads.
	var pages: Array = module_data.get("pages", [])
	var next_idx: int = current_page_index + 1
	if next_idx < pages.size():
		call_deferred("_prefetch_page_assets", pages[next_idx] as Dictionary)

	return root


func _build_checklist_page(page: Dictionary) -> Control:
	var root := _base_page()

	var grid := HBoxContainer.new()
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("separation", 18)
	root.add_child(grid)

	var summary := _card_panel(Color(0.06, 0.12, 0.18, 0.9))
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.size_flags_stretch_ratio = 1.0
	grid.add_child(summary)

	var summary_layout := VBoxContainer.new()
	summary_layout.add_theme_constant_override("separation", 14)
	summary.add_child(summary_layout)
	summary_layout.add_child(_eyebrow_label(page.get("eyebrow", "Phase")))
	summary_layout.add_child(_title_label(page.get("title", "")))
	summary_layout.add_child(_body_label(page.get("description", "")))

	var checklist := _card_panel(Color(0.08, 0.42, 0.58, 0.22))
	checklist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	checklist.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_child(checklist)

	var checklist_layout := VBoxContainer.new()
	checklist_layout.add_theme_constant_override("separation", 10)
	checklist.add_child(checklist_layout)
	checklist_layout.add_child(_section_title("Task checklist"))

	var items: Array = page.get("items", [])
	for index in items.size():
		checklist_layout.add_child(_step_label(index + 1, str(items[index])))

	return root


func _build_completion_page(page: Dictionary) -> Control:
	var root := _base_page()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 18)

	var card := _card_panel(Color(0.04, 0.14, 0.2, 0.95))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(card)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(layout)

	layout.add_child(_eyebrow_label(page.get("eyebrow", "Module complete")))

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 16)
	layout.add_child(hero)

	var badge := TextureRect.new()
	badge.custom_minimum_size = Vector2(72, 72)
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_tex := load("res://assets/ui/icon_achievement.png")
	if badge_tex != null:
		badge.texture = badge_tex
	hero.add_child(badge)

	var greet_col := VBoxContainer.new()
	greet_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	greet_col.add_theme_constant_override("separation", 6)
	hero.add_child(greet_col)

	var greet := Label.new()
	greet.text = str(page.get("title", "Congratulations!"))
	greet.add_theme_font_size_override("font_size", 36)
	greet.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1))
	greet_col.add_child(greet)

	var sub := Label.new()
	sub.text = str(page.get("subtitle", ""))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.78, 0.9, 0.96, 0.92))
	greet_col.add_child(sub)

	layout.add_child(_body_label(page.get("description", "")))

	var achievements: Array = page.get("achievements", [])
	if not achievements.is_empty():
		layout.add_child(_section_title(str(page.get("achievements_title", "What you completed"))))
		for item in achievements:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			layout.add_child(row)
			var mark := Label.new()
			mark.text = "✓"
			mark.add_theme_font_size_override("font_size", 18)
			mark.add_theme_color_override("font_color", Color(0.35, 0.95, 0.65, 1))
			row.add_child(mark)
			var text := Label.new()
			text.text = str(item)
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text.add_theme_font_size_override("font_size", 15)
			text.add_theme_color_override("font_color", Color(0.9, 0.95, 0.98, 0.95))
			row.add_child(text)

	var home_btn := Button.new()
	home_btn.text = str(page.get("button_label", "Back to Home"))
	home_btn.custom_minimum_size = Vector2(0, 48)
	home_btn.focus_mode = Control.FOCUS_NONE
	_apply_action_button_style(home_btn)
	home_btn.pressed.connect(_on_exit_btn_pressed)
	layout.add_child(home_btn)

	return root


func _build_simulation_page(page: Dictionary, is_assessment: bool) -> Control:
	simulation_page_type = page.get("type", "")
	simulation_completion_message = page.get("completion_message", "Simulation complete.")
	simulation_phase_steps = page.get("steps", [])
	simulation_completed_ids = {}
	simulation_seed_state = page.get("seed_state", [])
	simulation_total_steps = simulation_phase_steps.size()
	simulation_is_pc_build = str(page.get("sim_mode", "")) == "pc_build"
	simulation_is_network_lab = str(page.get("sim_mode", "")) == "network_lab"
	simulation_is_server_lab = str(page.get("sim_mode", "")) == "server_lab"
	simulation_is_maintenance_bench = str(page.get("sim_mode", "")) == "maintenance_bench"
	simulation_is_crimp_lab = str(page.get("sim_mode", "")) == "crimp_lab"
	simulation_is_crossover_task = str(page.get("sim_mode", "")) == "crossover_task"
	simulation_guided_hints = not is_assessment

	if simulation_manager_instance != null and is_instance_valid(simulation_manager_instance):
		simulation_manager_instance.queue_free()
	simulation_manager_instance = SimulationManager.new()
	simulation_manager_instance.name = "SimulationManager"
	add_child(simulation_manager_instance)

	if simulation_is_pc_build:
		return _build_pc_build_simulation_page(page, is_assessment)
	if simulation_is_network_lab:
		return _build_network_lab_simulation_page(page, is_assessment)
	if simulation_is_server_lab:
		return _build_server_lab_simulation_page(page, is_assessment)
	if simulation_is_maintenance_bench:
		return _build_maintenance_bench_simulation_page(page, is_assessment)
	if simulation_is_crimp_lab:
		return _build_crimp_lab_simulation_page(page, is_assessment)
	if simulation_is_crossover_task:
		return _build_crossover_task_page(page, is_assessment)
	return _build_quiz_simulation_page(page, is_assessment)


func _build_pc_build_simulation_page(page: Dictionary, is_assessment: bool) -> Control:
	var build_parts: Array = page.get("build_parts", [])
	if build_parts.is_empty():
		build_parts = ModuleContentRegistry.module_1_build_parts()
	# Shares the compact mission strip with the other workstations. The old
	# stacked header ran ~265px tall and pushed the parts tray and slot buttons
	# below the fold at 720p, which hid the install and remove controls.
	var built: Array = _build_workstation_page(
		page,
		is_assessment,
		_packed(PC_BUILD_BENCH_PATH),
		"Build Bench",
		"Drag a part from the right onto its bay. Tap a seated part to remove it.",
		build_parts
	)
	active_build_bench = built[1] as Control
	if active_build_bench.has_signal("action_submitted"):
		active_build_bench.action_submitted.connect(_on_build_bench_action)
	_connect_simulation_signals()
	if simulation_seed_state.is_empty():
		_start_simulation()
	return built[0] as Control


func _build_network_lab_simulation_page(page: Dictionary, is_assessment: bool) -> Control:
	# Clean workstation: compact mission strip + full lab (no stacked headers/tips).
	var root := _base_page()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var mission := PanelContainer.new()
	mission.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mission_style := StyleBoxFlat.new()
	mission_style.bg_color = Color(0.04, 0.12, 0.18, 0.94)
	mission_style.border_color = Color(0.3, 0.72, 0.88, 0.28)
	mission_style.set_border_width_all(1)
	mission_style.set_corner_radius_all(12)
	mission_style.content_margin_left = 14
	mission_style.content_margin_right = 14
	mission_style.content_margin_top = _mission_inset()
	mission_style.content_margin_bottom = _mission_inset()
	mission.add_theme_stylebox_override("panel", mission_style)
	root.add_child(mission)
	mission.resized.connect(_apply_page_min_width)

	var mission_col := VBoxContainer.new()
	mission_col.add_theme_constant_override("separation", 4 if _viewport_short() else 6)
	mission.add_child(mission_col)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	mission_col.add_child(top_row)

	var phase_chip := Label.new()
	phase_chip.text = str(page.get("eyebrow", "Network Workstation")).to_upper()
	phase_chip.add_theme_font_size_override("font_size", 11)
	phase_chip.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	top_row.add_child(phase_chip)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	simulation_progress_label = Label.new()
	simulation_progress_label.text = "Step 0 / %d" % maxi(simulation_total_steps, 1)
	simulation_progress_label.add_theme_font_size_override("font_size", 12)
	simulation_progress_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.95))
	top_row.add_child(simulation_progress_label)

	simulation_progress_bar = ProgressBar.new()
	simulation_progress_bar.min_value = 0
	simulation_progress_bar.max_value = 100
	simulation_progress_bar.value = 0
	simulation_progress_bar.show_percentage = false
	simulation_progress_bar.custom_minimum_size = Vector2(120, 10)
	top_row.add_child(simulation_progress_bar)

	simulation_instruction_label = RichTextLabel.new()
	simulation_instruction_label.bbcode_enabled = true
	simulation_instruction_label.fit_content = true
	simulation_instruction_label.scroll_active = false
	simulation_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	simulation_instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	simulation_instruction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simulation_instruction_label.add_theme_font_size_override("normal_font_size", 13 if _viewport_short() else 14)
	simulation_instruction_label.custom_minimum_size = Vector2(0, 20 if _viewport_short() else 22)
	mission_col.add_child(simulation_instruction_label)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 10)
	mission_col.add_child(meta_row)

	simulation_feedback_label = Label.new()
	simulation_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simulation_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	simulation_feedback_label.add_theme_font_size_override("font_size", 12)
	simulation_feedback_label.add_theme_color_override("font_color", Color(0.72, 0.88, 0.95, 0.9))
	simulation_feedback_label.text = "Cable → Configure PC → Ping. Yellow highlight = next devices."
	meta_row.add_child(simulation_feedback_label)

	# Tip shares the feedback row space; keep node for step updates.
	simulation_tip_label = Label.new()
	simulation_tip_label.visible = false
	simulation_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	simulation_tip_label.add_theme_font_size_override("font_size", 11)
	simulation_tip_label.add_theme_color_override("font_color", Color(0.55, 0.82, 0.95, 0.85))
	mission_col.add_child(simulation_tip_label)

	if is_assessment:
		var pit_row := HFlowContainer.new()
		pit_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pit_row.add_theme_constant_override("h_separation", 14)
		pit_row.add_theme_constant_override("v_separation", 2)
		mission_col.add_child(pit_row)
		for pitfall in page.get("pitfalls", []):
			var chip := Label.new()
			chip.text = "• %s" % str(pitfall)
			chip.add_theme_font_size_override("font_size", 11)
			chip.add_theme_color_override("font_color", Color(1.0, 0.72, 0.45, 0.95))
			pit_row.add_child(chip)

	active_network_lab = _packed(NETWORK_LAB_PATH).instantiate() as Control
	active_network_lab.anchor_left = 0.0
	active_network_lab.anchor_top = 0.0
	active_network_lab.anchor_right = 0.0
	active_network_lab.anchor_bottom = 0.0
	active_network_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_network_lab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lab_h := maxf(_lab_floor(380.0), get_viewport().get_visible_rect().size.y - 240.0)
	active_network_lab.custom_minimum_size = Vector2(0, lab_h)
	root.add_child(active_network_lab)
	if active_network_lab.has_method("setup"):
		var preset: Array = []
		var topo: Variant = page.get("topology", {})
		if typeof(topo) == TYPE_DICTIONARY and not (topo as Dictionary).is_empty():
			preset = [topo]
		active_network_lab.call_deferred("setup", preset, simulation_guided_hints)
	if active_network_lab.has_signal("action_submitted"):
		active_network_lab.action_submitted.connect(_on_network_lab_action)

	_connect_simulation_signals()
	_start_simulation()
	return root


func _build_server_lab_simulation_page(page: Dictionary, is_assessment: bool) -> Control:
	var built: Array = _build_workstation_page(
		page,
		is_assessment,
		_packed(SERVER_LAB_PATH),
		"Server Workstation",
		"Folders → Groups/Users → NTFS → Share → Client test."
	)
	active_server_lab = built[1] as Control
	if active_server_lab.has_signal("action_submitted"):
		active_server_lab.action_submitted.connect(_on_server_lab_action)
	_connect_simulation_signals()
	_start_simulation()
	return built[0] as Control


func _build_maintenance_bench_simulation_page(page: Dictionary, is_assessment: bool) -> Control:
	# The assessment starts from a cold bench; guided phases resume the visit.
	var preset: Array = [] if is_assessment else _prior_bench_step_ids()
	var built: Array = _build_workstation_page(
		page,
		is_assessment,
		_packed(MAINTENANCE_BENCH_PATH),
		"Service Bench",
		"Intake → Hardware PM → Software PM → Network → Repair & document.",
		preset
	)
	active_maintenance_bench = built[1] as Control
	if active_maintenance_bench.has_signal("action_submitted"):
		active_maintenance_bench.action_submitted.connect(_on_maintenance_bench_action)
	_connect_simulation_signals()
	_start_simulation()
	return built[0] as Control


func _build_crimp_lab_simulation_page(page: Dictionary, is_assessment: bool) -> Control:
	# The page names the standard each plug is built to, which is the only
	# difference between a straight-through station and a crossover station.
	var spec: Array = [str(page.get("end_a", "t568b")), str(page.get("end_b", "t568b"))]
	var flow: String = (
		"Strip → fan → order both ends to T568B → crimp → test."
		if spec[0] == spec[1]
		else "Strip → fan → T568A on one end, T568B on the other → crimp → test."
	)
	var built: Array = _build_workstation_page(
		page, is_assessment, _packed(CRIMP_LAB_PATH), "Crimping Bench", flow, spec
	)
	active_crimp_lab = built[1] as Control
	if active_crimp_lab.has_signal("action_submitted"):
		active_crimp_lab.action_submitted.connect(_on_crimp_lab_action)
	_connect_simulation_signals()
	_start_simulation()
	return built[0] as Control


## The crossover scenario spans two benches: crimp the connector, then use it to
## link the workstations. Only one bench is on screen at a time, and the run
## swaps to whichever one the current step belongs to.
func _build_crossover_task_page(page: Dictionary, is_assessment: bool) -> Control:
	var spec: Array = [str(page.get("end_a", "t568a")), str(page.get("end_b", "t568b"))]
	var root := _build_workstation_chrome(
		page,
		is_assessment,
		"Crossover Task",
		"Crimp the connector, cable the two workstations, then prove the link."
	)

	var stage_row := HBoxContainer.new()
	stage_row.add_theme_constant_override("separation", 8)
	root.add_child(stage_row)

	crossover_bench_btn = _stage_btn("Crimping Bench", "bench")
	crossover_site_btn = _stage_btn("Workstation Site", "site")
	stage_row.add_child(crossover_bench_btn)
	stage_row.add_child(crossover_site_btn)

	active_crimp_lab = _attach_lab(root, _packed(CRIMP_LAB_PATH), spec)
	if active_crimp_lab.has_signal("action_submitted"):
		active_crimp_lab.action_submitted.connect(_on_crimp_lab_action)
	active_network_lab = _attach_lab(root, _packed(NETWORK_LAB_PATH), [])
	if active_network_lab.has_signal("action_submitted"):
		active_network_lab.action_submitted.connect(_on_network_lab_action)

	_show_crossover_stage("bench")
	_connect_simulation_signals()
	_start_simulation()
	return root


func _stage_btn(label: String, stage: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(func() -> void: _show_crossover_stage(stage))
	return btn


func _show_crossover_stage(stage: String) -> void:
	crossover_stage = stage
	if active_crimp_lab != null and is_instance_valid(active_crimp_lab):
		active_crimp_lab.visible = stage == "bench"
	if active_network_lab != null and is_instance_valid(active_network_lab):
		active_network_lab.visible = stage == "site"
	_style_stage_btn(crossover_bench_btn, stage == "bench")
	_style_stage_btn(crossover_site_btn, stage == "site")
	_apply_page_min_width()


## Which bench owns a given step action on the crossover scenario.
func _crossover_owner(action: String) -> Control:
	if action == "crimp":
		return active_crimp_lab
	return active_network_lab


func _style_stage_btn(btn: Button, active: bool) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color(0.09, 0.45, 0.65, 0.95) if active else Color(0.05, 0.15, 0.22, 0.9)
	)
	style.border_color = (
		Color(0.45, 0.9, 1.0, 0.85) if active else Color(0.32, 0.68, 0.85, 0.35)
	)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override(
		"font_color", Color(0.98, 0.99, 1.0) if active else Color(0.68, 0.82, 0.9)
	)


## Step ids completed on earlier guided pages of the current bench module.
func _prior_bench_step_ids() -> Array:
	var ids: Array = []
	var pages: Array = module_data.get("pages", [])
	for index in mini(current_page_index, pages.size()):
		var prior: Dictionary = pages[index] as Dictionary
		if str(prior.get("sim_mode", "")) != "maintenance_bench":
			continue
		if str(prior.get("type", "")) == "assessment":
			continue
		for step_variant in prior.get("steps", []):
			ids.append(str((step_variant as Dictionary).get("id", "")))
	return ids


## Shared chrome for every embedded workstation lab. Returns [root, lab].
func _build_workstation_page(
	page: Dictionary,
	is_assessment: bool,
	lab_scene: PackedScene,
	default_eyebrow: String,
	flow_hint: String,
	preset: Array = []
) -> Array:
	var root := _build_workstation_chrome(page, is_assessment, default_eyebrow, flow_hint)
	return [root, _attach_lab(root, lab_scene, preset)]


func _attach_lab(root: Control, lab_scene: PackedScene, preset: Array) -> Control:
	var lab := lab_scene.instantiate() as Control
	lab.anchor_left = 0.0
	lab.anchor_top = 0.0
	lab.anchor_right = 0.0
	lab.anchor_bottom = 0.0
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lab_h := maxf(_lab_floor(380.0), get_viewport().get_visible_rect().size.y - 260.0)
	lab.custom_minimum_size = Vector2(0, lab_h)
	root.add_child(lab)
	if lab.has_method("setup"):
		lab.call_deferred("setup", preset, simulation_guided_hints)
	return lab


func _build_workstation_chrome(
	page: Dictionary, is_assessment: bool, default_eyebrow: String, flow_hint: String
) -> VBoxContainer:
	# Stable workstation chrome — same pattern as network lab to avoid layout jump.
	var root := _base_page()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var mission := PanelContainer.new()
	mission.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mission_style := StyleBoxFlat.new()
	mission_style.bg_color = Color(0.04, 0.12, 0.18, 0.94)
	mission_style.border_color = Color(0.3, 0.72, 0.88, 0.28)
	mission_style.set_border_width_all(1)
	mission_style.set_corner_radius_all(12)
	mission_style.content_margin_left = 14
	mission_style.content_margin_right = 14
	mission_style.content_margin_top = _mission_inset()
	mission_style.content_margin_bottom = _mission_inset()
	mission.add_theme_stylebox_override("panel", mission_style)
	root.add_child(mission)
	# The strip height depends on how the instruction wraps; re-fit the lab once
	# it settles so the workstation ends exactly at the navigation bar.
	mission.resized.connect(_apply_page_min_width)

	var mission_col := VBoxContainer.new()
	mission_col.add_theme_constant_override("separation", 4 if _viewport_short() else 6)
	mission.add_child(mission_col)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	mission_col.add_child(top_row)

	var phase_chip := Label.new()
	phase_chip.text = str(page.get("eyebrow", default_eyebrow)).to_upper()
	phase_chip.add_theme_font_size_override("font_size", 11)
	phase_chip.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	top_row.add_child(phase_chip)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	simulation_progress_label = Label.new()
	simulation_progress_label.text = "Step 0 / %d" % maxi(simulation_total_steps, 1)
	simulation_progress_label.add_theme_font_size_override("font_size", 12)
	simulation_progress_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.95))
	top_row.add_child(simulation_progress_label)

	simulation_progress_bar = ProgressBar.new()
	simulation_progress_bar.min_value = 0
	simulation_progress_bar.max_value = 100
	simulation_progress_bar.value = 0
	simulation_progress_bar.show_percentage = false
	simulation_progress_bar.custom_minimum_size = Vector2(120, 10)
	top_row.add_child(simulation_progress_bar)

	if is_assessment:
		var reset_btn := Button.new()
		reset_btn.text = "RESET"
		reset_btn.focus_mode = Control.FOCUS_NONE
		reset_btn.custom_minimum_size = Vector2(72, 28)
		reset_btn.add_theme_font_size_override("font_size", 11)
		reset_btn.pressed.connect(_reset_current_assessment)
		top_row.add_child(reset_btn)
		_style_assessment_tool_btn(reset_btn)

	simulation_instruction_label = RichTextLabel.new()
	simulation_instruction_label.bbcode_enabled = true
	simulation_instruction_label.fit_content = true
	simulation_instruction_label.scroll_active = false
	simulation_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	simulation_instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	simulation_instruction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simulation_instruction_label.add_theme_font_size_override("normal_font_size", 13 if _viewport_short() else 14)
	simulation_instruction_label.custom_minimum_size = Vector2(0, 20 if _viewport_short() else 22)
	mission_col.add_child(simulation_instruction_label)

	simulation_feedback_label = Label.new()
	simulation_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simulation_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	simulation_feedback_label.add_theme_font_size_override("font_size", 12)
	simulation_feedback_label.add_theme_color_override("font_color", Color(0.72, 0.88, 0.95, 0.9))
	simulation_feedback_label.text = flow_hint
	mission_col.add_child(simulation_feedback_label)

	simulation_tip_label = Label.new()
	simulation_tip_label.visible = false
	mission_col.add_child(simulation_tip_label)

	if is_assessment:
		# Flow container so the pitfall chips wrap instead of running off the strip.
		var pit_row := HFlowContainer.new()
		pit_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pit_row.add_theme_constant_override("h_separation", 14)
		pit_row.add_theme_constant_override("v_separation", 2)
		mission_col.add_child(pit_row)
		for pitfall in page.get("pitfalls", []):
			var chip := Label.new()
			chip.text = "• %s" % str(pitfall)
			chip.add_theme_font_size_override("font_size", 11)
			chip.add_theme_color_override("font_color", Color(1.0, 0.72, 0.45, 0.95))
			pit_row.add_child(chip)

	return root


func _build_quiz_simulation_page(page: Dictionary, is_assessment: bool) -> Control:
	var root := _base_page()
	root.add_theme_constant_override("separation", 12)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Compact header strip
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(header)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 4)
	header.add_child(copy)
	copy.add_child(_eyebrow_label(page.get("eyebrow", "Phase")))
	var title := _title_label(page.get("title", ""))
	title.add_theme_font_size_override("font_size", 22)
	copy.add_child(title)
	var body := _body_label(page.get("description", ""))
	body.add_theme_font_size_override("font_size", 13)
	copy.add_child(body)

	if is_assessment:
		# One wrapping row of chips: stacked warning lines ate ~110px of height
		# and pushed the answer choices off the bottom of the page.
		var pitfalls: Array = page.get("pitfalls", [])
		if not pitfalls.is_empty():
			var pit_row := HFlowContainer.new()
			pit_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pit_row.add_theme_constant_override("h_separation", 14)
			pit_row.add_theme_constant_override("v_separation", 2)
			copy.add_child(pit_row)
			for pitfall in pitfalls:
				var chip := Label.new()
				chip.text = "!  %s" % str(pitfall)
				chip.add_theme_font_size_override("font_size", 12)
				chip.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32, 1))
				pit_row.add_child(chip)

	# Left = models · Right = question + answers
	var phone := false
	var layout_node := get_node_or_null("/root/ResponsiveLayout")
	if layout_node != null and layout_node.has_method("is_phone"):
		phone = bool(layout_node.call("is_phone"))
	var split: BoxContainer
	if phone:
		split = VBoxContainer.new()
	else:
		split = HBoxContainer.new()
	split.add_theme_constant_override("separation", 12 if phone else 16)
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var view_h: float = get_viewport_rect().size.y
	split.custom_minimum_size = Vector2(0, maxf(300.0 if phone else 340.0, view_h - (240.0 if phone else 260.0)))
	root.add_child(split)
	simulation_split = split
	# The header wraps differently per phase; re-fit once it settles so the
	# answer choices always end at the navigation bar instead of being clipped.
	header.resized.connect(_apply_page_min_width)

	var model_titles: Array = page.get("related_models", [])
	if model_titles.is_empty():
		var single: String = str(page.get("related_model", ""))
		if single != "":
			model_titles = [single]

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.95
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(left)

	if not model_titles.is_empty():
		var gallery: Control = _build_model_gallery(model_titles)
		gallery.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gallery.size_flags_vertical = Control.SIZE_EXPAND_FILL
		left.add_child(gallery)
	else:
		var placeholder := Control.new()
		placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		left.add_child(placeholder)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.15
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(right)

	# Question + progress band
	var prompt_card := _card_panel(Color(0.05, 0.14, 0.2, 0.9))
	prompt_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right.add_child(prompt_card)
	var prompt_layout := VBoxContainer.new()
	prompt_layout.add_theme_constant_override("separation", 10)
	prompt_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_card.add_child(prompt_layout)

	simulation_instruction_label = RichTextLabel.new()
	simulation_instruction_label.bbcode_enabled = true
	simulation_instruction_label.fit_content = true
	simulation_instruction_label.scroll_active = false
	simulation_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	simulation_instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	simulation_instruction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simulation_instruction_label.add_theme_font_size_override("normal_font_size", 16)
	simulation_instruction_label.custom_minimum_size = Vector2(0, 36)
	prompt_layout.add_child(simulation_instruction_label)

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 10)
	progress_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_layout.add_child(progress_row)

	simulation_progress_label = Label.new()
	simulation_progress_label.text = "Question 0 / %d" % maxi(simulation_total_steps, 1)
	simulation_progress_label.add_theme_font_size_override("font_size", 13)
	simulation_progress_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.95))
	progress_row.add_child(simulation_progress_label)

	simulation_progress_bar = ProgressBar.new()
	simulation_progress_bar.min_value = 0
	simulation_progress_bar.max_value = 100
	simulation_progress_bar.step = 1
	simulation_progress_bar.value = 0
	simulation_progress_bar.show_percentage = true
	simulation_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simulation_progress_bar.custom_minimum_size = Vector2(0, 14)
	progress_row.add_child(simulation_progress_bar)

	simulation_feedback_label = Label.new()
	simulation_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	simulation_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simulation_feedback_label.add_theme_font_size_override("font_size", 13)
	simulation_feedback_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.9))
	prompt_layout.add_child(simulation_feedback_label)

	simulation_tip_label = Label.new()
	simulation_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	simulation_tip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simulation_tip_label.add_theme_font_size_override("font_size", 12)
	simulation_tip_label.add_theme_color_override("font_color", Color(0.55, 0.82, 0.95, 0.88))
	simulation_tip_label.text = ""
	prompt_layout.add_child(simulation_tip_label)

	# Answer choices — rebuilt each step as a 4-option MCQ
	var station := _card_panel(Color(0.06, 0.28, 0.4, 0.22))
	station.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	station.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(station)
	var station_layout := VBoxContainer.new()
	station_layout.add_theme_constant_override("separation", 10)
	station_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	station_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	station.add_child(station_layout)
	station_layout.add_child(_section_title("Choose the best next action"))

	var button_scroll := ScrollContainer.new()
	button_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	station_layout.add_child(button_scroll)

	simulation_answer_grid = GridContainer.new()
	simulation_answer_grid.columns = 1
	simulation_answer_grid.add_theme_constant_override("h_separation", 10)
	simulation_answer_grid.add_theme_constant_override("v_separation", 10)
	simulation_answer_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_scroll.add_child(simulation_answer_grid)

	_connect_simulation_signals()
	_start_simulation()
	return root


func _on_build_bench_action(action: SimulationAction) -> void:
	if simulation_manager_instance == null:
		return
	simulation_manager_instance.receive_action(action)


func _on_network_lab_action(action: SimulationAction) -> void:
	if simulation_manager_instance == null:
		return
	simulation_manager_instance.receive_action(action)


func _on_server_lab_action(action: SimulationAction) -> void:
	if simulation_manager_instance == null:
		return
	simulation_manager_instance.receive_action(action)


func _on_maintenance_bench_action(action: SimulationAction) -> void:
	if simulation_manager_instance == null:
		return
	simulation_manager_instance.receive_action(action)


func _on_crimp_lab_action(action: SimulationAction) -> void:
	if simulation_manager_instance == null:
		return
	simulation_manager_instance.receive_action(action)


func _rebuild_quiz_choices(current_step_id: String) -> void:
	if _is_interactive_sim() or simulation_answer_grid == null:
		return
	_quiz_choice_locked = false
	# queue_free, not free: this runs inside the pressed answer's signal
	# emission, and freeing the emitting button outright is refused and leaks it.
	while simulation_answer_grid.get_child_count() > 0:
		var child: Node = simulation_answer_grid.get_child(0)
		simulation_answer_grid.remove_child(child)
		child.queue_free()
	simulation_buttons.clear()

	var correct: Dictionary = _find_step_content(current_step_id)
	if correct.is_empty():
		return

	var distractors: Array = []
	for step_variant in simulation_phase_steps:
		var step_data: Dictionary = step_variant as Dictionary
		var sid: String = str(step_data.get("id", ""))
		if sid == "" or sid == current_step_id:
			continue
		distractors.append(step_data)
	distractors.shuffle()

	var options: Array = [correct]
	for d in distractors:
		if options.size() >= 4:
			break
		options.append(d)
	# Pad with generic safe wrong actions if a phase has fewer than 4 steps.
	var fillers: Array = [
		{"id": "_filler_skip_esd", "label": "Skip ESD protection and start mounting parts", "action": "tap", "target": "_filler_skip_esd"},
		{"id": "_filler_force_fit", "label": "Force the part into place without checking orientation", "action": "tap", "target": "_filler_force_fit"},
		{"id": "_filler_power_early", "label": "Power on before cables and cooling are connected", "action": "tap", "target": "_filler_power_early"},
		{"id": "_filler_ignore_docs", "label": "Skip documentation and hand the PC over unmarked", "action": "tap", "target": "_filler_ignore_docs"},
	]
	for f in fillers:
		if options.size() >= 4:
			break
		var fid: String = str(f.get("id", ""))
		var used := false
		for o in options:
			if str(o.get("id", "")) == fid:
				used = true
				break
		if not used:
			options.append(f)
	options.shuffle()

	var letters: Array[String] = ["A", "B", "C", "D"]
	for index in mini(options.size(), 4):
		var step_data: Dictionary = options[index] as Dictionary
		var step_id: String = str(step_data.get("id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 48)
		button.text = "%s  ·  %s" % [letters[index], str(step_data.get("label", ""))]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_simulation_step_pressed.bind(step_data))
		_apply_action_button_style(button)
		simulation_answer_grid.add_child(button)
		simulation_buttons[step_id] = button


func _build_model_gallery(model_titles: Array) -> Control:
	# 2-column grid fills the left pane (no empty dead space on the right).
	var panel := _card_panel(Color(0.03, 0.1, 0.15, 0.75))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 8)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(wrap)

	var heading := Label.new()
	heading.text = "Reference models · drag any model to rotate"
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", Color(0.55, 0.82, 0.95, 0.9))
	wrap.add_child(heading)

	var titles: Array = []
	for title_variant in model_titles:
		var title: String = str(title_variant)
		if title != "":
			titles.append(title)

	# Rows of two, but a trailing odd card stretches across the row instead of
	# leaving a grid hole with dead space beside it.
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.add_child(rows)

	var index: int = 0
	while index < titles.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rows.add_child(row)
		for column in mini(2, titles.size() - index):
			var card := _build_inline_model_preview(str(titles[index + column]))
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.size_flags_vertical = Control.SIZE_EXPAND_FILL
			row.add_child(card)
		index += 2

	return panel


func _build_inline_model_preview(model_title: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 120)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.07, 0.11, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.35, 0.78, 0.92, 0.18)
	style.content_margin_left = 6
	style.content_margin_top = 4
	style.content_margin_right = 6
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(stack)

	var title_label := Label.new()
	title_label.text = model_title
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", Color(0.35, 0.82, 0.95, 1))
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.clip_text = true
	stack.add_child(title_label)
	simulation_preview_label = title_label

	var viewer: Control = _packed(CARD_VIEWER_PATH).instantiate() as Control
	viewer.custom_minimum_size = Vector2(0, 88)
	viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewer.mouse_filter = Control.MOUSE_FILTER_STOP
	stack.add_child(viewer)

	var close_btn: Button = viewer.get_node_or_null("Button") as Button
	if close_btn != null:
		close_btn.visible = false

	var sv := viewer.get_node_or_null("SubViewportContainer/SubViewport") as SubViewport
	if sv != null:
		sv.transparent_bg = false
		if PerformanceProfile != null:
			PerformanceProfile.apply_to_subviewport(sv, viewer)
		else:
			sv.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE

	var container: Node3D = viewer.get_node("SubViewportContainer/SubViewport/Node3D/ModelPivot/ModelContainer") as Node3D
	simulation_preview_container = container
	simulation_preview_viewer = viewer
	if viewer.has_method("setup"):
		viewer.setup(0.01, 0.2, 0.04)
	if viewer.has_method("set_interactive"):
		viewer.set_interactive(true)
	if viewer.has_method("set_auto_rotate"):
		viewer.set_auto_rotate(true)
	# The gallery states this once in its heading; per-card overlays just sat on
	# top of the models.
	if viewer.has_method("set_hint_enabled"):
		viewer.set_hint_enabled(false)

	var item: Dictionary = _find_model_item_by_title(model_title)
	if not item.is_empty():
		_pending_preview_loads.append({
			"item": item,
			"container": container,
			"viewer": viewer,
		})
	return panel

func _find_model_item_by_title(title: String) -> Dictionary:
	for page in module_data.get("pages", []):
		if page.get("type", "") != "model_library":
			continue
		for item in page.get("items", []):
			if str(item.get("title", "")) == title:
				return item
	return {}


func _load_preview_model(item: Dictionary) -> void:
	_load_preview_model_into(item, simulation_preview_container, simulation_preview_viewer)


func _load_preview_model_into(item: Dictionary, container: Node3D, viewer: Control) -> void:
	if container == null:
		return

	while container.get_child_count() > 0:
		var child: Node = container.get_child(0)
		container.remove_child(child)
		child.free()

	var model: Node3D = null
	var scene_path: String = _safe_model_path(str(item.get("scene_path", "")))
	if scene_path != "" and ResourceLoader.exists(scene_path):
		var packed: PackedScene = _packed(scene_path)
		if packed != null:
			model = packed.instantiate()
			# Shared factory scene defaults to SSD — apply the item's part_id
			# before entering the tree so _ready() builds the right mesh.
			var pid := str(item.get("part_id", ""))
			if model != null and pid != "" and "part_id" in model:
				model.part_id = pid
	if model == null:
		model = _build_placeholder_model(item.get("title", "Model"))

	container.add_child(model)
	# Defer framing with explicit target so gallery cards don't steal each other.
	call_deferred("_finish_preview_model_target", model, viewer, str(item.get("title", "")))


func _finish_preview_model() -> void:
	_finish_preview_model_target(simulation_preview_model, simulation_preview_viewer, "")


func _finish_preview_model_target(model: Node3D, viewer: Control, title: String) -> void:
	if model == null or not is_instance_valid(model):
		return
	# Only motherboard uses the old socket/ground stripper.
	if title.to_lower().contains("motherboard"):
		ModelGeometryCleanup.strip_placeholder_volumes(model)

	# Wait a couple frames so glTF meshes/materials are ready before framing.
	await get_tree().process_frame
	await get_tree().process_frame
	if model == null or not is_instance_valid(model):
		return

	_prepare_preview_model_visibility(model)

	if viewer != null and is_instance_valid(viewer) and viewer.has_method("frame_model"):
		viewer.frame_model(title)
		# Second pass after transforms settle (tiny Sketchfab tools need this).
		await get_tree().process_frame
		if viewer != null and is_instance_valid(viewer) and viewer.has_method("frame_model"):
			viewer.frame_model(title)


func _prepare_preview_model_visibility(root: Node) -> void:
	if root == null:
		return
	if root.has_meta("sb_procedural"):
		_force_preview_visible(root)
		return
	_boost_preview_imported_materials(root)


func _force_preview_visible(root: Node) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		mi.visible = true
		mi.layers = 1
	for child in root.get_children():
		_force_preview_visible(child)


func _boost_preview_imported_materials(root: Node) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		mi.visible = true
		mi.layers = 1
		var source: Material = mi.get_active_material(0)
		if source == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			source = mi.mesh.surface_get_material(0)
		if source is BaseMaterial3D:
			var base := (source as BaseMaterial3D).duplicate() as BaseMaterial3D
			base.metallic = minf(base.metallic, 0.4)
			base.roughness = maxf(base.roughness, 0.3)
			var c := base.albedo_color
			if c.r < 0.05 and c.g < 0.05 and c.b < 0.05:
				base.albedo_color = Color(0.28, 0.3, 0.34, c.a)
			mi.material_override = base
	for child in root.get_children():
		_boost_preview_imported_materials(child)


func _safe_model_path(scene_path: String) -> String:
	return scene_path


func _base_page() -> VBoxContainer:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_theme_constant_override("separation", 22)
	return root


func _card_panel(panel_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var style := StyleBoxFlat.new()
	style.bg_color = panel_color
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.35, 0.78, 0.92, 0.14)
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _eyebrow_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value.to_upper()
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.35, 0.82, 0.95, 1))
	return label


func _title_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _subtitle_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.78, 0.9, 0.96, 0.88))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _body_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.86, 0.93, 0.97, 0.92))
	return label


func _section_title(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1))
	return label


func _bullet_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = "•  %s" % text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.86, 0.93, 0.97, 0.92))
	return label


func _warning_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = "!  %s" % text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32, 1))
	return label


func _step_label(index: int, text_value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 40)

	var badge := Label.new()
	badge.text = "%02d" % index
	badge.custom_minimum_size = Vector2(40, 40)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", Color(0.02, 0.08, 0.12, 1))

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.35, 0.82, 0.95, 1)
	badge_style.corner_radius_top_left = 12
	badge_style.corner_radius_top_right = 12
	badge_style.corner_radius_bottom_left = 12
	badge_style.corner_radius_bottom_right = 12
	badge.add_theme_stylebox_override("normal", badge_style)
	row.add_child(badge)

	var text_label := Label.new()
	text_label.text = text_value
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(0, 0)
	text_label.add_theme_font_size_override("font_size", 15)
	text_label.add_theme_color_override("font_color", Color(0.92, 0.96, 0.99, 0.95))
	row.add_child(text_label)

	return row


func _apply_action_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.03, 0.1, 0.15, 0.96)
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_left = 14
	normal.corner_radius_bottom_right = 14
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.35, 0.82, 0.95, 0.35)
	normal.content_margin_left = 16
	normal.content_margin_top = 12
	normal.content_margin_right = 16
	normal.content_margin_bottom = 12

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.06, 0.2, 0.28, 0.98)
	hover.border_color = Color(0.45, 0.88, 1.0, 0.55)

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.12, 0.48, 0.62, 0.45)

	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.05, 0.12, 0.16, 0.7)
	disabled.border_color = Color(0.35, 0.82, 0.95, 0.18)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(0.9, 0.98, 1.0, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.7, 0.8, 0.85, 0.75))
	button.modulate = Color(1, 1, 1, 1)


func _build_empty_state(title_text: String, body_text: String) -> Control:
	var root := _base_page()
	var card := _card_panel(Color(0.9529412, 0.98039216, 0.99215686, 0.08))
	root.add_child(card)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	card.add_child(layout)
	layout.add_child(_title_label(title_text))
	layout.add_child(_body_label(body_text))
	return root


func _update_navigation_state() -> void:
	var page_count: int = module_data.get("pages", []).size()
	prev_btn.disabled = current_page_index <= 0
	next_btn.disabled = current_page_index >= page_count - 1


func _on_prev_btn_pressed() -> void:
	if _page_turn_busy or current_page_index <= 0:
		return
	_page_turn_busy = true
	UiMotion.pulse_button(prev_btn)
	current_page_index -= 1
	_finish_page_turn_async()


func _on_next_btn_pressed() -> void:
	if _page_turn_busy:
		return
	var pages: Array = module_data.get("pages", [])
	if current_page_index >= pages.size() - 1:
		_on_exit_btn_pressed()
		return
	_page_turn_busy = true
	UiMotion.pulse_button(next_btn)
	current_page_index += 1
	_finish_page_turn_async()


func _finish_page_turn_async() -> void:
	_pending_preview_loads.clear()
	var pages: Array = module_data.get("pages", [])
	if current_page_index >= 0 and current_page_index < pages.size():
		var page: Dictionary = pages[current_page_index] as Dictionary
		# Parts Lab only needs the light InteractiveHardwareLab scene — short wait.
		var timeout_ms := 1500 if str(page.get("type", "")) == "model_library" else 8000
		await _await_critical_paths(_paths_for_page(page), timeout_ms)
	if not is_instance_valid(self):
		return
	_render_page()
	_page_turn_busy = false


func _on_exit_btn_pressed() -> void:
	var host: Node = get_parent()
	while host != null and not host.has_method("send_event"):
		host = host.get_parent()

	if host != null:
		host.send_event("destroy", module_id)


func _connect_simulation_signals() -> void:
	if simulation_manager_instance == null:
		return
	if not simulation_manager_instance.step_changed.is_connected(_on_simulation_step_changed):
		simulation_manager_instance.step_changed.connect(_on_simulation_step_changed)
	if not simulation_manager_instance.step_completed.is_connected(_on_simulation_step_completed):
		simulation_manager_instance.step_completed.connect(_on_simulation_step_completed)
	if not simulation_manager_instance.action_incorrect.is_connected(_on_simulation_action_incorrect):
		simulation_manager_instance.action_incorrect.connect(_on_simulation_action_incorrect)
	if not simulation_manager_instance.simulation_completed.is_connected(_on_simulation_completed):
		simulation_manager_instance.simulation_completed.connect(_on_simulation_completed)


func _start_simulation() -> void:
	var steps: Array[SimulationStep] = []
	for step_variant in simulation_phase_steps:
		var step_data: Dictionary = step_variant as Dictionary
		var step_id: String = str(step_data.get("id", ""))
		steps.append(SimulationStep.new(
			step_id,
			str(step_data.get("instruction", "")),
			str(step_data.get("action", "tap")),
			str(step_data.get("target", step_id)),
			str(step_data.get("destination", "")),
			step_data.get("value", null)
		))

	var mode := SimulationMode.Type.ASSESSMENT if simulation_page_type == "assessment" else SimulationMode.Type.GUIDED
	simulation_manager_instance.start(steps, mode)


func _finalize_seeded_simulation() -> void:
	if active_build_bench != null and active_build_bench.has_method("apply_seed_state"):
		active_build_bench.apply_seed_state(simulation_seed_state)
	if simulation_manager_instance != null:
		_start_simulation()


func _reset_current_assessment() -> void:
	if simulation_page_type != "assessment" or simulation_manager_instance == null:
		return
	simulation_completed_ids.clear()
	_quiz_choice_locked = false
	_pending_correct_tip = ""
	if active_build_bench != null and active_build_bench.has_method("reset_scenario"):
		active_build_bench.reset_scenario()
	if active_crimp_lab != null and active_crimp_lab.has_method("reset_scenario"):
		active_crimp_lab.reset_scenario()
	if active_network_lab != null and active_network_lab.has_method("reset_scenario"):
		active_network_lab.reset_scenario()
	if active_server_lab != null and active_server_lab.has_method("reset_scenario"):
		active_server_lab.reset_scenario()
	if simulation_is_crossover_task:
		_show_crossover_stage("bench")
	_start_simulation()
	_update_simulation_progress_ui()
	if simulation_feedback_label != null:
		simulation_feedback_label.text = "Scenario reset — start again from step 1."
		simulation_feedback_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.9))


func _style_assessment_tool_btn(button: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.06, 0.95)
	style.border_color = Color(1.0, 0.55, 0.35, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", Color(1.0, 0.82, 0.62))


func _on_simulation_step_pressed(step_data: Dictionary) -> void:
	if simulation_manager_instance == null:
		return
	if _quiz_choice_locked and not _is_interactive_sim():
		return
	var step_id: String = str(step_data.get("id", ""))
	# Allow distractors even if that step was already completed earlier.
	if _is_interactive_sim() and simulation_completed_ids.has(step_id):
		return
	var action := SimulationAction.new(
		str(step_data.get("action", "tap")),
		str(step_data.get("target", step_id)),
		str(step_data.get("destination", ""))
	)
	# Keep button lookup key for flash feedback on wrong quiz picks.
	if not _is_interactive_sim():
		action.value = step_id
	simulation_manager_instance.receive_action(action)


func _find_step_content(step_id: String) -> Dictionary:
	for step_variant in simulation_phase_steps:
		var step_data: Dictionary = step_variant as Dictionary
		if str(step_data.get("id", "")) == step_id:
			return step_data
	return {}


func _update_simulation_progress_ui() -> void:
	if simulation_progress_bar == null:
		return
	var answered: int = simulation_completed_ids.size()
	var total: int = maxi(simulation_total_steps, 1)
	var pct: float = (float(answered) / float(total)) * 100.0
	simulation_progress_bar.value = pct
	if simulation_progress_label != null:
		var current_q: int = mini(answered + 1, total)
		var unit: String = "Step" if _is_interactive_sim() else "Question"
		if answered >= total:
			simulation_progress_label.text = "Complete · %d / %d" % [answered, total]
		else:
			simulation_progress_label.text = "%s %d / %d" % [unit, current_q, total]


func _refresh_answer_button_states(_current_step_id: String = "") -> void:
	for step_id_variant in simulation_buttons.keys():
		var step_id: String = str(step_id_variant)
		var button: Button = simulation_buttons[step_id] as Button
		if button == null or not is_instance_valid(button):
			continue
		if simulation_completed_ids.has(step_id):
			button.disabled = true
			_apply_answer_result_style(button, true)
		else:
			button.disabled = false
			_apply_action_button_style(button)
			button.modulate = Color(1, 1, 1, 1)


func _on_simulation_step_changed(step) -> void:
	var step_id: String = str(step.id)
	simulation_current_step_id = step_id
	var content: Dictionary = _find_step_content(step_id)
	var question_text: String = str(content.get("question", step.instruction))
	var tip_text: String = str(content.get("tip", content.get("instruction", "")))

	var heading: String = "Question" if simulation_page_type == "assessment" else "Next action"
	if simulation_is_pc_build:
		heading = "Install step" if simulation_page_type != "assessment" else (
			"Remove step" if str(step.action) == "remove" else "Fix step"
		)
	elif _is_workstation_sim():
		heading = "Do this" if simulation_page_type != "assessment" else "Assessment"
	if simulation_instruction_label != null:
		if _is_workstation_sim():
			simulation_instruction_label.text = "[b]%s:[/b] %s" % [heading, question_text]
		else:
			simulation_instruction_label.text = "[b]%s[/b]\n%s" % [heading, question_text]

	if simulation_tip_label != null:
		if simulation_is_pc_build:
			simulation_tip_label.visible = false
			simulation_tip_label.text = "Tip: Drag the part from the right onto its bay."
		elif _is_workstation_sim():
			simulation_tip_label.visible = false
		elif tip_text != "" and tip_text != question_text:
			simulation_tip_label.visible = true
			simulation_tip_label.text = "Tip: %s" % tip_text
		else:
			simulation_tip_label.visible = true
			simulation_tip_label.text = "Tip: Choose the safest technician action for this step."

	if simulation_feedback_label != null:
		if _pending_correct_tip != "":
			simulation_feedback_label.text = "Correct — %s" % _pending_correct_tip
			simulation_feedback_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.7, 1))
			_pending_correct_tip = ""
		elif simulation_is_pc_build:
			var part_name: String = str(step.target).replace("_", " ")
			var slot_name: String = str(step.destination).replace("_", " ")
			if str(step.action) == "remove":
				simulation_feedback_label.text = "Remove %s from %s." % [part_name, slot_name]
			else:
				simulation_feedback_label.text = "Drag %s onto %s." % [part_name, slot_name]
			simulation_feedback_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.9))
		elif simulation_is_network_lab:
			if tip_text != "":
				simulation_feedback_label.text = tip_text
			else:
				simulation_feedback_label.text = "Complete the highlighted cable / IP / ping action on the canvas."
			simulation_feedback_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.9))
		elif simulation_is_server_lab:
			if tip_text != "":
				simulation_feedback_label.text = tip_text
			else:
				simulation_feedback_label.text = "Use the Server Manager panels on the right to complete this step."
			simulation_feedback_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.9))
		elif simulation_is_maintenance_bench:
			if tip_text != "":
				simulation_feedback_label.text = tip_text
			else:
				simulation_feedback_label.text = "Run the matching service action on the bench to the right."
			simulation_feedback_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.9))
		elif simulation_is_crimp_lab or simulation_is_crossover_task:
			if tip_text != "":
				simulation_feedback_label.text = tip_text
			else:
				simulation_feedback_label.text = "Work the crimping bench — tools on the right, pins on the plug."
			simulation_feedback_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.9))
		else:
			simulation_feedback_label.text = "Pick the best answer. Wrong choices stay available — try again."
			simulation_feedback_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.9))

	if simulation_is_pc_build and active_build_bench != null:
		if active_build_bench.has_method("set_step_hint"):
			active_build_bench.set_step_hint(str(step.target), str(step.destination))
		if active_build_bench.has_method("highlight_part"):
			active_build_bench.highlight_part(str(step.target))
	elif simulation_is_network_lab and active_network_lab != null:
		if active_network_lab.has_method("set_guided_hint"):
			active_network_lab.set_guided_hint(str(step.target), str(step.destination))
	elif simulation_is_server_lab and active_server_lab != null:
		if active_server_lab.has_method("set_guided_hint"):
			active_server_lab.set_guided_hint(str(step.target), str(step.destination))
	elif simulation_is_maintenance_bench and active_maintenance_bench != null:
		if active_maintenance_bench.has_method("set_guided_hint"):
			active_maintenance_bench.set_guided_hint(str(step.target), str(step.destination))
	elif simulation_is_crimp_lab and active_crimp_lab != null:
		if active_crimp_lab.has_method("set_guided_hint"):
			active_crimp_lab.set_guided_hint(str(step.target), str(step.destination))
	elif simulation_is_crossover_task:
		var owner_lab: Control = _crossover_owner(str(step.action))
		_show_crossover_stage("bench" if str(step.action) == "crimp" else "site")
		if owner_lab != null and owner_lab.has_method("set_guided_hint"):
			owner_lab.set_guided_hint(str(step.target), str(step.destination))
	elif not _is_interactive_sim():
		_rebuild_quiz_choices(step_id)

	_refresh_help_context()
	_update_simulation_progress_ui()
	_refresh_answer_button_states(step_id)


func _on_simulation_step_completed(step) -> void:
	var step_id: String = str(step.id)
	simulation_completed_ids[step_id] = true
	_quiz_choice_locked = true

	var content: Dictionary = _find_step_content(step_id)
	_pending_correct_tip = str(content.get("tip", content.get("instruction", "Correct.")))

	if simulation_is_pc_build and active_build_bench != null:
		if str(step.action) != "remove" and active_build_bench.has_method("mark_installed"):
			active_build_bench.mark_installed(str(step.target), str(step.destination))
	if simulation_is_network_lab and active_network_lab != null and active_network_lab.has_method("mark_step_done"):
		active_network_lab.mark_step_done(str(step.target), str(step.destination))
	if simulation_is_server_lab and active_server_lab != null and active_server_lab.has_method("mark_step_done"):
		active_server_lab.mark_step_done(str(step.target), str(step.destination))
	if (
		simulation_is_maintenance_bench
		and active_maintenance_bench != null
		and active_maintenance_bench.has_method("mark_step_done")
	):
		active_maintenance_bench.mark_step_done(str(step.target), str(step.destination))
	if simulation_is_crimp_lab and active_crimp_lab != null and active_crimp_lab.has_method("mark_step_done"):
		active_crimp_lab.mark_step_done(str(step.target), str(step.destination))
	if simulation_is_crossover_task:
		var done_lab: Control = _crossover_owner(str(step.action))
		if done_lab != null and done_lab.has_method("mark_step_done"):
			done_lab.mark_step_done(str(step.target), str(step.destination))

	if simulation_buttons.has(step_id):
		var button: Button = simulation_buttons[step_id] as Button
		if button != null:
			button.disabled = true
			_apply_answer_result_style(button, true)
			var motion := get_node_or_null("/root/UiMotion")
			if motion != null and motion.has_method("pulse_button"):
				motion.call("pulse_button", button)

	_update_simulation_progress_ui()


func _on_simulation_action_incorrect(action) -> void:
	_pending_correct_tip = ""
	_quiz_choice_locked = false
	if simulation_feedback_label != null:
		if simulation_is_pc_build:
			simulation_feedback_label.text = "Wrong part or slot — check the install step and try again."
		elif simulation_is_network_lab:
			simulation_feedback_label.text = "Wrong cable, IP, or ping target — follow the current lab step."
		elif simulation_is_server_lab:
			simulation_feedback_label.text = "Wrong server action — follow the current admin step."
		elif simulation_is_maintenance_bench:
			simulation_feedback_label.text = "Wrong service action — follow the current maintenance step."
		elif simulation_is_crossover_task:
			simulation_feedback_label.text = "Not the step this scenario is waiting for — re-read the task."
		elif simulation_is_crimp_lab:
			simulation_feedback_label.text = "Wrong crimping action — follow the current step."
		else:
			simulation_feedback_label.text = "Not yet — re-read the question and choose the safer next step."
		simulation_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55, 1))

	if simulation_is_pc_build and active_build_bench != null and active_build_bench.has_method("flash_incorrect"):
		active_build_bench.flash_incorrect()
	if simulation_is_network_lab and active_network_lab != null and active_network_lab.has_method("flash_incorrect"):
		active_network_lab.flash_incorrect()
	if simulation_is_server_lab and active_server_lab != null and active_server_lab.has_method("flash_incorrect"):
		active_server_lab.flash_incorrect()
	if (
		simulation_is_maintenance_bench
		and active_maintenance_bench != null
		and active_maintenance_bench.has_method("flash_incorrect")
	):
		active_maintenance_bench.flash_incorrect()
	if simulation_is_crimp_lab and active_crimp_lab != null and active_crimp_lab.has_method("flash_incorrect"):
		active_crimp_lab.flash_incorrect()
	if simulation_is_crossover_task:
		for lab in [active_crimp_lab, active_network_lab]:
			if lab != null and is_instance_valid(lab) and lab.has_method("flash_incorrect"):
				lab.flash_incorrect()

	var wrong_key: String = ""
	if action.value != null:
		wrong_key = str(action.value)
	if wrong_key == "" or not simulation_buttons.has(wrong_key):
		wrong_key = str(action.target)
	if simulation_buttons.has(wrong_key):
		var button: Button = simulation_buttons[wrong_key] as Button
		if button == null:
			return
		_apply_answer_result_style(button, false)
		get_tree().create_timer(0.55).timeout.connect(
			func() -> void:
				if not is_instance_valid(button):
					return
				_apply_action_button_style(button)
				button.modulate = Color(1, 1, 1, 1)
		)


func _on_simulation_completed() -> void:
	var tip: String = _pending_correct_tip
	_pending_correct_tip = ""
	_quiz_choice_locked = true
	if simulation_instruction_label != null:
		simulation_instruction_label.text = "[b]Phase complete[/b]\n%s" % simulation_completion_message
	if simulation_tip_label != null:
		simulation_tip_label.text = "Use Next to continue the Module learning path."
	if simulation_feedback_label != null:
		var correct: int = int(simulation_manager_instance.correct_actions)
		var misses: int = int(simulation_manager_instance.incorrect_actions)
		var attempts: int = maxi(correct + misses, 1)
		var accuracy: float = (float(correct) / float(attempts)) * 100.0
		var line: String = "Accuracy %.0f%%  ·  %d correct  ·  %d misses" % [accuracy, correct, misses]
		if tip != "":
			line = "Correct — %s\n%s" % [tip, line]
		simulation_feedback_label.text = line
		simulation_feedback_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.7, 1))
	_update_simulation_progress_ui()
	for button_variant in simulation_buttons.values():
		var button: Button = button_variant as Button
		if button != null and is_instance_valid(button):
			button.disabled = true
	# Host completion events fire on the completion page (_emit_path_completed_once).


func _emit_path_completed_once() -> void:
	if _path_completion_emitted:
		return
	_path_completion_emitted = true
	if simulation_type == 1:
		_emit_host_event("assessment_completed")
	else:
		_emit_host_event("guided_completed")


func _emit_host_event(event_name: String) -> void:
	var host: Node = get_parent()
	while host != null and not host.has_method("send_event"):
		host = host.get_parent()
	if host != null:
		host.send_event(event_name, module_id)


func _sync_page_progress_to_host() -> void:
	var pages: Array = module_data.get("pages", [])
	if pages.is_empty():
		return
	var total: int = maxi(pages.size(), 1)
	# Cap at 99 — 100% only via guided_completed / assessment_completed.
	var pct: float = minf((float(current_page_index + 1) / float(total)) * 100.0, 99.0)
	var host: Node = get_parent()
	while host != null and not host.has_method("send_event"):
		host = host.get_parent()
	if host != null:
		host.send_event("progress_update", module_id, pct)


func _apply_answer_result_style(button: Button, is_correct: bool) -> void:
	var style := StyleBoxFlat.new()
	if is_correct:
		style.bg_color = Color(0.08, 0.32, 0.22, 0.95)
		style.border_color = Color(0.35, 0.95, 0.65, 0.85)
	else:
		style.bg_color = Color(0.32, 0.1, 0.12, 0.95)
		style.border_color = Color(1.0, 0.45, 0.45, 0.85)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 16
	style.content_margin_bottom = 12
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.95, 0.98, 1.0, 0.9))
	button.modulate = Color(1, 1, 1, 1)


func _on_model_card_pressed(item: Dictionary) -> void:
	_update_model_description(item)
	_load_model_into_viewer(item)


func _update_model_description(item: Dictionary) -> void:
	var source_text: String = item.get("source_label", "")
	var source_url: String = item.get("source_url", "")

	var copy := "[b]%s[/b]\n%s\n\n%s" % [
		item.get("title", ""),
		item.get("summary", ""),
		item.get("details", "")
	]

	if source_text != "":
		copy += "\n\n[i]Asset status:[/i] %s" % item.get("status", "placeholder")
		copy += "\n[i]Source:[/i] %s" % source_text

	if source_url != "":
		copy += "\n[i]Reference:[/i] %s" % source_url

	active_model_description.text = copy


func _load_model_into_viewer(item: Dictionary) -> void:
	if active_viewer_container != null:
		while active_viewer_container.get_child_count() > 0:
			var child: Node = active_viewer_container.get_child(0)
			active_viewer_container.remove_child(child)
			child.free()
	active_viewer_model = null

	var scene_path: String = _safe_model_path(str(item.get("scene_path", "")))
	if scene_path != "" and ResourceLoader.exists(scene_path):
		var scene: PackedScene = _packed(scene_path)
		if scene != null:
			active_viewer_model = scene.instantiate()
			var pid := str(item.get("part_id", ""))
			if active_viewer_model != null and pid != "" and "part_id" in active_viewer_model:
				active_viewer_model.part_id = pid
	else:
		active_viewer_model = _build_placeholder_model(item.get("title", "Placeholder"))

	active_viewer_container.add_child(active_viewer_model)
	call_deferred("_finish_viewer_model")


func _finish_viewer_model() -> void:
	if active_viewer_model == null or not is_instance_valid(active_viewer_model):
		return
	if active_viewer != null and active_viewer.has_method("frame_model"):
		active_viewer.frame_model()


func _build_placeholder_model(title_text: String) -> Node3D:
	var root := Node3D.new()

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.4, 0.08, 1.0)
	mesh_instance.mesh = mesh

	var surface_material := StandardMaterial3D.new()
	surface_material.albedo_color = Color(0.05, 0.28, 0.14, 1)
	mesh_instance.material_override = surface_material
	root.add_child(mesh_instance)

	root.name = "%sPlaceholder" % title_text.replace(" ", "")
	return root
