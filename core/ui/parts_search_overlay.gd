extends Control
class_name PartsSearchOverlay

## Shared CSS Parts Encyclopedia overlay — scoped to a module when module_id > 0.

signal closed

var _module_id: int = 0
var _list: VBoxContainer = null
var _detail: RichTextLabel = null
var _query: LineEdit = null
var _category: String = CssPartsCatalog.ALL


func open(parent: Control, module_id: int = 0, initial_query: String = "") -> void:
	_module_id = module_id
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 80
	parent.add_child(self)
	_build_ui(initial_query)
	_refresh_list()


func _build_ui(initial_query: String) -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.62)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close()
	)
	add_child(dimmer)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 40
	panel.offset_right = -40
	panel.offset_top = 36
	panel.offset_bottom = -36
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.09, 0.14, 0.98)
	style.border_color = Color(0.35, 0.82, 0.95, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.35
	left.add_theme_constant_override("separation", 8)
	root.add_child(left)

	var header := HBoxContainer.new()
	left.add_child(header)
	var title := Label.new()
	title.text = "Parts Encyclopedia"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(_close)
	header.add_child(close_btn)

	var scope := Label.new()
	if _module_id > 0:
		scope.text = "Showing parts for Module %d" % _module_id
	else:
		scope.text = "Intro · full CSS Parts Encyclopedia"
	scope.add_theme_font_size_override("font_size", 11)
	scope.add_theme_color_override("font_color", Color(0.65, 0.82, 0.92, 0.85))
	left.add_child(scope)

	_query = LineEdit.new()
	_query.placeholder_text = "Search components, cables, servers…"
	_query.text = initial_query
	_query.custom_minimum_size = Vector2(0, 38)
	_query.text_changed.connect(func(_t: String) -> void: _refresh_list())
	left.add_child(_query)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dstyle := StyleBoxFlat.new()
	dstyle.bg_color = Color(0.04, 0.14, 0.2, 0.98)
	dstyle.border_color = Color(0.3, 0.75, 0.92, 0.35)
	dstyle.set_border_width_all(1)
	dstyle.set_corner_radius_all(12)
	dstyle.content_margin_left = 12
	dstyle.content_margin_right = 12
	dstyle.content_margin_top = 10
	dstyle.content_margin_bottom = 10
	detail_panel.add_theme_stylebox_override("panel", dstyle)
	root.add_child(detail_panel)

	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = true
	_detail.scroll_active = true
	_detail.custom_minimum_size = Vector2(260, 0)
	_detail.text = "[color=#8cf]Select a part[/color] to read the overview."
	detail_panel.add_child(_detail)


func _refresh_list() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	var needle: String = _query.text if _query != null else ""
	var parts: Array = CssPartsCatalog.filter_parts(needle, _category)
	for part in parts:
		if _module_id > 0 and not _module_id in part.get("related_modules", []):
			continue
		var row := Button.new()
		row.text = "%s  ·  %s" % [str(part.get("title", "?")), str(part.get("category", ""))]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.focus_mode = Control.FOCUS_NONE
		row.add_theme_font_size_override("font_size", 12)
		row.pressed.connect(_show_part.bind(part))
		_list.add_child(row)
	if _list.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "No matching parts."
		empty.add_theme_color_override("font_color", Color(0.7, 0.85, 0.92, 0.8))
		_list.add_child(empty)


func _show_part(part: Dictionary) -> void:
	if _detail == null:
		return
	_detail.text = (
		"[b]%s[/b]\n[color=#7cf]%s[/color]\n\n%s\n\n[b]How it works[/b]\n%s\n\n[b]CSS use[/b]\n%s\n\n[b]Common issues[/b]\n%s\n\n[b]Technician tips[/b]\n%s"
		% [
			str(part.get("title", "")),
			str(part.get("category", "")),
			str(part.get("summary", "")),
			str(part.get("overview", "")),
			str(part.get("css_use", "")),
			str(part.get("common_issues", "")),
			str(part.get("technician_tips", "")),
		]
	)


func _close() -> void:
	closed.emit()
	queue_free()
