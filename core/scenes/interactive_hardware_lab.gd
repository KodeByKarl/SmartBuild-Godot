extends Control

signal model_selected(item: Dictionary)

@onready var title_label: Label = $Split/ViewerCard/ViewerMargin/ViewerStack/TitleRow/TitleLabel
@onready var category_label: Label = $Split/ViewerCard/ViewerMargin/ViewerStack/TitleRow/CategoryBadge
@onready var fact_label: RichTextLabel = $Split/ViewerCard/ViewerMargin/ViewerStack/FactLabel
@onready var tip_label: Label = $Split/ViewerCard/ViewerMargin/ViewerStack/TipLabel
@onready var cards_box: VBoxContainer = $Split/LibraryCard/LibraryMargin/LibraryStack/Scroll/Cards
@onready var filter_box: HBoxContainer = $Split/LibraryCard/LibraryMargin/LibraryStack/Filters
@onready var preview_image: TextureRect = $Split/ViewerCard/ViewerMargin/ViewerStack/PreviewFrame/PreviewInner/PreviewImage
@onready var preview_caption: Label = $Split/ViewerCard/ViewerMargin/ViewerStack/PreviewFrame/PreviewInner/PreviewCaption

var items: Array = []
var filtered_items: Array = []
var current_item: Dictionary = {}
var current_filter: String = "All"
var card_buttons: Dictionary = {}
var _split: HBoxContainer = null
var _cards_scroll: ScrollContainer = null


func setup(model_items: Array) -> void:
	_bind_ui()
	items = model_items.duplicate(true)
	_build_filters()
	_apply_filter("All")
	if tip_label != null:
		tip_label.text = "Image catalog · tap a card, then Next"
	# Never leave the preview black — auto-open the first part.
	if not filtered_items.is_empty():
		select_item(filtered_items[0] as Dictionary)
	else:
		if title_label != null:
			title_label.text = "Pick a part"
		if category_label != null:
			category_label.text = "IMAGE LAB"
		if fact_label != null:
			fact_label.text = "[b]Hardware Catalog[/b]\nTap any card to inspect a static image of the part. Live 3D is reserved for simulations."
		if preview_image != null:
			preview_image.texture = null
		if preview_caption != null:
			preview_caption.text = "Select a part from the list"


func shutdown_lab() -> void:
	current_item = {}
	if preview_image != null:
		preview_image.texture = null


func _ready() -> void:
	_bind_ui()
	_prepare_embedded_layout()
	_split = get_node_or_null("Split") as HBoxContainer
	if _split != null:
		_split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if cards_box != null:
		cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _cards_scroll != null:
		_cards_scroll.scroll_deadzone = 24
		_cards_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_responsive_layout()
	if not resized.is_connected(_on_lab_resized):
		resized.connect(_on_lab_resized)
	modulate.a = 1.0
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func _bind_ui() -> void:
	if title_label == null:
		title_label = get_node_or_null("Split/ViewerCard/ViewerMargin/ViewerStack/TitleRow/TitleLabel") as Label
	if category_label == null:
		category_label = get_node_or_null("Split/ViewerCard/ViewerMargin/ViewerStack/TitleRow/CategoryBadge") as Label
	if fact_label == null:
		fact_label = get_node_or_null("Split/ViewerCard/ViewerMargin/ViewerStack/FactLabel") as RichTextLabel
	if tip_label == null:
		tip_label = get_node_or_null("Split/ViewerCard/ViewerMargin/ViewerStack/TipLabel") as Label
	if cards_box == null:
		cards_box = get_node_or_null("Split/LibraryCard/LibraryMargin/LibraryStack/Scroll/Cards") as VBoxContainer
	if filter_box == null:
		filter_box = get_node_or_null("Split/LibraryCard/LibraryMargin/LibraryStack/Filters") as HBoxContainer
	if preview_image == null:
		preview_image = get_node_or_null("Split/ViewerCard/ViewerMargin/ViewerStack/PreviewFrame/PreviewInner/PreviewImage") as TextureRect
	if preview_caption == null:
		preview_caption = get_node_or_null("Split/ViewerCard/ViewerMargin/ViewerStack/PreviewFrame/PreviewInner/PreviewCaption") as Label
	if _cards_scroll == null:
		_cards_scroll = get_node_or_null("Split/LibraryCard/LibraryMargin/LibraryStack/Scroll") as ScrollContainer


func _prepare_embedded_layout() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_END
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	if custom_minimum_size.y < 420.0:
		custom_minimum_size.y = 440.0


