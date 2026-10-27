class_name LessonDeck
extends Control

## Swipeable lesson deck: Figma header (Back / module title / Help), one page
## at a time in a TouchSwipePager, and a small page indicator underneath.
##
## A module supplies data, not scenes: set `module_title` and `pages` before
## the deck enters the tree (or call `set_pages()` later). Each page entry is
## either a LessonLayouts page Dictionary or {"scene": "res://…tscn"} for a
## bespoke page. Subclasses override the `_on_*` hooks for progress, Back,
## and page actions.

signal page_changed(index: int)

var module_id := -1
var module_title := ""
## Word used in Help ("slide" for Module 0, "page" elsewhere).
var page_noun := "page"
var pages: Array = []
var current_index := 0
var current_page: Control = null

var _page_nodes: Dictionary = {}
var _scene_cache: Dictionary = {}
var _loading_label: Label = null
var _help_overlay: Control = null
var _help_body: RichTextLabel = null

@onready var page_scroll: ScrollContainer = $Wrapper/Presentation/PageScroll
## Swipe pager: pages follow the finger and snap to the next / previous one.
@onready var content: TouchSwipePager = $Wrapper/Presentation/PageScroll/Content
@onready var module_label: Label = $Wrapper/Header/ModuleLabel
@onready var phase_label: Label = $Wrapper/Header/PhaseLabel
@onready var help_btn: Button = $Wrapper/Header/HelpButton
@onready var exit_btn: Button = $Wrapper/Header/ExitButton
@onready var page_indicator: LessonPageIndicator = $Wrapper/Navigation/PageNumberLabel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	LessonTheme.ensure_mode_loaded()
	_apply_background()
	LessonHeader.style(exit_btn, module_label, help_btn, module_title)
	_style_frame()
	content.neighbor_provider = _neighbor_page
	content.page_committed.connect(_on_swipe_committed)
	exit_btn.pressed.connect(_on_back_pressed)
	help_btn.pressed.connect(_toggle_help)
	page_scroll.resized.connect(_sync_page_min_height)
	if not get_viewport().size_changed.is_connected(_apply_shell_insets):
		get_viewport().size_changed.connect(_apply_shell_insets)
	_sync_page_min_height()
	_apply_shell_insets()
	if not pages.is_empty():
		show_page(current_index)


func _apply_background() -> void:
	var bg := get_node_or_null("Background") as ColorRect
	if bg != null:
		bg.color = LessonTheme.NAVY


## Repaint an already-loaded module after Android changes the app-wide theme.
## Godot stays alive behind Compose, so _ready() is not called again when the
## learner returns to the dashboard and opens the same module in another mode.
func refresh_theme() -> void:
	if not is_node_ready():
		return
	_apply_background()
	LessonHeader.style(exit_btn, module_label, help_btn, module_title)
	if phase_label != null:
		phase_label.add_theme_color_override("font_color", LessonTheme.FIGMA_TEXT)
	if page_indicator != null:
		page_indicator.refresh_theme()
	if _help_overlay != null and is_instance_valid(_help_overlay):
		_help_overlay.queue_free()
		_help_overlay = null
		_help_body = null
	for node in _page_nodes.values():
		if node != null and is_instance_valid(node):
			(node as Node).queue_free()
	_page_nodes.clear()
	current_page = null
	content.set_current(null)
	show_page(current_index)


func set_pages(new_pages: Array, start_index: int = 0) -> void:
	for node in _page_nodes.values():
		if node != null and is_instance_valid(node):
			(node as Node).queue_free()
	_page_nodes.clear()
	pages = new_pages
	current_index = clampi(start_index, 0, maxi(pages.size() - 1, 0))
	if is_inside_tree() and is_node_ready():
		show_page(current_index)


func page_count() -> int:
	return pages.size()


