extends Control

## Module 4 service bench as a Windows-style PC desktop (monitor + tool windows).
## Gameplay contract unchanged: step ids, _perform, _action_buttons, action_submitted.

signal action_submitted(action: SimulationAction)

const ROOT_CAUSE := "dust_thermal"
const TICKET_ID := "4821"
const OFFICE_IP := "192.168.1.50"
const OFFICE_MASK := "255.255.255.0"
const OFFICE_GW := "192.168.1.1"
const OFFICE_DNS := "8.8.8.8"
const PING_EXT := "8.8.8.8"

const DISK_TOTAL_GB := 256.0
const DISK_FREE_BEFORE_GB := 12.0
const DISK_FREE_AFTER_GB := 48.0

## Win light theme
const WIN_TITLE := Color(0.95, 0.96, 0.98)
const WIN_BODY := Color(0.97, 0.97, 0.98)
const WIN_BORDER := Color(0.55, 0.58, 0.62)
const WIN_ACCENT := Color(0.0, 0.47, 0.83)
const WIN_TEXT := Color(0.12, 0.12, 0.14)
const WIN_MUTED := Color(0.35, 0.38, 0.42)
const DESK_BG := Color(0.02, 0.12, 0.22)
const WALLPAP_A := Color(0.12, 0.35, 0.62)
const WALLPAP_B := Color(0.05, 0.18, 0.38)

var guided_hints: bool = true
var _hint_target: String = ""

var _done: Dictionary = {}
var _found: Dictionary = {}
var _root_choice: String = ""

var _status: Label = null
var _ticket_label: Label = null
var _hardware_label: Label = null
var _software_label: Label = null
var _network_label: Label = null
var _log: RichTextLabel = null
var _root_option: OptionButton = null
var _action_scroll: ScrollContainer = null
var _state_scroll: ScrollContainer = null
var _state_sections: Dictionary = {}
var _step_group: Dictionary = {}
var _pending_scroll: String = ""
var _action_buttons: Dictionary = {}

var _disk_free_gb: float = DISK_FREE_BEFORE_GB
var _disk_cleaned: bool = false
var _disk_usage_bar: ProgressBar = null
var _disk_usage_label: Label = null
var _chk_temp: CheckBox = null
var _chk_recycle: CheckBox = null
var _chk_downloads: CheckBox = null

var _screen: Control = null
var _windows_layer: Control = null
var _taskbar_chips: HBoxContainer = null
var _clock_label: Label = null
var _window_panels: Dictionary = {}
var _window_scrolls: Dictionary = {}
var _active_window: String = ""
var _coach_panel: PanelContainer = null
var _alert_panel: PanelContainer = null
var _alert_col: VBoxContainer = null
var _esd_check: CheckBox = null
var _case_closed: Control = null
var _case_open: Control = null
var _dust_overlay: ColorRect = null
var _nic_check: CheckBox = null
var _cable_status: Label = null
var _link_light: ColorRect = null
var _ip_edit: LineEdit = null
var _mask_edit: LineEdit = null
var _gw_edit: LineEdit = null
var _dns_edit: LineEdit = null
var _ping_edit: LineEdit = null
var _ping_out: RichTextLabel = null
var _ticket_no_edit: LineEdit = null
var _report_edit: TextEdit = null
var _pinged_gw: bool = false
var _pinged_ext: bool = false
var _dust_hits: int = 0


func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	if custom_minimum_size.y < 360.0:
		custom_minimum_size.y = 400.0 if get_viewport().get_visible_rect().size.y <= 760.0 else 480.0
	_build_ui()
	_refresh_all()
	_open_window("ticket")
	_refresh_status("Open a desktop icon, then run the matching Windows tool for this service visit.")
	_refresh_alerts()


func setup(completed: Array = [], hints: bool = true) -> void:
	guided_hints = hints
	if _status == null:
		call_deferred("setup", completed, hints)
		return
	_preload_completed(completed)
	_refresh_all()
	_refresh_hints()
	_refresh_alerts()
	if _hint_target != "":
		_scroll_to_step(_hint_target)


func reset_scenario() -> void:
	_done.clear()
	_found.clear()
	_root_choice = ""
	_disk_free_gb = DISK_FREE_BEFORE_GB
	_disk_cleaned = false
	_pinged_gw = false
	_pinged_ext = false
	_dust_hits = 0
	if _esd_check != null:
		_esd_check.button_pressed = false
	if _nic_check != null:
		_nic_check.button_pressed = false
	if _ip_edit != null:
		_ip_edit.text = "10.255.0.1"
		_mask_edit.text = "255.0.0.0"
		_gw_edit.text = "10.0.0.1"
		_dns_edit.text = "1.1.1.1"
	if _ping_edit != null:
		_ping_edit.text = ""
	if _ping_out != null:
		_ping_out.text = "Ready."
	if _ticket_no_edit != null:
		_ticket_no_edit.text = ""
	if _report_edit != null:
		_report_edit.text = ""
	if _chk_temp != null:
		_chk_temp.button_pressed = true
	if _chk_recycle != null:
		_chk_recycle.button_pressed = false
	if _chk_downloads != null:
		_chk_downloads.button_pressed = false
	_sync_hardware_visual()
	_refresh_all()
	_refresh_alerts()
	_open_window("ticket")
	_refresh_status("Scenario reset — start the service visit again.")


func _preload_completed(completed: Array) -> void:
	if completed.is_empty():
		return
	for id_variant in completed:
		var step_id: String = str(id_variant)
		if step_id == "":
			continue
		_done[step_id] = true
		_apply_findings(step_id)
		if step_id == "disk_cleanup":
			_disk_cleaned = true
			_disk_free_gb = DISK_FREE_AFTER_GB
			_refresh_disk_panel()
		if step_id == "ping_path":
			_pinged_gw = true
			_pinged_ext = true
		if step_id == "dust_out":
			_dust_hits = 2
	_sync_hardware_visual()
	if _done.is_empty():
		return
	_log_line("Earlier phases of this service visit restored.")


func set_guided_hint(target: String, _destination: String) -> void:
	_hint_target = target
	_open_window_for_step(target)
	_refresh_hints()
	_refresh_action_states()
	_scroll_to_step(target)


func _scroll_to_step(step_id: String) -> void:
	if not guided_hints:
		return
	_pending_scroll = step_id
	if not is_inside_tree():
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if _pending_scroll != step_id or not is_inside_tree():
		return
	_open_window_for_step(step_id)
	var group: String = str(_step_group.get(step_id, ""))
	var scroll: ScrollContainer = _window_scrolls.get(group, _action_scroll) as ScrollContainer
	if scroll != null and is_instance_valid(scroll):
		var btn: Button = _action_buttons.get(step_id, null) as Button
		if btn != null and is_instance_valid(btn):
			scroll.ensure_control_visible(btn)


func mark_step_done(_target: String, _destination: String) -> void:
	_refresh_all()


func flash_incorrect() -> void:
	if _status != null:
		_status.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		_refresh_status("Wrong service action — check the current step.")
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			if _status != null:
				_status.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
		)


