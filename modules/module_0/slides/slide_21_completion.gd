extends Control

## Module 0 finale — greeting, animated achievement checklist, proceed home.

signal proceed_home

const CYAN := Color(0.09, 0.65, 0.87, 1)
const WHITE := Color(0.95, 0.98, 0.99, 1)
const NAVY := Color(0.003921569, 0.09019608, 0.13725491, 1)

const ACHIEVEMENTS: Array[Dictionary] = [
	{"title": "Industry & workplace basics", "detail": "You learned how CSS fits modern workplaces."},
	{"title": "Safety & quality mindset", "detail": "You reviewed safe, standards-based servicing habits."},
	{"title": "Computer fundamentals", "detail": "You can describe how a system is organized."},
	{"title": "Hardware awareness", "detail": "You identified key components and roles."},
	{"title": "Ports, connectors & tools", "detail": "You know the essentials for technician work."},
]

var _list: VBoxContainer
var _progress_bar: ProgressBar
var _progress_label: Label
var _home_btn: Button
var _revealed: int = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_ui()
	_play_checklist_animation()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var eyebrow := Label.new()
	eyebrow.text = "MODULE 0 COMPLETE"
	eyebrow.add_theme_font_size_override("font_size", 14)
	eyebrow.add_theme_color_override("font_color", CYAN)
	root.add_child(eyebrow)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 16)
	root.add_child(hero)

	var badge := TextureRect.new()
	badge.custom_minimum_size = Vector2(72, 72)
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.texture = _load_ui_texture("res://assets/ui/icon_achievement.png")
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(badge)

	var greet_col := VBoxContainer.new()
	greet_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	greet_col.add_theme_constant_override("separation", 4)
	hero.add_child(greet_col)

	var greet := Label.new()
	greet.text = "Congratulations!"
	greet.add_theme_font_size_override("font_size", 42)
	greet.add_theme_color_override("font_color", WHITE)
	greet_col.add_child(greet)

	var sub := Label.new()
	sub.text = "You finished Introduction to Computer Systems Servicing.\nHere’s everything you unlocked along the way."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.78, 0.9, 0.96, 0.95))
	greet_col.add_child(sub)

	# Progress summary card
	var progress_card := PanelContainer.new()
	progress_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pc_style := StyleBoxFlat.new()
	pc_style.bg_color = Color(0.04, 0.18, 0.28, 0.95)
	pc_style.corner_radius_top_left = 16
	pc_style.corner_radius_top_right = 16
	pc_style.corner_radius_bottom_left = 16
	pc_style.corner_radius_bottom_right = 16
	pc_style.border_width_left = 1
	pc_style.border_width_top = 1
	pc_style.border_width_right = 1
	pc_style.border_width_bottom = 1
	pc_style.border_color = Color(0.35, 0.82, 0.95, 0.4)
	pc_style.content_margin_left = 20
	pc_style.content_margin_top = 16
	pc_style.content_margin_right = 20
	pc_style.content_margin_bottom = 16
	progress_card.add_theme_stylebox_override("panel", pc_style)
	root.add_child(progress_card)

	var progress_col := VBoxContainer.new()
	progress_col.add_theme_constant_override("separation", 10)
	progress_card.add_child(progress_col)

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 14)
	progress_col.add_child(progress_row)

	var ring := TextureRect.new()
	ring.custom_minimum_size = Vector2(40, 40)
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ring.texture = _load_ui_texture("res://assets/ui/icon_progress_ring.png")
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_row.add_child(ring)

	_progress_label = Label.new()
	_progress_label.text = "0%"
	_progress_label.add_theme_font_size_override("font_size", 28)
	_progress_label.add_theme_color_override("font_color", WHITE)
	progress_row.add_child(_progress_label)

	var progress_copy := Label.new()
	progress_copy.text = "Module progress"
	progress_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_copy.add_theme_font_size_override("font_size", 15)
	progress_copy.add_theme_color_override("font_color", Color(0.75, 0.9, 0.98, 0.9))
	progress_row.add_child(progress_copy)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value = 0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, 16)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill := StyleBoxFlat.new()
	fill.bg_color = CYAN
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_left = 8
	fill.corner_radius_bottom_right = 8
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.08, 0.12, 0.9)
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	_progress_bar.add_theme_stylebox_override("fill", fill)
	_progress_bar.add_theme_stylebox_override("background", bg)
	progress_col.add_child(_progress_bar)

	var checklist_title := Label.new()
	checklist_title.text = "Achievements unlocked"
	checklist_title.add_theme_font_size_override("font_size", 16)
	checklist_title.add_theme_color_override("font_color", CYAN)
	root.add_child(checklist_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	for item in ACHIEVEMENTS:
		_list.add_child(_make_checklist_row(str(item.get("title", "")), str(item.get("detail", "")), false))

	_home_btn = Button.new()
	_home_btn.text = "Proceed to Home"
	_home_btn.custom_minimum_size = Vector2(0, 52)
	_home_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home_btn.focus_mode = Control.FOCUS_NONE
	_home_btn.disabled = true
	_home_btn.modulate = Color(1, 1, 1, 0.45)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = CYAN
	btn_style.corner_radius_top_left = 14
	btn_style.corner_radius_top_right = 14
	btn_style.corner_radius_bottom_left = 14
	btn_style.corner_radius_bottom_right = 14
	btn_style.content_margin_left = 18
	btn_style.content_margin_right = 18
	btn_style.content_margin_top = 12
	btn_style.content_margin_bottom = 12
	_home_btn.add_theme_stylebox_override("normal", btn_style)
	_home_btn.add_theme_stylebox_override("hover", btn_style)
	_home_btn.add_theme_stylebox_override("pressed", btn_style)
	_home_btn.add_theme_stylebox_override("disabled", btn_style)
	_home_btn.add_theme_color_override("font_color", NAVY)
	_home_btn.add_theme_color_override("font_disabled_color", Color(0.02, 0.08, 0.12, 0.55))
	_home_btn.add_theme_font_size_override("font_size", 16)
	_home_btn.pressed.connect(func() -> void: proceed_home.emit())
	root.add_child(_home_btn)


func _make_checklist_row(title_text: String, detail_text: String, checked: bool) -> PanelContainer:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.modulate = Color(1, 1, 1, 0.15) if not checked else Color(1, 1, 1, 1)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.12, 0.18, 0.92)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.35, 0.82, 0.95, 0.22)
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	row.add_theme_stylebox_override("panel", style)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	row.add_child(h)

	var check := TextureRect.new()
	check.name = "CheckMark"
	check.custom_minimum_size = Vector2(28, 28)
	check.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	check.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	check.texture = _load_ui_texture("res://assets/ui/icon_circle_empty.png")
	check.modulate = Color(0.45, 0.7, 0.85, 0.55)
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(check)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	h.add_child(copy)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", WHITE)
	copy.add_child(title)

	var detail := Label.new()
	detail.text = detail_text
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 12)
	detail.add_theme_color_override("font_color", Color(0.7, 0.85, 0.95, 0.85))
	copy.add_child(detail)

	return row


