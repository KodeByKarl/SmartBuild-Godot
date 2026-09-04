extends Control

## Module 2 crimping bench: strip the jacket, fan the pairs, lay eight
## conductors into an RJ45 in the right standard, crimp, then wire-map the
## finished cable. Both ends are built separately so a straight-through and a
## crossover are the same workflow with different targets.

signal action_submitted(action: SimulationAction)

## Below this width the tool column drops under the work area.
const STACK_WIDTH := 840.0

const T568B: Array = ["wo", "o", "wg", "bl", "wbl", "g", "wbr", "br"]
const T568A: Array = ["wg", "g", "wo", "bl", "wbl", "o", "wbr", "br"]

const WIRE_ORDER: Array = ["wo", "o", "wg", "g", "bl", "wbl", "br", "wbr"]
const WIRE_LABELS := {
	"wo": "W/Orange",
	"o": "Orange",
	"wg": "W/Green",
	"g": "Green",
	"bl": "Blue",
	"wbl": "W/Blue",
	"br": "Brown",
	"wbr": "W/Brown",
}
const WIRE_COLORS := {
	"wo": Color(0.95, 0.55, 0.16),
	"o": Color(0.95, 0.55, 0.16),
	"wg": Color(0.18, 0.72, 0.34),
	"g": Color(0.18, 0.72, 0.34),
	"bl": Color(0.26, 0.46, 0.93),
	"wbl": Color(0.26, 0.46, 0.93),
	"br": Color(0.55, 0.36, 0.2),
	"wbr": Color(0.55, 0.36, 0.2),
}
## White-striped conductors render as a white body banded with the pair colour.
const STRIPED := {"wo": true, "wg": true, "wbl": true, "wbr": true}

const STANDARD_NAMES := {"t568a": "T568A", "t568b": "T568B"}

var guided_hints: bool = true

var _target_a: String = "t568b"
var _target_b: String = "t568b"
var _pins: Dictionary = {}
var _inserted: Dictionary = {"a": false, "b": false}
var _crimped: Dictionary = {"a": false, "b": false}
var _cable_selected: bool = false
var _stripped: bool = false
var _untwisted: bool = false
var _tested: bool = false
var _active_end: String = "a"
var _selected_wire: String = ""
var _done: Dictionary = {}
## Actions the simulation already accepted — re-earning one after cutting a
## plug off must not answer whatever step the run has moved on to.
var _graded: Dictionary = {}
var _hint_target: String = ""

var _status: Label = null
var _connector: Control = null
var _pin_row: HBoxContainer = null
var _pin_buttons: Array = []
var _reference: Control = null
var _palette: HFlowContainer = null
var _end_a_btn: Button = null
var _end_b_btn: Button = null
var _target_label: Label = null
var _log: RichTextLabel = null
var _columns: BoxContainer = null
var _work_col: VBoxContainer = null
var _tool_buttons: Dictionary = {}


func _ready() -> void:
	# Sit cleanly inside ModuleShell VBox — full-rect anchors clip the left edge.
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	if custom_minimum_size.y < 360.0:
		custom_minimum_size.y = 440.0
	_reset_pins()
	_build_ui()
	_refresh_all()
	_refresh_status("Work the tools top to bottom. Lay each conductor into a pin, then crimp.")


## `spec` carries the standard each end must be built to, e.g.
## ["t568b", "t568b"] for a straight-through or ["t568a", "t568b"] to cross.
func setup(spec: Array = [], hints: bool = true) -> void:
	guided_hints = hints
	if _status == null:
		call_deferred("setup", spec, hints)
		return
	if spec.size() > 0:
		_target_a = str(spec[0])
	if spec.size() > 1:
		_target_b = str(spec[1])
	_refresh_all()


func set_guided_hint(target: String, _destination: String) -> void:
	_hint_target = target
	# Jump to whichever plug the current step is about so the work area and the
	# reference strip always describe the same end.
	if target.ends_with("_a"):
		_active_end = "a"
	elif target.ends_with("_b"):
		_active_end = "b"
	_refresh_all()
	if guided_hints:
		_refresh_status("Next: %s" % _action_title(target))