# ── UI shell: desk + bezel + desktop ─────────────────────────────────────────


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_action_buttons.clear()
	_state_sections.clear()
	_step_group.clear()
	_window_panels.clear()
	_window_scrolls.clear()

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)

	var desk := ColorRect.new()
	desk.color = DESK_BG
	desk.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(desk)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 52)
	root.add_child(margin)

	var bezel := PanelContainer.new()
	bezel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bezel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bezel.add_theme_stylebox_override("panel", _bezel_style())
	margin.add_child(bezel)

	_screen = Control.new()
	_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen.clip_contents = true
	bezel.add_child(_screen)

	var wallpaper := ColorRect.new()
	wallpaper.color = WALLPAP_A
	wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(wallpaper)
	# Soft gradient bands (procedural Win11-ish)
	var band := ColorRect.new()
	band.color = Color(WALLPAP_B.r, WALLPAP_B.g, WALLPAP_B.b, 0.55)
	band.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band.offset_top = 120
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(band)

	_build_desktop_icons(_screen)
	_build_alert_tray(_screen)

	_windows_layer = Control.new()
	_windows_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_windows_layer.offset_bottom = -40
	_windows_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_windows_layer)

	_build_all_windows()
	_build_taskbar(_screen)
	_build_coach_overlay(root)

	# Compatibility aliases used by older scroll helpers
	_action_scroll = _window_scrolls.get("software", null) as ScrollContainer
	_state_scroll = _window_scrolls.get("ticket", null) as ScrollContainer


func _bezel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.72, 0.76, 0.8)
	s.border_color = Color(0.45, 0.48, 0.52)
	s.set_border_width_all(2)
	s.set_corner_radius_all(14)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 12
	s.content_margin_bottom = 18
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	return s


func _build_desktop_icons(parent: Control) -> void:
	# Scroll so Close Ticket stays reachable on short phone screens.
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	scroll.anchor_right = 0.0
	scroll.offset_left = 6
	scroll.offset_top = 8
	scroll.offset_right = 124
	scroll.offset_bottom = -44
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.z_index = 8
	parent.add_child(scroll)

	var icons := VBoxContainer.new()
	icons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icons.add_theme_constant_override("separation", 6)
	scroll.add_child(icons)

	icons.add_child(_desk_icon("Service Ticket", "ticket"))
	icons.add_child(_desk_icon("Field Service", "hardware"))
	icons.add_child(_desk_icon("Windows Tools", "software"))
	icons.add_child(_desk_icon("Disk Cleanup", "disk"))
	icons.add_child(_desk_icon("Network", "network"))
	icons.add_child(_desk_icon("Close Ticket", "close"))


func _desk_icon(label: String, win_id: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(108, 44)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(11))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.16)
	style.border_color = Color(1, 1, 1, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.15, 0.42, 0.62, 0.92)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", pressed)
	_bind_btn_colors(btn, Color(0.95, 0.98, 1.0))
	btn.pressed.connect(func() -> void: _open_window(win_id))
	return btn


func _build_taskbar(parent: Control) -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -40
	bar.offset_bottom = 0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 0.92)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	bar.add_theme_stylebox_override("panel", style)
	parent.add_child(bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)

	var start := Button.new()
	start.text = "Start"
	start.focus_mode = Control.FOCUS_NONE
	start.custom_minimum_size = Vector2(72, 28)
	_style_win_btn(start, true)
	start.pressed.connect(func() -> void: _open_window("software"))
	row.add_child(start)

	var close_ticket := Button.new()
	close_ticket.text = "Close Ticket"
	close_ticket.focus_mode = Control.FOCUS_NONE
	close_ticket.custom_minimum_size = Vector2(108, 28)
	_style_win_btn(close_ticket, true)
	close_ticket.pressed.connect(func() -> void: _open_window("close"))
	row.add_child(close_ticket)

	_taskbar_chips = HBoxContainer.new()
	_taskbar_chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_taskbar_chips.add_theme_constant_override("separation", 6)
	row.add_child(_taskbar_chips)

	_clock_label = Label.new()
	_clock_label.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(11))
	_clock_label.add_theme_color_override("font_color", Color(0.9, 0.93, 0.96))
	_clock_label.text = "9:41 AM"
	row.add_child(_clock_label)


