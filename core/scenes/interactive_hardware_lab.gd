extends Control

signal model_selected(item: Dictionary)

@onready var viewport_container: SubViewportContainer = $Split/ViewerCard/ViewerMargin/ViewerStack/ViewportFrame/SubViewportContainer
@onready var subviewport: SubViewport = $Split/ViewerCard/ViewerMargin/ViewerStack/ViewportFrame/SubViewportContainer/SubViewport
@onready var world: Node3D = $Split/ViewerCard/ViewerMargin/ViewerStack/ViewportFrame/SubViewportContainer/SubViewport/World
@onready var pivot: Node3D = $Split/ViewerCard/ViewerMargin/ViewerStack/ViewportFrame/SubViewportContainer/SubViewport/World/Pivot
@onready var model_container: Node3D = $Split/ViewerCard/ViewerMargin/ViewerStack/ViewportFrame/SubViewportContainer/SubViewport/World/Pivot/ModelContainer
@onready var camera: Camera3D = $Split/ViewerCard/ViewerMargin/ViewerStack/ViewportFrame/SubViewportContainer/SubViewport/World/Camera
@onready var title_label: Label = $Split/ViewerCard/ViewerMargin/ViewerStack/TitleRow/TitleLabel
@onready var category_label: Label = $Split/ViewerCard/ViewerMargin/ViewerStack/TitleRow/CategoryBadge
@onready var fact_label: RichTextLabel = $Split/ViewerCard/ViewerMargin/ViewerStack/FactLabel
@onready var tip_label: Label = $Split/ViewerCard/ViewerMargin/ViewerStack/TipLabel
@onready var cards_box: VBoxContainer = $Split/LibraryCard/LibraryMargin/LibraryStack/Scroll/Cards
@onready var filter_box: HBoxContainer = $Split/LibraryCard/LibraryMargin/LibraryStack/Filters
@onready var spin_btn: Button = $Split/ViewerCard/ViewerMargin/ViewerStack/Actions/SpinButton
@onready var auto_btn: Button = $Split/ViewerCard/ViewerMargin/ViewerStack/Actions/AutoButton
@onready var reset_btn: Button = $Split/ViewerCard/ViewerMargin/ViewerStack/Actions/ResetButton

var items: Array = []
var filtered_items: Array = []
var current_item: Dictionary = {}
var current_model: Node3D = null
var current_filter: String = "All"
var auto_rotate := true
var is_dragging := false
var last_mouse := Vector2.ZERO
var card_buttons: Dictionary = {}
var _intro_tween: Tween = null
var _touch_dragging := false
var _last_touch := Vector2.ZERO
var _split: HBoxContainer = null


func setup(model_items: Array) -> void:
	items = model_items.duplicate(true)
	# Cards first — do NOT auto-load or prefetch 3D. Instant page entry on Android.
	_build_filters()
	_apply_filter("All")
	if title_label != null:
		title_label.text = "Pick a part"
	if category_label != null:
		category_label.text = "PARTS LAB"
	if fact_label != null:
		fact_label.text = "[b]Parts Lab[/b]\nTap any card to inspect a lightweight teaching model. Orbit with drag."
	if tip_label != null:
		tip_label.text = "Tap a part card to load its 3D model"