func _on_lab_resized() -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if _split == null:
		return
	var narrow: bool = size.x > 0.0 and size.x < 780.0
	var layout_node := get_node_or_null("/root/ResponsiveLayout")
	if layout_node != null and layout_node.has_method("is_phone"):
		narrow = bool(layout_node.call("is_phone")) or size.x < 780.0
	_split.add_theme_constant_override("separation", 10 if narrow else 18)
	var library := _split.get_node_or_null("LibraryCard") as Control
	var viewer := _split.get_node_or_null("ViewerCard") as Control
	if library == null or viewer == null:
		return
	if narrow:
		_split.alignment = BoxContainer.ALIGNMENT_BEGIN
		library.size_flags_stretch_ratio = 1.0
		viewer.size_flags_stretch_ratio = 1.15
	else:
		library.size_flags_stretch_ratio = 0.72
		viewer.size_flags_stretch_ratio = 1.45


func _build_filters() -> void:
	if filter_box == null:
		return
	for child in filter_box.get_children():
		child.queue_free()

	var categories: Array[String] = ["All"]
	for item in items:
		var category: String = str(item.get("category", "Hardware"))
		if not categories.has(category):
			categories.append(category)

	for category in categories:
		var button := Button.new()
		button.text = category
		button.toggle_mode = true
		button.button_pressed = category == current_filter
		button.custom_minimum_size = Vector2(0, 36)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		_style_filter_button(button, category == current_filter)
		button.pressed.connect(_on_filter_pressed.bind(category))
		filter_box.add_child(button)


func _apply_filter(category: String) -> void:
	current_filter = category
	filtered_items.clear()
	for item in items:
		if category == "All" or str(item.get("category", "Hardware")) == category:
			filtered_items.append(item)
	_rebuild_cards()
	_build_filters()


func _rebuild_cards() -> void:
	if cards_box == null:
		return
	for child in cards_box.get_children():
		child.queue_free()
	card_buttons.clear()

	for index in filtered_items.size():
		var item: Dictionary = filtered_items[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 64)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = false
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		var summary := str(item.get("summary", ""))
		if summary.length() > 64:
			summary = summary.substr(0, 61) + "..."
		button.text = "%s\n%s" % [item.get("title", ""), summary]
		_style_card_button(button, false)
		# Bind by index — Dictionary binds were unreliable after filter rebuilds on some devices.
		button.pressed.connect(_on_card_pressed.bind(index))
		cards_box.add_child(button)
		card_buttons[item.get("title", "")] = button


func _on_card_pressed(index: int) -> void:
	if index < 0 or index >= filtered_items.size():
		return
	select_item(filtered_items[index] as Dictionary)


func select_item(item: Dictionary) -> void:
	_bind_ui()
	current_item = item
	if title_label != null:
		title_label.text = str(item.get("title", "Component"))
	if category_label != null:
		category_label.text = str(item.get("category", "Hardware")).to_upper()
	if fact_label != null:
		fact_label.text = "[b]Fun fact[/b]\n%s\n\n[b]Technician tip[/b]\n%s" % [
			item.get("fun_fact", item.get("details", "")),
			item.get("tip", "Handle carefully and follow ESD safety.")
		]
	if tip_label != null:
		tip_label.text = "Static image preview · tap Next to continue"
	if preview_image != null:
		preview_image.texture = PartPreviewImage.texture_for(item)
		preview_image.visible = true
		preview_image.modulate = Color.WHITE
	if preview_caption != null:
		preview_caption.text = str(item.get("title", "Part"))
	_highlight_selected_card(str(item.get("title", "")))
	model_selected.emit(item)
	var motion := get_node_or_null("/root/UiMotion")
	var btn = card_buttons.get(item.get("title", ""), null)
	if motion != null and btn != null and motion.has_method("pulse_button"):
		motion.call("pulse_button", btn)


func _highlight_selected_card(title: String) -> void:
	for key in card_buttons.keys():
		var button: Button = card_buttons[key]
		_style_card_button(button, key == title)


func _on_filter_pressed(category: String) -> void:
	_apply_filter(category)
	if not filtered_items.is_empty():
		select_item(filtered_items[0] as Dictionary)


func _style_card_button(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.65, 0.87, 0.28) if selected else Color(0.004, 0.09, 0.137, 0.85)
	normal.border_color = Color(0.35, 0.85, 1.0, 0.95) if selected else Color(0.95, 0.98, 0.99, 0.12)
	normal.set_border_width_all(2 if selected else 1)
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 0.99, 1))


func _style_filter_button(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.65, 0.87, 1) if selected else Color(0.004, 0.09, 0.137, 0.9)
	normal.border_color = Color(0.35, 0.85, 1.0, 0.9) if selected else Color(0.95, 0.98, 0.99, 0.12)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(18)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_color_override("font_color", Color(0.004, 0.09, 0.14, 1) if selected else Color(0.95, 0.98, 0.99, 0.9))