func _build_coach_overlay(parent: Control) -> void:
	_coach_panel = PanelContainer.new()
	_coach_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_coach_panel.anchor_right = 0.0
	_coach_panel.anchor_top = 1.0
	_coach_panel.offset_left = 132
	_coach_panel.offset_right = 420
	_coach_panel.offset_top = -48
	_coach_panel.offset_bottom = -8
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.28, 0.48, 0.88)
	style.border_color = Color(0.4, 0.75, 0.95, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_coach_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(_coach_panel)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	_status.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	_coach_panel.add_child(_status)


# ── Windows ──────────────────────────────────────────────────────────────────


func _build_all_windows() -> void:
	_window_panels["ticket"] = _make_window(
		"Service Ticket — Help Desk",
		"ticket",
		_build_ticket_body()
	)
	_window_panels["hardware"] = _make_window(
		"Field Service — Hardware PM",
		"hardware",
		_build_hardware_body()
	)
	_window_panels["software"] = _make_window(
		"Windows Tools",
		"software",
		_build_software_body()
	)
	_window_panels["disk"] = _make_window(
		"Disk Cleanup: Local Disk (C:)",
		"disk",
		_build_disk_cleanup_panel(),
		Vector2(0.26, 0.08),
		Vector2(0.96, 0.88)
	)
	_window_panels["network"] = _make_window(
		"Network & Internet",
		"network",
		_build_network_body()
	)
	_window_panels["close"] = _make_window(
		"Notepad — Service Report",
		"close",
		_build_close_body()
	)
	for id in _window_panels.keys():
		(_window_panels[id] as Control).visible = false
		_windows_layer.add_child(_window_panels[id])


func _make_window(
	title: String,
	win_id: String,
	body: Control,
	anchor_min: Vector2 = Vector2(0.24, 0.05),
	anchor_max: Vector2 = Vector2(0.98, 0.90)
) -> PanelContainer:
	var win := PanelContainer.new()
	win.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	win.anchor_left = anchor_min.x
	win.anchor_top = anchor_min.y
	win.anchor_right = anchor_max.x
	win.anchor_bottom = anchor_max.y
	win.offset_left = 0
	win.offset_top = 0
	win.offset_right = 0
	win.offset_bottom = 0
	win.mouse_filter = Control.MOUSE_FILTER_STOP
	win.add_theme_stylebox_override("panel", _win_frame_style())
	win.set_meta("win_id", win_id)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	win.add_child(col)

	var titlebar := HBoxContainer.new()
	titlebar.custom_minimum_size = Vector2(0, 32)
	var tb_style_wrap := PanelContainer.new()
	tb_style_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tbs := StyleBoxFlat.new()
	tbs.bg_color = WIN_TITLE
	tbs.content_margin_left = 10
	tbs.content_margin_right = 6
	tbs.content_margin_top = 4
	tbs.content_margin_bottom = 4
	tb_style_wrap.add_theme_stylebox_override("panel", tbs)
	col.add_child(tb_style_wrap)
	tb_style_wrap.add_child(titlebar)

	var ttl := Label.new()
	ttl.text = title
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	ttl.add_theme_color_override("font_color", WIN_TEXT)
	titlebar.add_child(ttl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(36, 24)
	close_btn.pressed.connect(func() -> void: win.visible = false; _refresh_taskbar())
	_style_win_btn(close_btn, false)
	titlebar.add_child(close_btn)

	var body_wrap := PanelContainer.new()
	body_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bs := StyleBoxFlat.new()
	bs.bg_color = WIN_BODY
	bs.content_margin_left = 10
	bs.content_margin_right = 10
	bs.content_margin_top = 8
	bs.content_margin_bottom = 8
	body_wrap.add_theme_stylebox_override("panel", bs)
	col.add_child(body_wrap)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_wrap.add_child(scroll)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	# Map scroll / state section keys used by helpers
	var group_key := win_id
	if win_id == "disk":
		group_key = "software"
	elif win_id == "ticket":
		group_key = "intake"
	_window_scrolls[group_key] = scroll
	if win_id == "software":
		_window_scrolls["software"] = scroll
	if win_id == "disk":
		_window_scrolls["disk"] = scroll
	_state_sections[group_key] = win
	if win_id == "ticket":
		_state_sections["intake"] = win
	if win_id == "close":
		_state_sections["close"] = win

	return win


func _win_frame_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = WIN_BODY
	s.border_color = WIN_BORDER
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 10
	return s


func _open_window(win_id: String) -> void:
	if not _window_panels.has(win_id):
		return
	_active_window = win_id
	for id in _window_panels.keys():
		var p: Control = _window_panels[id] as Control
		p.visible = (id == win_id)
		if p.visible:
			_windows_layer.move_child(p, _windows_layer.get_child_count() - 1)
	_refresh_taskbar()


func _open_window_for_step(step_id: String) -> void:
	var group: String = str(_step_group.get(step_id, ""))
	match group:
		"intake":
			_open_window("ticket")
		"hardware":
			_open_window("hardware")
		"software":
			if step_id == "disk_cleanup":
				_open_window("disk")
			else:
				_open_window("software")
		"network":
			_open_window("network")
		"close":
			_open_window("close")
		_:
			pass


func _refresh_taskbar() -> void:
	if _taskbar_chips == null:
		return
	for child in _taskbar_chips.get_children():
		child.queue_free()
	var titles := {
		"ticket": "Ticket",
		"hardware": "Hardware",
		"software": "Tools",
		"disk": "Disk Cleanup",
		"network": "Network",
		"close": "Report",
	}
	for id in _window_panels.keys():
		var p: Control = _window_panels[id] as Control
		if p == null or not p.visible:
			continue
		var chip := Button.new()
		chip.text = str(titles.get(id, id))
		chip.focus_mode = Control.FOCUS_NONE
		chip.custom_minimum_size = Vector2(88, 26)
		_style_win_btn(chip, id == _active_window)
		chip.pressed.connect(_open_window.bind(id))
		_taskbar_chips.add_child(chip)


# ── Window bodies ────────────────────────────────────────────────────────────


func _build_ticket_body() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hdr := _win_heading("IT Help Desk — Service Request #4821")
	col.add_child(hdr)

	_ticket_label = _win_state_label()
	col.add_child(_ticket_label)
	_state_sections["intake"] = col

	col.add_child(_win_sep())
	col.add_child(_win_muted("Actions"))
	col.add_child(_action_btn("Read service request", "read_ticket", "intake"))
	col.add_child(_action_btn("Clarify with the user", "ask_clarify", "intake"))
	col.add_child(_action_btn("Stage toolkit & ESD gear", "stage_tools", "intake"))
	col.add_child(_action_btn("Check backup needs", "backup_note", "intake"))
	col.add_child(_action_btn("Plan the service order", "plan_order", "intake"))
	return col


func _build_hardware_body() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_win_heading("Field service — chassis"))
	col.add_child(_win_muted("Work the PC itself: clip ESD, open the side panel, then tap the dusty parts."))
	_hardware_label = _win_state_label()
	col.add_child(_hardware_label)
	_state_sections["hardware"] = col
	col.add_child(_win_sep())

	_esd_check = CheckBox.new()
	_esd_check.text = "Clip ESD strap to chassis"
	_esd_check.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	_esd_check.add_theme_color_override("font_color", WIN_TEXT)
	_esd_check.toggled.connect(func(on: bool) -> void:
		if on:
			_try_step("ground_up")
		_sync_hardware_visual()
	)
	col.add_child(_esd_check)
	_register_hidden_step("ground_up", "hardware", "Clip ESD strap")

	var chassis := PanelContainer.new()
	chassis.custom_minimum_size = Vector2(0, 168)
	chassis.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.16, 0.18, 0.22)
	cs.border_color = Color(0.45, 0.48, 0.52)
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(8)
	cs.content_margin_left = 8
	cs.content_margin_right = 8
	cs.content_margin_top = 8
	cs.content_margin_bottom = 8
	chassis.add_theme_stylebox_override("panel", cs)
	col.add_child(chassis)

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 152)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chassis.add_child(stage)

	_case_closed = VBoxContainer.new()
	_case_closed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_case_closed.add_theme_constant_override("separation", 8)
	stage.add_child(_case_closed)
	var closed_lbl := Label.new()
	closed_lbl.text = "Side panel on — internals hidden"
	closed_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	closed_lbl.add_theme_color_override("font_color", Color(0.82, 0.86, 0.9))
	_case_closed.add_child(closed_lbl)
	var open_btn := Button.new()
	open_btn.text = "Remove side panel"
	open_btn.focus_mode = Control.FOCUS_NONE
	open_btn.custom_minimum_size = Vector2(0, 36)
	open_btn.set_meta("base_text", "Remove side panel")
	_style_win_btn(open_btn, true)
	open_btn.pressed.connect(func() -> void: _try_step("open_case_pm"); _sync_hardware_visual())
	_action_buttons["open_case_pm"] = open_btn
	_step_group["open_case_pm"] = "hardware"
	_case_closed.add_child(open_btn)

	_case_open = Control.new()
	_case_open.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_case_open.visible = false
	stage.add_child(_case_open)

	_dust_overlay = ColorRect.new()
	_dust_overlay.color = Color(0.45, 0.38, 0.22, 0.55)
	_dust_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dust_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_case_open.add_child(_dust_overlay)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_case_open.add_child(grid)
	grid.add_child(_hotspot_btn("Blow dust from heatsink", "dust_heatsink"))
	grid.add_child(_hotspot_btn("Blow dust from fans", "dust_fans"))
	grid.add_child(_hotspot_btn("Inspect cooling fans", "check_fans"))
	grid.add_child(_hotspot_btn("Reseat loose DIMM 2", "reseat_ram"))
	grid.add_child(_hotspot_btn("Tug-test power/SATA", "check_cables_int"))
	var spacer := Control.new()
	grid.add_child(spacer)
	_register_hidden_step("dust_out", "hardware", "Remove dust")
	return col


func _build_software_body() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_win_heading("Windows Tools"))
	col.add_child(_win_muted("Administrative tools for this workstation"))

	_software_label = _win_state_label()
	col.add_child(_software_label)
	_state_sections["software"] = col

	col.add_child(_win_sep())
	# Explorer-style tool rows
	col.add_child(_tools_row("Windows Update", "Install OS & security updates", "os_updates"))
	col.add_child(_tools_row("Windows Security", "Run malware scan", "malware_scan"))
	col.add_child(_tools_row("Task Manager", "Trim startup apps", "startup_trim"))
	col.add_child(_tools_row("Disk Cleanup", "Open Disk Cleanup for drive C:", "disk_cleanup_open"))
	col.add_child(_tools_row("Device Manager", "Check critical drivers", "driver_health"))

	# Hidden real disk_cleanup is in disk window; open helper launches it
	var open_disk := Button.new()
	open_disk.visible = false
	open_disk.set_meta("base_text", "Open Disk Cleanup")
	_action_buttons["disk_cleanup_open"] = open_disk
	_step_group["disk_cleanup_open"] = "software"
	open_disk.pressed.connect(func() -> void: _open_window("disk"))
	col.add_child(open_disk)

	col.add_child(_win_sep())
	col.add_child(_win_muted("Event log"))
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.fit_content = false
	_log.scroll_active = true
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(0, 72)
	_log.add_theme_font_size_override("normal_font_size", ResponsiveLayout.readable_font(11))
	_log.add_theme_color_override("default_color", Color(0.15, 0.45, 0.2))
	_log.text = "Service log ready."
	col.add_child(_log)
	return col


