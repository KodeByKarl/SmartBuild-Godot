class_name LessonBlocks
extends RefCounted

## Building blocks for lesson pages: the content card, labels, art panels and
## info cards. Layouts in LessonLayouts compose these; pages never build raw
## controls themselves.

## Slide art is already transparent. Cache the imported texture as-is.
static var _art_cache: Dictionary = {}


## Content card: navy background, rounded panel, and an overflow scroll that
## does not block page swipes. Returns the VBox that sections are added to.
static func mount(root: Control, panel_style: StyleBox = null, tight: bool = false) -> VBoxContainer:
	for child in root.get_children():
		child.queue_free()

	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = LessonTheme.NAVY
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Compact margins so title+cards fit phone viewports (panelist: cut slides).
	var outer_x := 6 if tight else 8
	var outer_y := 2 if tight else 4
	outer.add_theme_constant_override("margin_left", outer_x)
	outer.add_theme_constant_override("margin_top", outer_y)
	outer.add_theme_constant_override("margin_right", outer_x)
	outer.add_theme_constant_override("margin_bottom", outer_y)
	root.add_child(outer)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# No outer frame: the info cards are the only containers on the page.
	panel.add_theme_stylebox_override("panel", panel_style if panel_style != null else StyleBoxEmpty.new())
	outer.add_child(panel)

	var inner := MarginContainer.new()
	var inner_x := 8 if tight else 10
	var inner_y := 4 if tight else 8
	inner.add_theme_constant_override("margin_left", inner_x)
	inner.add_theme_constant_override("margin_top", inner_y)
	inner.add_theme_constant_override("margin_right", inner_x)
	inner.add_theme_constant_override("margin_bottom", inner_y)
	panel.add_child(inner)

	# Scroll fallback when cards still overflow on short screens.
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	# Page-level overflow scroll, not a list: page swipes still start here.
	scroll.set_meta("swipe_passthrough", true)
	inner.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 2 if tight else 5)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	# Fill the panel height. Do not set a width floor — that locked the slide
	# wider than the phone and clipped the right edge.
	var fit := func() -> void:
		if scroll.size.y <= 0.0:
			return
		content.custom_minimum_size = Vector2(0, scroll.size.y)
	scroll.resized.connect(fit)
	fit.call_deferred()
	return content


static func make_label(text: String, settings: LabelSettings, expand: bool = true) -> Label:
	var lbl: Label = LessonFitLabel.new()
	lbl.text = text
	lbl.label_settings = settings
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(0, 0)
	if expand:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl


## Body copy with **bold** phrases from Figma. `bold_runs` are substrings of
## `text` drawn in Google Sans Flex Bold.
static func make_rich(text: String, size: int, bold_runs: Array = [], align: int = HORIZONTAL_ALIGNMENT_LEFT) -> RichTextLabel:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := LessonTheme.readable(size)
	rt.add_theme_font_override("normal_font", LessonTheme.load_font(LessonTheme.FONT_BODY))
	rt.add_theme_font_override("bold_font", LessonTheme.load_font(LessonTheme.FONT_CARD))
	rt.add_theme_font_size_override("normal_font_size", fs)
	rt.add_theme_font_size_override("bold_font_size", fs)
	rt.add_theme_color_override("default_color", LessonTheme.FIGMA_TEXT)
	rt.add_theme_constant_override("line_separation", 2)
	# Justify like Figma: full lines only — never stretch a one-line paragraph
	# ("Examples: …", list headings) or the last line of a paragraph.
	rt.justification_flags = (
		TextServer.JUSTIFICATION_KASHIDA
		| TextServer.JUSTIFICATION_WORD_BOUND
		| TextServer.JUSTIFICATION_SKIP_LAST_LINE
	)
	var body := _escape_bbcode(text)
	for run in bold_runs:
		var r := _escape_bbcode(str(run))
		var at := body.find(r)
		if r != "" and at >= 0:
			# First occurrence only, as in the Figma copy.
			body = body.substr(0, at) + "[b]%s[/b]" % r + body.substr(at + r.length())
	match align:
		HORIZONTAL_ALIGNMENT_FILL:
			body = "[fill]%s[/fill]" % body
		HORIZONTAL_ALIGNMENT_CENTER:
			body = "[center]%s[/center]" % body
	rt.text = body
	return rt