func mark_step_done(target: String, _destination: String) -> void:
	_graded[target] = true
	_refresh_all()


func flash_incorrect() -> void:
	if _status == null:
		return
	_status.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	_refresh_status("Wrong crimping action — check the current step.")
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		if _status != null:
			_status.add_theme_color_override("font_color", Color(0.78, 0.9, 0.98))
	)


func _reset_pins() -> void:
	_pins = {"a": _empty_row(), "b": _empty_row()}


func _empty_row() -> Array:
	return ["", "", "", "", "", "", "", ""]


# ── Build ─────────────────────────────────────────────────────────────────────


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_tool_buttons.clear()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", Color(0.78, 0.9, 0.98))
	root.add_child(_status)

	# Plain BoxContainer so the orientation can flip on narrow screens.
	_columns = BoxContainer.new()
	_columns.vertical = false
	_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_columns.add_theme_constant_override("separation", 12)
	root.add_child(_columns)

	_work_col = _build_work_column()
	_columns.add_child(_work_col)
	_columns.add_child(_build_tool_column())

	_columns.resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _build_work_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(320, 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = 1.75
	col.add_theme_constant_override("separation", 6)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)

	_end_a_btn = Button.new()
	_end_a_btn.text = "End A"
	_end_a_btn.focus_mode = Control.FOCUS_NONE
	_end_a_btn.pressed.connect(func() -> void: _switch_end("a"))
	head.add_child(_end_a_btn)

	_end_b_btn = Button.new()
	_end_b_btn.text = "End B"
	_end_b_btn.focus_mode = Control.FOCUS_NONE
	_end_b_btn.pressed.connect(func() -> void: _switch_end("b"))
	head.add_child(_end_b_btn)

	_target_label = Label.new()
	_target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_target_label.clip_text = true
	_target_label.add_theme_font_size_override("font_size", 12)
	_target_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.98))
	head.add_child(_target_label)

	var plug := PanelContainer.new()
	plug.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plug.size_flags_vertical = Control.SIZE_EXPAND_FILL
	plug.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.09, 0.15, 0.98)))
	col.add_child(plug)

	_connector = Control.new()
	_connector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_connector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_connector.custom_minimum_size = Vector2(0, 150)
	_connector.mouse_filter = Control.MOUSE_FILTER_STOP
	_connector.draw.connect(_draw_connector)
	_connector.gui_input.connect(_on_connector_input)
	plug.add_child(_connector)

	# Explicit Pin 1–8 hit targets — drawing-only lanes were easy to miss.
	_pin_row = HBoxContainer.new()
	_pin_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pin_row.add_theme_constant_override("separation", 4)
	_pin_buttons.clear()
	for pin_i in 8:
		var pin_btn := Button.new()
		pin_btn.text = "Pin %d" % (pin_i + 1)
		pin_btn.focus_mode = Control.FOCUS_NONE
		pin_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pin_btn.custom_minimum_size = Vector2(0, 36)
		pin_btn.tooltip_text = "Pin %d — tap after selecting a conductor" % (pin_i + 1)
		pin_btn.pressed.connect(_on_pin_pressed.bind(pin_i))
		_style_pin_btn(pin_btn, false)
		_pin_row.add_child(pin_btn)
		_pin_buttons.append(pin_btn)
	col.add_child(_pin_row)

	_reference = Control.new()
	_reference.custom_minimum_size = Vector2(0, 34)
	_reference.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reference.draw.connect(_draw_reference)
	col.add_child(_reference)

	var pal_hdr := Label.new()
	pal_hdr.text = "CONDUCTORS"
	pal_hdr.add_theme_font_size_override("font_size", 10)
	pal_hdr.add_theme_color_override("font_color", Color(0.45, 0.8, 0.95, 0.9))
	col.add_child(pal_hdr)

	_palette = HFlowContainer.new()
	_palette.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_palette.add_theme_constant_override("h_separation", 6)
	_palette.add_theme_constant_override("v_separation", 6)
	col.add_child(_palette)
	return col