func _tools_row(tool_name: String, action_label: String, step_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var icon := Label.new()
	icon.text = "▣"
	icon.custom_minimum_size = Vector2(28, 0)
	icon.add_theme_color_override("font_color", WIN_ACCENT)
	row.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = tool_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	name_lbl.add_theme_color_override("font_color", WIN_TEXT)
	row.add_child(name_lbl)

	if step_id == "disk_cleanup_open":
		var open_btn := Button.new()
		open_btn.text = "Open"
		open_btn.focus_mode = Control.FOCUS_NONE
		open_btn.custom_minimum_size = Vector2(72, 28)
		_style_win_btn(open_btn, true)
		open_btn.pressed.connect(func() -> void: _open_window("disk"))
		row.add_child(open_btn)
	else:
		row.add_child(_action_btn(action_label, step_id, "software"))
	return row


func _build_disk_cleanup_panel() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	col.add_child(_win_heading("Disk Cleanup — Drive Selection"))
	col.add_child(_win_muted("Files to delete from Local Disk (C:)"))

	_disk_usage_label = Label.new()
	_disk_usage_label.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	_disk_usage_label.add_theme_color_override("font_color", WIN_TEXT)
	col.add_child(_disk_usage_label)

	_disk_usage_bar = ProgressBar.new()
	_disk_usage_bar.custom_minimum_size = Vector2(0, 16)
	_disk_usage_bar.show_percentage = false
	col.add_child(_disk_usage_bar)

	col.add_child(_win_sep())
	col.add_child(_win_muted("Files to delete"))

	_chk_temp = CheckBox.new()
	_chk_temp.text = "Temporary files (18.4 GB)"
	_chk_temp.button_pressed = true
	_chk_temp.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	_chk_temp.add_theme_color_override("font_color", WIN_TEXT)
	col.add_child(_chk_temp)

	_chk_recycle = CheckBox.new()
	_chk_recycle.text = "Recycle Bin (2.1 GB)"
	_chk_recycle.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	_chk_recycle.add_theme_color_override("font_color", WIN_TEXT)
	col.add_child(_chk_recycle)

	_chk_downloads = CheckBox.new()
	_chk_downloads.text = "Downloads (6.2 GB)"
	_chk_downloads.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	_chk_downloads.add_theme_color_override("font_color", WIN_TEXT)
	col.add_child(_chk_downloads)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	col.add_child(actions)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.custom_minimum_size = Vector2(88, 30)
	_style_win_btn(cancel, false)
	cancel.pressed.connect(func() -> void: _open_window("software"))
	actions.add_child(cancel)

	var run_btn := Button.new()
	run_btn.text = "OK"
	run_btn.focus_mode = Control.FOCUS_NONE
	run_btn.custom_minimum_size = Vector2(88, 30)
	run_btn.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	run_btn.set_meta("base_text", "OK — Run Disk Cleanup")
	run_btn.pressed.connect(_run_disk_cleanup)
	_style_win_primary(run_btn)
	_action_buttons["disk_cleanup"] = run_btn
	_step_group["disk_cleanup"] = "software"
	actions.add_child(run_btn)

	_refresh_disk_panel()
	return col


func _build_network_body() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_win_heading("Network & Internet"))
	col.add_child(_win_muted("Fix the adapter, swap the cable, set addressing, then ping."))
	_network_label = _win_state_label()
	col.add_child(_network_label)
	_state_sections["network"] = col
	col.add_child(_win_sep())

	_nic_check = CheckBox.new()
	_nic_check.text = "Enable Ethernet adapter (currently disabled)"
	_nic_check.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	_nic_check.add_theme_color_override("font_color", WIN_TEXT)
	_nic_check.toggled.connect(func(on: bool) -> void:
		if on:
			_try_step("check_nic")
			_nic_check.text = "Ethernet adapter enabled"
		_refresh_alerts()
	)
	col.add_child(_nic_check)
	_register_hidden_step("check_nic", "network", "Enable adapter")

	var cable_row := HBoxContainer.new()
	cable_row.add_theme_constant_override("separation", 8)
	col.add_child(cable_row)
	_cable_status = Label.new()
	_cable_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cable_status.text = "Patch cable: broken latch · no link"
	_cable_status.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	_cable_status.add_theme_color_override("font_color", Color(0.7, 0.15, 0.12))
	cable_row.add_child(_cable_status)
	var swap := Button.new()
	swap.text = "Swap cable"
	swap.focus_mode = Control.FOCUS_NONE
	swap.custom_minimum_size = Vector2(110, 30)
	swap.set_meta("base_text", "Swap cable")
	_style_win_btn(swap, true)
	swap.pressed.connect(_swap_patch_cable)
	_action_buttons["swap_patch"] = swap
	_step_group["swap_patch"] = "network"
	cable_row.add_child(swap)

	var link_row := HBoxContainer.new()
	link_row.add_theme_constant_override("separation", 8)
	col.add_child(link_row)
	_link_light = ColorRect.new()
	_link_light.custom_minimum_size = Vector2(18, 18)
	_link_light.color = Color(0.55, 0.12, 0.1)
	link_row.add_child(_link_light)
	var port_lbl := Label.new()
	port_lbl.text = "Switch port link light"
	port_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	port_lbl.add_theme_color_override("font_color", WIN_TEXT)
	link_row.add_child(port_lbl)
	var port_btn := Button.new()
	port_btn.text = "Move port"
	port_btn.focus_mode = Control.FOCUS_NONE
	port_btn.custom_minimum_size = Vector2(110, 30)
	port_btn.set_meta("base_text", "Move port")
	_style_win_btn(port_btn, false)
	port_btn.pressed.connect(func() -> void: _try_step("check_switch_port"); _refresh_network_visual())
	_action_buttons["check_switch_port"] = port_btn
	_step_group["check_switch_port"] = "network"
	link_row.add_child(port_btn)

	col.add_child(_win_sep())
	col.add_child(_win_muted("IPv4 — type the office plan, or renew DHCP"))
	_ip_edit = _net_field("IP address", "10.255.0.1")
	_mask_edit = _net_field("Subnet mask", "255.0.0.0")
	_gw_edit = _net_field("Default gateway", "10.0.0.1")
	_dns_edit = _net_field("Preferred DNS", "1.1.1.1")
	col.add_child(_labeled_net("IP address", _ip_edit))
	col.add_child(_labeled_net("Subnet mask", _mask_edit))
	col.add_child(_labeled_net("Default gateway", _gw_edit))
	col.add_child(_labeled_net("Preferred DNS", _dns_edit))

	var ip_row := HBoxContainer.new()
	ip_row.alignment = BoxContainer.ALIGNMENT_END
	ip_row.add_theme_constant_override("separation", 8)
	col.add_child(ip_row)
	var dhcp := Button.new()
	dhcp.text = "Renew DHCP"
	dhcp.focus_mode = Control.FOCUS_NONE
	dhcp.custom_minimum_size = Vector2(120, 30)
	_style_win_btn(dhcp, false)
	dhcp.pressed.connect(_renew_dhcp)
	ip_row.add_child(dhcp)
	var apply_ip := Button.new()
	apply_ip.text = "Apply"
	apply_ip.focus_mode = Control.FOCUS_NONE
	apply_ip.custom_minimum_size = Vector2(88, 30)
	apply_ip.set_meta("base_text", "Apply")
	_style_win_btn(apply_ip, true)
	apply_ip.pressed.connect(_apply_ip_settings)
	_action_buttons["verify_ip"] = apply_ip
	_step_group["verify_ip"] = "network"
	ip_row.add_child(apply_ip)

	col.add_child(_win_sep())
	col.add_child(_win_muted("Ping — gateway %s then external %s" % [OFFICE_GW, PING_EXT]))
	_ping_edit = _net_field("Ping target", "")
	_ping_edit.placeholder_text = OFFICE_GW
	col.add_child(_labeled_net("Ping target", _ping_edit))
	var ping_btn := Button.new()
	ping_btn.text = "Ping"
	ping_btn.focus_mode = Control.FOCUS_NONE
	ping_btn.custom_minimum_size = Vector2(0, 32)
	ping_btn.set_meta("base_text", "Ping")
	_style_win_btn(ping_btn, true)
	ping_btn.pressed.connect(_run_ping)
	_action_buttons["ping_path"] = ping_btn
	_step_group["ping_path"] = "network"
	col.add_child(ping_btn)
	_ping_out = RichTextLabel.new()
	_ping_out.bbcode_enabled = true
	_ping_out.fit_content = true
	_ping_out.scroll_active = false
	_ping_out.custom_minimum_size = Vector2(0, 48)
	_ping_out.add_theme_font_size_override("normal_font_size", ResponsiveLayout.readable_font(11))
	_ping_out.add_theme_color_override("default_color", WIN_TEXT)
	_ping_out.text = "Ready."
	col.add_child(_ping_out)
	return col


