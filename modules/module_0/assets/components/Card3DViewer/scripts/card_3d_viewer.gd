extends Control

@onready var node_3d: Node3D = $SubViewportContainer/SubViewport/Node3D
@onready var button: Button = $Button
@onready var viewport_container: SubViewportContainer = $SubViewportContainer
@onready var subviewport: SubViewport = $SubViewportContainer/SubViewport

signal exit_viewer(value: bool)

var _interactive := true
var _hint_enabled := true
var _hint_label: Label = null


func setup(rotation_speed: float, zoom_speed: float, pan_speed: float) -> void:
	var world := _resolve_node_3d()
	if world == null:
		push_warning("Card3DViewer: Node3D missing; setup skipped.")
		return
	if world.has_method("setup"):
		world.setup(rotation_speed, zoom_speed, pan_speed)


func set_interactive(enabled: bool) -> void:
	_interactive = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if viewport_container != null:
		viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	var world := _resolve_node_3d()
	if world != null and world.has_method("set_interactive"):
		world.set_interactive(enabled)
	_update_hint_visibility()


func set_auto_rotate(enabled: bool) -> void:
	var world := _resolve_node_3d()
	if world != null and world.has_method("set_auto_rotate"):
		world.set_auto_rotate(enabled)


func _ready() -> void:
	if button != null:
		button.pressed.connect(_on_button_pressed)
	if viewport_container != null:
		viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
		if not viewport_container.gui_input.is_connected(_on_viewport_gui_input):
			viewport_container.gui_input.connect(_on_viewport_gui_input)
	_ensure_hint_label()
	call_deferred("_apply_performance")
	set_interactive(_interactive)
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)


func _on_resized() -> void:
	_apply_performance()


func _apply_performance() -> void:
	if subviewport == null:
		return
	if PerformanceProfile != null:
		PerformanceProfile.apply_to_subviewport(subviewport, self)
	else:
		var target := Vector2i(maxi(int(size.x), 160), maxi(int(size.y), 120))
		if target.x < 8 or target.y < 8:
			target = Vector2i(320, 240)
		subviewport.size = target


func _on_viewport_gui_input(event: InputEvent) -> void:
	if not _interactive:
		return
	var world := _resolve_node_3d()
	if world != null and world.has_method("handle_gui_input"):
		world.handle_gui_input(event)


func _on_button_pressed() -> void:
	exit_viewer.emit(true)
	var world := _resolve_node_3d()
	if world != null and world.has_method("reset"):
		world.reset()


func frame_model(view_hint: String = "") -> void:
	var world := _resolve_node_3d()
	if world == null:
		push_warning("Card3DViewer: Node3D missing; frame_model skipped.")
		return
	if world.has_method("setting_model"):
		world.setting_model(view_hint)
	_apply_performance()


func _ensure_hint_label() -> void:
	if _hint_label != null and is_instance_valid(_hint_label):
		return
	_hint_label = Label.new()
	_hint_label.name = "OrbitHint"
	_hint_label.text = "Drag to rotate"
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint_label.offset_top = -28
	_hint_label.offset_bottom = -6
	_hint_label.offset_left = 8
	_hint_label.offset_right = -8
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 11)
	_hint_label.add_theme_color_override("font_color", Color(0.75, 0.9, 0.98, 0.85))
	add_child(_hint_label)
	_update_hint_visibility()


## Lets a caller suppress the overlay on small cards that share one hint.
func set_hint_enabled(enabled: bool) -> void:
	_hint_enabled = enabled
	_update_hint_visibility()


func _update_hint_visibility() -> void:
	if _hint_label == null:
		return
	_hint_label.visible = _hint_enabled and _interactive and (button == null or not button.visible)


func _resolve_node_3d() -> Node3D:
	if node_3d != null and is_instance_valid(node_3d):
		return node_3d
	node_3d = get_node_or_null("SubViewportContainer/SubViewport/Node3D") as Node3D
	return node_3d
