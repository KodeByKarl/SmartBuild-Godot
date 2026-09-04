extends Control

var curr_slide: int = 0
var current_slide: Control = null
const MODULE_ID := 0
const PARTS_SEARCH_OVERLAY := preload("res://core/ui/parts_search_overlay.gd")

const SLIDE_PATHS: PackedStringArray = [
	"res://modules/module_0/slides/slide_1.tscn",
	"res://modules/module_0/slides/slide_2.tscn",
	"res://modules/module_0/slides/slide_3.tscn",
	"res://modules/module_0/slides/slide_4.tscn",
	"res://modules/module_0/slides/slide_5.tscn",
	"res://modules/module_0/slides/slide_6.tscn",
	"res://modules/module_0/slides/slide_7.tscn",
	"res://modules/module_0/slides/slide_8.tscn",
	"res://modules/module_0/slides/slide_9.tscn",
	"res://modules/module_0/slides/slide_10.tscn",
	"res://modules/module_0/slides/slide_11.tscn",
	"res://modules/module_0/slides/slide_12.tscn",
	"res://modules/module_0/slides/slide_13.tscn",
	"res://modules/module_0/slides/slide_14.tscn",
	"res://modules/module_0/slides/slide_15.tscn",
	"res://modules/module_0/slides/slide_16.tscn",
	"res://modules/module_0/slides/slide_17.tscn",
	"res://modules/module_0/slides/slide_18.tscn",
	"res://modules/module_0/slides/slide_19.tscn",
	"res://modules/module_0/slides/slide_20.tscn",
	"res://modules/module_0/slides/slide_21_completion.tscn",
]
var _slide_cache: Dictionary = {}

# Presentation.
@onready var content: VBoxContainer = $Wrapper/Presentation/Content
@onready var module_label: Label = $Wrapper/Header/ModuleLabel
@onready var phase_label: Label = $Wrapper/Header/PhaseLabel
@onready var search_btn: Button = $Wrapper/Header/SearchButton
@onready var help_btn: Button = $Wrapper/Header/HelpButton
# Navigation.
@onready var prev_btn: Button = $Wrapper/Navigation/Buttons/PreviousButton
@onready var next_btn: Button = $Wrapper/Navigation/Buttons/NextButton
@onready var page_num_lbl: Label = $Wrapper/Navigation/PageNumberLabel
@onready var exit_btn: Button = $Wrapper/Navigation/ExitButton

var _search_overlay: Control = null
var _help_overlay: Control = null
var _help_body: RichTextLabel = null


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_style_navigation()
	_style_header_tools()
	prev_btn.pressed.connect(_on_prev_btn_pressed)
	next_btn.pressed.connect(_on_next_btn_pressed)
	exit_btn.pressed.connect(_finish_module)
	search_btn.pressed.connect(_open_module_search)
	help_btn.pressed.connect(_toggle_module_help)
	_disable_btn()
	update_slide()


func _style_navigation() -> void:
	var cyan := Color(0.09, 0.65, 0.87, 1)
	var white := Color(0.95, 0.98, 0.99, 1)
	page_num_lbl.add_theme_color_override("font_color", white)
	page_num_lbl.add_theme_font_size_override("font_size", 14)

	for btn in [prev_btn, next_btn, exit_btn]:
		btn.custom_minimum_size = Vector2(60, 60)
		btn.expand_icon = true
		_apply_chrome_button(btn, cyan, white)
		for state in ["normal", "hover", "pressed", "disabled"]:
			var box := btn.get_theme_stylebox(state) as StyleBoxFlat
			if box == null:
				continue
			box.set_corner_radius_all(16)
			box.content_margin_left = 12
			box.content_margin_right = 12
			box.content_margin_top = 12
			box.content_margin_bottom = 12
	page_num_lbl.add_theme_font_size_override("font_size", 15)
	var navigation := get_node_or_null("Wrapper/Navigation") as Control
	if navigation != null:
		navigation.custom_minimum_size = Vector2(0, 72)

	var presentation := $Wrapper/Presentation as MarginContainer
	if presentation != null:
		presentation.add_theme_constant_override("margin_left", 8)
		presentation.add_theme_constant_override("margin_top", 4)
		presentation.add_theme_constant_override("margin_right", 8)
		presentation.add_theme_constant_override("margin_bottom", 4)

	var wrapper := $Wrapper as Control
	if wrapper != null:
		wrapper.offset_left = 18.0
		wrapper.offset_right = -18.0


func _style_header_tools() -> void:
	var cyan := Color(0.09, 0.65, 0.87, 1)
	var white := Color(0.95, 0.98, 0.99, 1)
	for btn in [search_btn, help_btn]:
		_apply_chrome_button(btn, cyan, white)
		btn.add_theme_color_override("font_color", white)
		btn.add_theme_color_override("font_hover_color", white)


func _apply_chrome_button(btn: Button, cyan: Color, white: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.04, 0.18, 0.28, 0.95)
	normal.border_color = Color(0.35, 0.82, 0.95, 0.45)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.08, 0.32, 0.45, 0.98)
	hover.border_color = cyan
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.03, 0.1, 0.16, 0.7)
	disabled.border_color = Color(0.25, 0.5, 0.65, 0.25)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("icon_normal_color", cyan)
	btn.add_theme_color_override("icon_hover_color", white)
	btn.add_theme_color_override("icon_disabled_color", Color(0.45, 0.6, 0.7, 0.5))
	btn.focus_mode = Control.FOCUS_NONE


func _slide_count() -> int:
	return SLIDE_PATHS.size()