func _build_tool_column() -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(230, 0)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.11, 0.18, 0.96)))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.add_child(col)

	var hdr := Label.new()
	hdr.text = "CRIMPING TOOLS"
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	col.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)

	list.add_child(_tool_btn("1 · Select Cat 6 UTP", "select_cable"))
	list.add_child(_tool_btn("2 · Strip the jacket", "strip_jacket"))
	list.add_child(_tool_btn("3 · Untwist & fan pairs", "untwist_pairs"))
	list.add_child(_tool_btn("4 · Insert into RJ45", "insert_end"))
	list.add_child(_tool_btn("5 · Crimp the plug", "crimp_end"))
	list.add_child(_tool_btn("6 · Test with cable tester", "test_cable"))
	list.add_child(_tool_btn("Cut this plug off", "cut_end"))

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.fit_content = false
	_log.scroll_active = true
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(0, 62)
	_log.add_theme_font_size_override("normal_font_size", 11)
	_log.add_theme_font_size_override("bold_font_size", 11)
	_log.add_theme_color_override("default_color", Color(0.7, 0.92, 0.78))
	_log.text = "Bench ready."
	col.add_child(_section("Tester / log", _log))
	return wrap


func _panel_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(0.28, 0.58, 0.72, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _section(title: String, body: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.13, 0.21, 0.9)))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(col)
	var hdr := Label.new()
	hdr.text = title.to_upper()
	hdr.add_theme_font_size_override("font_size", 10)
	hdr.add_theme_color_override("font_color", Color(0.45, 0.82, 0.95, 0.9))
	col.add_child(hdr)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	return panel