func _play_checklist_animation() -> void:
	_revealed = 0
	_animate_progress_to(100.0)
	_reveal_next_item()


func _animate_progress_to(target: float) -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress_visual, 0.0, target, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_progress_visual(value: float) -> void:
	if _progress_bar != null:
		_progress_bar.value = value
	if _progress_label != null:
		_progress_label.text = "%d%%" % int(round(value))


func _reveal_next_item() -> void:
	if _list == null:
		return
	if _revealed >= _list.get_child_count():
		_enable_home_button()
		return

	var row := _list.get_child(_revealed) as PanelContainer
	_revealed += 1
	if row == null:
		_reveal_next_item()
		return

	var check := row.find_child("CheckMark", true, false) as TextureRect
	var tween := create_tween()
	tween.tween_property(row, "modulate", Color(1, 1, 1, 1), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(row, "scale", Vector2.ONE, 0.28).from(Vector2(0.96, 0.96))
	tween.tween_callback(func() -> void:
		if check != null:
			check.texture = _load_ui_texture("res://assets/ui/icon_check_circle.png")
			check.modulate = Color(1, 1, 1, 1)
	)
	tween.tween_interval(0.22)
	tween.tween_callback(_reveal_next_item)


func _enable_home_button() -> void:
	if _home_btn == null:
		return
	_home_btn.disabled = false
	var tween := create_tween()
	tween.tween_property(_home_btn, "modulate", Color(1, 1, 1, 1), 0.35)


func _load_ui_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			return tex
	var image := Image.new()
	var err := image.load(path)
	if err == OK:
		return ImageTexture.create_from_image(image)
	return null