func _build_close_body() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_win_heading("Service report"))
	col.add_child(_win_muted("Confirm the root cause, retest, then type the ticket id and write-up."))
	col.add_child(_win_sep())
	col.add_child(_win_muted("Root cause"))
	_root_option = _root_cause_option()
	col.add_child(_root_option)
	col.add_child(_action_btn("Confirm root cause", "pick_root", "close"))
	col.add_child(_action_btn("Apply corrective action", "apply_fix", "close"))
	col.add_child(_action_btn("Run performance retest", "retest_perf", "close"))
	col.add_child(_action_btn("Run internet retest", "retest_net", "close"))
	col.add_child(_win_sep())
	col.add_child(_win_muted("Type ticket number exactly, then the report (must mention dust and the cleanup)."))
	_ticket_no_edit = LineEdit.new()
	_ticket_no_edit.placeholder_text = "Ticket number — %s" % TICKET_ID
	_ticket_no_edit.custom_minimum_size = Vector2(0, 32)
	_ticket_no_edit.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(13))
	col.add_child(_ticket_no_edit)
	_report_edit = TextEdit.new()
	_report_edit.placeholder_text = "Symptoms, cause, fix, parts used, time…"
	_report_edit.custom_minimum_size = Vector2(0, 88)
	_report_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_report_edit.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	col.add_child(_report_edit)
	var submit := Button.new()
	submit.text = "Submit service report"
	submit.focus_mode = Control.FOCUS_NONE
	submit.custom_minimum_size = Vector2(0, 36)
	submit.set_meta("base_text", "Submit service report")
	submit.pressed.connect(_submit_service_report)
	_style_win_btn(submit, true)
	_action_buttons["write_report"] = submit
	_step_group["write_report"] = "close"
	col.add_child(submit)
	_state_sections["close"] = col
	return col


# ── Shared Win chrome helpers ────────────────────────────────────────────────


func _win_heading(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(14))
	lbl.add_theme_color_override("font_color", WIN_TEXT)
	return lbl


func _win_muted(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(11))
	lbl.add_theme_color_override("font_color", WIN_MUTED)
	return lbl


func _win_state_label() -> Label:
	var lbl := Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	lbl.add_theme_constant_override("line_spacing", 2)
	lbl.add_theme_color_override("font_color", WIN_TEXT)
	return lbl


func _win_sep() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color(0.78, 0.8, 0.84)
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return line


func _style_win_btn(btn: Button, accent: bool) -> void:
	var style := StyleBoxFlat.new()
	var fg := Color.WHITE
	if accent:
		style.bg_color = WIN_ACCENT
		fg = Color.WHITE
	else:
		style.bg_color = Color(0.94, 0.94, 0.96)
		style.border_color = WIN_BORDER
		style.set_border_width_all(1)
		fg = WIN_TEXT
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	var pressed := style.duplicate() as StyleBoxFlat
	if accent:
		pressed.bg_color = Color(0.0, 0.32, 0.62)
	else:
		pressed.bg_color = Color(0.82, 0.84, 0.88)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(11))
	_bind_btn_colors(btn, fg)


func _style_win_primary(btn: Button) -> void:
	_style_win_btn(btn, true)


func _action_btn(text: String, step_id: String, group: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.custom_minimum_size = Vector2(0, 32)
	btn.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	btn.set_meta("base_text", text)
	btn.pressed.connect(func() -> void: _perform(step_id))
	_style_action_btn(btn, false)
	_action_buttons[step_id] = btn
	_step_group[step_id] = group
	return btn


func _style_action_btn(btn: Button, done: bool, is_next: bool = false) -> void:
	var style := StyleBoxFlat.new()
	if done:
		style.bg_color = Color(0.86, 0.94, 0.88)
		style.border_color = Color(0.25, 0.55, 0.35)
		btn.add_theme_color_override("font_color", Color(0.12, 0.35, 0.2))
	elif is_next:
		style.bg_color = Color(1.0, 0.95, 0.82)
		style.border_color = Color(0.85, 0.55, 0.1)
		style.set_border_width_all(2)
		btn.add_theme_color_override("font_color", Color(0.35, 0.22, 0.05))
	else:
		style.bg_color = Color(0.94, 0.95, 0.97)
		style.border_color = WIN_BORDER
		style.set_border_width_all(1)
		btn.add_theme_color_override("font_color", WIN_TEXT)
	if not is_next:
		style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.06)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = style.bg_color.darkened(0.12)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", style)
	var fg := Color(0.12, 0.35, 0.2) if done else (Color(0.35, 0.22, 0.05) if is_next else WIN_TEXT)
	_bind_btn_colors(btn, fg)
	var base: String = str(btn.get_meta("base_text", btn.text))
	btn.text = ("✓ %s" % base) if done else base


func _root_cause_option() -> OptionButton:
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.custom_minimum_size = Vector2(0, 32)
	opt.clip_text = true
	opt.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	var entries: Array = [
		["Dust / thermal throttling", "dust_thermal"],
		["Loose RAM module", "loose_ram"],
		["Faulty network cable", "bad_cable"],
		["Incorrect IP configuration", "bad_ip"],
		["Malware infection", "malware"],
	]
	for index in entries.size():
		var entry: Array = entries[index]
		opt.add_item(str(entry[0]), index)
		opt.set_item_metadata(index, str(entry[1]))
	return opt


