class_name LessonHeader
extends RefCounted

## Figma header row shared by every module: Back chip (blue circle + arrow),
## "Module N | Title" label, Help chip. Static so LessonDeck and SimulationPage
## style their own header nodes the same way.

const CYAN := Color(0.09, 0.65, 0.87, 1)


static func style(back_btn: Button, module_label: Label, help_btn: Button, title: String) -> void:
	if back_btn != null:
		style_back(back_btn)
	if module_label != null:
		style_module_label(module_label, title)
	if help_btn != null:
		style_help(help_btn)


static func style_back(btn: Button) -> void:
	btn.text = "Back"
	btn.icon = LessonTheme.load_texture(LessonTheme.ICON_BACK)
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.custom_minimum_size = Vector2(128, 52)
	apply_chip(btn)
	btn.add_theme_font_size_override("font_size", LessonTheme.readable(16))


static func style_help(btn: Button) -> void:
	apply_chip(btn)
	btn.custom_minimum_size = Vector2(80, 40)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", LessonTheme.readable(12))


static func style_module_label(label: Label, title: String) -> void:
	label.text = title
	label.add_theme_font_override("font", LessonTheme.tracked_font(LessonTheme.FONT_CARD, 1))
	label.add_theme_font_size_override("font_size", LessonTheme.readable(12))
	label.add_theme_color_override("font_color", LessonTheme.FIGMA_TEXT)


static func apply_chip(btn: Button) -> void:
	var normal := LessonTheme.chip_style()
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = CYAN
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_font_override("font", LessonTheme.load_font(LessonTheme.FONT_CARD))
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		btn.add_theme_color_override(key, LessonTheme.FIGMA_TEXT)
	# Icon art already carries its Figma colours; do not tint it.
	for key in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		btn.add_theme_color_override(key, Color.WHITE)
	btn.focus_mode = Control.FOCUS_NONE


## Older navy/cyan chrome button (Help overlay "Close").
static func apply_chrome_button(btn: Button) -> void:
	var white := LessonTheme.WHITE
	var normal := StyleBoxFlat.new()
	normal.bg_color = LessonTheme.FIGMA_CHIP
	normal.border_color = LessonTheme.FIGMA_CHIP_BORDER
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = LessonTheme.FIGMA_CHIP.lightened(0.08) if LessonTheme.light_mode else Color(0.08, 0.32, 0.45, 0.98)
	hover.border_color = CYAN
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(LessonTheme.FIGMA_CHIP, 0.7)
	disabled.border_color = Color(LessonTheme.FIGMA_CHIP_BORDER, 0.25)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("icon_normal_color", CYAN)
	btn.add_theme_color_override("icon_hover_color", white)
	btn.add_theme_color_override("icon_disabled_color", Color(0.45, 0.6, 0.7, 0.5))
	btn.focus_mode = Control.FOCUS_NONE


## Help overlay: dimmer + panel with a Close button and a rich-text body.
## Returns {"overlay": Control, "body": RichTextLabel}; caller frees overlay.
static func open_help_overlay(host: Control, on_close: Callable) -> Dictionary:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 75
	host.add_child(overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.45)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			on_close.call()
	)
	overlay.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 56
	panel.offset_right = -56
	panel.offset_top = 48
	panel.offset_bottom = -48
	var style := StyleBoxFlat.new()
	style.bg_color = LessonTheme.PANEL
	style.border_color = LessonTheme.PANEL_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var top := HBoxContainer.new()
	col.add_child(top)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(on_close)
	apply_chrome_button(close)
	close.add_theme_color_override("font_color", CYAN)
	close.add_theme_color_override("font_hover_color", LessonTheme.WHITE)
	top.add_child(close)
	var title := Label.new()
	title.text = "Module Help"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", LessonTheme.readable(20))
	title.add_theme_color_override("font_color", LessonTheme.FIGMA_TEXT)
	top.add_child(title)

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_color_override("default_color", LessonTheme.FIGMA_TEXT)
	col.add_child(body)
	return {"overlay": overlay, "body": body}