static func make_art(path: String, min_h: float = 96.0, _ratio: float = 1.0, expand_v: bool = false) -> Control:
	# Art PNGs are already transparent. A pale well behind them read as a white
	# background that was never cleaned off. Sit the drawing on the dark card.
	var v_flag := Control.SIZE_EXPAND_FILL if expand_v else Control.SIZE_SHRINK_END
	var slot := Control.new()
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.size_flags_vertical = v_flag
	# Width stays 0 so an illustration cannot push the row past the screen edge.
	slot.custom_minimum_size = Vector2(0, min_h)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.clip_contents = true

	var texture := load_art(path)
	if texture == null:
		var missing := Label.new()
		missing.text = "Illustration"
		missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		missing.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		missing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		missing.add_theme_font_size_override("font_size", LessonTheme.readable(14))
		missing.add_theme_color_override("font_color", Color(0.55, 0.78, 0.88, 0.85))
		slot.add_child(missing)
		return slot

	var tex := TextureRect.new()
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture = texture
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(tex)
	return slot


static func make_card(title: String, body: String, accent: bool = false, art_path: String = "", fill_art: bool = true) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0
	card.custom_minimum_size = Vector2(0, 0)
	card.add_theme_stylebox_override("panel", LessonTheme.card_style(accent))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(col)
	col.add_child(make_label(title, LessonTheme.card_title_settings()))
	var body_lbl := make_label(body, LessonTheme.card_body_settings())
	# Leave leftover card height for the illustration when it should fill the gap.
	if not fill_art:
		body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body_lbl)

	if art_path != "":
		# Modest icon slot. A fixed width here used to widen the row until the
		# last card was cut off on the right.
		if fill_art:
			# Grow into the empty card area. Keep the floor modest so a 2×2
			# page still fits; the expand flag is what enlarges the drawing.
			col.add_child(make_art(art_path, 36.0, 1.0, true))
		else:
			col.add_child(make_art(art_path, 58.0, 1.0, false))
	return card


static func add_cards_row(parent: Control, cards: Array, accents: Array = [], fill_art: bool = true) -> void:
	var columns := _columns_for(cards.size())
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 10)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.custom_minimum_size = Vector2(0, 0)
	parent.add_child(wrap)

	var index := 0
	while index < cards.size():
		var row := make_row(10)
		row.size_flags_stretch_ratio = 1.0
		wrap.add_child(row)
		for _col in columns:
			if index >= cards.size():
				break
			row.add_child(_card_from(cards[index], index, accents, fill_art))
			index += 1


## Equal-share row that never widens past its parent (see LessonShareRow).
static func make_row(separation: int, expand_v: bool = true) -> LessonShareRow:
	var row := LessonShareRow.new()
	row.separation = separation
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL if expand_v else Control.SIZE_SHRINK_CENTER
	return row


static func _card_from(entry: Dictionary, index: int, accents: Array, fill_art: bool = true) -> PanelContainer:
	var accent := index < accents.size() and bool(accents[index])
	if accents.is_empty():
		accent = (index % 2) == 1
	return make_card(
		str(entry.get("title", "")),
		str(entry.get("body", "")),
		accent,
		str(entry.get("art", "")),
		fill_art
	)


## Four cards across were clipped on the right of the phones in the review.
## Two rows of two stay even and fully on screen.
static func _columns_for(count: int) -> int:
	if count >= 4:
		return 2
	return count


static func load_art(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _art_cache.has(path):
		return _art_cache[path] as Texture2D
	if not ResourceLoader.exists(path):
		var alt := path.replace("-", "_")
		if alt != path and ResourceLoader.exists(alt):
			path = alt
		else:
			return null

	# Prefer ResourceLoader — Image.load(res://) is unreliable on exported Android.
	# Do not flatten or recolor: the PNGs already have a transparent background.
	var loaded := load(path) as Texture2D
	if loaded == null:
		return null
	_art_cache[path] = loaded
	return loaded


static func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")
