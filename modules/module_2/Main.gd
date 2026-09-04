extends Control

@export var module_id: int = 2

const MODULE_SHELL := preload("res://core/scenes/ModuleShell.tscn")

var simulation_type: int = 0
var progress: float = 0.0
var shell: Control = null


func configure(new_module_id: int, new_simulation_type: int = 0, new_progress: float = 0.0) -> void:
	module_id = new_module_id
	simulation_type = new_simulation_type
	progress = new_progress
	if shell != null and shell.has_method("configure"):
		shell.configure(module_id, simulation_type, progress)


func _ready() -> void:
	shell = MODULE_SHELL.instantiate()
	add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.offset_left = 0.0
	shell.offset_top = 0.0
	shell.offset_right = 0.0
	shell.offset_bottom = 0.0
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vp_size := get_viewport().get_visible_rect().size
	if vp_size.x > 1.0 and vp_size.y > 1.0:
		shell.size = vp_size
	if shell.has_method("configure"):
		shell.configure(module_id, simulation_type, progress)
