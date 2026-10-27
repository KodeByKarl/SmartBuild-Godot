class_name LessonLayouts
extends RefCounted

## Data-driven lesson page layouts. A page is a Dictionary:
##   {
##     "card": "figma" | "classic",   # content card style (default classic)
##     "sections": [ {"layout": "...", ...}, ... ],
##     "help": {"title": "...", "body": "..."},
##     "phase": "Career path",        # optional header chip text
##   }
## build_page() mounts the content card and renders each section in order, so
## a module is nothing more than an Array of these dictionaries.


static func build_page(root: Control, page: Dictionary) -> VBoxContainer:
	var style: StyleBox = null
	if str(page.get("card", "classic")) == "figma":
		style = LessonTheme.welcome_panel_style()
	var content := LessonBlocks.mount(root, style, bool(page.get("tight", false)))
	var sections: Array = page.get("sections", [])
	if sections.is_empty():
		header_body(content, "Lesson", "", ["Page content unavailable."])
		return content
	for section in sections:
		render_section(content, section as Dictionary, root)
	return content


static func render_section(content: VBoxContainer, s: Dictionary, page_root: Control = null) -> void:
	match str(s.get("layout", "")):
		# --- Module 0 layouts (classic navy + cyan) --------------------------
		"welcome_hero":
			welcome_hero(content, _str(s, "art"), _str(s, "title"), _str(s, "body"))
		"hero_split":
			hero_split(
				content, _str(s, "art"), _str(s, "title"), _str(s, "subtitle"),
				_strings(s.get("bodies", [])), bool(s.get("art_left", true)), float(s.get("ratio", 0.9))
			)
		"title_art_cards":
			title_art_cards(
				content, _str(s, "title"), _str(s, "subtitle"), _str(s, "art"),
				s.get("cards", []), float(s.get("ratio", 1.4)), bool(s.get("fill_art", true))
			)
		"stacked_art":
			stacked_art(content, s)
		"header_and_cards":
			header_and_cards(content, _str(s, "title"), _str(s, "subtitle"), _str(s, "hint"), s.get("cards", []))
		"header_body":
			header_body(content, _str(s, "title"), _str(s, "subtitle"), _strings(s.get("bodies", [])), _str(s, "art"))
		"cards_row":
			LessonBlocks.add_cards_row(content, s.get("cards", []))
		_:
			LessonFigmaLayouts.render(content, s, page_root)


## Figma "Prep Lesson - page 0": illustration left, bold title + justified intro right.
## Column weights mirror the frame (art 335 / gap 33 / text 404 inside an 840 card).
static func welcome_hero(content: VBoxContainer, art_path: String, title: String, body: String) -> void:
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 2)
	pad.add_theme_constant_override("margin_right", 36)
	content.add_child(pad)

	var row := LessonBlocks.make_row(33)
	pad.add_child(row)

	var art := LessonBlocks.make_art(art_path, 120.0, 1.5, true)
	art.size_flags_stretch_ratio = 335.0
	row.add_child(art)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.size_flags_stretch_ratio = 404.0
	text.add_theme_constant_override("separation", 36)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text)

	text.add_child(LessonBlocks.make_label(title, LessonTheme.welcome_title_settings()))
	var body_lbl := LessonBlocks.make_label(body, LessonTheme.welcome_body_settings())
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	text.add_child(body_lbl)


static func hero_split(content: VBoxContainer, art_path: String, title: String, subtitle: String, bodies: Array[String], art_left: bool = true, ratio: float = 0.9) -> void:
	var row := LessonBlocks.make_row(16)
	content.add_child(row)

	var art := LessonBlocks.make_art(art_path, 120.0, ratio, true)
	art.size_flags_stretch_ratio = 0.9
	art.custom_minimum_size = Vector2(0, 120)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.size_flags_stretch_ratio = 1.25
	text.custom_minimum_size = Vector2(0, 0)
	text.add_theme_constant_override("separation", 10)
	text.alignment = BoxContainer.ALIGNMENT_CENTER

	text.add_child(LessonBlocks.make_label(title, LessonTheme.title_settings(28)))
	if subtitle != "":
		text.add_child(LessonBlocks.make_label(subtitle, LessonTheme.subtitle_settings(16)))
	for body in bodies:
		var body_lbl := LessonBlocks.make_label(body, LessonTheme.body_settings(14))
		body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		text.add_child(body_lbl)

	if art_left:
		row.add_child(art)
		row.add_child(text)
	else:
		row.add_child(text)
		row.add_child(art)


