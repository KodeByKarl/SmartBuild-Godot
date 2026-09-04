extends Node3D

@onready var model_pivot: Node3D = $ModelPivot
@onready var model_container: Node3D = $ModelPivot/ModelContainer
@onready var camera: Camera3D = $Camera3D

var rotation_speed := 0.008
var zoom_speed := 0.2
var pan_speed := 0.002

var touches: Dictionary = {}
var previous_finger_1 := Vector2.ZERO
var previous_finger_2 := Vector2.ZERO
var previous_center := Vector2.ZERO

var is_rotating := false
var is_panning := false
var interactive := true
var auto_rotate := true
var auto_rotate_speed := 0.55

var last_mouse_position := Vector2.ZERO
var _view_hint := ""
var _base_pivot_rotation := Vector3.ZERO


func setup(rs: float, zs: float, ps: float) -> void:
	# Keep a usable floor so tiny legacy callers still feel responsive.
	rotation_speed = maxf(rs, 0.004)
	zoom_speed = zs
	pan_speed = maxf(ps, 0.001)


func set_interactive(enabled: bool) -> void:
	interactive = enabled
	set_process(enabled and auto_rotate)


func set_auto_rotate(enabled: bool) -> void:
	auto_rotate = enabled
	set_process(interactive and auto_rotate)


func _ready() -> void:
	_ensure_preview_lighting()
	setting_model()
	# Orbit is driven by SubViewportContainer.gui_input (card_3d_viewer.gd)
	# so quiz/page buttons are never stolen by global input.
	set_process_input(false)
	set_process_unhandled_input(false)
	if PerformanceProfile != null:
		auto_rotate_speed = PerformanceProfile.auto_rotate_speed * 0.65
	set_process(interactive and auto_rotate)


func _process(delta: float) -> void:
	if not interactive or not auto_rotate or model_pivot == null:
		return
	model_pivot.rotate_y(delta * auto_rotate_speed)


