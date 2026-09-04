extends Control

## Module 3 Server Admin workstation: folders, groups, NTFS, shares, client tests.

signal action_submitted(action: SimulationAction)

## Below this width the state column stacks above the action grid.
const STACK_WIDTH := 780.0
## Below this width the action cards collapse to a single column.
const SINGLE_COLUMN_WIDTH := 560.0

var guided_hints: bool = true
var _hint_target: String = ""
var _hint_destination: String = ""

var _folders: Dictionary = {}
var _groups: Dictionary = {}
var _users: Dictionary = {}
var _ntfs: Dictionary = {}
var _shares: Dictionary = {}
var _identified: Dictionary = {}

var _status: Label = null
var _tree_label: Label = null
var _accounts_label: Label = null
var _shares_label: Label = null
var _log: RichTextLabel = null
var _client_user: OptionButton = null
var _client_share: OptionButton = null
var _columns: BoxContainer = null
var _state_col: VBoxContainer = null
var _action_columns: BoxContainer = null
var _action_scroll: ScrollContainer = null
var _action_buttons: Dictionary = {}


func _ready() -> void:
	# Sit cleanly inside ModuleShell VBox — do not use full-rect anchors (they clip left).
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
	_refresh_status("Server Manager — follow the mission strip, then run the highlighted admin action.")


func setup(_unused: Array = [], hints: bool = true) -> void:
	guided_hints = hints
	if _status == null:
		call_deferred("setup", _unused, hints)
		return
	_refresh_action_states()
	_refresh_hints()
	if _hint_target != "":
		_scroll_to_hint()


func set_guided_hint(target: String, destination: String) -> void:
	_hint_target = target
	_hint_destination = destination
	_apply_access_test_hint()
	_refresh_hints()
	_refresh_action_states()
	_scroll_to_hint()


func mark_step_done(_target: String, _destination: String) -> void:
	_refresh_all()


func reset_scenario() -> void:
	_folders.clear()
	_groups.clear()
	_users.clear()
	_ntfs.clear()
	_shares.clear()
	_identified.clear()
	_hint_target = ""
	_hint_destination = ""
	if _log != null:
		_log.text = "Windows PowerShell transcript ready."
	_refresh_all()
	_refresh_status("Server Manager reset — configure shares from a clean state.")


func flash_incorrect() -> void:
	if _status != null:
		_status.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		_refresh_status("Incorrect admin action — check the current step.")
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			if _status != null:
				_status.add_theme_color_override("font_color", Color(0.78, 0.9, 0.98))
		)


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_action_buttons.clear()

	# The parent is a bare Control, so the root container must claim the full
	# rect itself — size flags alone leave it collapsed at its minimum size.
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	root.add_child(_build_title_bar())

	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", Color(0.78, 0.9, 0.98))
	root.add_child(_status)

	# Plain BoxContainer: only this base class allows flipping orientation,
	# which is how the workstation collapses to one column on narrow screens.
	_columns = BoxContainer.new()
	_columns.vertical = false
	_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_columns.add_theme_constant_override("separation", 12)
	root.add_child(_columns)

	_state_col = _build_state_column()
	_columns.add_child(_state_col)
	_columns.add_child(_build_action_column())

	_columns.resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _build_state_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(240, 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = 1.0
	col.add_theme_constant_override("separation", 6)

	# The readouts grow as folders, groups, and shares appear, so they scroll
	# instead of pushing the event log past the bottom of the workstation.
	var state_scroll := ScrollContainer.new()
	state_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	state_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(state_scroll)

	var cards := VBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 6)
	state_scroll.add_child(cards)

	cards.add_child(_section("Roles and Features", _build_roles_row()))
	_tree_label = _state_label()
	cards.add_child(_section("Shared Folders", _tree_label))
	_accounts_label = _state_label()
	cards.add_child(_section("Local Users and Groups", _accounts_label))
	_shares_label = _state_label()
	cards.add_child(_section("Published Shares", _shares_label))

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.fit_content = false
	_log.scroll_active = true
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(0, 62)
	_log.add_theme_font_size_override("normal_font_size", 11)
	_log.add_theme_font_size_override("bold_font_size", 11)
	_log.add_theme_color_override("default_color", Color(0.75, 0.78, 0.82))
	_log.text = "Windows PowerShell transcript ready."
	col.add_child(_section("Event log", _log))
	return col