func _refresh_disk_panel() -> void:
	if _disk_usage_label == null or _disk_usage_bar == null:
		return
	var used_pct: float = 1.0 - (_disk_free_gb / DISK_TOTAL_GB)
	_disk_usage_bar.min_value = 0.0
	_disk_usage_bar.max_value = 100.0
	_disk_usage_bar.value = used_pct * 100.0
	var status := "OK"
	var color := Color(0.12, 0.55, 0.28)
	if _disk_free_gb < 20.0:
		status = "CRITICAL — low disk space"
		color = Color(0.75, 0.15, 0.12)
	elif _disk_free_gb < 40.0:
		status = "Low free space"
		color = Color(0.7, 0.45, 0.05)
	_disk_usage_label.text = "C:  %.1f GB free of %.0f GB  ·  %s" % [_disk_free_gb, DISK_TOTAL_GB, status]
	_disk_usage_label.add_theme_color_override("font_color", color)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = color
	_disk_usage_bar.add_theme_stylebox_override("fill", bar_fill)


func _run_disk_cleanup() -> void:
	if _done.has("disk_cleanup"):
		_refresh_status("Disk cleanup already completed on this visit.")
		return
	if _chk_temp == null or not _chk_temp.button_pressed:
		_log_line("[color=#b86]Select at least Temporary files before running cleanup.[/color]")
		_refresh_status("Check Temporary files — that is where most of the reclaimed space lives.")
		return
	if not guided_hints and (_chk_recycle == null or not _chk_recycle.button_pressed):
		_log_line("[color=#b86]Action Center: Recycle Bin still holds 2.1 GB.[/color]")
		_refresh_status("Empty the Recycle Bin too — it is one of the storage warnings.")
		return
	var blocked: String = _blocked_reason("disk_cleanup")
	if blocked != "":
		_log_line("[color=#b86]%s[/color]" % blocked)
		_refresh_status(blocked)
		return
	_done["disk_cleanup"] = true
	_apply_findings("disk_cleanup")
	_disk_cleaned = true
	var reclaimed := 0.0
	if _chk_temp.button_pressed:
		reclaimed += 18.4
	if _chk_recycle != null and _chk_recycle.button_pressed:
		reclaimed += 2.1
	if _chk_downloads != null and _chk_downloads.button_pressed:
		reclaimed += 6.2
	_disk_free_gb = minf(DISK_FREE_AFTER_GB + (reclaimed - 18.4) * 0.15, DISK_TOTAL_GB - 8.0)
	_refresh_disk_panel()
	_log_line(_log_text("disk_cleanup"))
	_emit("disk_cleanup")
	_refresh_all()
	_refresh_status("Disk Cleanup finished. Free space restored on C:.")


# ── Gameplay (unchanged contract) ────────────────────────────────────────────


func _perform(step_id: String) -> void:
	if step_id == "disk_cleanup_open":
		_open_window("disk")
		return
	var blocked: String = _blocked_reason(step_id)
	if blocked != "":
		_log_line("[color=#b86]%s[/color]" % blocked)
		_refresh_status(blocked)
		return

	if step_id == "pick_root":
		_confirm_root_cause()
		return

	_done[step_id] = true
	_apply_findings(step_id)
	_log_line(_log_text(step_id))
	_emit(step_id)
	_refresh_all()


func _blocked_reason(step_id: String) -> String:
	match step_id:
		"open_case_pm":
			if not _done.has("ground_up"):
				return "Clip the ESD strap before opening the case."
		"dust_out", "check_fans", "reseat_ram", "check_cables_int":
			if not _done.has("open_case_pm"):
				return "Open the case before working on internals."
		"verify_ip":
			if not _done.has("check_nic"):
				return "Enable the adapter before checking addressing."
		"ping_path":
			if not _done.has("verify_ip"):
				return "Fix IP, gateway, and DNS before pinging."
		"apply_fix":
			if not _done.has("pick_root"):
				return "Confirm the root cause before repairing."
		"retest_perf", "retest_net":
			if not _done.has("apply_fix"):
				return "Apply the corrective action before retesting."
		"write_report":
			if not _done.has("retest_perf") or not _done.has("retest_net"):
				return "Retest performance and internet before closing the ticket."
	return ""


func _apply_findings(step_id: String) -> void:
	match step_id:
		"dust_out":
			_found["dust_thermal"] = true
		"reseat_ram":
			_found["loose_ram"] = true
		"malware_scan":
			_found["malware"] = true
		"disk_cleanup":
			_found["full_disk"] = true
		"swap_patch":
			_found["bad_cable"] = true
		"verify_ip":
			_found["bad_ip"] = true


func _confirm_root_cause() -> void:
	if _root_option == null:
		return
	if _found.is_empty():
		_log_line("[color=#b86]No evidence gathered yet — run maintenance first.[/color]")
		_refresh_status("Gather evidence with hardware and software PM before diagnosing.")
		return
	var choice: String = str(_root_option.get_item_metadata(_root_option.selected))
	if choice != ROOT_CAUSE:
		_log_line("[color=#a22]Evidence does not support %s as the primary cause.[/color]" % _cause_label(choice))
		_refresh_status("That fault was present but is not what slowed the PC. Re-read the thermal evidence.")
		return
	_root_choice = choice
	_done["pick_root"] = true
	_log_line("[color=#185]Root cause confirmed:[/color] %s" % _cause_label(choice))
	_emit("pick_root")
	_refresh_all()


func _emit(step_id: String) -> void:
	action_submitted.emit(SimulationAction.new("tap", step_id, ""))


func _log_text(step_id: String) -> String:
	match step_id:
		"read_ticket":
			return "Ticket read: slow PC, intermittent internet, heavy dust."
		"ask_clarify":
			return "User confirms: worse over the last month, no recent changes."
		"stage_tools":
			return "Toolkit, ESD strap/mat, air, and spare cable staged."
		"backup_note":
			return "User data flagged for backup before invasive repair."
		"plan_order":
			return "Plan set: hardware → software → network → repair → document."
		"ground_up":
			return "ESD strap clipped to the chassis."
		"open_case_pm":
			return "Side panel removed; cable layout photographed."
		"dust_out":
			return "[color=#a60]Heavy dust cleared[/color] from fans, heatsink, and filters."
		"check_fans":
			return "Fans spin freely; CPU cooler seated correctly."
		"reseat_ram":
			return "[color=#a60]DIMM 2 was loose[/color] — reseated until both clips latched."
		"check_cables_int":
			return "SATA and power connectors reseated and tug-tested."
		"os_updates":
			return "OS and security updates installed."
		"malware_scan":
			return "[color=#a60]Malware found[/color] and quarantined."
		"startup_trim":
			return "Unnecessary startup entries disabled."
		"disk_cleanup":
			return "[color=#a60]System drive was full[/color] — cleared selected files; C: now has %.0f GB free." % _disk_free_gb
		"driver_health":
			return "Chipset, storage, and network drivers current."
		"check_nic":
			return "[color=#a60]Adapter was disabled[/color] — re-enabled."
		"swap_patch":
			return "[color=#a60]Patch cable latch broken[/color] — replaced."
		"check_switch_port":
			return "Switch link light green on the new port."
		"verify_ip":
			return "[color=#a60]Static IP was wrong[/color] — DHCP renewed."
		"ping_path":
			return "[color=#185]Ping OK[/color] gateway and external host."
		"apply_fix":
			return "Corrective action applied for %s." % _cause_label(_root_choice)
		"retest_perf":
			return "[color=#185]Performance normal[/color] under load after cleaning."
		"retest_net":
			return "[color=#185]Internet stable[/color] across repeated tests."
		"write_report":
			return "Service report written: symptoms, cause, fix, parts, time."
		_:
			return step_id


