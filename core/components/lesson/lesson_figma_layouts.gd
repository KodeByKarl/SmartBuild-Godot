class_name LessonFigmaLayouts
extends RefCounted

## Figma SMARTBUILD page layouts for Modules 1–4. Every lesson page in those
## modules is one of these, filled from data:
##
##   figma_hero       big title + body (bold phrases, bullets) beside an illustration
##   figma_cards      title/subtitle + 2–4 step cards (title, divider, body, art, check badge)
##   figma_checklist  title/subtitle + tappable rows that turn green when checked
##   figma_wide       title/subtitle + one wide inner card (diagram, flow line or text)
##   figma_split      left info card + right illustration or numbered list card
##   be_ready         "Be Ready for Assessment!" bridge before the graded simulation
##   external_lab     hand-off card that starts a simulation hosted outside Godot
##   completion       Congratulations card + Proceed to Home / Retake Module
##
## Interactive sections report through the page root (LessonPage.emit_action).

const TITLE_SIZE := 24
const HERO_TITLE_SIZE := 32
const SUBTITLE_SIZE := 10
const CARD_TITLE_SIZE := 13
const CARD_BODY_SIZE := 12


static func render(content: VBoxContainer, s: Dictionary, page_root: Control = null) -> void:
	match str(s.get("layout", "")):
		"figma_hero":
			hero(content, s)
		"figma_cards":
			cards(content, s)
		"figma_checklist":
			checklist(content, s, page_root)
		"figma_wide":
			wide(content, s)
		"figma_split":
			split(content, s)
		"be_ready":
			be_ready(content, s)
		"external_lab":
			external_lab(content, s, page_root)
		"completion":
			completion(content, s, page_root)
		_:
			push_warning("LessonFigmaLayouts: unknown layout '%s'" % str(s.get("layout", "")))
			content.add_child(_title(str(s.get("title", "")), TITLE_SIZE))


# --- Shared pieces -------------------------------------------------------------

static func _title(text: String, size: int = TITLE_SIZE) -> Label:
	return LessonBlocks.make_label(text, LessonTheme.figma_text(size, true, 1))


static func _subtitle(text: String) -> Label:
	var ls := LessonTheme.figma_text(SUBTITLE_SIZE, false, 1)
	ls.font_color = Color(LessonTheme.FIGMA_TEXT, 0.88)
	return LessonBlocks.make_label(text, ls)


## Title + optional subtitle block used at the top of most Figma pages.
static func _header(content: VBoxContainer, s: Dictionary) -> void:
	var title := str(s.get("title", ""))
	if title != "":
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(box)
		box.add_child(_title(title, int(s.get("title_size", TITLE_SIZE))))
		var subtitle := str(s.get("subtitle", ""))
		if subtitle != "":
			box.add_child(_subtitle(subtitle))


static func _divider() -> Control:
	var line := ColorRect.new()
	line.color = Color(LessonTheme.FIGMA_TEXT, 0.55)
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


static func _card(done: bool = false) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", LessonTheme.figma_card_style(done))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


static func _bullets_text(items: Array) -> String:
	var lines: PackedStringArray = []
	for item in items:
		lines.append("•  %s" % str(item))
	return "\n".join(lines)


## Round check badge (Figma Rectangle 173/175 + check icon).
static func _badge(done: bool, size: float = 38.0) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(size, size)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring := TextureRect.new()
	ring.texture = LessonTheme.load_texture(LessonTheme.ICON_BADGE_ON if done else LessonTheme.ICON_BADGE_OFF)
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(ring)
	var tick := TextureRect.new()
	tick.texture = LessonTheme.load_texture(LessonTheme.ICON_CHECK)
	tick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tick.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset := size * 0.2
	tick.offset_left = inset
	tick.offset_top = inset
	tick.offset_right = -inset
	tick.offset_bottom = -inset
	tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(tick)
	return holder


static func _padded(child: Control, left: int, right: int, top: int = 0, bottom: int = 0, expand_v: bool = true) -> MarginContainer:
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL if expand_v else Control.SIZE_SHRINK_CENTER
	pad.add_theme_constant_override("margin_left", left)
	pad.add_theme_constant_override("margin_right", right)
	pad.add_theme_constant_override("margin_top", top)
	pad.add_theme_constant_override("margin_bottom", bottom)
	pad.add_child(child)
	return pad


# --- figma_hero ----------------------------------------------------------------

