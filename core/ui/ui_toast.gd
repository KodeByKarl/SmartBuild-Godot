class_name UiToast
extends Control

## Floating toast notifications — dark glass + cyan accent, bottom-center.

enum Kind { INFO, SUCCESS, WARN }

const NAVY := Color(0.02, 0.1, 0.16, 0.96)
const WHITE := Color(0.95, 0.98, 0.99, 1)
const CYAN := Color(0.09, 0.65, 0.87, 1)
const SUCCESS := Color(0.35, 0.9, 0.7, 1)
const WARN := Color(1.0, 0.78, 0.45, 1)

var _panel: PanelContainer
var _label: Label
var _accent: ColorRect
var _tween: Tween
var _hide_token: int = 0
var _rest_top: float = -88.0
var _rest_bottom: float = -28.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 120

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.modulate.a = 0.0
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -220.0
	_panel.offset_right = 220.0
	_panel.offset_top = _rest_top
	_panel.offset_bottom = _rest_bottom
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = NAVY
	style.border_color = Color(0.35, 0.82, 0.95, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	_panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)

	_accent = ColorRect.new()
	_accent.custom_minimum_size = Vector2(4, 44)
	_accent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_accent.color = CYAN
	_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_accent)

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_right", 18)
	pad.add_theme_constant_override("margin_bottom", 12)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pad)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", WHITE)
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(_label)


func show_message(message: String, kind: Kind = Kind.INFO, duration: float = 2.8) -> void:
	if _panel == null or _label == null:
		return

	_label.text = message
	match kind:
		Kind.SUCCESS:
			_accent.color = SUCCESS
		Kind.WARN:
			_accent.color = WARN
		_:
			_accent.color = CYAN

	_hide_token += 1
	var token := _hide_token

	if _tween != null and is_instance_valid(_tween):
		_tween.kill()

	_panel.visible = true
	_panel.modulate.a = 0.0
	_panel.offset_top = _rest_top + 22.0
	_panel.offset_bottom = _rest_bottom + 22.0

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_panel, "offset_top", _rest_top, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_panel, "offset_bottom", _rest_bottom, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.set_parallel(false)
	_tween.tween_interval(maxf(duration, 0.8))
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func() -> void:
		if token == _hide_token and is_instance_valid(_panel):
			_panel.visible = false
	)


static func ensure(host: Control) -> UiToast:
	var existing := host.get_node_or_null("UiToast") as UiToast
	if existing != null:
		return existing
	var toast := UiToast.new()
	toast.name = "UiToast"
	host.add_child(toast)
	return toast