func show_page(index: int) -> void:
	current_index = clampi(index, 0, maxi(page_count() - 1, 0))
	_hide_current_page()
	if page_scroll != null:
		page_scroll.scroll_vertical = 0
	_apply_page_chrome()
	_update_indicator(current_index)
	_update_phase_chip()
	_update_nav_state()

	var page := _get_or_make_page(current_index)
	if page == null:
		if _loading_label == null or not is_instance_valid(_loading_label):
			_loading_label = Label.new()
			_loading_label.text = "Loading…"
			_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_loading_label.add_theme_font_size_override("font_size", LessonTheme.readable(16))
			content.add_child(_loading_label)
		_loading_label.visible = true
		call_deferred("_retry_page_if_needed")
		call_deferred("_prewarm_neighbors")
		return
	_show_page_node(page)
	call_deferred("_prewarm_neighbors")


## Re-evaluates swipe bounds (e.g. after a checklist unlocks the next page).
func refresh_navigation() -> void:
	_update_nav_state()


# --- Hooks for modules --------------------------------------------------------

## Called each time a page becomes the visible page.
func _on_page_shown(_index: int) -> void:
	pass


## Lets a module supply its own node for a page entry (e.g. a simulation).
## Return null to use the default LessonPage / scene handling.
func _make_custom_page(_index: int, _entry: Variant) -> Control:
	return null


func _update_indicator(index: int) -> void:
	page_indicator.show_position(index, page_count())


## Neighbour pages are built ahead of time for smooth swipes; heavy pages
## (3D simulations) can opt out and build only when reached.
func _should_prewarm(_index: int) -> bool:
	return true


## Immersive pages (full-screen simulations) hide the header and indicator and
## drop the frame margins so the page owns the whole screen.
func _is_immersive(index: int) -> bool:
	if index >= 0 and index < page_count() and pages[index] is Dictionary:
		return bool((pages[index] as Dictionary).get("immersive", false))
	return false


## Called once per page node after it is created (connect bespoke signals here).
func _on_page_created(_index: int, _node: Control) -> void:
	pass


## LessonPage sections report interactions (checklist ticks, completion buttons).
func _on_page_action(_index: int, _action_name: String, _payload: Variant) -> void:
	pass


func _on_back_pressed() -> void:
	send_host_event("destroy")


func _can_swipe_forward(index: int) -> bool:
	return index < page_count() - 1


func _can_swipe_back(index: int) -> bool:
	return index > 0


func _help_for(index: int) -> Dictionary:
	if index >= 0 and index < page_count() and pages[index] is Dictionary:
		var help: Variant = (pages[index] as Dictionary).get("help", {})
		if help is Dictionary and not (help as Dictionary).is_empty():
			return help
	return {"title": "%s help" % module_title, "body": "Swipe left for the next %s, right to go back." % page_noun}


func send_host_event(event_name: String, percent: float = -1.0) -> void:
	var host: Node = get_parent()
	while host != null and not host.has_method("send_event"):
		host = host.get_parent()
	if host == null:
		# Standalone (editor / tests): leaving events close the deck itself.
		if event_name in ["destroy", "assessment_completed", "guided_completed"]:
			queue_free()
		return
	if percent >= 0.0:
		host.send_event(event_name, module_id, percent)
	else:
		host.send_event(event_name, module_id)


# --- Layout -------------------------------------------------------------------

## Pages are authored to fill the screen, but taller ones were being clipped
## with no way to reach the bottom. Floor the page at the visible height so it
## still fills when it fits, and lets the scroll take over when it does not.
func _sync_page_min_height() -> void:
	if content == null or page_scroll == null:
		return
	var visible_h: float = page_scroll.size.y
	if visible_h < 64.0:
		return
	content.custom_minimum_size.y = visible_h


func _style_frame() -> void:
	var navigation := get_node_or_null("Wrapper/Navigation") as Control
	if navigation != null:
		navigation.custom_minimum_size = Vector2(0, 40)
	var presentation := $Wrapper/Presentation as MarginContainer
	if presentation != null:
		presentation.add_theme_constant_override("margin_left", 8)
		presentation.add_theme_constant_override("margin_top", 4)
		presentation.add_theme_constant_override("margin_right", 8)
		presentation.add_theme_constant_override("margin_bottom", 4)