## {title, body, bold:[...], bullets:[...], body_after:"", art, art_side:"right"|"left",
##  art_ratio (0.45), body_size (15), title_size (32)}
static func hero(content: VBoxContainer, s: Dictionary) -> void:
	var row := LessonBlocks.make_row(20)
	content.add_child(_padded(row, 6, 6, 2, 2))

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 10)
	text.size_flags_stretch_ratio = 1.0 - float(s.get("art_ratio", 0.45))
	text.add_child(_title(str(s.get("title", "")), int(s.get("title_size", HERO_TITLE_SIZE))))
	var body_size := int(s.get("body_size", 15))
	var bold: Array = s.get("bold", [])
	var body := str(s.get("body", ""))
	if body != "":
		text.add_child(LessonBlocks.make_rich(body, body_size, bold, HORIZONTAL_ALIGNMENT_FILL))
	var bullets: Array = s.get("bullets", [])
	if not bullets.is_empty():
		text.add_child(LessonBlocks.make_rich(_bullets_text(bullets), body_size, bold))
	var after := str(s.get("body_after", ""))
	if after != "":
		text.add_child(LessonBlocks.make_rich(after, body_size, bold, HORIZONTAL_ALIGNMENT_FILL))

	var art := LessonBlocks.make_art(str(s.get("art", "")), 64.0, 1.4, true)
	art.size_flags_stretch_ratio = float(s.get("art_ratio", 0.45))

	if str(s.get("art_side", "right")) == "left":
		row.add_child(art)
		row.add_child(text)
	else:
		row.add_child(text)
		row.add_child(art)


# --- figma_cards ---------------------------------------------------------------

## {title, subtitle, cards:[{title, body, bullets, art, art_side, done, check}],
##  body_align: "center"|"fill", badges: bool}
static func cards(content: VBoxContainer, s: Dictionary) -> void:
	_header(content, s)
	var list: Array = s.get("cards", [])
	var with_badges := bool(s.get("badges", false))
	# "stack": cards one above the other, each full width (long copy + side art).
	var stacked := bool(s.get("stack", false))
	var row: Container
	if stacked:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row = col
	else:
		row = LessonBlocks.make_row(8)
	content.add_child(row)
	# Only rows with no images at all grow their text to fill the cards.
	var text_row := true
	for entry_variant in list:
		if str((entry_variant as Dictionary).get("art", "")) != "":
			text_row = false
	var align := HORIZONTAL_ALIGNMENT_FILL if str(s.get("body_align", "center")) == "fill" else HORIZONTAL_ALIGNMENT_CENTER
	var titles: Array[Label] = []
	for entry_variant in list:
		var entry: Dictionary = entry_variant as Dictionary
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", -14 if with_badges else 0)
		row.add_child(column)
		var step_card := _step_card(entry, align, int(s.get("card_title_size", CARD_TITLE_SIZE)), int(s.get("card_body_size", CARD_BODY_SIZE)), row if text_row else null)
		column.add_child(step_card)
		if not stacked:
			titles.append(step_card.get_meta("title_label") as Label)
		if with_badges:
			var badge_row := CenterContainer.new()
			badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge_row.add_child(_badge(bool(entry.get("done", false))))
			column.add_child(badge_row)
	if titles.size() > 1:
		_equalize_title_heights.call_deferred(titles)


## Cards side by side wrap titles to different line counts, which pushes their
## dividers and body text out of line. Give every title the tallest height.
static func _equalize_title_heights(titles: Array[Label]) -> void:
	if titles.is_empty() or not is_instance_valid(titles[0]) or not titles[0].is_inside_tree():
		return
	var tree := titles[0].get_tree()
	# Clear any earlier floor, then wait until the row has its real width so the
	# wrapped height is measured at that width (not at a one-letter-wide column).
	for t in titles:
		if is_instance_valid(t):
			t.custom_minimum_size.y = 0.0
	await tree.process_frame
	await tree.process_frame
	var tallest := 0.0
	for t in titles:
		if is_instance_valid(t) and t.size.x >= 48.0:
			tallest = maxf(tallest, t.get_combined_minimum_size().y)
	for t in titles:
		if is_instance_valid(t):
			t.custom_minimum_size.y = tallest


static func _spacer() -> Control:
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