func _tool_btn(text: String, act: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.custom_minimum_size = Vector2(0, 28)
	btn.add_theme_font_size_override("font_size", 12)
	btn.set_meta("base_text", text)
	btn.pressed.connect(func() -> void: _perform(act))
	_tool_buttons[act] = btn
	return btn


func _apply_responsive_layout() -> void:
	if _columns == null or not is_instance_valid(_columns):
		return
	var width: float = _columns.size.x
	if width < 1.0:
		width = size.x
	var stacked: bool = width > 0.0 and width < STACK_WIDTH
	if _columns.is_vertical() != stacked:
		_columns.set_vertical(stacked)
	if _work_col != null and is_instance_valid(_work_col):
		_work_col.size_flags_vertical = (
			Control.SIZE_SHRINK_BEGIN if stacked else Control.SIZE_EXPAND_FILL
		)


# ── Drawing ───────────────────────────────────────────────────────────────────


func _lane_metrics(control: Control) -> Dictionary:
	var pad := 8.0
	var lane_w: float = (control.size.x - pad * 2.0) / 8.0
	return {"pad": pad, "lane_w": lane_w}


func _draw_connector() -> void:
	if _connector == null:
		return
	var area: Vector2 = _connector.size
	if area.x < 60.0 or area.y < 60.0:
		return
	var metrics: Dictionary = _lane_metrics(_connector)
	var pad: float = metrics["pad"]
	var lane_w: float = metrics["lane_w"]
	var num_h := 16.0
	var body_h: float = clampf(area.y * 0.28, 34.0, 54.0)
	var lane_h: float = area.y - body_h - num_h - 6.0
	var row: Array = _pins[_active_end]
	var font: Font = ThemeDB.fallback_font

	for index in 8:
		var x: float = pad + float(index) * lane_w
		var lane := Rect2(x + 2.0, 2.0, lane_w - 4.0, lane_h)
		var wire: String = str(row[index])
		if wire == "":
			_connector.draw_rect(lane, Color(0.08, 0.15, 0.22, 0.9), true)
			_connector.draw_rect(lane, Color(0.35, 0.6, 0.75, 0.35), false, 1.0)
		else:
			_draw_wire(lane, wire)

		# Pin number under the plug body.
		var num_pos := Vector2(x, area.y - 3.0)
		_connector.draw_string(
			font,
			num_pos,
			str(index + 1),
			HORIZONTAL_ALIGNMENT_CENTER,
			lane_w,
			11,
			Color(0.6, 0.8, 0.92, 0.9)
		)

	# The plug shell sits over the conductor tails; gold bar marks a crimped plug.
	var body := Rect2(pad, lane_h + 2.0, area.x - pad * 2.0, body_h)
	_connector.draw_rect(body, Color(0.62, 0.72, 0.82, 0.16), true)
	_connector.draw_rect(body, Color(0.66, 0.84, 0.96, 0.55), false, 1.5)
	var crimped: bool = bool(_crimped[_active_end])
	var contact_col: Color = (
		Color(0.98, 0.78, 0.3, 0.95) if crimped else Color(0.5, 0.62, 0.72, 0.5)
	)
	for index in 8:
		var cx: float = pad + float(index) * lane_w + lane_w * 0.5
		_connector.draw_rect(
			Rect2(cx - 2.0, body.position.y + 5.0, 4.0, body.size.y * 0.45), contact_col, true
		)
	var caption: String = "%s · %s" % [
		"End %s" % _active_end.to_upper(),
		"crimped" if crimped else ("seated" if bool(_inserted[_active_end]) else "open")
	]
	_connector.draw_string(
		font,
		Vector2(pad + 4.0, body.position.y + body.size.y - 6.0),
		caption,
		HORIZONTAL_ALIGNMENT_LEFT,
		area.x,
		11,
		Color(0.75, 0.88, 0.96, 0.85)
	)


func _draw_wire(rect: Rect2, wire: String) -> void:
	var col: Color = WIRE_COLORS[wire]
	if bool(STRIPED.get(wire, false)):
		_connector.draw_rect(rect, Color(0.93, 0.95, 0.97), true)
		var bands := 7
		var band_h: float = rect.size.y / float(bands)
		for i in bands:
			if i % 2 == 1:
				_connector.draw_rect(
					Rect2(rect.position.x, rect.position.y + band_h * float(i), rect.size.x, band_h),
					col,
					true
				)
	else:
		_connector.draw_rect(rect, col, true)
	_connector.draw_rect(rect, Color(0.04, 0.08, 0.12, 0.75), false, 1.0)


## Guided mode only: the colour order this end is supposed to end up in.
func _draw_reference() -> void:
	if _reference == null or not guided_hints:
		return
	if _reference.size.x < 60.0:
		return
	var metrics: Dictionary = _lane_metrics(_reference)
	var pad: float = metrics["pad"]
	var lane_w: float = metrics["lane_w"]
	var order: Array = _standard_order(_target_for(_active_end))
	for index in 8:
		var x: float = pad + float(index) * lane_w
		var chip := Rect2(x + 2.0, 4.0, lane_w - 4.0, 14.0)
		var wire: String = str(order[index])
		var col: Color = WIRE_COLORS[wire]
		if bool(STRIPED.get(wire, false)):
			_reference.draw_rect(chip, Color(0.93, 0.95, 0.97), true)
			_reference.draw_rect(
				Rect2(chip.position.x, chip.position.y + 5.0, chip.size.x, 4.0), col, true
			)
		else:
			_reference.draw_rect(chip, col, true)
		_reference.draw_rect(chip, Color(0.04, 0.08, 0.12, 0.7), false, 1.0)
	_reference.draw_string(
		ThemeDB.fallback_font,
		Vector2(pad, 31.0),
		"%s reference" % _standard_name(_target_for(_active_end)),
		HORIZONTAL_ALIGNMENT_LEFT,
		_reference.size.x,
		10,
		Color(0.55, 0.75, 0.88, 0.8)
	)


# ── Interaction ───────────────────────────────────────────────────────────────


func _on_connector_input(event: InputEvent) -> void:
	var tapped: bool = (
		(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if not tapped:
		return
	# Prefer local mouse position so clicks map correctly after layout.
	var local_x: float = event.position.x
	if event is InputEventMouseButton:
		local_x = _connector.get_local_mouse_position().x
	var metrics: Dictionary = _lane_metrics(_connector)
	var lane_w: float = metrics["lane_w"]
	if lane_w <= 0.0:
		return
	var index: int = int(floor((local_x - float(metrics["pad"])) / lane_w))
	if index < 0 or index > 7:
		return
	_on_pin_pressed(index)


func _on_pin_pressed(index: int) -> void:
	if not _untwisted:
		_warn("Strip the jacket and fan the pairs before laying conductors.")
		return
	if bool(_crimped[_active_end]):
		_warn("End %s is crimped. Cut the plug off to rework it." % _active_end.to_upper())
		return
	var row: Array = _pins[_active_end]
	if str(row[index]) != "":
		var freed: String = str(row[index])
		row[index] = ""
		_refresh_all()
		_refresh_status("Pulled %s back out of pin %d." % [WIRE_LABELS[freed], index + 1])
		return
	if _selected_wire == "":
		_warn("Pick a conductor from the fan below, then tap a pin.")
		return
	if row.has(_selected_wire):
		_warn("%s is already in this plug." % WIRE_LABELS[_selected_wire])
		return
	row[index] = _selected_wire
	var placed: String = _selected_wire
	_selected_wire = ""
	_refresh_all()
	_refresh_status("Pin %d ← %s" % [index + 1, WIRE_LABELS[placed]])
	_check_order()


func _switch_end(end_id: String) -> void:
	_active_end = end_id
	_selected_wire = ""
	_refresh_all()
	_refresh_status("Working End %s — target %s." % [
		end_id.to_upper(), _standard_name(_target_for(end_id))
	])


## The arrange step is earned by the pins themselves, never by a button.
func _check_order() -> void:
	var end_id: String = _active_end
	var act: String = "order_end_%s" % end_id
	if _done.has(act):
		return
	if _pins[end_id] != _standard_order(_target_for(end_id)):
		return
	_complete(act, "End %s laid out to %s." % [
		end_id.to_upper(), _standard_name(_target_for(end_id))
	])


# ── Actions ───────────────────────────────────────────────────────────────────


## `insert_end` / `crimp_end` / `cut_end` follow whichever plug is on the bench.
func _resolve(act: String) -> String:
	if act == "insert_end" or act == "crimp_end":
		return "%s_%s" % [act, _active_end]
	return act


func _perform(act: String) -> void:
	if act == "cut_end":
		_cut_plug()
		return
	var resolved: String = _resolve(act)
	var blocked: String = _blocked_reason(resolved)
	if blocked != "":
		_warn(blocked)
		return
	match resolved:
		"select_cable":
			_cable_selected = true
			_complete(resolved, "Cat 6 UTP cut to length.")
		"strip_jacket":
			_stripped = true
			_complete(resolved, "Jacket stripped ~25 mm, conductors undamaged.")
		"untwist_pairs":
			_untwisted = true
			_complete(resolved, "Pairs untwisted and fanned — ready to order.")
		"insert_end_a", "insert_end_b":
			_inserted[_active_end] = true
			_complete(resolved, "Conductors seated to the front of the plug, jacket inside the shell.")
		"crimp_end_a", "crimp_end_b":
			_crimped[_active_end] = true
			_complete(resolved, "End %s crimped — contacts pierced." % _active_end.to_upper())
		"test_cable":
			_run_test()


## Prerequisites mirror the physical job — you cannot crimp an empty plug.
func _blocked_reason(act: String) -> String:
	match act:
		"strip_jacket":
			if not _cable_selected:
				return "Select the cable stock first."
		"untwist_pairs":
			if not _stripped:
				return "Strip the jacket before untwisting the pairs."
		"insert_end_a", "insert_end_b":
			if not _untwisted:
				return "Fan the pairs before seating them in a plug."
			if bool(_crimped[_active_end]):
				return "End %s is already crimped." % _active_end.to_upper()
			var mismatch: String = _order_problem(_active_end)
			if mismatch != "":
				return mismatch
		"crimp_end_a", "crimp_end_b":
			if not bool(_inserted[_active_end]):
				return "Seat the conductors in the plug before crimping."
			if bool(_crimped[_active_end]):
				return "End %s is already crimped." % _active_end.to_upper()
		"test_cable":
			if not bool(_crimped["a"]) or not bool(_crimped["b"]):
				return "Crimp both ends before running the tester."
	return ""


## Names the first pin that does not match the standard this end is built to.
## Under assessment the pin is withheld — the student has to spot it.
func _order_problem(end_id: String) -> String:
	var row: Array = _pins[end_id]
	var order: Array = _standard_order(_target_for(end_id))
	for index in 8:
		if str(row[index]) == "":
			return "Pin %d is still empty — all eight conductors must be seated." % (index + 1)
	for index in 8:
		if str(row[index]) != str(order[index]):
			if not guided_hints:
				return "That sequence is not %s. Check the pins before you crimp." % _standard_name(
					_target_for(end_id)
				)
			return "Pin %d should be %s for %s, not %s." % [
				index + 1,
				WIRE_LABELS[order[index]],
				_standard_name(_target_for(end_id)),
				WIRE_LABELS[row[index]]
			]
	return ""


func _cut_plug() -> void:
	var end_id: String = _active_end
	_pins[end_id] = _empty_row()
	_inserted[end_id] = false
	_crimped[end_id] = false
	_done.erase("order_end_%s" % end_id)
	_done.erase("insert_end_%s" % end_id)
	_done.erase("crimp_end_%s" % end_id)
	_tested = false
	_done.erase("test_cable")
	_selected_wire = ""
	_refresh_all()
	_log_line("[color=#f9c46b]Plug cut off End %s — conductors re-fanned.[/color]" % end_id.to_upper())
	_refresh_status("End %s cleared. Lay the conductors again." % end_id.to_upper())


func _run_test() -> void:
	var kind: String = _cable_kind()
	var wanted: String = _intended_kind()
	_log_line("[b]Wire map[/b] %s" % _wire_map_line())
	if kind == "miswired":
		_log_line("[color=#f77]FAIL — the two ends do not form a recognised cable.[/color]")
		_refresh_status("Tester failed. Cut off the bad plug and rebuild that end.")
		return
	if kind != wanted:
		_log_line("[color=#f77]FAIL — this is a %s cable, but a %s was specified.[/color]" % [
			kind, wanted
		])
		_refresh_status("Right build, wrong cable — check which standard each end needs.")
		return
	_tested = true
	_log_line("[color=#7d7]PASS — continuity good on all 8 pins (%s).[/color]" % kind)
	_complete("test_cable", "Cable certified as %s." % kind)


func _wire_map_line() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for index in 8:
		parts.append("%d–%d" % [index + 1, _far_pin(index)])
	return " ".join(parts)


## Which pin at End B the conductor leaving pin `index` at End A lands on.
func _far_pin(index: int) -> int:
	var wire: String = str(_pins["a"][index])
	var far: Array = _pins["b"]
	for j in 8:
		if str(far[j]) == wire:
			return j + 1
	return 0


func _cable_kind() -> String:
	var a: Array = _pins["a"]
	var b: Array = _pins["b"]
	if a == T568B and b == T568B:
		return "straight-through"
	if a == T568A and b == T568A:
		return "straight-through"
	if (a == T568A and b == T568B) or (a == T568B and b == T568A):
		return "crossover"
	return "miswired"


func _intended_kind() -> String:
	return "straight-through" if _target_a == _target_b else "crossover"


func _complete(act: String, message: String) -> void:
	_done[act] = true
	_log_line(message)
	# A step the run already accepted (before a plug was cut off) must not be
	# submitted twice — it would answer whatever step is current now.
	if not _graded.has(act):
		action_submitted.emit(SimulationAction.new("crimp", act, ""))
	_refresh_all()


# ── Refresh ───────────────────────────────────────────────────────────────────


func _refresh_all() -> void:
	_refresh_palette()
	_refresh_tools()
	_refresh_pin_buttons()
	if _target_label != null:
		_target_label.text = "End %s target: %s   ·   building a %s cable" % [
			_active_end.to_upper(), _standard_name(_target_for(_active_end)), _intended_kind()
		]
	# The tool buttons tick green as steps land; the end buttons carry the state
	# of the plug you are not currently looking at.
	if _end_a_btn != null:
		_end_a_btn.text = "End A ✓" if bool(_crimped["a"]) else "End A"
		_style_btn(_end_a_btn, _active_end == "a", false)
	if _end_b_btn != null:
		_end_b_btn.text = "End B ✓" if bool(_crimped["b"]) else "End B"
		_style_btn(_end_b_btn, _active_end == "b", false)
	if _reference != null:
		_reference.visible = guided_hints
		_reference.queue_redraw()
	if _connector != null:
		_connector.queue_redraw()


func _refresh_palette() -> void:
	if _palette == null:
		return
	for child in _palette.get_children():
		child.queue_free()
	if not _untwisted:
		var hint := Label.new()
		hint.text = "Pairs still twisted — run tools 1 to 3 first."
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", Color(0.6, 0.75, 0.85, 0.85))
		_palette.add_child(hint)
		return
	var row: Array = _pins[_active_end]
	for wire_variant in WIRE_ORDER:
		var wire: String = str(wire_variant)
		var used: bool = row.has(wire)
		var chip := Button.new()
		chip.text = str(WIRE_LABELS[wire])
		chip.focus_mode = Control.FOCUS_NONE
		chip.disabled = used
		chip.custom_minimum_size = Vector2(0, 28)
		chip.add_theme_font_size_override("font_size", 11)
		_style_wire_chip(chip, wire, used, wire == _selected_wire)
		chip.pressed.connect(func() -> void: _select_wire(wire))
		_palette.add_child(chip)


func _select_wire(wire: String) -> void:
	_selected_wire = "" if _selected_wire == wire else wire
	_refresh_all()
	if _selected_wire != "":
		_refresh_status(
			"%s selected — tap Pin 1–8 below the plug (or the matching lane)." % WIRE_LABELS[wire]
		)


func _refresh_tools() -> void:
	for key in _tool_buttons.keys():
		var act: String = str(key)
		var btn: Button = _tool_buttons[act] as Button
		if btn == null or not is_instance_valid(btn):
			continue
		var resolved: String = _resolve(act)
		var done: bool = _done.has(resolved)
		var is_next: bool = guided_hints and resolved == _hint_target
		_style_btn(btn, false, is_next, done)


func _style_btn(btn: Button, active: bool, is_next: bool, done: bool = false) -> void:
	var style := StyleBoxFlat.new()
	if done:
		style.bg_color = Color(0.07, 0.28, 0.24, 0.95)
		style.border_color = Color(0.35, 0.85, 0.62, 0.55)
	elif is_next:
		style.bg_color = Color(0.24, 0.19, 0.06, 0.95)
		style.border_color = Color(1.0, 0.78, 0.32, 0.85)
	elif active:
		style.bg_color = Color(0.09, 0.45, 0.65, 0.95)
		style.border_color = Color(0.45, 0.9, 1.0, 0.8)
	else:
		style.bg_color = Color(0.05, 0.18, 0.26, 0.95)
		style.border_color = Color(0.35, 0.8, 0.95, 0.45)
	style.set_border_width_all(2 if is_next and not done else 1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	var font_color := Color(0.95, 0.98, 1.0)
	if done:
		font_color = Color(0.72, 0.95, 0.82)
	elif is_next:
		font_color = Color(1.0, 0.88, 0.62)
	btn.add_theme_color_override("font_color", font_color)
	var base: String = str(btn.get_meta("base_text", btn.text))
	btn.text = ("✓ %s" % base) if done else base


func _refresh_pin_buttons() -> void:
	if _pin_buttons.is_empty():
		return
	var row: Array = _pins.get(_active_end, _empty_row())
	var armed: bool = _selected_wire != "" and _untwisted and not bool(_crimped[_active_end])
	for i in _pin_buttons.size():
		var btn: Button = _pin_buttons[i] as Button
		if btn == null:
			continue
		var filled: String = str(row[i]) if i < row.size() else ""
		if filled != "":
			btn.text = "%d · %s" % [i + 1, WIRE_LABELS.get(filled, filled)]
			_style_pin_btn(btn, true)
		else:
			btn.text = "Pin %d" % (i + 1)
			_style_pin_btn(btn, false, armed)
		btn.disabled = bool(_crimped[_active_end])


func _style_pin_btn(btn: Button, filled: bool, highlight: bool = false) -> void:
	var style := StyleBoxFlat.new()
	if filled:
		style.bg_color = Color(0.08, 0.28, 0.22, 0.95)
		style.border_color = Color(0.35, 0.9, 0.65, 0.85)
	elif highlight:
		style.bg_color = Color(0.08, 0.22, 0.34, 0.98)
		style.border_color = Color(0.95, 0.6, 0.2, 0.95)
	else:
		style.bg_color = Color(0.05, 0.12, 0.18, 0.95)
		style.border_color = Color(0.35, 0.65, 0.8, 0.45)
	style.set_border_width_all(2 if highlight or filled else 1)
	style.set_corner_radius_all(6)
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0))


func _style_wire_chip(chip: Button, wire: String, used: bool, selected: bool) -> void:
	var col: Color = WIRE_COLORS[wire]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(col.r, col.g, col.b, 0.22 if used else 0.55)
	style.border_color = Color(1.0, 0.95, 0.7, 0.95) if selected else Color(col.r, col.g, col.b, 0.9)
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	for slot in ["normal", "hover", "pressed", "disabled"]:
		chip.add_theme_stylebox_override(slot, style)
	var text_col := Color(0.98, 0.99, 1.0) if not used else Color(0.6, 0.68, 0.75)
	chip.add_theme_color_override("font_color", text_col)
	chip.add_theme_color_override("font_disabled_color", text_col)


# ── Helpers ───────────────────────────────────────────────────────────────────


func _target_for(end_id: String) -> String:
	return _target_a if end_id == "a" else _target_b


func _standard_order(standard: String) -> Array:
	return T568A if standard == "t568a" else T568B


func _standard_name(standard: String) -> String:
	return str(STANDARD_NAMES.get(standard, standard.to_upper()))


func _action_title(act: String) -> String:
	match act:
		"select_cable":
			return "select the cable stock"
		"strip_jacket":
			return "strip the jacket"
		"untwist_pairs":
			return "untwist and fan the pairs"
		"order_end_a":
			return "lay End A out to %s" % _standard_name(_target_a)
		"order_end_b":
			return "lay End B out to %s" % _standard_name(_target_b)
		"insert_end_a", "insert_end_b":
			return "seat the conductors in the plug"
		"crimp_end_a", "crimp_end_b":
			return "crimp the plug"
		"test_cable":
			return "test the finished cable"
	return act


func _warn(text: String) -> void:
	_log_line("[color=#f9c46b]%s[/color]" % text)
	_refresh_status(text)


func _refresh_status(text: String) -> void:
	if _status != null:
		_status.text = text


func _log_line(line: String) -> void:
	if _log == null:
		return
	_log.text = str(_log.text) + "\n" + line
