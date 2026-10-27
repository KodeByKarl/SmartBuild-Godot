class_name LessonTextFit
extends Node

## Grows the text of a text-only lesson card so it fills the card instead of
## leaving dead space under a few small lines. Attach to the card (parent);
## `column` is the VBox holding the title, divider and body.
##
## On every resize it measures the wrapped text at increasing scales and keeps
## the largest one that still fits, capped so text never gets oversized.

const FILL := 0.82          ## share of the card height the text may use
const MAX_BODY_PX := 30.0   ## upper bound for body text
const MAX_TITLE_PX := 34.0  ## upper bound for card titles
const STEP := 0.05

var column: VBoxContainer = null
## Cards in one row share a group so they all use the same (smallest) scale
## and their titles line up.
var group: Object = null
var best_scale := 1.0
var _items: Array = []      ## [{node, kind, base}]
var _top_pad: Control = null
var _avail := Vector2.ZERO
var _base_sep := 8
var _last_size := Vector2.ZERO
var _pending := false


static func attach(card: Control, col: VBoxContainer, row_group: Object = null) -> void:
	var fit := LessonTextFit.new()
	fit.name = "TextFit"
	fit.column = col
	fit.group = row_group
	card.add_child(fit)


func _ready() -> void:
	var card := get_parent() as Control
	if card == null or column == null:
		return
	_base_sep = column.get_theme_constant("separation")
	_collect(column)
	if group != null:
		# Row cards share one top line: a pad above the title, sized from the
		# tallest card, keeps titles and dividers level across the row.
		column.alignment = BoxContainer.ALIGNMENT_BEGIN
		_top_pad = Control.new()
		_top_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(_top_pad)
		column.move_child(_top_pad, 0)
	card.resized.connect(_queue_fit)
	_queue_fit()


func _collect(node: Node) -> void:
	for child in node.get_children():
		if child is RichTextLabel:
			var rt := child as RichTextLabel
			_items.append({"node": rt, "kind": "rich", "base": rt.get_theme_font_size("normal_font_size")})
		elif child is Label and (child as Label).label_settings != null:
			var lbl := child as Label
			# Own copy so scaling one card never resizes another.
			lbl.label_settings = lbl.label_settings.duplicate()
			_items.append({"node": lbl, "kind": "label", "base": lbl.label_settings.font_size})
		else:
			_collect(child)


func _queue_fit() -> void:
	if _pending:
		return
	_pending = true
	_fit.call_deferred()


func _fit() -> void:
	_pending = false
	var card := get_parent() as Control
	if card == null or not is_instance_valid(column):
		return
	if card.size.is_equal_approx(_last_size) or card.size.x < 40.0 or card.size.y < 40.0:
		return
	_last_size = card.size
	var style := card.get_theme_stylebox("panel")
	var margin_w := style.get_margin(SIDE_LEFT) + style.get_margin(SIDE_RIGHT) if style else 24.0
	var margin_h := style.get_margin(SIDE_TOP) + style.get_margin(SIDE_BOTTOM) if style else 22.0
	var width := card.size.x - margin_w
	var height := (card.size.y - margin_h) * FILL
	_avail = Vector2(width, card.size.y - margin_h)
	if width <= 10.0 or height <= 10.0:
		return

	var max_scale := 3.0
	for item in _items:
		var cap := MAX_TITLE_PX if item["kind"] == "label" else MAX_BODY_PX
		max_scale = minf(max_scale, cap / maxf(float(item["base"]), 1.0))
	var scale := 1.0
	var s := maxf(max_scale, 1.0)
	while s >= 1.0:
		if _measure(s, width) <= height:
			scale = s
			break
		s -= STEP
	best_scale = scale
	if group == null:
		_apply(scale)
		return
	# Use the smallest scale of the row so every card matches.
	var shared := scale
	var members: Array = []
	for sib in _row_members():
		members.append(sib)
		shared = minf(shared, sib.best_scale)
	var tallest := 0.0
	for m in members:
		m._apply(shared)
		tallest = maxf(tallest, m._measure(shared, m._avail.x))
	for m in members:
		if m._top_pad != null:
			m._top_pad.custom_minimum_size.y = maxf(0.0, (m._avail.y - tallest) * 0.5)


func _row_members() -> Array:
	var out: Array = []
	var row := group as Node
	if row == null:
		return [self]
	for fit in row.find_children("TextFit", "LessonTextFit", true, false):
		out.append(fit)
	return out


func _measure(scale: float, width: float) -> float:
	var total := 0.0
	var count := 0
	for item in _items:
		var px := int(round(float(item["base"]) * scale))
		var text := ""
		var font: Font = null
		var extra_line := 0.0
		if item["kind"] == "rich":
			var rt: RichTextLabel = item["node"]
			text = _plain(rt.text)
			font = rt.get_theme_font("normal_font")
			extra_line = float(rt.get_theme_constant("line_separation"))
		else:
			var lbl: Label = item["node"]
			text = lbl.text
			font = lbl.label_settings.font
			extra_line = float(lbl.label_settings.line_spacing)
		if font == null:
			font = ThemeDB.fallback_font
		var size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, px)
		var lines := maxf(1.0, round(size.y / maxf(font.get_height(px), 1.0)))
		total += size.y + extra_line * lines
		count += 1
	total += float(_base_sep) * scale * float(maxi(count, 1))  # gaps + divider
	return total


func _apply(scale: float) -> void:
	column.add_theme_constant_override("separation", int(round(float(_base_sep) * scale)))
	for item in _items:
		var px := int(round(float(item["base"]) * scale))
		if item["kind"] == "rich":
			var rt: RichTextLabel = item["node"]
			rt.add_theme_font_size_override("normal_font_size", px)
			rt.add_theme_font_size_override("bold_font_size", px)
		else:
			var lbl: Label = item["node"]
			lbl.label_settings.font_size = px
			lbl.update_minimum_size()


static func _plain(bbcode: String) -> String:
	var out := bbcode
	for tag in ["[b]", "[/b]", "[fill]", "[/fill]", "[center]", "[/center]"]:
		out = out.replace(tag, "")
	return out.replace("[lb]", "[")