func _cause_label(cause_id: String) -> String:
	match cause_id:
		"dust_thermal":
			return "dust / thermal throttling"
		"loose_ram":
			return "a loose RAM module"
		"bad_cable":
			return "a faulty network cable"
		"bad_ip":
			return "incorrect IP configuration"
		"malware":
			return "malware infection"
		"full_disk":
			return "a full storage drive"
		_:
			return "the selected fault"


func _refresh_all() -> void:
	if _ticket_label != null:
		var lines: PackedStringArray = PackedStringArray()
		lines.append("Slow PC · intermittent internet · dust")
		lines.append(_state_line("Ticket reviewed", "read_ticket"))
		lines.append(_state_line("User clarified", "ask_clarify"))
		lines.append(_state_line("Tools & ESD staged", "stage_tools"))
		lines.append(_state_line("Backup flagged", "backup_note"))
		lines.append(_state_line("Service order planned", "plan_order"))
		_ticket_label.text = "\n".join(lines)

	if _hardware_label != null:
		var lines2: PackedStringArray = PackedStringArray()
		lines2.append(_state_line("ESD protection", "ground_up"))
		lines2.append(_state_line("Case open", "open_case_pm"))
		lines2.append(_state_line("Dust cleared", "dust_out"))
		lines2.append(_state_line("Fans checked", "check_fans"))
		lines2.append(_state_line("RAM reseated", "reseat_ram"))
		lines2.append(_state_line("Internal cables", "check_cables_int"))
		_hardware_label.text = "\n".join(lines2)

	if _software_label != null:
		var lines3: PackedStringArray = PackedStringArray()
		lines3.append(_disk_state_line())
		lines3.append(_state_line("Updates installed", "os_updates"))
		lines3.append(_state_line("Malware scan", "malware_scan"))
		lines3.append(_state_line("Startup trimmed", "startup_trim"))
		lines3.append(_state_line("Disk space freed", "disk_cleanup"))
		lines3.append(_state_line("Drivers current", "driver_health"))
		_software_label.text = "\n".join(lines3)

	if _network_label != null:
		var lines4: PackedStringArray = PackedStringArray()
		lines4.append(_state_line("Adapter enabled", "check_nic"))
		lines4.append(_state_line("Patch cable", "swap_patch"))
		lines4.append(_state_line("Switch link", "check_switch_port"))
		lines4.append(_state_line("IP / gateway / DNS", "verify_ip"))
		lines4.append(_state_line("Ping path", "ping_path"))
		lines4.append("Root cause: %s" % (_cause_label(_root_choice) if _root_choice != "" else "not confirmed"))
		_network_label.text = "\n".join(lines4)

	_refresh_disk_panel()
	_refresh_action_states()
	_sync_hardware_visual()
	_refresh_network_visual()
	_refresh_alerts()


func _state_line(label: String, step_id: String) -> String:
	return "%s %s" % ["✓" if _done.has(step_id) else "·", label]


func _disk_state_line() -> String:
	var prefix := "✓" if _disk_cleaned else "!"
	var free_text := "%.0f GB free on C:" % _disk_free_gb
	if not _disk_cleaned:
		return "%s %s (critical — run Disk Cleanup)" % [prefix, free_text]
	return "%s %s (cleaned)" % [prefix, free_text]


func _refresh_action_states() -> void:
	for key in _action_buttons.keys():
		var btn: Button = _action_buttons[key] as Button
		if btn == null or not is_instance_valid(btn):
			continue
		if str(key) == "disk_cleanup_open":
			continue
		var is_next: bool = guided_hints and str(key) == _hint_target
		_style_action_btn(btn, _done.has(key), is_next)
	# Disk cleanup OK button
	if _action_buttons.has("disk_cleanup"):
		var dbtn: Button = _action_buttons["disk_cleanup"] as Button
		if dbtn != null:
			var is_next_d: bool = guided_hints and _hint_target == "disk_cleanup"
			_style_action_btn(dbtn, _done.has("disk_cleanup"), is_next_d)
			if not _done.has("disk_cleanup"):
				dbtn.text = "OK"
				if is_next_d:
					dbtn.text = "OK — Run Disk Cleanup"


func _refresh_hints() -> void:
	if not guided_hints or _hint_target == "":
		return
	_refresh_status("Next action: %s" % _hint_label(_hint_target))


func _hint_label(step_id: String) -> String:
	var btn: Button = _action_buttons.get(step_id, null) as Button
	if btn != null and is_instance_valid(btn):
		return str(btn.get_meta("base_text", step_id))
	return step_id


func _refresh_status(text: String) -> void:
	if _status != null:
		_status.text = text


func _log_line(line: String) -> void:
	if _log == null:
		return
	_log.text = str(_log.text) + "\n" + line


func _bind_btn_colors(btn: Button, fg: Color) -> void:
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	btn.add_theme_color_override("font_focus_color", fg)
	btn.add_theme_color_override("font_disabled_color", Color(fg.r, fg.g, fg.b, 0.55))


func _register_hidden_step(step_id: String, group: String, label: String) -> void:
	var btn := Button.new()
	btn.visible = false
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.set_meta("base_text", label)
	_action_buttons[step_id] = btn
	_step_group[step_id] = group
	add_child(btn)


func _try_step(step_id: String) -> void:
	if _done.has(step_id):
		return
	_perform(step_id)


func _hotspot_btn(text: String, kind: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.custom_minimum_size = Vector2(0, 36)
	btn.set_meta("base_text", text)
	_style_win_btn(btn, false)
	btn.pressed.connect(func() -> void: _on_hotspot(kind))
	if kind == "check_fans" or kind == "reseat_ram" or kind == "check_cables_int":
		_action_buttons[kind] = btn
		_step_group[kind] = "hardware"
	return btn


func _on_hotspot(kind: String) -> void:
	if kind == "dust_heatsink" or kind == "dust_fans":
		var blocked: String = _blocked_reason("dust_out")
		if blocked != "":
			_refresh_status(blocked)
			return
		_dust_hits += 1
		_sync_hardware_visual()
		if _dust_hits >= 2:
			_try_step("dust_out")
		else:
			_refresh_status("Dust remaining — clean the other area too.")
		return
	_try_step(kind)


func _sync_hardware_visual() -> void:
	if _esd_check != null and _done.has("ground_up"):
		_esd_check.set_pressed_no_signal(true)
	var opened: bool = _done.has("open_case_pm")
	if _case_closed != null:
		_case_closed.visible = not opened
	if _case_open != null:
		_case_open.visible = opened
	if _dust_overlay != null:
		if _done.has("dust_out"):
			_dust_overlay.visible = false
		else:
			_dust_overlay.visible = opened
			var remaining: float = clampf(0.55 - float(_dust_hits) * 0.22, 0.12, 0.55)
			_dust_overlay.color = Color(0.45, 0.38, 0.22, remaining)


func _net_field(placeholder: String, default_text: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.text = default_text
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(0, 30)
	edit.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	return edit


func _labeled_net(caption: String, edit: LineEdit) -> VBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 2)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl := Label.new()
	lbl.text = caption
	lbl.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(11))
	lbl.add_theme_color_override("font_color", WIN_MUTED)
	wrap.add_child(lbl)
	wrap.add_child(edit)
	return wrap


func _swap_patch_cable() -> void:
	_try_step("swap_patch")
	_refresh_network_visual()