## Keep chrome off the rounded corners and the landscape nav/cutout.
## The right inset used to stop at 18px, so card rows ran under the screen edge.
func _apply_shell_insets() -> void:
	var wrapper := $Wrapper as Control
	if wrapper == null:
		return
	if _is_immersive(current_index):
		return
	var left := 16.0
	var right := 20.0
	var top := 10.0
	var bottom := 16.0
	var win := Vector2(DisplayServer.window_get_size())
	var vp := get_viewport().get_visible_rect().size
	if win.x > 1.0 and win.y > 1.0 and vp.x > 1.0 and vp.y > 1.0:
		var safe := DisplayServer.get_display_safe_area()
		var sx := vp.x / win.x
		var sy := vp.y / win.y
		left = maxf(left, float(safe.position.x) * sx)
		right = maxf(right, float(win.x - safe.position.x - safe.size.x) * sx)
		top = maxf(top, float(safe.position.y) * sy)
		bottom = maxf(bottom, float(win.y - safe.position.y - safe.size.y) * sy)
	wrapper.offset_left = clampf(left, 12.0, 48.0)
	wrapper.offset_right = -clampf(right, 16.0, 56.0)
	wrapper.offset_top = clampf(top, 8.0, 40.0)
	wrapper.offset_bottom = -clampf(bottom, 12.0, 48.0)


func _apply_page_chrome() -> void:
	var immersive := _is_immersive(current_index)
	var header := get_node_or_null("Wrapper/Header") as Control
	var navigation := get_node_or_null("Wrapper/Navigation") as Control
	var presentation := get_node_or_null("Wrapper/Presentation") as MarginContainer
	var wrapper := get_node_or_null("Wrapper") as Control
	if header != null:
		header.visible = not immersive
	if navigation != null:
		navigation.visible = not immersive
	if presentation != null:
		var m := 0 if immersive else 8
		presentation.add_theme_constant_override("margin_left", m)
		presentation.add_theme_constant_override("margin_right", m)
		presentation.add_theme_constant_override("margin_top", 0 if immersive else 4)
		presentation.add_theme_constant_override("margin_bottom", 0 if immersive else 4)
	if wrapper != null:
		if immersive:
			wrapper.offset_left = 0
			wrapper.offset_right = 0
			wrapper.offset_top = 0
			wrapper.offset_bottom = 0
		else:
			_apply_shell_insets()


func _update_phase_chip() -> void:
	if phase_label == null:
		return
	var phase := ""
	if current_index < page_count() and pages[current_index] is Dictionary:
		phase = str((pages[current_index] as Dictionary).get("phase", ""))
	phase_label.text = phase
	phase_label.visible = phase != ""


func _update_nav_state() -> void:
	content.has_prev = _can_swipe_back(current_index)
	content.has_next = _can_swipe_forward(current_index)


# --- Pages --------------------------------------------------------------------

func _page_scene_path(index: int) -> String:
	if index < 0 or index >= page_count():
		return ""
	var entry: Variant = pages[index]
	if entry is Dictionary:
		return str((entry as Dictionary).get("scene", ""))
	return ""


func _packed_scene(path: String, allow_sync: bool) -> PackedScene:
	if _scene_cache.has(path):
		return _scene_cache[path] as PackedScene
	if ResourceWarmup != null and ResourceWarmup.has_method("get_packed"):
		var warmed: PackedScene = ResourceWarmup.get_packed(path)
		if warmed != null:
			_scene_cache[path] = warmed
			return warmed
		if not allow_sync:
			if ResourceWarmup.has_method("prefetch"):
				ResourceWarmup.prefetch(path)
			return null
	var packed := load(path) as PackedScene
	if packed != null:
		_scene_cache[path] = packed
	else:
		push_error("LessonDeck failed to load page scene: %s" % path)
	return packed