func _packed_slide(index: int) -> PackedScene:
	if index < 0 or index >= SLIDE_PATHS.size():
		return null
	var path := SLIDE_PATHS[index]
	if _slide_cache.has(path):
		return _slide_cache[path] as PackedScene
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		var res: Resource = ResourceLoader.load_threaded_get(path)
		if res is PackedScene:
			_slide_cache[path] = res
			return res as PackedScene
	var packed := load(path) as PackedScene
	if packed != null:
		_slide_cache[path] = packed
	else:
		push_error("Module 0 failed to load slide: %s" % path)
	return packed


func update_slide():
	if current_slide != null:
		current_slide.queue_free()
		current_slide = null

	var packed := _packed_slide(curr_slide)
	if packed == null:
		push_error("Module 0 missing slide at index %d" % curr_slide)
		return
	current_slide = packed.instantiate()
	content.add_child(current_slide)
	if current_slide is Control:
		(current_slide as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		(current_slide as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL
		if OS.get_name() == "Android":
			(current_slide as Control).modulate.a = 1.0
		else:
			UiMotion.play_enter(current_slide as Control)

	if current_slide.has_signal("proceed_home"):
		current_slide.proceed_home.connect(_finish_module)

	page_num_lbl.text = str((curr_slide + 1), " / ", _slide_count())
	_update_phase_chip()
	_refresh_help_context()
	_disable_btn()
	_sync_intro_progress()
	call_deferred("_prefetch_next_slide")


func _prefetch_next_slide() -> void:
	var last: int = mini(curr_slide + 3, _slide_count())
	for index in range(curr_slide + 1, last):
		var path := SLIDE_PATHS[index]
		if _slide_cache.has(path):
			continue
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
			continue
		ResourceLoader.load_threaded_request(path)


func _update_phase_chip() -> void:
	if phase_label == null:
		return
	var slide_no: int = curr_slide + 1
	if slide_no <= 6:
		phase_label.text = "Career path"
	elif slide_no <= 10:
		phase_label.text = "Safety & quality"
	elif slide_no <= 20:
		phase_label.text = "Hardware basics"
	else:
		phase_label.text = "Complete"


func _open_module_search() -> void:
	if _search_overlay != null and is_instance_valid(_search_overlay):
		_search_overlay.queue_free()
		_search_overlay = null
	var overlay: Control = PARTS_SEARCH_OVERLAY.new()
	# Module 0 shows the full encyclopedia (related_modules often include 0 + 1).
	overlay.open(self, 0)
	_search_overlay = overlay
	overlay.closed.connect(func() -> void: _search_overlay = null)


func _toggle_module_help() -> void:
	if _help_overlay != null and is_instance_valid(_help_overlay):
		_close_module_help()
		return
	_open_module_help()


func _open_module_help() -> void:
	_close_module_help()
	_help_overlay = Control.new()
	_help_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_help_overlay.z_index = 75
	add_child(_help_overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.45)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close_module_help()
	)
	_help_overlay.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 56
	panel.offset_right = -56
	panel.offset_top = 48
	panel.offset_bottom = -48
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.10, 0.16, 0.98)
	style.border_color = Color(0.35, 0.82, 0.95, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	_help_overlay.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var top := HBoxContainer.new()
	col.add_child(top)
	var title := Label.new()
	title.text = "Module Help"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	top.add_child(title)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_close_module_help)
	top.add_child(close)

	_help_body = RichTextLabel.new()
	_help_body.bbcode_enabled = true
	_help_body.fit_content = true
	_help_body.scroll_active = true
	_help_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_help_body)
	_refresh_help_context()


func _close_module_help() -> void:
	if _help_overlay != null and is_instance_valid(_help_overlay):
		_help_overlay.queue_free()
	_help_overlay = null
	_help_body = null


func _refresh_help_context() -> void:
	if _help_body == null:
		return
	var slide_no: int = curr_slide + 1
	var help: Dictionary = Module0LessonContent.help_for(slide_no)
	_help_body.text = (
		"[b]%s[/b]\n\n%s\n\n[color=#7cf]Slide[/color] %d / %d\n\n[color=#8cf]Search[/color] opens the Parts Encyclopedia.\nUse Prev / Next to continue the intro."
		% [str(help.get("title", "Help")), str(help.get("body", "")), slide_no, _slide_count()]
	)


func _sync_intro_progress() -> void:
	var total: int = maxi(_slide_count(), 1)
	# Never mark 100% from page position — only "Proceed to Home" completes intro.
	var pct: float = minf((float(curr_slide + 1) / float(total)) * 100.0, 99.0)
	var host: Node = get_parent()
	while host != null and not host.has_method("send_event"):
		host = host.get_parent()
	if host != null:
		host.send_event("progress_update", MODULE_ID, pct)


func _disable_btn():
	var last_index: int = _slide_count() - 1
	var on_completion: bool = curr_slide == last_index
	prev_btn.disabled = curr_slide == 0
	prev_btn.visible = true
	# Celebration page uses in-slide "Proceed to Home" instead of Next.
	next_btn.disabled = on_completion
	next_btn.visible = not on_completion

func _on_prev_btn_pressed():
	UiMotion.pulse_button(prev_btn)
	curr_slide -= 1
	call_deferred("update_slide")

func _on_next_btn_pressed():
	UiMotion.pulse_button(next_btn)
	curr_slide += 1
	call_deferred("update_slide")


func _finish_module() -> void:
	var host: Node = get_parent()
	while host != null and not host.has_method("send_event"):
		host = host.get_parent()
	if host != null:
		# Flowchart: Intro lesson complete → save progress → Home.
		host.send_event("assessment_completed", MODULE_ID)
	else:
		queue_free()