func _build_title_bar() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.28, 0.48, 0.98)
	style.border_color = Color(0.35, 0.55, 0.75, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	bar.add_child(row)
	var title := Label.new()
	title.text = "Server Manager  ·  Local Server (SERVER01)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	row.add_child(title)
	var sub := Label.new()
	sub.text = "File and Storage Services"
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.75, 0.88, 0.98, 0.9))
	row.add_child(sub)
	return bar


func _build_action_column() -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(300, 0)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.size_flags_stretch_ratio = 1.75
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.11, 0.15, 0.98)
	style.border_color = Color(0.32, 0.48, 0.62, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	wrap.add_theme_stylebox_override("panel", style)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.add_child(col)

	var hdr := Label.new()
	hdr.text = "Server Manager · Actions"
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92))
	col.add_child(hdr)

	_action_scroll = ScrollContainer.new()
	_action_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_action_scroll)

	# Two packed columns rather than a grid: grid rows align to the tallest card
	# and push the last group off-screen at 720p. Reading order stays 1-2-3-4.
	_action_columns = BoxContainer.new()
	_action_columns.vertical = false
	_action_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_action_columns.add_theme_constant_override("separation", 10)
	_action_scroll.add_child(_action_columns)

	var pack_a := _action_pack()
	pack_a.add_child(_action_card("Storage", _build_folder_actions()))
	pack_a.add_child(_action_card("Groups & Users", _build_account_actions()))
	_action_columns.add_child(pack_a)

	var pack_b := _action_pack()
	pack_b.add_child(_action_card("NTFS & Sharing", _build_perm_actions()))
	pack_b.add_child(_action_card("Connect to Share", _build_client_panel()))
	_action_columns.add_child(pack_b)
	return wrap


func _action_pack() -> VBoxContainer:
	var pack := VBoxContainer.new()
	pack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pack.add_theme_constant_override("separation", 10)
	return pack


## Keeps the workstation readable from phone widths up to desktop.
func _apply_responsive_layout() -> void:
	if _columns == null or not is_instance_valid(_columns):
		return
	var width: float = _columns.size.x
	if width < 1.0:
		width = size.x
	var stacked: bool = width > 0.0 and width < STACK_WIDTH
	if _columns.is_vertical() != stacked:
		_columns.set_vertical(stacked)
	if _state_col != null and is_instance_valid(_state_col):
		_state_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if stacked else Control.SIZE_EXPAND_FILL
	var single: bool = width > 0.0 and width < SINGLE_COLUMN_WIDTH
	if _action_columns != null and is_instance_valid(_action_columns) and _action_columns.is_vertical() != single:
		_action_columns.set_vertical(single)


func _section(title: String, body: Control, expand: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if expand:
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.16, 0.96)
	style.border_color = Color(0.35, 0.42, 0.52, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(col)
	col.add_child(_card_header(title, Color(0.78, 0.82, 0.88)))
	if body != null:
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if expand:
			body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(body)
	return panel


func _action_card(title: String, body: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.14, 0.22, 0.75)
	style.border_color = Color(0.3, 0.6, 0.75, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(col)
	col.add_child(_card_header(title, Color(0.72, 0.78, 0.88)))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	return panel


func _card_header(title: String, color: Color) -> Label:
	var hdr := Label.new()
	hdr.text = title
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", color)
	return hdr


func _state_label() -> Label:
	var lbl := Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_constant_override("line_spacing", 2)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.90, 0.94))
	return lbl


func _build_roles_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_action_btn("Identify File Server", func() -> void: _identify("server"), "role:server"))
	row.add_child(_action_btn("Identify NAS / Storage", func() -> void: _identify("storage"), "role:storage"))
	row.add_child(_action_btn("Identify Client PC", func() -> void: _identify("client"), "role:client"))
	return row


func _build_folder_actions() -> VBoxContainer:
	var col := _action_list()
	col.add_child(_action_btn("New Folder…  D:\\Shares", func() -> void: _mkdir("shares_root"), "folder:shares_root"))
	col.add_child(_action_btn("New Folder…  Accounting", func() -> void: _mkdir("accounting"), "folder:accounting"))
	col.add_child(_action_btn("New Folder…  HumanResources", func() -> void: _mkdir("hr"), "folder:hr"))
	return col