static func title_art_cards(content: VBoxContainer, title: String, subtitle: String, art_path: String, cards: Array, ratio: float = 1.4, fill_art: bool = true) -> void:
	var top := LessonBlocks.make_row(12, false)
	# Keep the header compact so the cards below stay fully on screen.
	content.add_child(top)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.size_flags_stretch_ratio = 1.45
	text.custom_minimum_size = Vector2(0, 0)
	text.add_theme_constant_override("separation", 4)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(text)
	text.add_child(LessonBlocks.make_label(title, LessonTheme.title_settings(24)))
	if subtitle != "":
		text.add_child(LessonBlocks.make_label(subtitle, LessonTheme.body_settings(13)))

	var art := LessonBlocks.make_art(art_path, 96.0, ratio, false)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_stretch_ratio = 0.7
	art.custom_minimum_size = Vector2(0, 96)
	top.add_child(art)

	if not cards.is_empty():
		LessonBlocks.add_cards_row(content, cards, [], fill_art)


## Two stacked illustrations beside a title block. Options (all optional):
##   arts_ratio (0.9), arts_gap (10), text_gap (10), subtitle_size (15),
##   body, then "cards" for a row of cards underneath.
static func stacked_art(content: VBoxContainer, s: Dictionary) -> void:
	var row := LessonBlocks.make_row(16)
	content.add_child(row)

	var arts := VBoxContainer.new()
	arts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arts.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arts.size_flags_stretch_ratio = float(s.get("arts_ratio", 0.9))
	arts.custom_minimum_size = Vector2(0, 0)
	arts.add_theme_constant_override("separation", int(s.get("arts_gap", 10)))
	row.add_child(arts)
	arts.add_child(LessonBlocks.make_art(_str(s, "art_a"), 96.0, 1.4, true))
	arts.add_child(LessonBlocks.make_art(_str(s, "art_b"), 96.0, 1.4, true))

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.size_flags_stretch_ratio = 1.2
	text.custom_minimum_size = Vector2(0, 0)
	text.add_theme_constant_override("separation", int(s.get("text_gap", 10)))
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text)
	text.add_child(LessonBlocks.make_label(_str(s, "title"), LessonTheme.title_settings(28)))
	var subtitle := _str(s, "subtitle")
	if subtitle != "":
		text.add_child(LessonBlocks.make_label(subtitle, LessonTheme.subtitle_settings(int(s.get("subtitle_size", 15)))))
	var body := _str(s, "body")
	if body != "":
		var body_lbl := LessonBlocks.make_label(body, LessonTheme.body_settings(14))
		body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		text.add_child(body_lbl)

	var cards: Array = s.get("cards", [])
	if not cards.is_empty():
		LessonBlocks.add_cards_row(content, cards)


static func header_and_cards(content: VBoxContainer, title: String, subtitle: String, hint: String, cards: Array) -> void:
	content.add_child(LessonBlocks.make_label(title, LessonTheme.title_settings(24)))
	if subtitle != "":
		content.add_child(LessonBlocks.make_label(subtitle, LessonTheme.subtitle_settings(14)))
	if hint != "":
		content.add_child(LessonBlocks.make_label(hint, LessonTheme.body_settings(12)))
	LessonBlocks.add_cards_row(content, cards)


static func header_body(content: VBoxContainer, title: String, subtitle: String, bodies: Array[String], art_path: String = "") -> void:
	if art_path != "":
		hero_split(content, art_path, title, subtitle, bodies, false, 1.1)
		return
	content.add_child(LessonBlocks.make_label(title, LessonTheme.title_settings(26)))
	if subtitle != "":
		content.add_child(LessonBlocks.make_label(subtitle, LessonTheme.subtitle_settings(15)))
	for body in bodies:
		content.add_child(LessonBlocks.make_label(body, LessonTheme.body_settings(13)))


static func _str(s: Dictionary, key: String) -> String:
	return str(s.get(key, ""))


static func _strings(values: Variant) -> Array[String]:
	var out: Array[String] = []
	if values is Array:
		for v in values:
			out.append(str(v))
	return out
