class_name Module0SlideBuilder
extends RefCounted

## Builds dark glass chrome + common Module 0 slide layouts.


static func mount(root: Control) -> VBoxContainer:
	for child in root.get_children():
		child.queue_free()

	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Module0SlideTheme.NAVY
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 20)
	outer.add_theme_constant_override("margin_top", 16)
	outer.add_theme_constant_override("margin_right", 20)
	outer.add_theme_constant_override("margin_bottom", 12)
	root.add_child(outer)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", Module0SlideTheme.panel_style())
	outer.add_child(panel)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 28)
	inner.add_theme_constant_override("margin_top", 24)
	inner.add_theme_constant_override("margin_right", 28)
	inner.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(inner)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 16)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(content)
	return content


static func make_label(text: String, settings: LabelSettings, expand: bool = true) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.label_settings = settings
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if expand:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl


static func make_art(path: String, min_h: float = 200.0, ratio: float = 1.0) -> Control:
	var wrap := AspectRatioContainer.new()
	wrap.ratio = ratio
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.custom_minimum_size = Vector2(0, min_h)
	wrap.stretch_mode = AspectRatioContainer.STRETCH_FIT

	var tex := TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture = _load_texture(path)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(tex)
	return wrap


static func make_card(title: String, body: String, accent: bool = false, art_path: String = "") -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Module0SlideTheme.card_style(accent))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(col)
	col.add_child(make_label(title, Module0SlideTheme.card_title_settings()))
	col.add_child(make_label(body, Module0SlideTheme.card_body_settings()))

	if art_path != "":
		var art := TextureRect.new()
		art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art.custom_minimum_size = Vector2(0, 100)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture = _load_texture(art_path)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(art)
	return card


static func add_cards_row(parent: Control, cards: Array, accents: Array = []) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	for i in cards.size():
		var entry: Dictionary = cards[i]
		var accent := i < accents.size() and bool(accents[i])
		if accents.is_empty():
			accent = (i % 2) == 1
		row.add_child(make_card(
			str(entry.get("title", "")),
			str(entry.get("body", "")),
			accent,
			str(entry.get("art", ""))
		))


static func hero_split(content: VBoxContainer, art_path: String, title: String, subtitle: String, bodies: Array[String], art_left: bool = true, ratio: float = 0.9) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(row)

	var art := make_art(art_path, 220.0, ratio)
	art.size_flags_stretch_ratio = 0.95

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.size_flags_stretch_ratio = 1.15
	text.add_theme_constant_override("separation", 12)
	text.alignment = BoxContainer.ALIGNMENT_CENTER

	text.add_child(make_label(title, Module0SlideTheme.title_settings(34)))
	if subtitle != "":
		text.add_child(make_label(subtitle, Module0SlideTheme.subtitle_settings(18)))
	for body in bodies:
		text.add_child(make_label(body, Module0SlideTheme.body_settings(16)))

	if art_left:
		row.add_child(art)
		row.add_child(text)
	else:
		row.add_child(text)
		row.add_child(art)


static func title_art_cards(content: VBoxContainer, title: String, subtitle: String, art_path: String, cards: Array, ratio: float = 1.4) -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 24)
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top.size_flags_stretch_ratio = 1.1
	content.add_child(top)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 10)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(text)
	text.add_child(make_label(title, Module0SlideTheme.title_settings(32)))
	if subtitle != "":
		text.add_child(make_label(subtitle, Module0SlideTheme.body_settings(16)))

	var art := make_art(art_path, 160.0, ratio)
	art.size_flags_stretch_ratio = 0.85
	top.add_child(art)

	if not cards.is_empty():
		add_cards_row(content, cards)


static func stacked_art(content: VBoxContainer, title: String, subtitle: String, body: String, art_a: String, art_b: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(row)

	var arts := VBoxContainer.new()
	arts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arts.size_flags_stretch_ratio = 0.9
	arts.add_theme_constant_override("separation", 12)
	row.add_child(arts)
	arts.add_child(make_art(art_a, 140.0, 1.4))
	arts.add_child(make_art(art_b, 140.0, 1.4))

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_stretch_ratio = 1.15
	text.add_theme_constant_override("separation", 12)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text)
	text.add_child(make_label(title, Module0SlideTheme.title_settings(32)))
	if subtitle != "":
		text.add_child(make_label(subtitle, Module0SlideTheme.subtitle_settings(17)))
	if body != "":
		text.add_child(make_label(body, Module0SlideTheme.body_settings(15)))


static func header_and_cards(content: VBoxContainer, title: String, subtitle: String, hint: String, cards: Array) -> void:
	content.add_child(make_label(title, Module0SlideTheme.title_settings(32)))
	if subtitle != "":
		content.add_child(make_label(subtitle, Module0SlideTheme.subtitle_settings(17)))
	if hint != "":
		content.add_child(make_label(hint, Module0SlideTheme.body_settings(14)))
	add_cards_row(content, cards)


static func header_body(content: VBoxContainer, title: String, subtitle: String, bodies: Array[String], art_path: String = "") -> void:
	if art_path != "":
		hero_split(content, art_path, title, subtitle, bodies, false, 1.1)
		return
	content.add_child(make_label(title, Module0SlideTheme.title_settings(34)))
	if subtitle != "":
		content.add_child(make_label(subtitle, Module0SlideTheme.subtitle_settings(18)))
	for body in bodies:
		content.add_child(make_label(body, Module0SlideTheme.body_settings(16)))


static func _load_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex != null:
		return tex
	var image := Image.new()
	if image.load(path) == OK:
		return ImageTexture.create_from_image(image)
	return null