func handle_gui_input(event: InputEvent) -> void:
	if not interactive:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_rotating = event.pressed
			last_mouse_position = event.position
			if event.pressed:
				auto_rotate = false
				set_process(false)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
			last_mouse_position = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.z = clampf(camera.position.z - zoom_speed, 0.6, 12.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.z = clampf(camera.position.z + zoom_speed, 0.6, 12.0)

	elif event is InputEventMouseMotion:
		var delta: Vector2 = event.position - last_mouse_position
		last_mouse_position = event.position
		if is_rotating:
			model_pivot.rotate_y(-delta.x * rotation_speed)
			model_pivot.rotate_x(-delta.y * rotation_speed)
			model_pivot.rotation.x = clampf(model_pivot.rotation.x, -1.2, 0.55)
		elif is_panning:
			camera.position.x -= delta.x * pan_speed
			camera.position.y += delta.y * pan_speed

	elif event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
			auto_rotate = false
			set_process(false)
			if touches.size() == 2:
				previous_finger_1 = touches.values()[0]
				previous_finger_2 = touches.values()[1]
				previous_center = (previous_finger_1 + previous_finger_2) / 2.0
		else:
			touches.erase(event.index)
			if touches.size() < 2:
				previous_finger_1 = Vector2.ZERO
				previous_finger_2 = Vector2.ZERO
				previous_center = Vector2.ZERO

	elif event is InputEventScreenDrag:
		touches[event.index] = event.position
		if touches.size() == 1:
			model_pivot.rotation.x -= event.relative.y * rotation_speed
			model_pivot.rotation.y -= event.relative.x * rotation_speed
			model_pivot.rotation.x = clampf(model_pivot.rotation.x, -1.2, 0.55)
		elif touches.size() == 2:
			var positions: Array = touches.values()
			var finger_1: Vector2 = positions[0] as Vector2
			var finger_2: Vector2 = positions[1] as Vector2
			var curr_distance := finger_1.distance_to(finger_2)
			var previous_distance := previous_finger_1.distance_to(previous_finger_2)
			var distance_change := curr_distance - previous_distance
			camera.position.z = clampf(camera.position.z - distance_change * zoom_speed * 0.02, 0.6, 12.0)
			var curr_center := (finger_1 + finger_2) / 2.0
			var curr_movement := curr_center - previous_center
			model_pivot.position.x += curr_movement.x * pan_speed
			model_pivot.position.y -= curr_movement.y * pan_speed
			previous_finger_1 = finger_1
			previous_finger_2 = finger_2
			previous_center = curr_center


func reset() -> void:
	model_pivot.position = Vector3.ZERO
	model_pivot.rotation = _base_pivot_rotation
	_view_hint = ""
	auto_rotate = true
	set_process(interactive and auto_rotate)


func setting_model(view_hint: String = "") -> void:
	if view_hint != "":
		_view_hint = view_hint
	_ensure_preview_lighting()

	var meshes: Array = model_container.find_children(
		"*",
		"MeshInstance3D",
		true,
		false
	)

	if meshes.is_empty():
		return

	var combined_aabb := AABB()
	var first_mesh := true

	for mesh: Variant in meshes:
		var mesh_instance: MeshInstance3D = mesh as MeshInstance3D
		if mesh_instance == null or not mesh_instance.is_visible_in_tree():
			continue
		var mesh_aabb: AABB = mesh_instance.get_aabb()
		var local_xform: Transform3D = (
			model_container.global_transform.affine_inverse()
			* mesh_instance.global_transform
		)
		mesh_aabb = local_xform * mesh_aabb
		if first_mesh:
			combined_aabb = mesh_aabb
			first_mesh = false
		else:
			combined_aabb = combined_aabb.merge(mesh_aabb)

	if first_mesh:
		return

	var center := combined_aabb.get_center()
	var size := combined_aabb.size
	var max_extent := maxf(size.x, maxf(size.y, size.z))
	if max_extent < 0.0001:
		max_extent = combined_aabb.size.length()
	if max_extent < 0.0001:
		return

	# Fill the small inline preview cards (~150x104) with a little padding.
	var fit_scale := clampf(1.85 / max_extent, 0.001, 120.0)

	for child in model_container.get_children():
		if child is Node3D:
			var node := child as Node3D
			node.scale = Vector3.ONE * fit_scale
			node.position = (-center * fit_scale)

	# Second pass recenter after scale (Sketchfab roots often drift).
	if model_container.is_inside_tree():
		model_container.force_update_transform()
	var world_aabb := AABB()
	var has_world := false
	for mesh: Variant in meshes:
		var mesh_instance: MeshInstance3D = mesh as MeshInstance3D
		if mesh_instance == null or not is_instance_valid(mesh_instance) or not mesh_instance.is_visible_in_tree():
			continue
		mesh_instance.force_update_transform()
		var wa: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		if not has_world:
			world_aabb = wa
			has_world = true
		else:
			world_aabb = world_aabb.merge(wa)
	if has_world:
		var world_center := world_aabb.get_center()
		for child in model_container.get_children():
			if child is Node3D:
				(child as Node3D).global_position -= world_center

	model_pivot.position = Vector3.ZERO
	_apply_preview_view(size)
	_base_pivot_rotation = model_pivot.rotation
	camera.current = true
	camera.visible = true


func _apply_preview_view(local_size: Vector3) -> void:
	var hint := _view_hint.to_lower()
	var sx := maxf(local_size.x, 0.0001)
	var sy := maxf(local_size.y, 0.0001)
	var sz := maxf(local_size.z, 0.0001)
	var is_flat := sy < sx * 0.38 and sy < sz * 0.38
	var is_long := maxf(sx, maxf(sy, sz)) > 2.2 * minf(sx, minf(sy, sz))

	if hint.contains("anti-static") or hint.contains("antistatic") or is_flat:
		# High 3/4 so the ESD mat face (and strap/cord) read clearly — not edge-on.
		model_pivot.rotation = Vector3(deg_to_rad(-62), deg_to_rad(38), 0)
		camera.position = Vector3(0, 1.55, 2.35)
		camera.fov = 38.0
	elif hint.contains("modem"):
		# Boxy CPE — pull back so the whole shell + front panel read, not a corner close-up.
		model_pivot.rotation = Vector3(deg_to_rad(-22), deg_to_rad(32), 0)
		camera.position = Vector3(0, 0.75, 3.15)
		camera.fov = 42.0
	elif hint.contains("router") or hint.contains("switch") or hint.contains("access point"):
		model_pivot.rotation = Vector3(deg_to_rad(-24), deg_to_rad(38), 0)
		camera.position = Vector3(0, 0.7, 2.95)
		camera.fov = 40.0
	elif hint.contains("ethernet") or hint.contains("cable") or hint.contains("screwdriver") or is_long:
		# Lay long tools/cables across the frame so the handle/shaft are readable.
		model_pivot.rotation = Vector3(deg_to_rad(-18), deg_to_rad(105), deg_to_rad(12))
		camera.position = Vector3(0, 0.55, 2.55)
		camera.fov = 36.0
	else:
		model_pivot.rotation = Vector3(deg_to_rad(-28), deg_to_rad(42), 0)
		camera.position = Vector3(0, 0.55, 2.45)
		camera.fov = 40.0

	camera.look_at(Vector3.ZERO, Vector3.UP)


func _ensure_preview_lighting() -> void:
	if get_node_or_null("WorldEnvironment") == null:
		var env_node := WorldEnvironment.new()
		env_node.name = "WorldEnvironment"
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.02, 0.06, 0.09, 1)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.72, 0.76, 0.82, 1)
		env.ambient_light_energy = 1.2
		env_node.environment = env
		add_child(env_node)

	if get_node_or_null("KeyLight") == null:
		var key := DirectionalLight3D.new()
		key.name = "KeyLight"
		key.light_energy = 1.35
		key.shadow_enabled = false
		key.rotation_degrees = Vector3(-48, 35, 0)
		add_child(key)

	if get_node_or_null("FillLight") == null:
		var fill := OmniLight3D.new()
		fill.name = "FillLight"
		fill.light_energy = 0.85
		fill.omni_range = 12.0
		fill.position = Vector3(-2.2, 2.0, 2.4)
		add_child(fill)

	if get_node_or_null("RimLight") == null:
		var rim := OmniLight3D.new()
		rim.name = "RimLight"
		rim.light_energy = 0.55
		rim.omni_range = 10.0
		rim.light_color = Color(0.55, 0.75, 1.0)
		rim.position = Vector3(2.0, 1.2, -1.8)
		add_child(rim)