static func _step_card(entry: Dictionary, align: int, title_size: int, body_size: int, fit_row: Node = null) -> PanelContainer:
	var card := _card(bool(entry.get("done", false)))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Text-only cards: the text grows to fill the card (LessonTextFit) and the
	# block stays centred, so there is no dead space under a few small lines.
	var text_only := str(entry.get("art", "")) == ""
	if text_only:
		col.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(col)
	if text_only and fit_row != null:
		LessonTextFit.attach(card, col, fit_row)

	var title := LessonBlocks.make_label(str(entry.get("title", "")), LessonTheme.figma_text(title_size, true))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.set_meta("title_label", title)
	col.add_child(title)
	if not bool(entry.get("no_divider", false)):
		col.add_child(_divider())

	var body_box: Container = col
	var art_path := str(entry.get("art", ""))
	if art_path != "" and str(entry.get("art_side", "bottom")) == "right":
		var inner := LessonBlocks.make_row(10)
		col.add_child(inner)
		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.size_flags_stretch_ratio = 1.1
		inner.add_child(text_col)
		body_box = text_col
		_card_body(body_box, entry, HORIZONTAL_ALIGNMENT_FILL, body_size)
		var side_art := LessonBlocks.make_art(art_path, 40.0, 1.0, true)
		side_art.size_flags_stretch_ratio = 0.9
		inner.add_child(side_art)
		return card

	_card_body(body_box, entry, align, body_size)
	if art_path != "":
		col.add_child(LessonBlocks.make_art(art_path, 36.0, 1.0, true))
	return card


static func _card_body(box: Container, entry: Dictionary, align: int, body_size: int) -> void:
	var body := str(entry.get("body", ""))
	if body != "":
		box.add_child(LessonBlocks.make_rich(body, body_size, entry.get("bold", []), align))
	var bullets: Array = entry.get("bullets", [])
	if not bullets.is_empty():
		box.add_child(LessonBlocks.make_rich(_bullets_text(bullets), body_size, []))
	var subhead := str(entry.get("subhead", ""))
	if subhead != "":
		box.add_child(_divider())
		box.add_child(LessonBlocks.make_label(subhead, LessonTheme.figma_text(int(entry.get("subhead_size", 16)), true)))
	var sub_bullets: Array = entry.get("sub_bullets", [])
	if not sub_bullets.is_empty():
		box.add_child(LessonBlocks.make_rich(_bullets_text(sub_bullets), body_size, []))


# --- figma_checklist -------------------------------------------------------------

## {title, subtitle, items:[...]}. Tapping a row toggles it green (Figma 19:4).
## An item is a String or {title, body, art} (art = small thumbnail at the left).
## Reports LessonPage action "checklist" with {index, checked, all_checked}.
static func checklist(content: VBoxContainer, s: Dictionary, page_root: Control) -> void:
	_header(content, s)
	var outer := _card()
	outer.add_theme_stylebox_override("panel", LessonTheme.figma_card_style())
	content.add_child(outer)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(rows)

	var items: Array = s.get("items", [])
	var states: Array = []
	for i in items.size():
		states.append(false)
	for i in items.size():
		var item: Variant = items[i]
		var item_title := str((item as Dictionary).get("title", "")) if item is Dictionary else str(item)
		var item_body := str((item as Dictionary).get("body", "")) if item is Dictionary else ""
		var item_art := str((item as Dictionary).get("art", "")) if item is Dictionary else ""
		# The row is a container so it grows with wrapped text; a transparent
		# button over it takes the tap.
		var row := PanelContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 68)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_stylebox_override("panel", LessonTheme.checklist_row_style(false))
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 12)
		row_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(row_box)
		var badge := _badge(false, 48.0)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row_box.add_child(badge)
		if item_art != "":
			var thumb := TextureRect.new()
			thumb.texture = LessonTheme.load_texture(item_art)
			thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			thumb.custom_minimum_size = Vector2(80, 60)
			thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row_box.add_child(thumb)
		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text_col.add_theme_constant_override("separation", 0)
		text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_box.add_child(text_col)
		var label := LessonBlocks.make_label(item_title, LessonTheme.figma_text(18, true))
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_col.add_child(label)
		if item_body != "":
			var detail := LessonBlocks.make_label(item_body, LessonTheme.figma_text(13, false))
			detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_col.add_child(detail)

		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hit.set_meta("no_swipe", true)
		for state in ["normal", "hover", "pressed", "focus"]:
			hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		row.add_child(hit)
		# PanelContainer fits every child to its rect; keep the button out of
		# the size calculation by letting it fill whatever the row ends up as.
		hit.size_flags_horizontal = Control.SIZE_FILL
		hit.size_flags_vertical = Control.SIZE_FILL

		var index := i
		hit.pressed.connect(func() -> void:
			states[index] = not bool(states[index])
			row.add_theme_stylebox_override("panel", LessonTheme.checklist_row_style(bool(states[index])))
			_swap_badge(badge, bool(states[index]))
			if page_root != null and page_root.has_method("emit_action"):
				page_root.emit_action("checklist", {"index": index, "checked": states[index], "all_checked": not states.has(false)})
		)
		rows.add_child(row)