func _ready() -> void:
	# Must be container-sized when embedded in ModuleShell ScrollContainer.
	# Full-rect anchors collapse the gallery/viewport to zero height.
	_prepare_embedded_layout()
	_split = get_node_or_null("Split") as HBoxContainer
	if _split != null:
		_split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spin_btn.pressed.connect(_on_spin_pressed)
	auto_btn.pressed.connect(_on_auto_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
	viewport_container.gui_input.connect(_on_viewport_gui_input)
	_style_action_buttons()
	_style_viewport_frame()
	if subviewport != null:
		subviewport.own_world_3d = true
		# Solid backdrop so dark ceramic parts (CPU) stay readable.
		subviewport.transparent_bg = false
		_ensure_world_environment()
		_apply_viewport_quality()
	# Make sure card list fills the scroll width at 1280x720.
	if cards_box != null:
		cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var profile := get_node_or_null("/root/PerformanceProfile")
	if profile != null:
		auto_rotate_speed_scale()
	_apply_responsive_layout()
	if not resized.is_connected(_on_lab_resized):
		resized.connect(_on_lab_resized)
	modulate.a = 1.0
	visible = true


func _prepare_embedded_layout() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_END
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	if custom_minimum_size.y < 480.0:
		custom_minimum_size.y = 520.0
	var frame := get_node_or_null("Split/ViewerCard/ViewerMargin/ViewerStack/ViewportFrame") as Control
	if frame != null and frame.custom_minimum_size.y < 220.0:
		frame.custom_minimum_size.y = 260.0


func auto_rotate_speed_scale() -> void:
	# Consumed by _process via PerformanceProfile.auto_rotate_speed.
	pass


func _on_lab_resized() -> void:
	_apply_responsive_layout()
	_apply_viewport_quality()


func _apply_viewport_quality() -> void:
	if subviewport == null:
		return
	var profile := get_node_or_null("/root/PerformanceProfile")
	if profile != null and profile.has_method("apply_to_subviewport"):
		profile.call("apply_to_subviewport", subviewport, viewport_container)
	elif viewport_container != null and viewport_container.size.x > 8.0 and viewport_container.size.y > 8.0:
		subviewport.size = Vector2i(int(viewport_container.size.x), int(viewport_container.size.y))
	else:
		# Avoid a 0x0 render target while the lab is still laying out.
		subviewport.size = Vector2i(640, 360)


func _apply_responsive_layout() -> void:
	if _split == null:
		return
	var narrow: bool = size.x > 0.0 and size.x < 780.0
	var layout_node := get_node_or_null("/root/ResponsiveLayout")
	if layout_node != null and layout_node.has_method("is_phone"):
		narrow = bool(layout_node.call("is_phone")) or size.x < 780.0
	_split.add_theme_constant_override("separation", 10 if narrow else 18)
	var library := _split.get_node_or_null("LibraryCard") as Control
	var viewer := _split.get_node_or_null("ViewerCard") as Control
	if library == null or viewer == null:
		return
	library.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	library.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if narrow:
		# Viewer first on phones so the model is immediately interactive.
		if _split.get_child(0) != viewer:
			_split.move_child(viewer, 0)
		library.size_flags_stretch_ratio = 0.9
		viewer.size_flags_stretch_ratio = 1.2
		if tip_label != null:
			tip_label.text = "Drag to orbit  •  Pinch zoom  •  Spin for a turn"
	else:
		if _split.get_child(0) != library:
			_split.move_child(library, 0)
		library.size_flags_stretch_ratio = 0.72
		viewer.size_flags_stretch_ratio = 1.2
	if cards_box != null and size.x > 8.0:
		cards_box.custom_minimum_size.x = maxf(180.0, size.x * 0.28)


func _ensure_world_environment() -> void:
	if world == null:
		return
	if world.get_node_or_null("WorldEnvironment") != null:
		return
	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.07, 0.1, 1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.74, 0.8, 1)
	env.ambient_light_energy = 1.15
	env_node.environment = env
	world.add_child(env_node)


func _style_viewport_frame() -> void:
	var frame := $Split/ViewerCard/ViewerMargin/ViewerStack/ViewportFrame as PanelContainer
	if frame == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.08, 1)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	frame.add_theme_stylebox_override("panel", style)

func _process(delta: float) -> void:
	if auto_rotate and pivot != null:
		var speed := 0.85
		var profile := get_node_or_null("/root/PerformanceProfile")
		if profile != null and "auto_rotate_speed" in profile:
			speed = float(profile.get("auto_rotate_speed"))
		pivot.rotate_y(delta * speed)


func _build_filters() -> void:
	for child in filter_box.get_children():
		child.queue_free()

	var categories: Array[String] = ["All"]
	for item in items:
		var category: String = str(item.get("category", "Hardware"))
		if not categories.has(category):
			categories.append(category)

	for category in categories:
		var button := Button.new()
		button.text = category
		button.toggle_mode = true
		button.button_pressed = category == current_filter
		button.custom_minimum_size = Vector2(0, 36)
		_style_filter_button(button, category == current_filter)
		button.pressed.connect(_on_filter_pressed.bind(category))
		filter_box.add_child(button)