func _build_account_actions() -> VBoxContainer:
	var col := _action_list()
	col.add_child(_action_btn("New Group…  G_Accounting", func() -> void: _create_group("g_accounting"), "group:g_accounting"))
	col.add_child(_action_btn("New Group…  G_HR", func() -> void: _create_group("g_hr"), "group:g_hr"))
	col.add_child(_action_btn("New User…  Anna", func() -> void: _create_user("anna", "g_accounting"), "user:anna"))
	col.add_child(_action_btn("New User…  Hiro", func() -> void: _create_user("hiro", "g_hr"), "user:hiro"))
	col.add_child(_action_btn("Add to Group…  Anna → G_Accounting", func() -> void: _add_to_group("anna", "g_accounting"), "nest:anna"))
	col.add_child(_action_btn("Add to Group…  Hiro → G_HR", func() -> void: _add_to_group("hiro", "g_hr"), "nest:hiro"))
	return col


func _build_perm_actions() -> VBoxContainer:
	var col := _action_list()
	col.add_child(_action_btn("Permissions…  Accounting (NTFS)", func() -> void: _set_ntfs("accounting", "g_accounting"), "ntfs:accounting"))
	col.add_child(_action_btn("Permissions…  HumanResources (NTFS)", func() -> void: _set_ntfs("hr", "g_hr"), "ntfs:hr"))
	col.add_child(_action_btn("Advanced Sharing…  Accounting", func() -> void: _publish_share("accounting"), "share:accounting"))
	col.add_child(_action_btn("Advanced Sharing…  HumanResources", func() -> void: _publish_share("hr"), "share:hr"))
	return col


func _build_client_panel() -> VBoxContainer:
	var col := _action_list()
	_client_user = _client_option([["Anna (Accounting)", "anna"], ["Hiro (HR)", "hiro"]])
	col.add_child(_field_label("Sign in as"))
	col.add_child(_client_user)
	_client_share = _client_option([["\\\\Server\\Accounting", "accounting"], ["\\\\Server\\HumanResources", "hr"]])
	col.add_child(_field_label("Connect to share"))
	col.add_child(_client_share)
	col.add_child(_action_btn("Test Connection", _run_access_test, "access_test"))
	return col


func _action_list() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return col


func _field_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.8, 0.9))
	return lbl


func _client_option(entries: Array) -> OptionButton:
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.custom_minimum_size = Vector2(0, 32)
	opt.clip_text = true
	opt.add_theme_font_size_override("font_size", 12)
	for index in entries.size():
		var entry: Array = entries[index]
		opt.add_item(str(entry[0]), index)
		opt.set_item_metadata(index, str(entry[1]))
	return opt


func _action_btn(text: String, cb: Callable, state_key: String = "") -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.custom_minimum_size = Vector2(0, 30)
	btn.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	btn.add_theme_font_size_override("font_size", 12)
	btn.set_meta("base_text", text)
	btn.pressed.connect(cb)
	_style_action_btn(btn, false)
	if state_key != "":
		_action_buttons[state_key] = btn
	return btn