static func _swap_badge(holder: Control, done: bool) -> void:
	var ring := holder.get_child(0) as TextureRect
	if ring != null:
		ring.texture = LessonTheme.load_texture(LessonTheme.ICON_BADGE_ON if done else LessonTheme.ICON_BADGE_OFF)


# --- figma_wide ------------------------------------------------------------------

## {title, subtitle, inner_title, body, art, flow, art_height}
static func wide(content: VBoxContainer, s: Dictionary) -> void:
	_header(content, s)
	var card := _card()
	content.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(col)
	var inner_title := str(s.get("inner_title", ""))
	if inner_title != "":
		var t := _title(inner_title, 24)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(t)
		col.add_child(_padded(_divider(), 48, 48, 0, 0, false))
	var body := str(s.get("body", ""))
	if body != "":
		col.add_child(_padded(LessonBlocks.make_rich(body, 12, s.get("bold", []), HORIZONTAL_ALIGNMENT_CENTER), 80, 80, 0, 0, false))
	var flow := str(s.get("flow", ""))
	if flow != "":
		var f := LessonBlocks.make_label(flow, LessonTheme.figma_text(24, false))
		f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(f)
	var art := str(s.get("art", ""))
	if art != "":
		col.add_child(LessonBlocks.make_art(art, float(s.get("art_height", 80.0)), 1.0, true))


# --- figma_split -----------------------------------------------------------------

## Left info card + right side. {title, left:{title, body}, right_art, right:{heading, columns:[[...],[...]]},
##  left_ratio (0.3)}
static func split(content: VBoxContainer, s: Dictionary) -> void:
	_header(content, s)
	var row := LessonBlocks.make_row(12)
	content.add_child(row)
	var left: Dictionary = s.get("left", {})
	var left_card := _step_card(left, HORIZONTAL_ALIGNMENT_CENTER, int(left.get("title_size", 16)), int(left.get("body_size", 14)))
	left_card.size_flags_stretch_ratio = float(s.get("left_ratio", 0.3))
	row.add_child(left_card)

	var right_art := str(s.get("right_art", ""))
	if right_art != "":
		var art := LessonBlocks.make_art(right_art, 80.0, 1.0, true)
		art.size_flags_stretch_ratio = 1.0 - float(s.get("left_ratio", 0.3))
		row.add_child(art)
		return
	var right: Dictionary = s.get("right", {})
	var right_card := _card()
	right_card.size_flags_stretch_ratio = 1.0 - float(s.get("left_ratio", 0.3))
	row.add_child(right_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	right_card.add_child(col)
	var heading := LessonBlocks.make_label(str(right.get("heading", "")), LessonTheme.figma_text(14, true))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)
	var columns := LessonBlocks.make_row(16)
	col.add_child(columns)
	for list_variant in right.get("columns", []):
		var lines: PackedStringArray = []
		for item in (list_variant as Array):
			lines.append(str(item))
		columns.add_child(LessonBlocks.make_rich("\n".join(lines), 12, []))


# --- be_ready --------------------------------------------------------------------

const BE_READY_BODY := "Now that you’ve finished the guided simulation, you will now perform the simulation without hints or guides. Take a breath, then continue when you are ready."
const BE_READY_BODY_2 := "Pay close attention to each step, complete the required actions carefully, and apply what you have learned throughout the simulation."


## Figma 58:3 "Be Ready for Assessment!" — same copy in every module.
static func be_ready(content: VBoxContainer, s: Dictionary) -> void:
	hero(content, {
		"title": str(s.get("title", "Be Ready for Assessment!")),
		"title_size": 36,
		"body": str(s.get("body", BE_READY_BODY)),
		"body_after": str(s.get("body_after", BE_READY_BODY_2)),
		"bold": ["without hints or guides"],
		"body_size": 14,
		"art": str(s.get("art", "")),
		"art_ratio": 0.42,
	})
	var hint := str(s.get("hint", ""))
	if hint != "":
		var l := LessonBlocks.make_label(hint, LessonTheme.figma_text(12, true))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.label_settings.font_color = LessonTheme.FIGMA_DONE_BORDER
		content.add_child(_padded(l, 8, 16, 0, 0, false))


