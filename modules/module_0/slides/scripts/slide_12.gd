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
var super_computer_model := preload("res://assets/models/super_computer/scene.gltf")
var mini_computer_model := preload("res://assets/models/mini_computer/mini_computer.glb")
var mainframe_model := preload("res://assets/models/main_frame_computer/scene.gltf")
var curr_micro_computer_model := 0
var micro_computer_models = [
	preload("res://assets/models/laptop/macbrookpro/macbookpro.tscn"),
	preload("res://assets/models/ipad/scene.gltf"),
]

func _ready() -> void:
	#var scm := super_computer_model.instantiate()
	#card_3d_viewer_model_pivot.add_child(scm)
	
	card_3d_viewer.visible = false
	panel_container.visible = true
	
	card_3d_viewer.exit_viewer.connect(_on_data_from_card_3d_viewer)
	
	super_computer_card.pressed.connect(_on_super_computer_card_pressed)
	mini_computer_card.pressed.connect(_on_mini_computer_card_pressed)
	mainframe_card.pressed.connect(_on_mainframe_card_pressed)
	micro_computer_card.pressed.connect(_on_micro_computer_card_pressed)

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

func _set_3d_model(card: int):
	match card:
		0:
			print("Super Computer")
			current_model = super_computer_model.instantiate()
			card_3d_viewer_node_3d.setup(0.001, 0.2, 0.2)
		1:
			print("Mini Computer")
			current_model = mini_computer_model.instantiate()
			card_3d_viewer_node_3d.setup(0.001, 0.2, 0.2)
		2:
			print("Mainframe")
			current_model = mainframe_model.instantiate()
			card_3d_viewer_node_3d.setup(0.0005, 0.01, 0.01)
		3:
			print("Micro Computer")
			current_model = micro_computer_models[curr_micro_computer_model].instantiate()
			card_3d_viewer_node_3d.setup(0.0005, 0.01, 0.01)
			curr_micro_computer_model += 1
			if micro_computer_models.size() == curr_micro_computer_model:
				curr_micro_computer_model = 0
	
	card_3d_viewer_model_pivot.add_child(current_model)
	card_3d_viewer_node_3d.setting_model()
	card_3d_viewer.visible = true
	panel_container.visible = false
