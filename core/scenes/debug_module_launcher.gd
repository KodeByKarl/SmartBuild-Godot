extends Control
## DEBUG-ONLY module picker for editor / desktop runs without Android.
## Not a product dashboard — gated by Main.gd + EnvConfig flags.

signal module_selected(module_id: int, simulation_type: int)

const BG := Color(0.003921569, 0.09019608, 0.13725491, 1)
const CYAN := Color(0.09, 0.65, 0.87, 1)

const MODULES: Array[Dictionary] = [
	{"id": 0, "title": "Module 0 — Introduction"},
	{"id": 1, "title": "Module 1 — PC Systems"},
	{"id": 2, "title": "Module 2 — Networks"},
	{"id": 3, "title": "Module 3 — Servers"},
	{"id": 4, "title": "Module 4 — Maintenance"},
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)
	var title := Label.new()
	title.text = "DEBUG — Simulation launcher"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", CYAN)
	col.add_child(title)
	var hint := Label.new()
	hint.text = "Auth / Home live in Compose. This picker is editor-only."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95, 0.9))
	col.add_child(hint)
	for entry in MODULES:
		var mid: int = int(entry["id"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		col.add_child(row)
		var guided := Button.new()
		guided.text = "%s · Guided" % str(entry["title"])
		guided.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		guided.custom_minimum_size = Vector2(0, 40)
		guided.focus_mode = Control.FOCUS_NONE
		guided.pressed.connect(_emit_pick.bind(mid, 0))
		row.add_child(guided)
		var assess := Button.new()
		assess.text = "Assessment"
		assess.custom_minimum_size = Vector2(120, 40)
		assess.focus_mode = Control.FOCUS_NONE
		assess.pressed.connect(_emit_pick.bind(mid, 1))
		row.add_child(assess)


func _emit_pick(module_id: int, simulation_type: int) -> void:
	module_selected.emit(module_id, simulation_type)