func _get_or_make_page(index: int, allow_sync: bool = false) -> Control:
	if index < 0 or index >= page_count():
		return null
	if _page_nodes.has(index):
		var existing: Control = _page_nodes[index] as Control
		if existing != null and is_instance_valid(existing):
			return existing
		_page_nodes.erase(index)

	var node: Control = _make_custom_page(index, pages[index])
	var scene_path := _page_scene_path(index)
	if node != null:
		pass
	elif scene_path != "":
		var packed := _packed_scene(scene_path, allow_sync)
		if packed == null:
			return null
		node = packed.instantiate() as Control
	else:
		var lesson_page := LessonPage.create(pages[index] as Dictionary)
		lesson_page.action.connect(func(action_name: String, payload: Variant) -> void:
			_on_page_action(index, action_name, payload)
		)
		node = lesson_page
	if node == null:
		return null
	node.visible = false
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.modulate.a = 1.0
	content.add_child(node)
	_page_nodes[index] = node
	_on_page_created(index, node)
	return node


func _hide_current_page() -> void:
	if current_page != null and is_instance_valid(current_page):
		current_page.visible = false
	current_page = null
	# Recentre the pager so a "Loading…" placeholder is not left off-screen.
	content.set_current(null)
	if _loading_label != null and is_instance_valid(_loading_label):
		_loading_label.visible = false


func _show_page_node(page: Control) -> void:
	current_page = page
	current_page.visible = true
	current_page.modulate.a = 1.0
	content.set_current(page)
	if _loading_label != null and is_instance_valid(_loading_label):
		_loading_label.visible = false
	_refresh_help_context()
	_on_page_shown(current_index)
	page_changed.emit(current_index)


func _retry_page_if_needed() -> void:
	if current_page != null and is_instance_valid(current_page) and current_page.visible:
		return
	var page := _get_or_make_page(current_index)
	if page == null:
		call_deferred("_retry_page_if_needed")
		return
	_show_page_node(page)


func _evict_far_pages() -> void:
	for key in _page_nodes.keys():
		var index: int = int(key)
		if absi(index - current_index) > 2:
			var node: Control = _page_nodes[index] as Control
			_page_nodes.erase(index)
			if node != null and is_instance_valid(node):
				node.queue_free()


func _prewarm_neighbors() -> void:
	for offset in [1, 2, -1]:
		var index: int = current_index + offset
		if index >= 0 and index < page_count() and not _page_nodes.has(index) and _should_prewarm(index):
			_get_or_make_page(index)
			await get_tree().process_frame
			if not is_instance_valid(self):
				return
	_evict_far_pages()


## Pager asks for the page it should slide in beside the current one.
func _neighbor_page(direction: int) -> Control:
	var index: int = current_index + direction
	if index < 0 or index >= page_count():
		return null
	# The finger is already moving, so load now rather than letting the swipe
	# bounce back while a warmup finishes.
	return _get_or_make_page(index, true)


func _on_swipe_committed(direction: int) -> void:
	var index: int = clampi(current_index + direction, 0, page_count() - 1)
	if index == current_index:
		return
	show_page(index)


# --- Help ---------------------------------------------------------------------

func _toggle_help() -> void:
	if _help_overlay != null and is_instance_valid(_help_overlay):
		_close_help()
		return
	var opened := LessonHeader.open_help_overlay(self, _close_help)
	_help_overlay = opened["overlay"]
	_help_body = opened["body"]
	_refresh_help_context()


func _close_help() -> void:
	if _help_overlay != null and is_instance_valid(_help_overlay):
		_help_overlay.queue_free()
	_help_overlay = null
	_help_body = null


func _refresh_help_context() -> void:
	if _help_body == null:
		return
	var help := _help_for(current_index)
	_help_body.text = (
		"[b]%s[/b]\n\n%s\n\n[color=#7cf]%s[/color] %d / %d\n\nSwipe left for the next %s, right to go back."
		% [str(help.get("title", "Help")), str(help.get("body", "")), page_noun.capitalize(), current_index + 1, page_count(), page_noun]
	)
