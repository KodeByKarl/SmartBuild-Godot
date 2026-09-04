extends Area3D

## Visual socket marker for PC build simulation.

@export var slot_id: String = ""
@export var label_text: String = ""

var _mesh: MeshInstance3D
var _label: Label3D
var _mat: StandardMaterial3D
var _occupied := false
var _highlighted := false
var _slot_size: Vector3 = Vector3(0.35, 0.04, 0.25)
var _pulse_tween: Tween = null


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 2
	collision_mask = 0
	_ensure_visuals()
	_refresh_look()


func setup(id: String, title: String, size: Vector3 = Vector3(0.35, 0.04, 0.25)) -> void:
	slot_id = id
	label_text = title
	_slot_size = size
	_ensure_visuals()
	if _mesh != null and _mesh.mesh is BoxMesh:
		(_mesh.mesh as BoxMesh).size = size
	var shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape != null and shape.shape is BoxShape3D:
		(shape.shape as BoxShape3D).size = size + Vector3(0.04, 0.1, 0.04)
	if _label != null:
		_label.text = title
		_label.position = Vector3(0, size.y * 0.5 + 0.06, 0)
		_label.font_size = 28
		_label.pixel_size = 0.0045
		_label.outline_size = 8
	_refresh_look()


func set_highlighted(on: bool) -> void:
	_highlighted = on
	_refresh_look()
	if on and not _occupied:
		_start_pulse()
	else:
		_stop_pulse()


func set_occupied(on: bool) -> void:
	_occupied = on
	_stop_pulse()
	_refresh_look()


func is_occupied() -> bool:
	return _occupied


func _start_pulse() -> void:
	_stop_pulse()
	if _mesh == null:
		return
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(_mesh, "scale", Vector3(1.08, 1.2, 1.08), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(_mesh, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	if _mesh != null:
		_mesh.scale = Vector3.ONE


func _ensure_visuals() -> void:
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.name = "Mesh"
		var box := BoxMesh.new()
		box.size = _slot_size
		_mesh.mesh = box
		_mat = StandardMaterial3D.new()
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.albedo_color = Color(0.15, 0.55, 0.75, 0.35)
		_mat.emission_enabled = true
		_mat.emission = Color(0.1, 0.45, 0.65)
		_mat.emission_energy_multiplier = 0.4
		_mesh.material_override = _mat
		add_child(_mesh)
	if get_node_or_null("CollisionShape3D") == null:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = _slot_size + Vector3(0.04, 0.1, 0.04)
		col.shape = shape
		add_child(col)
	if _label == null:
		_label = Label3D.new()
		_label.name = "Label"
		_label.text = label_text
		_label.font_size = 28
		_label.pixel_size = 0.0045
		_label.outline_size = 8
		_label.modulate = Color(0.92, 0.97, 1.0, 0.95)
		_label.position = Vector3(0, 0.1, 0)
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label.visible = false
		add_child(_label)


func _refresh_look() -> void:
	if _mat == null:
		return
	if _label != null:
		_label.visible = _highlighted and not _occupied
		if _highlighted:
			_label.modulate = Color(1.0, 0.92, 0.35, 1.0)
		else:
			_label.modulate = Color(0.9, 0.95, 1.0, 0.9)
	if _occupied:
		_mat.albedo_color = Color(0.12, 0.55, 0.28, 0.5)
		_mat.emission = Color(0.15, 0.7, 0.35)
		_mat.emission_energy_multiplier = 0.55
		if _mesh != null:
			_mesh.visible = false
	elif _highlighted:
		_mat.albedo_color = Color(0.95, 0.75, 0.15, 0.65)
		_mat.emission = Color(1.0, 0.8, 0.2)
		_mat.emission_energy_multiplier = 1.35
		if _mesh != null:
			_mesh.visible = true
	else:
		_mat.albedo_color = Color(0.18, 0.5, 0.7, 0.32)
		_mat.emission = Color(0.12, 0.42, 0.6)
		_mat.emission_energy_multiplier = 0.4
		if _mesh != null:
			_mesh.visible = true