func _renew_dhcp() -> void:
	if _ip_edit == null:
		return
	_ip_edit.text = OFFICE_IP
	_mask_edit.text = OFFICE_MASK
	_gw_edit.text = OFFICE_GW
	_dns_edit.text = OFFICE_DNS
	_apply_ip_settings()


func _apply_ip_settings() -> void:
	if _ip_edit == null:
		return
	var ip: String = _ip_edit.text.strip_edges()
	var mask: String = _mask_edit.text.strip_edges()
	var gw: String = _gw_edit.text.strip_edges()
	var dns: String = _dns_edit.text.strip_edges()
	var ok: bool = ip == OFFICE_IP and mask == OFFICE_MASK and gw == OFFICE_GW and dns == OFFICE_DNS
	if not ok:
		_log_line("[color=#b86]Static IP rejected — does not match the office network.[/color]")
		_refresh_status("Office plan is %s / %s / gw %s / dns %s — or tap Renew DHCP." % [OFFICE_IP, OFFICE_MASK, OFFICE_GW, OFFICE_DNS])
		return
	_try_step("verify_ip")


func _run_ping() -> void:
	var blocked: String = _blocked_reason("ping_path")
	if blocked != "":
		_refresh_status(blocked)
		if _ping_out != null:
			_ping_out.text = "[color=#a22]%s[/color]" % blocked
		return
	if _ping_edit == null:
		return
	var target: String = _ping_edit.text.strip_edges()
	if target == OFFICE_GW:
		_pinged_gw = true
		_ping_out.text = "[color=#185]Reply from %s: bytes=32 time=1ms TTL=64[/color]" % OFFICE_GW
		if not _pinged_ext:
			_refresh_status("Gateway reachable. Now ping %s." % PING_EXT)
	elif target == PING_EXT:
		_pinged_ext = true
		_ping_out.text = "[color=#185]Reply from %s: bytes=32 time=18ms TTL=117[/color]" % PING_EXT
	else:
		_ping_out.text = "[color=#a22]Request timed out.[/color]"
		_refresh_status("Ping the gateway %s first, then %s." % [OFFICE_GW, PING_EXT])
		return
	if _pinged_gw and _pinged_ext:
		_try_step("ping_path")


func _refresh_network_visual() -> void:
	if _nic_check != null:
		_nic_check.set_pressed_no_signal(_done.has("check_nic"))
		_nic_check.text = (
			"Ethernet adapter enabled"
			if _done.has("check_nic")
			else "Enable Ethernet adapter (currently disabled)"
		)
	if _cable_status != null:
		if _done.has("swap_patch"):
			_cable_status.text = "Patch cable: replaced · latch OK"
			_cable_status.add_theme_color_override("font_color", Color(0.12, 0.45, 0.22))
		else:
			_cable_status.text = "Patch cable: broken latch · no link"
			_cable_status.add_theme_color_override("font_color", Color(0.7, 0.15, 0.12))
	if _link_light != null:
		var linked: bool = _done.has("check_switch_port") or _done.has("swap_patch")
		_link_light.color = Color(0.15, 0.75, 0.28) if linked else Color(0.55, 0.12, 0.1)


func _submit_service_report() -> void:
	var blocked: String = _blocked_reason("write_report")
	if blocked != "":
		_refresh_status(blocked)
		return
	var ticket := ""
	if _ticket_no_edit != null:
		ticket = _ticket_no_edit.text.strip_edges()
	if ticket != TICKET_ID:
		_refresh_status("Type the ticket number exactly: %s" % TICKET_ID)
		return
	var body := ""
	if _report_edit != null:
		body = _report_edit.text.to_lower()
	if body.find("dust") < 0 or (body.find("clean") < 0 and body.find("thermal") < 0):
		_refresh_status("Write the report: mention dust and the cleanup / thermal fix.")
		return
	_try_step("write_report")


func _build_alert_tray(parent: Control) -> void:
	_alert_panel = PanelContainer.new()
	_alert_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_alert_panel.anchor_left = 1.0
	_alert_panel.offset_left = -208
	_alert_panel.offset_right = -6
	_alert_panel.offset_top = 8
	_alert_panel.offset_bottom = -44
	_alert_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.94)
	style.border_color = Color(0.95, 0.7, 0.25, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_alert_panel.add_theme_stylebox_override("panel", style)
	_alert_panel.z_index = 40
	parent.add_child(_alert_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_alert_panel.add_child(col)

	var hdr := Label.new()
	hdr.text = "Action Center"
	hdr.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(12))
	hdr.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
	col.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_alert_col = VBoxContainer.new()
	_alert_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_alert_col.add_theme_constant_override("separation", 6)
	scroll.add_child(_alert_col)


func _refresh_alerts() -> void:
	if _alert_panel == null or _alert_col == null:
		return
	_alert_panel.visible = not guided_hints
	if guided_hints:
		return
	for child in _alert_col.get_children():
		child.queue_free()
	var items: Array = _open_alerts()
	if items.is_empty():
		_alert_col.add_child(_alert_card("All clear", "No open warnings on this workstation.", "", false))
		return
	for item in items:
		var entry: Dictionary = item
		_alert_col.add_child(_alert_card(str(entry.get("title", "")), str(entry.get("body", "")), str(entry.get("win", "")), true))


func _open_alerts() -> Array:
	var out: Array = []
	if not _disk_cleaned:
		out.append({
			"title": "Storage almost full",
			"body": "C: has %.0f GB free. Empty Recycle Bin and run Disk Cleanup." % _disk_free_gb,
			"win": "disk"
		})
	if not _done.has("malware_scan"):
		out.append({
			"title": "Threat detected",
			"body": "Windows Security has not scanned this PC yet.",
			"win": "software"
		})
	if not _done.has("check_nic"):
		out.append({
			"title": "No internet",
			"body": "Ethernet adapter is disabled.",
			"win": "network"
		})
	if not _done.has("swap_patch"):
		out.append({
			"title": "Unstable link",
			"body": "Patch cable latch is broken — swap the cable.",
			"win": "network"
		})
	if not _done.has("verify_ip"):
		out.append({
			"title": "Bad IP config",
			"body": "Static address does not match the office plan.",
			"win": "network"
		})
	if not _done.has("dust_out"):
		out.append({
			"title": "Overheating",
			"body": "Heatsink and fans are packed with dust.",
			"win": "hardware"
		})
	if not _done.has("reseat_ram"):
		out.append({
			"title": "Memory warning",
			"body": "DIMM 2 is not fully seated.",
			"win": "hardware"
		})
	return out


func _alert_card(title: String, body: String, win_id: String, warn: bool) -> Button:
	var btn := Button.new()
	btn.text = "%s\n%s" % [title, body]
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 58)
	var style := StyleBoxFlat.new()
	if warn:
		style.bg_color = Color(0.28, 0.16, 0.06, 0.96)
		style.border_color = Color(0.95, 0.65, 0.2, 0.8)
	else:
		style.bg_color = Color(0.08, 0.22, 0.16, 0.96)
		style.border_color = Color(0.35, 0.75, 0.5, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = style.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", pressed)
	_bind_btn_colors(btn, Color(0.98, 0.95, 0.88) if warn else Color(0.86, 0.96, 0.9))
	btn.add_theme_font_size_override("font_size", ResponsiveLayout.readable_font(10))
	if win_id != "":
		btn.pressed.connect(func() -> void: _open_window(win_id))
	return btn
