extends Control

@onready var card_3d_viewer: Control = $MarginContainer/Card3dViewer
@onready var card_3d_viewer_node_3d: Node3D = $MarginContainer/Card3dViewer/SubViewportContainer/SubViewport/Node3D
@onready var card_3d_viewer_model_pivot: Node3D = $MarginContainer/Card3dViewer/SubViewportContainer/SubViewport/Node3D/ModelPivot/ModelContainer

@onready var panel_container: Panel = $MarginContainer/PanelContainer

@onready var super_computer_card: Button = $MarginContainer/PanelContainer/MarginContainer/HBoxContainer/HBoxContainer/VBoxContainer/Button
@onready var mini_computer_card: Button = $MarginContainer/PanelContainer/MarginContainer/HBoxContainer/HBoxContainer/VBoxContainer/Button2
@onready var mainframe_card: Button = $MarginContainer/PanelContainer/MarginContainer/HBoxContainer/HBoxContainer/VBoxContainer2/Button2
@onready var micro_computer_card: Button = $MarginContainer/PanelContainer/MarginContainer/HBoxContainer/HBoxContainer/VBoxContainer2/Button

var current_model: Node3D = null
var _model_cache: Dictionary = {}
var curr_micro_computer_model := 0
const SUPER_COMPUTER_PATH := "res://assets/models/shared/super_computer/scene.gltf"
const MINI_COMPUTER_PATH := "res://assets/models/shared/mini_computer/mini_computer.glb"
const MAINFRAME_PATH := "res://assets/models/module_3/mainframe/scene.gltf"
const MICRO_COMPUTER_PATHS: PackedStringArray = [
	"res://assets/models/module_1/laptop/scene.gltf",
	"res://assets/models/shared/ipad/scene.gltf",
]

func _ready() -> void:
	if ResourceWarmup != null and ResourceWarmup.has_method("prefetch_many"):
		var paths: PackedStringArray = [
			SUPER_COMPUTER_PATH,
			MINI_COMPUTER_PATH,
			MAINFRAME_PATH,
		]
		paths.append_array(MICRO_COMPUTER_PATHS)
		ResourceWarmup.prefetch_many(paths)
	card_3d_viewer.visible = false
	panel_container.visible = true

	card_3d_viewer.exit_viewer.connect(_on_data_from_card_3d_viewer)
	if card_3d_viewer.has_method("set_interactive"):
		card_3d_viewer.set_interactive(true)
	if card_3d_viewer.has_method("setup"):
		card_3d_viewer.setup(0.01, 0.2, 0.04)

	super_computer_card.pressed.connect(_on_super_computer_card_pressed)
	mini_computer_card.pressed.connect(_on_mini_computer_card_pressed)
	mainframe_card.pressed.connect(_on_mainframe_card_pressed)
	micro_computer_card.pressed.connect(_on_micro_computer_card_pressed)
	if OS.get_name() != "Android":
		UiMotion.play_enter(self)

func _on_data_from_card_3d_viewer(value):
	print("Data from Card 3D Viewer: ", value)
	if value:
		card_3d_viewer.visible = false
		panel_container.visible = true
		print("Current Model: ", current_model.to_string())
		if current_model != null:
			current_model.queue_free()
			current_model = null
		print("Current Model: ", current_model)

func _on_super_computer_card_pressed():
	_set_3d_model(0)

func _on_mini_computer_card_pressed():
	_set_3d_model(1)

func _on_mainframe_card_pressed():
	_set_3d_model(2)

func _on_micro_computer_card_pressed():
	_set_3d_model(3)

func _set_3d_model1(card: int):
	card_3d_viewer.visible = true
	panel_container.visible = false

func _packed_model(path: String) -> PackedScene:
	if _model_cache.has(path):
		return _model_cache[path] as PackedScene
	if ResourceWarmup != null and ResourceWarmup.has_method("get_packed"):
		var warmed: PackedScene = ResourceWarmup.get_packed(path)
		if warmed != null:
			_model_cache[path] = warmed
			return warmed
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return null
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res: Resource = ResourceLoader.load_threaded_get(path)
		if res is PackedScene:
			_model_cache[path] = res
			return res as PackedScene
	var packed := load(path) as PackedScene
	if packed != null:
		_model_cache[path] = packed
	else:
		push_error("slide_12 failed to load model: %s" % path)
	return packed


func _path_for_card(card: int) -> String:
	match card:
		0:
			return SUPER_COMPUTER_PATH
		1:
			return MINI_COMPUTER_PATH
		2:
			return MAINFRAME_PATH
		3:
			var path := MICRO_COMPUTER_PATHS[curr_micro_computer_model]
			curr_micro_computer_model += 1
			if curr_micro_computer_model >= MICRO_COMPUTER_PATHS.size():
				curr_micro_computer_model = 0
			return path
	return ""


func _apply_card_framing(card: int) -> void:
	if card_3d_viewer_node_3d == null:
		return
	if card == 0 or card == 1:
		card_3d_viewer_node_3d.setup(0.001, 0.2, 0.2)
	else:
		card_3d_viewer_node_3d.setup(0.0005, 0.01, 0.01)


func _show_model(packed: PackedScene, card: int) -> void:
	if packed == null:
		return
	if current_model != null and is_instance_valid(current_model):
		current_model.queue_free()
		current_model = null
	current_model = packed.instantiate()
	card_3d_viewer_model_pivot.add_child(current_model)
	_apply_card_framing(card)
	card_3d_viewer_node_3d.setting_model()
	if card_3d_viewer.has_method("set_interactive"):
		card_3d_viewer.set_interactive(true)
	card_3d_viewer.visible = true
	panel_container.visible = false
	if OS.get_name() != "Android":
		UiMotion.play_enter(card_3d_viewer)


func _set_3d_model_when_ready(card: int, path: String) -> void:
	if path == "" or ResourceWarmup == null or not ResourceWarmup.has_method("await_packed"):
		return
	card_3d_viewer.visible = true
	panel_container.visible = false
	var packed: PackedScene = await ResourceWarmup.await_packed(path, 12000)
	if packed == null or not is_instance_valid(self):
		return
	_model_cache[path] = packed
	_show_model(packed, card)


func _set_3d_model(card: int):
	var path := _path_for_card(card)
	var packed := _packed_model(path)
	if packed == null:
		_set_3d_model_when_ready(card, path)
		return
	_show_model(packed, card)