func _style_action_btn(btn: Button, done: bool, is_next: bool = false) -> void:
	var style := StyleBoxFlat.new()
	if done:
		style.bg_color = Color(0.12, 0.32, 0.22, 0.95)
		style.border_color = Color(0.35, 0.75, 0.55, 0.55)
	elif is_next:
		style.bg_color = Color(0.28, 0.22, 0.08, 0.95)
		style.border_color = Color(1.0, 0.78, 0.32, 0.85)
	else:
		style.bg_color = Color(0.14, 0.18, 0.24, 0.95)
		style.border_color = Color(0.42, 0.48, 0.58, 0.45)
	style.set_border_width_all(2 if is_next and not done else 1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	var font_color := Color(0.92, 0.94, 0.98)
	if done:
		font_color = Color(0.72, 0.92, 0.78)
	elif is_next:
		font_color = Color(1.0, 0.88, 0.62)
	btn.add_theme_color_override("font_color", font_color)
	var base: String = str(btn.get_meta("base_text", btn.text))
	btn.text = ("✓ %s" % base) if done else base


func _identify(role: String) -> void:
	_identified[role] = true
	_log_line("Identified: %s" % role)
	_emit("identify", role, "")
	_refresh_all()


func _mkdir(folder_id: String) -> void:
	if folder_id == "accounting" or folder_id == "hr":
		if not _folders.has("shares_root"):
			_log_line("Create D:\\Shares first.")
			_refresh_status("Create the data root before department folders.")
			return
	_folders[folder_id] = true
	_log_line("Created: %s" % _folder_label(folder_id))
	_emit("mkdir", folder_id, "")
	_refresh_all()


func _create_group(group_id: String) -> void:
	_groups[group_id] = true
	_log_line("Group created: %s" % group_id)
	_emit("create_group", group_id, "")
	_refresh_all()


func _create_user(user_id: String, default_group: String) -> void:
	_users[user_id] = ""
	_log_line("User created: %s" % user_id)
	_emit("create_user", user_id, default_group)
	_refresh_all()


func _add_to_group(user_id: String, group_id: String) -> void:
	if not _users.has(user_id):
		_log_line("Create the user first.")
		return
	if not _groups.has(group_id):
		_log_line("Create the group first.")
		return
	_users[user_id] = group_id
	_log_line("Added %s → %s" % [user_id, group_id])
	_emit("add_to_group", user_id, group_id)
	_refresh_all()


func _set_ntfs(folder_id: String, group_id: String) -> void:
	if not _folders.has(folder_id):
		_log_line("Create the folder first.")
		return
	if not _groups.has(group_id):
		_log_line("Create the group first.")
		return
	_ntfs[folder_id] = group_id
	_log_line("NTFS Modify: %s on %s" % [group_id, folder_id])
	_emit("set_ntfs", folder_id, group_id)
	_refresh_all()


func _publish_share(folder_id: String) -> void:
	if not _folders.has(folder_id):
		_log_line("Create the folder first.")
		return
	if not _ntfs.has(folder_id):
		_log_line("Set NTFS before sharing.")
		return
	_shares[folder_id] = true
	_log_line("Published \\\\Server\\%s" % _folder_label(folder_id))
	_emit("share", folder_id, "")
	_refresh_all()


func _run_access_test() -> void:
	if _client_user == null or _client_share == null:
		return
	var user_id: String = str(_client_user.get_item_metadata(_client_user.selected))
	var share_id: String = str(_client_share.get_item_metadata(_client_share.selected))
	if not _shares.has(share_id):
		_log_line("Share is not published yet.")
		_refresh_status("Publish the share before testing client access.")
		return
	var user_group: String = str(_users.get(user_id, ""))
	var allowed_group: String = str(_ntfs.get(share_id, ""))
	var ok := user_group != "" and user_group == allowed_group
	var result := "allow" if ok else "deny"
	if ok:
		_log_line("[color=#7d7]ACCESS OK[/color]  %s → %s" % [user_id, share_id])
	else:
		_log_line("[color=#f77]ACCESS DENIED[/color]  %s → %s" % [user_id, share_id])
	_emit("access_test", share_id, result)
	_refresh_status("Client test: %s" % ("authorized access works." if ok else "unauthorized access blocked."))


func _emit(action: String, target: String, destination: String) -> void:
	action_submitted.emit(SimulationAction.new(action, target, destination))


func _folder_label(folder_id: String) -> String:
	match folder_id:
		"shares_root":
			return "D:\\Shares"
		"accounting":
			return "Accounting"
		"hr":
			return "HumanResources"
		_:
			return folder_id


func _refresh_all() -> void:
	if _tree_label != null:
		var lines: PackedStringArray = PackedStringArray()
		lines.append("D:\\")
		if _folders.has("shares_root"):
			lines.append("└─ Shares")
			if _folders.has("accounting"):
				lines.append("   ├─ Accounting · NTFS %s" % _ntfs_label("accounting"))
			if _folders.has("hr"):
				lines.append("   └─ HumanResources · NTFS %s" % _ntfs_label("hr"))
			if not _folders.has("accounting") and not _folders.has("hr"):
				lines.append("   (no department folders yet)")
		else:
			lines.append("└─ (no Shares root yet)")
		_tree_label.text = "\n".join(lines)

	if _accounts_label != null:
		var lines2: PackedStringArray = PackedStringArray()
		lines2.append("Groups")
		if _groups.is_empty():
			lines2.append("   (none)")
		else:
			for g in _groups.keys():
				lines2.append("   • %s" % g)
		lines2.append("Users")
		if _users.is_empty():
			lines2.append("   (none)")
		else:
			for u in _users.keys():
				var grp: String = str(_users[u])
				lines2.append("   • %s → %s" % [u, grp if grp != "" else "(no group)"])
		_accounts_label.text = "\n".join(lines2)

	if _shares_label != null:
		var lines3: PackedStringArray = PackedStringArray()
		if _shares.is_empty():
			lines3.append("No shares published.")
		else:
			for s in _shares.keys():
				lines3.append("   • \\\\Server\\%s" % _folder_label(str(s)))
		var roles: PackedStringArray = PackedStringArray()
		for r in ["server", "storage", "client"]:
			if _identified.has(r):
				roles.append(r)
		lines3.append("Roles marked: %s" % (", ".join(roles) if not roles.is_empty() else "none"))
		_shares_label.text = "\n".join(lines3)

	_refresh_action_states()


func _ntfs_label(folder_id: String) -> String:
	var group_id: String = str(_ntfs.get(folder_id, ""))
	return group_id if group_id != "" else "unset"


## Completed milestones stay visible as green checks so students can audit work.
func _refresh_action_states() -> void:
	var done: Dictionary = {
		"role:server": _identified.has("server"),
		"role:storage": _identified.has("storage"),
		"role:client": _identified.has("client"),
		"folder:shares_root": _folders.has("shares_root"),
		"folder:accounting": _folders.has("accounting"),
		"folder:hr": _folders.has("hr"),
		"group:g_accounting": _groups.has("g_accounting"),
		"group:g_hr": _groups.has("g_hr"),
		"user:anna": _users.has("anna"),
		"user:hiro": _users.has("hiro"),
		"nest:anna": str(_users.get("anna", "")) != "",
		"nest:hiro": str(_users.get("hiro", "")) != "",
		"ntfs:accounting": _ntfs.has("accounting"),
		"ntfs:hr": _ntfs.has("hr"),
		"share:accounting": _shares.has("accounting"),
		"share:hr": _shares.has("hr"),
	}
	for key in _action_buttons.keys():
		var btn: Button = _action_buttons[key] as Button
		if btn == null or not is_instance_valid(btn):
			continue
		var is_next: bool = guided_hints and str(key) == _hint_button_key()
		_style_action_btn(btn, bool(done.get(key, false)), is_next)


func _hint_button_key() -> String:
	var t := _hint_target
	var d := _hint_destination
	if t in ["server", "storage", "client"]:
		return "role:" + t
	if t == "shares_root":
		return "folder:shares_root"
	if t in ["accounting", "hr"]:
		if d in ["allow", "deny"]:
			return "access_test"
		if d.begins_with("g_"):
			return "ntfs:" + t
		if _folders.has(t) and _ntfs.has(t):
			return "share:" + t
		return "folder:" + t
	if t.begins_with("g_"):
		return "group:" + t
	if t in ["anna", "hiro"]:
		if d.begins_with("g_"):
			return "nest:" + t
		return "user:" + t
	return t


func _scroll_to_hint() -> void:
	if not guided_hints or _hint_target == "":
		return
	if not is_inside_tree():
		return
	call_deferred("_deferred_scroll_hint")


func _deferred_scroll_hint() -> void:
	if _action_scroll == null or not is_instance_valid(_action_scroll):
		return
	var key := _hint_button_key()
	var btn: Button = _action_buttons.get(key, null) as Button
	if btn == null or not is_instance_valid(btn):
		return
	# ensure_control_visible errors if the button is not under the scroll yet.
	if not _action_scroll.is_ancestor_of(btn):
		return
	_action_scroll.ensure_control_visible(btn)


func _apply_access_test_hint() -> void:
	if _client_user == null or _client_share == null:
		return
	if _hint_destination not in ["allow", "deny"]:
		return
	var user_id := "anna" if _hint_target == "accounting" else "hiro" if _hint_target == "hr" else ""
	if user_id == "":
		return
	for i in _client_user.item_count:
		if str(_client_user.get_item_metadata(i)) == user_id:
			_client_user.select(i)
			break
	for i in _client_share.item_count:
		if str(_client_share.get_item_metadata(i)) == _hint_target:
			_client_share.select(i)
			break


func _refresh_hints() -> void:
	if not guided_hints or _hint_target == "":
		return
	var dest: String = ""
	match _hint_destination:
		"":
			dest = ""
		"allow":
			dest = " → expect ALLOW"
		"deny":
			dest = " → expect DENY"
		_:
			dest = " → %s" % _entity_label(_hint_destination)
	_refresh_status("Next target: %s%s" % [_entity_label(_hint_target), dest])


func _entity_label(entity_id: String) -> String:
	match entity_id:
		"server":
			return "File Server"
		"storage":
			return "NAS / Storage"
		"client":
			return "Client PC"
		"g_accounting":
			return "G_Accounting"
		"g_hr":
			return "G_HR"
		"anna":
			return "Anna"
		"hiro":
			return "Hiro"
		_:
			return _folder_label(entity_id)


func _refresh_status(text: String) -> void:
	if _status != null:
		_status.text = text


func _log_line(line: String) -> void:
	if _log == null:
		return
	_log.text = str(_log.text) + "\n" + line