func _apply_filter(category: String) -> void:
	current_filter = category
	filtered_items.clear()
	for item in items:
		if category == "All" or str(item.get("category", "Hardware")) == category:
			filtered_items.append(item)
	_rebuild_cards()
	_build_filters()


func _rebuild_cards() -> void:
	for child in cards_box.get_children():
		child.queue_free()
	card_buttons.clear()

	for item in filtered_items:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 64)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = false
		var summary := str(item.get("summary", ""))
		if summary.length() > 64:
			summary = summary.substr(0, 61) + "..."
		button.text = "%s\n%s" % [item.get("title", ""), summary]
		_style_card_button(button, false)
		button.pressed.connect(select_item.bind(item))
		cards_box.add_child(button)
		card_buttons[item.get("title", "")] = button


func select_item(item: Dictionary) -> void:
	current_item = item
	title_label.text = str(item.get("title", "Component"))
	category_label.text = str(item.get("category", "Hardware")).to_upper()
	fact_label.text = "[b]Fun fact[/b]\n%s\n\n[b]Technician tip[/b]\n%s" % [
		item.get("fun_fact", item.get("details", "")),
		item.get("tip", "Handle carefully and follow ESD safety.")
	]
	if tip_label != null:
		tip_label.text = "Drag to orbit  •  Scroll / pinch to zoom  •  Spin for a closer look"
	_load_model(item)
	_highlight_selected_card(item.get("title", ""))
	model_selected.emit(item)
	if cards_box != null:
		var motion := get_node_or_null("/root/UiMotion")
		var btn = card_buttons.get(item.get("title", ""), null)
		if motion != null and btn != null and motion.has_method("pulse_button"):
			motion.call("pulse_button", btn)


func _clear_model_container() -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
		_intro_tween = null
	# Hard-clear every previous model so nothing can linger in the viewport.
	while model_container.get_child_count() > 0:
		var child: Node = model_container.get_child(0)
		model_container.remove_child(child)
		child.free()
	current_model = null


## Prefetch disabled — Parts Lab uses one shared procedural scene loaded on tap.
func _prefetch_all_model_paths() -> void:
	pass


