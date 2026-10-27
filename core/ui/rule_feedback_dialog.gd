class_name RuleFeedbackDialog
extends Control

## Modal correct/incorrect feedback for rule-based simulation actions.

signal closed
signal proceed_pressed

var _proceed_on_confirm := false

const NAVY := Color(0.02, 0.1, 0.16, 0.98)
const WHITE := Color(0.95, 0.98, 0.99, 1)
const OK_GREEN := Color(0.3, 0.82, 0.52, 1)
const BAD_RED := Color(0.95, 0.4, 0.38, 1)

var _panel: PanelContainer
var _title: Label
var _body: Label
var _confirm: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 130

	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			dismiss()
	)
	add_child(dimmer)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -200.0
	_panel.offset_right = 200.0
	_panel.offset_top = -120.0
	_panel.offset_bottom = 120.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = NAVY
	style.border_color = Color(0.35, 0.82, 0.95, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 16
	_panel.add_theme_stylebox_override("panel", style)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.add_child(col)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(22))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(15))
	_body.add_theme_color_override("font_color", Color(0.86, 0.93, 0.97, 0.95))
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_body)

	_confirm = Button.new()
	_confirm.custom_minimum_size = Vector2(0, 44)
	_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm.focus_mode = Control.FOCUS_NONE
	_confirm.pressed.connect(dismiss)
	col.add_child(_confirm)
	_style_confirm(false)


func present(correct: bool, heading: String, detail: String) -> void:
	if _title == null:
		return
	_proceed_on_confirm = false
	_title.text = "Correct" if correct else "Incorrect"
	_title.add_theme_color_override("font_color", OK_GREEN if correct else BAD_RED)
	var lines: PackedStringArray = []
	if heading.strip_edges() != "":
		lines.append(heading.strip_edges())
	if detail.strip_edges() != "":
		lines.append(detail.strip_edges())
	_body.text = "\n\n".join(lines) if not lines.is_empty() else (
		"Nice work — keep going." if correct else "Try again using the current guide."
	)
	_confirm.text = "Continue" if correct else "Got it"
	_style_confirm(correct)
	visible = true
	modulate.a = 1.0


func present_done(detail: String, button_text: String) -> void:
	present(true, "Congrats, you are done", detail)
	if _title != null:
		_title.text = "Congrats, you are done"
	if _confirm != null:
		_confirm.text = button_text
	_proceed_on_confirm = true
	visible = true


func dismiss() -> void:
	visible = false
	var proceed := _proceed_on_confirm
	_proceed_on_confirm = false
	closed.emit()
	if proceed:
		proceed_pressed.emit()


func _style_confirm(correct: bool) -> void:
	if _confirm == null:
		return
	var accent := OK_GREEN if correct else Color(0.09, 0.65, 0.87, 1)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.22, 0.32, 0.98)
	normal.border_color = accent
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	_confirm.add_theme_stylebox_override("normal", normal)
	_confirm.add_theme_stylebox_override("hover", normal)
	_confirm.add_theme_stylebox_override("pressed", normal)
	_confirm.add_theme_color_override("font_color", WHITE)
	_confirm.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(15))


static func ensure(host: Control) -> RuleFeedbackDialog:
	var existing := host.get_node_or_null("RuleFeedbackDialog") as RuleFeedbackDialog
	if existing != null:
		return existing
	var dialog := RuleFeedbackDialog.new()
	dialog.name = "RuleFeedbackDialog"
	dialog.visible = false
	host.add_child(dialog)
	return dialog