# --- external_lab ------------------------------------------------------------------

## Hand-off to a simulation that runs outside Godot (Modules 2–4 Compose labs).
## {title, body, art, button, action}
static func external_lab(content: VBoxContainer, s: Dictionary, page_root: Control) -> void:
	hero(content, {
		"title": str(s.get("title", "Guided Simulation")),
		"body": str(s.get("body", "")),
		"bold": s.get("bold", []),
		"art": str(s.get("art", "")),
		"art_ratio": 0.42,
	})
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_END
	content.add_child(_padded(bar, 8, 16, 0, 10, false))
	var start := _pill(str(s.get("button", "Start Guided Simulation")), true)
	start.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	start.set_meta("no_swipe", true)
	start.pressed.connect(func() -> void:
		if page_root != null and page_root.has_method("emit_action"):
			page_root.emit_action(str(s.get("action", "start_lab")), null)
	)
	bar.add_child(start)


# --- completion ------------------------------------------------------------------

## Figma 1:1679. {title, subtitle, topics:[...], proceed_label, retake_label}
## Emits "proceed_home" and "retake" through the page root.
static func completion(content: VBoxContainer, s: Dictionary, page_root: Control) -> void:
	var row := LessonBlocks.make_row(48)
	content.add_child(_padded(row, 24, 40, 8, 8))

	var card := _card()
	card.size_flags_stretch_ratio = 0.95
	row.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	col.add_child(top)
	var badge := _badge(true, 52.0)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(badge)
	var heads := VBoxContainer.new()
	heads.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heads.add_theme_constant_override("separation", 2)
	top.add_child(heads)
	heads.add_child(LessonBlocks.make_label(str(s.get("title", "Congratulations!")), LessonTheme.figma_text(22, true, 1)))
	heads.add_child(LessonBlocks.make_label(str(s.get("subtitle", "")), LessonTheme.figma_text(16, true, 1)))

	# Topics spread evenly over the space between the heading and the 100% bar.
	var topics := VBoxContainer.new()
	topics.add_theme_constant_override("separation", 0)
	topics.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_padded(topics, 64, 0))
	topics.add_child(_spacer())
	for topic in s.get("topics", []):
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 14)
		topics.add_child(line)
		topics.add_child(_spacer())
		var dot := _badge(true, 28.0)
		var ring := dot.get_child(0) as TextureRect
		ring.texture = LessonTheme.load_texture(LessonTheme.ICON_DONE_DOT)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(dot)
		line.add_child(LessonBlocks.make_label(str(topic), LessonTheme.figma_text(19, false, 1)))

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 12)
	col.add_child(progress_row)
	var pct := Label.new()
	pct.text = "100%"
	pct.label_settings = LessonTheme.figma_text(24, true, 1)
	pct.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress_row.add_child(pct)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.value = 100
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(0, 22)
	var fill := StyleBoxFlat.new()
	fill.bg_color = LessonTheme.FIGMA_BAR
	fill.set_corner_radius_all(19)
	var track := StyleBoxFlat.new()
	track.bg_color = LessonTheme.FIGMA_BAR_TRACK
	track.set_corner_radius_all(19)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", track)
	progress_row.add_child(bar)

	var actions := VBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 40)
	actions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions.size_flags_stretch_ratio = 0.8
	row.add_child(actions)
	var proceed := _pill(str(s.get("proceed_label", "Proceed to Home")), true)
	var retake := _pill(str(s.get("retake_label", "Retake Module")), false)
	for b in [proceed, retake]:
		(b as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		(b as Button).set_meta("no_swipe", true)
		actions.add_child(b)
	proceed.pressed.connect(func() -> void:
		if page_root != null and page_root.has_method("emit_action"):
			page_root.emit_action("proceed_home", null)
	)
	retake.pressed.connect(func() -> void:
		if page_root != null and page_root.has_method("emit_action"):
			page_root.emit_action("retake", null)
	)


static func _pill(text: String, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(320, 56)
	var normal := LessonTheme.pill_style(
		LessonTheme.FIGMA_PROCEED if primary else LessonTheme.FIGMA_RETAKE,
		Color.WHITE if primary else LessonTheme.FIGMA_RETAKE_BORDER
	)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = hover.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_font_override("font", LessonTheme.tracked_font(LessonTheme.FONT_CARD, 1))
	btn.add_theme_font_size_override("font_size", LessonTheme.readable(20))
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		btn.add_theme_color_override(key, LessonTheme.FIGMA_TEXT)
	return btn