func _load_model(item: Dictionary) -> void:
	_clear_model_container()

	var scene_path: String = item.get("scene_path", "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_warning("Failed to load model scene: %s" % scene_path)
		return

	# Procedural lab parts are tiny — sync load is fine and avoids thread races.
	var packed: PackedScene = null
	if str(item.get("part_id", "")) != "":
		packed = load(scene_path) as PackedScene
	else:
		var status := ResourceLoader.load_threaded_get_status(scene_path)
		if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_request(scene_path)
		_load_model_async(scene_path, item)
		return

	if packed == null:
		push_warning("Failed to load PackedScene: %s" % scene_path)
		return
	current_model = packed.instantiate()
	if current_model == null:
		return
	var pid := str(item.get("part_id", ""))
	if pid != "" and "part_id" in current_model:
		current_model.part_id = pid
	model_container.add_child(current_model)
	_finish_loaded_model()


func _load_model_async(scene_path: String, requested_item: Dictionary) -> void:
	# Poll until the threaded load finishes (or give up after ~15 s for large glTF).
	var deadline := Time.get_ticks_msec() + 15000
	while true:
		var status := ResourceLoader.load_threaded_get_status(scene_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED or Time.get_ticks_msec() > deadline:
			push_warning("Threaded load failed or timed out: %s" % scene_path)
			return
		await get_tree().process_frame
		# Bail if the user switched to another item while we were waiting.
		if current_item != requested_item:
			return
		if not is_instance_valid(self):
			return

	var packed := ResourceLoader.load_threaded_get(scene_path) as PackedScene
	if packed == null:
		push_warning("Threaded load returned null PackedScene: %s" % scene_path)
		return

	# Guard: user may have selected a different item while we waited.
	if current_item != requested_item or not is_instance_valid(self):
		return

	current_model = packed.instantiate()
	if current_model == null:
		return
	var pid := str(requested_item.get("part_id", ""))
	if pid != "" and "part_id" in current_model:
		current_model.part_id = pid

	model_container.add_child(current_model)
	_finish_loaded_model()


func _finish_loaded_model() -> void:
	if current_model == null or not is_instance_valid(current_model):
		return

	# Wait until MeshInstance3D nodes exist (imported glTF can lag a few frames).
	# Reduced from 12 → 4: on Android at 30 fps this is still ~130 ms, enough
	# for any glTF to surface its first mesh node after instantiation.
	for _i in 4:
		if _count_mesh_instances(current_model) > 0:
			break
		await get_tree().process_frame
		if current_model == null or not is_instance_valid(current_model):
			return

	# One extra frame so imported mesh transforms settle.
	await get_tree().process_frame
	if current_model == null or not is_instance_valid(current_model):
		return

	var mesh_count := _count_mesh_instances(current_model)
	var is_procedural := current_model.has_meta("sb_procedural")
	# Junk stripping is ONLY for the old motherboard socket/ground blockers.
	# Other Sketchfab assets (case, keyboard, …) often have 65k+ verts and must stay intact.
	var title := str(current_item.get("title", "")).to_lower()
	var is_motherboard := title.contains("motherboard")
	if not is_procedural and is_motherboard and mesh_count > 2:
		ModelGeometryCleanup.strip_placeholder_volumes(current_model)
		_purge_blocking_cubes(current_model)

	_ensure_meshes_visible(current_model)
	var play_intro := true
	var profile := get_node_or_null("/root/PerformanceProfile")
	if profile != null and "enable_model_intro" in profile:
		play_intro = bool(profile.get("enable_model_intro"))
	_reset_view_to_model(play_intro)
	_apply_viewport_quality()


func _count_mesh_instances(root: Node) -> int:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, meshes)
	return meshes.size()


func _ensure_meshes_visible(root: Node) -> void:
	# Procedural teaching meshes already have strong identity colors — do not wash them out.
	if root.has_meta("sb_procedural"):
		_force_visible_only(root)
		return
	_boost_imported_materials(root)


func _force_visible_only(root: Node) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		mi.visible = true
		mi.layers = 1
	for child in root.get_children():
		_force_visible_only(child)


func _boost_imported_materials(root: Node) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		mi.visible = true
		mi.layers = 1
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var source: Material = mi.get_active_material(0)
		if source == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			source = mi.mesh.surface_get_material(0)
		if source is BaseMaterial3D:
			var base := (source as BaseMaterial3D).duplicate() as BaseMaterial3D
			base.metallic = minf(base.metallic, 0.35)
			base.roughness = maxf(base.roughness, 0.35)
			var c := base.albedo_color
			# Pure-black Sketchfab metals (common on PC cases) vanish on a dark backdrop.
			if c.r < 0.04 and c.g < 0.04 and c.b < 0.04:
				base.albedo_color = Color(0.22, 0.23, 0.26, c.a)
				base.emission_enabled = true
				base.emission = Color(0.08, 0.09, 0.11)
				base.emission_energy_multiplier = 0.25
			else:
				var lum := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
				if lum < 0.18:
					var boost := 0.32 / maxf(lum, 0.05)
					base.albedo_color = Color(
						clampf(c.r * boost, 0.0, 1.0),
						clampf(c.g * boost, 0.0, 1.0),
						clampf(c.b * boost, 0.0, 1.0),
						c.a
					)
			mi.material_override = base
	for child in root.get_children():
		_boost_imported_materials(child)


## Centers + scales the model so it fills the viewer, then resets camera/pivot.
func _reset_view_to_model(play_intro: bool = false) -> void:
	if current_model == null or not is_instance_valid(current_model):
		return
	_frame_model()
	# Mild tilt — strong Y spin was pushing wide boards off a narrow aspect.
	pivot.rotation = Vector3(-0.35, 0.55, 0)
	var radius := _framed_radius()
	camera.current = true
	camera.fov = 40.0
	camera.position = Vector3(0, radius * 0.2, maxf(radius * 2.6, 2.4))
	camera.look_at(Vector3.ZERO, Vector3.UP)
	auto_rotate = true
	if auto_btn != null:
		auto_btn.text = "Auto: ON"
	if play_intro:
		_play_intro_motion()


func _framed_radius() -> float:
	if current_model == null:
		return 1.2
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(current_model, meshes)
	if meshes.is_empty():
		return 1.2
	var aabb := AABB()
	var first := true
	for mi in meshes:
		if not mi.is_visible_in_tree():
			continue
		var world_aabb: AABB = mi.global_transform * mi.get_aabb()
		if first:
			aabb = world_aabb
			first = false
		else:
			aabb = aabb.merge(world_aabb)
	if first:
		return 1.2
	return maxf(aabb.size.length() * 0.5, 0.6)


## Deletes the large white / cube blocker that sits on top of boards.
func _purge_blocking_cubes(root: Node) -> void:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, meshes)
	if meshes.is_empty():
		return

	# Find the flattest largest mesh = PCB.
	var board_aabb := AABB()
	var best_score := -1.0
	for mesh_instance in meshes:
		if not is_instance_valid(mesh_instance):
			continue
		var world_aabb: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		var area: float = world_aabb.size.x * world_aabb.size.z
		var thickness: float = maxf(world_aabb.size.y, 0.0001)
		var score: float = area / thickness
		if score > best_score:
			best_score = score
			board_aabb = world_aabb

	var board_span := maxf(board_aabb.size.x, board_aabb.size.z)
	var board_thickness := maxf(board_aabb.size.y, 0.02)
	var board_center := board_aabb.get_center()
	var to_delete: Array[Node] = []

	for mesh_instance in meshes:
		if not is_instance_valid(mesh_instance):
			continue
		var world_aabb: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		var size := world_aabb.size
		var longest := maxf(size.x, maxf(size.y, size.z))
		var shortest := minf(size.x, minf(size.y, size.z))
		if longest < 0.05:
			continue
		var cube_like := shortest > longest * 0.45
		var tall := size.y > board_thickness * 4.0 and size.y > board_span * 0.08
		var near_center := Vector2(
			world_aabb.get_center().x - board_center.x,
			world_aabb.get_center().z - board_center.z
		).length() < board_span * 0.4
		var bright := _is_bright_mesh(mesh_instance)
		if (cube_like and tall and near_center) or (bright and tall and near_center and cube_like):
			to_delete.append(mesh_instance)

	for node in to_delete:
		if is_instance_valid(node):
			node.visible = false
			node.free()


