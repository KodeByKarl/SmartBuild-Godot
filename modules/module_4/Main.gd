extends Control

## Module 4 boots in Real PC Mode: the simulation opens in a dedicated OS window
## (desktop/editor). Android / headless / Compose-hosted runs stay embedded.

@export var module_id: int = 4

const MODULE_SHELL := preload("res://core/scenes/ModuleShell.tscn")
const REAL_PC_TITLE := "SmartBuild — Real PC Mode · Module 4"
const WINDOW_SIZE := Vector2i(1280, 720)
const WINDOW_MIN := Vector2i(1024, 600)

var simulation_type: int = 0
var progress: float = 0.0
var shell: Control = null

var _pc_window: Window = null
var _dock_status: Label = null
var _focus_btn: Button = null
var _real_pc_mode: bool = false


func configure(new_module_id: int, new_simulation_type: int = 0, new_progress: float = 0.0) -> void:
	module_id = new_module_id
	simulation_type = new_simulation_type
	progress = new_progress
	if shell != null and shell.has_method("configure"):
		shell.configure(module_id, simulation_type, progress)


func _ready() -> void:
	_real_pc_mode = _supports_real_pc_window()
	shell = MODULE_SHELL.instantiate()
	if _real_pc_mode:
		_build_host_dock()
		_open_real_pc_window()
	else:
		_embed_shell_here()
	if shell.has_method("configure"):
		shell.configure(module_id, simulation_type, progress)


func _exit_tree() -> void:
	_teardown_pc_window()


func _supports_real_pc_window() -> bool:
	# Separate OS windows are for desktop editor / standalone Godot only.
	if DisplayServer.get_name() == "headless":
		return false
	if OS.has_feature("android") or OS.has_feature("ios"):
		return false
	if Engine.has_singleton("SmartBuildBridge"):
		return false
	return true


func _embed_shell_here() -> void:
	add_child(shell)
	_fit_full_rect(shell)
	var vp_size := get_viewport().get_visible_rect().size
	if vp_size.x > 1.0 and vp_size.y > 1.0:
		shell.size = vp_size


func _open_real_pc_window() -> void:
	if _pc_window != null and is_instance_valid(_pc_window):
		_pc_window.show()
		_pc_window.grab_focus()
		_set_dock_status("Real PC window is open — work inside that window.")
		return

	_pc_window = Window.new()
	_pc_window.name = "RealPcWindow"
	_pc_window.title = REAL_PC_TITLE
	_pc_window.size = WINDOW_SIZE
	_pc_window.min_size = WINDOW_MIN
	_pc_window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	_pc_window.unresizable = false
	_pc_window.always_on_top = false
	_pc_window.transient = false
	_pc_window.exclusive = false
	_pc_window.close_requested.connect(_on_pc_window_close_requested)
	add_child(_pc_window)

	# Window is its own viewport — shell fills it like a real workstation screen.
	if shell.get_parent() != null:
		shell.get_parent().remove_child(shell)
	_pc_window.add_child(shell)
	_fit_full_rect(shell)
	shell.size = Vector2(WINDOW_SIZE)

	_pc_window.visible = true
	_pc_window.popup_centered(WINDOW_SIZE)
	_pc_window.grab_focus()
	_set_dock_status("Real PC Mode: Module 4 is running in a new window.")
	if _focus_btn != null:
		_focus_btn.text = "Focus Real PC Window"


func _on_pc_window_close_requested() -> void:
	# Hide instead of freeing — student can reopen from the host dock.
	if _pc_window != null and is_instance_valid(_pc_window):
		_pc_window.hide()
	_set_dock_status("Real PC window closed. Tap “Open Real PC Window” to continue the simulation.")
	if _focus_btn != null:
		_focus_btn.text = "Open Real PC Window"


func _teardown_pc_window() -> void:
	if shell != null and is_instance_valid(shell) and _pc_window != null and is_instance_valid(_pc_window):
		if shell.get_parent() == _pc_window:
			_pc_window.remove_child(shell)
	if _pc_window != null and is_instance_valid(_pc_window):
		_pc_window.queue_free()
		_pc_window = null


func _build_host_dock() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.09, 0.14)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(440, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.14, 0.22, 0.96)
	style.border_color = Color(0.35, 0.75, 0.95, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)

	var title := Label.new()
	title.text = "Module 4 · Real PC Mode"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	col.add_child(title)

	var blurb := Label.new()
	blurb.text = "The service PC opens in a separate window so the Windows desktop simulation feels like a real workstation."
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.add_theme_font_size_override("font_size", 13)
	blurb.add_theme_color_override("font_color", Color(0.78, 0.9, 0.98))
	col.add_child(blurb)

	_dock_status = Label.new()
	_dock_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock_status.add_theme_font_size_override("font_size", 12)
	_dock_status.add_theme_color_override("font_color", Color(0.7, 0.88, 0.78))
	col.add_child(_dock_status)

	_focus_btn = Button.new()
	_focus_btn.text = "Focus Real PC Window"
	_focus_btn.focus_mode = Control.FOCUS_NONE
	_focus_btn.custom_minimum_size = Vector2(0, 42)
	_focus_btn.pressed.connect(_open_real_pc_window)
	_style_primary(_focus_btn)
	col.add_child(_focus_btn)

	var hint := Label.new()
	hint.text = "Use Exit inside the Real PC window (module nav) to leave the simulation."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.55, 0.72, 0.85))
	col.add_child(hint)


func _set_dock_status(text: String) -> void:
	if _dock_status != null:
		_dock_status.text = text


func _fit_full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _style_primary(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.55, 0.82)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", Color(0.02, 0.08, 0.12))
	btn.add_theme_font_size_override("font_size", 14)
