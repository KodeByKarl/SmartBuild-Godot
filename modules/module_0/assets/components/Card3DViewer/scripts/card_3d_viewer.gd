extends Control

@onready var node_3d: Node3D = $SubViewportContainer/SubViewport/Node3D
@onready var button: Button = $Button

signal exit_viewer(value: bool)

func setup(rotation_speed: float, zoom_speed: float, pan_speed: float):
	node_3d.setup(rotation_speed, zoom_speed, pan_speed)

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	exit_viewer.emit(true)
	node_3d.reset()

func frame_model():
	node_3d.setting_model()