func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		_collect_meshes(child, out)


func _is_bright_mesh(mesh_instance: MeshInstance3D) -> bool:
	var mat := mesh_instance.material_override
	if mat is StandardMaterial3D:
		var color: Color = (mat as StandardMaterial3D).albedo_color
		return color.r > 0.8 and color.g > 0.8 and color.b > 0.8
	return false


func _frame_model() -> void:
	if current_model == null:
		return

	# Reset before measuring so AABB is in local unscaled space.
	current_model.position = Vector3.ZERO
	current_model.rotation = Vector3.ZERO
	current_model.scale = Vector3.ONE

	# Force update so global transforms are valid for AABB math.
	if current_model.is_inside_tree():
		current_model.force_update_transform()

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(current_model, meshes)
	if meshes.is_empty():
		push_warning("Hardware lab: no MeshInstance3D found to frame.")
		return

	var combined_aabb := AABB()
	var first_mesh := true
	for mesh_instance in meshes:
		if not mesh_instance.is_visible_in_tree():
			continue
		mesh_instance.force_update_transform()
		var mesh_aabb := mesh_instance.get_aabb()
		var local_xform := current_model.global_transform.affine_inverse() * mesh_instance.global_transform
		mesh_aabb = local_xform * mesh_aabb
		if first_mesh:
			combined_aabb = mesh_aabb
			first_mesh = false
		else:
			combined_aabb = combined_aabb.merge(mesh_aabb)

	if first_mesh:
		return

	var center := combined_aabb.get_center()
	var max_extent := maxf(combined_aabb.size.x, maxf(combined_aabb.size.y, combined_aabb.size.z))
	if max_extent < 0.0001:
		max_extent = combined_aabb.size.length()
	if max_extent < 0.0001:
		return

	# Fill ~2.6 units so boards/cases stay inside the 1280x720 viewer.
	var fit_scale := clampf(2.6 / max_extent, 0.001, 1000.0)
	current_model.scale = Vector3.ONE * fit_scale
	current_model.position = -center * fit_scale

	# Second pass: recenter using world AABB after scale (Sketchfab roots can drift).
	if current_model.is_inside_tree():
		current_model.force_update_transform()
	var world_aabb := AABB()
	var has_world := false
	for mesh_instance in meshes:
		if not is_instance_valid(mesh_instance) or not mesh_instance.is_visible_in_tree():
			continue
		mesh_instance.force_update_transform()
		var wa: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		if not has_world:
			world_aabb = wa
			has_world = true
		else:
			world_aabb = world_aabb.merge(wa)
	if has_world:
		current_model.global_position -= world_aabb.get_center()


func _on_reset_pressed() -> void:
	_reset_view_to_model(false)


func _play_intro_motion() -> void:
	if current_model == null:
		return
	var target_scale := current_model.scale
	var target_pos := current_model.position
	current_model.scale = target_scale * 0.05
	current_model.position = target_pos * 0.05
	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)
	_intro_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(current_model, "scale", target_scale, 0.4)
	_intro_tween.tween_property(current_model, "position", target_pos, 0.4)


func _highlight_selected_card(title: String) -> void:
	for key in card_buttons.keys():
		var button: Button = card_buttons[key]
		_style_card_button(button, key == title)


func _on_filter_pressed(category: String) -> void:
	_apply_filter(category)
	if not filtered_items.is_empty():
		select_item(filtered_items[0])


func _on_spin_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(pivot, "rotation:y", pivot.rotation.y + TAU, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_auto_pressed() -> void:
	auto_rotate = not auto_rotate
	auto_btn.text = "Auto: ON" if auto_rotate else "Auto: OFF"


func _on_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			last_mouse = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.z = clampf(camera.position.z - 0.25, 0.5, 14.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.z = clampf(camera.position.z + 0.25, 0.5, 14.0)
	elif event is InputEventMouseMotion and is_dragging:
		_orbit_by_delta(event.position - last_mouse)
		last_mouse = event.position
	elif event is InputEventScreenTouch:
		_touch_dragging = event.pressed
		_last_touch = event.position
		if event.pressed:
			auto_rotate = false
			if auto_btn != null:
				auto_btn.text = "Auto: OFF"
	elif event is InputEventScreenDrag and _touch_dragging:
		_orbit_by_delta(event.relative)
		_last_touch = event.position


func _orbit_by_delta(delta: Vector2) -> void:
	auto_rotate = false
	if auto_btn != null:
		auto_btn.text = "Auto: OFF"
	pivot.rotate_y(-delta.x * 0.01)
	pivot.rotate_x(-delta.y * 0.01)
	pivot.rotation.x = clampf(pivot.rotation.x, -1.1, 0.45)

func _style_action_buttons() -> void:
	for button in [spin_btn, auto_btn, reset_btn]:
		_style_chip_button(button)


func _style_chip_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.003921569, 0.09019608, 0.13725491, 0.92)
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_left = 14
	normal.corner_radius_bottom_right = 14
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.09, 0.65, 0.87, 0.4)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.011764706, 0.16862746, 0.23921569, 0.95)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 0.99, 1))


func _style_filter_button(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.65, 0.87, 0.28) if selected else Color(0.003921569, 0.09019608, 0.13725491, 0.8)
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 0.99, 1))


func _style_card_button(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.65, 0.87, 0.32) if selected else Color(0.02, 0.1, 0.16, 0.95)
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_left = 14
	normal.corner_radius_bottom_right = 14
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.35, 0.82, 0.95, 0.7) if selected else Color(0.95, 0.98, 0.99, 0.1)

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.08, 0.28, 0.38, 0.95)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_font_size_override("font_size", 13)
	var font_col := Color(0.96, 0.98, 1.0, 1.0)
	button.add_theme_color_override("font_color", font_col)
	button.add_theme_color_override("font_hover_color", font_col)
	button.add_theme_color_override("font_pressed_color", font_col)
	button.add_theme_color_override("font_focus_color", font_col)
	button.add_theme_color_override("font_disabled_color", Color(0.96, 0.98, 1.0, 0.55))
