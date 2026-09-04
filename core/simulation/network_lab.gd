extends Control

## Packet Tracer-style topology: devices, dashed cables, animated packets.

signal action_submitted(action: SimulationAction)

const DEVICE_ORDER := ["modem", "router", "switch", "server", "ap", "pc1", "pc2"]
const DEVICE_LABELS := {
	"modem": "Modem",
	"router": "Router",
	"switch": "Switch",
	"server": "File Server",
	"pc1": "PC1",
	"pc2": "PC2",
	"ap": "Access Point",
}
const DEVICE_SUB := {
	"modem": "WAN Edge",
	"router": "Gateway",
	"switch": "LAN Hub",
	"server": "Server",
	"ap": "Wi-Fi",
	"pc1": "Client",
	"pc2": "Client",
}
## Border colors match the student sketch (yellow / green / purple / blue).
const DEVICE_COLORS := {
	"modem": Color(0.95, 0.82, 0.25),
	"router": Color(0.95, 0.82, 0.25),
	"switch": Color(0.35, 0.85, 0.45),
	"server": Color(0.95, 0.62, 0.28),
	"ap": Color(0.72, 0.42, 0.92),
	"pc1": Color(0.55, 0.72, 0.95),
	"pc2": Color(0.55, 0.72, 0.95),
}
const DEVICE_ICONS := {
	"modem": "res://assets/icons/network/icon_modem.png",
	"router": "res://assets/icons/network/icon_router.png",
	"switch": "res://assets/icons/network/icon_switch.png",
	"server": "res://assets/icons/network/icon_router.png",
	"ap": "res://assets/icons/network/icon_ap.png",
	"pc1": "res://assets/icons/network/icon_pc.png",
	"pc2": "res://assets/icons/network/icon_pc.png",
}
const NODE_SIZE := Vector2(118, 118)
const NODE_SIZE_COMPACT := Vector2(96, 96)
const ICON_SIZE := Vector2(72, 72)
const ICON_SIZE_COMPACT := Vector2(58, 58)
## Stack canvas above inspector below this width; compact toolbar above this.
const STACK_WIDTH := 880.0
const COMPACT_WIDTH := 1180.0

## Cisco cabling rule: unlike device classes take a straight-through cable,
## like classes take a crossover. Switches and modems sit on the "network" side.
const DEVICE_WIRING := {
	"pc1": "host",
	"pc2": "host",
	"router": "host",
	"ap": "host",
	"switch": "network",
	"server": "network",
	"modem": "network",
}

const CABLE_LABELS := {
	"straight": "Straight-Through",
	"crossover": "Crossover",
	"console": "Console",
}
const CABLE_COLORS := {
	"straight": Color(0.86, 0.93, 1.0, 0.85),
	"crossover": Color(1.0, 0.78, 0.35, 0.9),
	"console": Color(0.45, 0.78, 0.98, 0.85),
}
const LINK_UP_COLOR := Color(0.35, 0.92, 0.45)
const LINK_DOWN_COLOR := Color(1.0, 0.35, 0.35)

var guided_hints: bool = true
var _mode: String = "select" # select | cable
var _devices: Dictionary = {}
var _links: Array = [] # {a, b, cable, up}
var _cable_type: String = "straight"
var _cable_picker: OptionButton = null
var _selected_id: String = ""
var _cable_from: String = ""
var _hint_target: String = ""
var _hint_destination: String = ""
var _packets: Array = [] # {from, to, t, life, color}

var _canvas: Control = null
var _draw_layer: Control = null
var _status: Label = null
var _config_ip: LineEdit = null
var _config_mask: LineEdit = null
var _config_gw: LineEdit = null
var _config_dns: LineEdit = null
var _ping_target: LineEdit = null
var _cli_out: RichTextLabel = null
var _select_tool: Button = null
var _cable_tool: Button = null
var _layout_ready: bool = false
var _user_arranged: bool = false
var _topology_mode: bool = false
var _topo_config: Dictionary = {}
var _palette_row: HFlowContainer = null
var _delete_tool: Button = null
var _apply_ip_btn: Button = null
var _root_row: BoxContainer = null
var _left_col: VBoxContainer = null
var _right_col: VBoxContainer = null
var _reset_links_btn: Button = null
var _reset_layout_btn: Button = null
var _node_size: Vector2 = NODE_SIZE
var _icon_size: Vector2 = ICON_SIZE
var _drag_id: String = ""
var _drag_grab: Vector2 = Vector2.ZERO
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_moved: bool = false
const DRAG_THRESHOLD := 6.0


func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	if custom_minimum_size.y < 360.0:
		custom_minimum_size.y = 480.0 if get_viewport().get_visible_rect().size.y > 760.0 else 400.0
	_build_ui()
	if not _topology_mode:
		_spawn_default_topology()
	_refresh_status("Select = move/select devices · Cable = link two devices.")
	resized.connect(_apply_responsive_layout)
	set_process(true)
	call_deferred("_apply_responsive_layout")


func _process(delta: float) -> void:
	var need_redraw := false
	if not _packets.is_empty():
		var keep: Array = []
		for p in _packets:
			p.t = float(p.t) + delta / maxf(float(p.life), 0.05)
			if float(p.t) < 1.0:
				keep.append(p)
		_packets = keep
		need_redraw = true
	if _mode == "cable" and _cable_from != "":
		need_redraw = true
	if need_redraw and _draw_layer != null:
		_draw_layer.queue_redraw()


func setup(preset: Array = [], hints: bool = true) -> void:
	guided_hints = hints
	if _canvas == null:
		call_deferred("setup", preset, hints)
		return
	if preset.size() > 0 and typeof(preset[0]) == TYPE_DICTIONARY:
		_topo_config = (preset[0] as Dictionary).duplicate(true)
		_topology_mode = str(_topo_config.get("mode", "")) == "topology"
	if _palette_row != null:
		_palette_row.visible = _topology_mode
	if _delete_tool != null:
		_delete_tool.visible = _topology_mode
	if _topology_mode:
		_clear_topology()
		for dev in _topo_config.get("seed_devices", []):
			_add_device(str(dev))
		_refresh_status("Add devices from the palette, cable them, then address and ping.")
	elif _devices.is_empty():
		_spawn_default_topology()
	_refresh_hints()
	call_deferred("_relayout_devices")


func set_guided_hint(target: String, destination: String) -> void:
	_hint_target = target
	_hint_destination = destination
	_refresh_hints()


func flash_incorrect() -> void:
	if _status != null:
		_status.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		_refresh_status("Wrong link or setting — follow the current step.")
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			if _status != null:
				_status.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
		)


func mark_step_done(_target: String, _destination: String) -> void:
	_cable_from = ""
	_refresh_hints()


func reset_scenario() -> void:
	if not _topology_mode:
		_reset_links()
		_reset_layout()
		return
	_clear_topology()
	for dev in _topo_config.get("seed_devices", []):
		_add_device(str(dev))
	_selected_id = ""
	_cable_from = ""
	_refresh_hints()
	call_deferred("_relayout_devices")


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var root := BoxContainer.new()
	root.vertical = false
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	_root_row = root

	# ── Left: tools + topology + CLI ──
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 2.4
	left.add_theme_constant_override("separation", 6)
	root.add_child(left)
	_left_col = left

	var toolbar := PanelContainer.new()
	var tb_style := StyleBoxFlat.new()
	tb_style.bg_color = Color(0.05, 0.12, 0.2, 0.95)
	tb_style.border_color = Color(0.28, 0.55, 0.7, 0.35)
	tb_style.set_border_width_all(1)
	tb_style.set_corner_radius_all(10)
	tb_style.content_margin_left = 8
	tb_style.content_margin_right = 8
	tb_style.content_margin_top = 6
	tb_style.content_margin_bottom = 6
	toolbar.add_theme_stylebox_override("panel", tb_style)
	left.add_child(toolbar)

	# PanelContainer only lays out ONE child — stack tool + palette rows in a VBox.
	var toolbar_stack := VBoxContainer.new()
	toolbar_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar_stack.add_theme_constant_override("separation", 6)
	toolbar.add_child(toolbar_stack)

	var toolbar_row := HBoxContainer.new()
	toolbar_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar_row.add_theme_constant_override("separation", 8)
	toolbar_stack.add_child(toolbar_row)

	var tools_lbl := Label.new()
	tools_lbl.text = "TOOLS"
	tools_lbl.add_theme_font_size_override("font_size", 10)
	tools_lbl.add_theme_color_override("font_color", Color(0.5, 0.75, 0.9, 0.85))
	toolbar_row.add_child(tools_lbl)

	_select_tool = _tool_btn("Select", "select")
	_cable_tool = _tool_btn("Cable", "cable")
	toolbar_row.add_child(_select_tool)
	toolbar_row.add_child(_cable_tool)

	# Picking the wrong cable is the mistake this station is meant to teach, so
	# the type is an explicit choice rather than something the lab infers.
	_cable_picker = OptionButton.new()
	_cable_picker.focus_mode = Control.FOCUS_NONE
	_cable_picker.custom_minimum_size = Vector2(0, 30)
	_cable_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cable_picker.add_theme_font_size_override("font_size", 12)
	var cable_ids: Array = ["straight", "crossover", "console"]
	for index in cable_ids.size():
		var cable_id: String = str(cable_ids[index])
		_cable_picker.add_item(str(CABLE_LABELS[cable_id]), index)
		_cable_picker.set_item_metadata(index, cable_id)
	_cable_picker.item_selected.connect(_on_cable_type_selected)
	_style_btn(_cable_picker, false)
	toolbar_row.add_child(_cable_picker)

	var reset_links_btn := Button.new()
	reset_links_btn.text = "Reset Links"
	reset_links_btn.focus_mode = Control.FOCUS_NONE
	_style_btn(reset_links_btn, false)
	reset_links_btn.pressed.connect(_reset_links)
	_reset_links_btn = reset_links_btn
	toolbar_row.add_child(reset_links_btn)

	var reset_layout_btn := Button.new()
	reset_layout_btn.text = "Reset Layout"
	reset_layout_btn.focus_mode = Control.FOCUS_NONE
	_style_btn(reset_layout_btn, false)
	reset_layout_btn.pressed.connect(_reset_layout)
	_reset_layout_btn = reset_layout_btn
	toolbar_row.add_child(reset_layout_btn)

	_delete_tool = Button.new()
	_delete_tool.text = "Delete"
	_delete_tool.focus_mode = Control.FOCUS_NONE
	_delete_tool.visible = false
	_style_btn(_delete_tool, false)
	_delete_tool.pressed.connect(_delete_selected_device)
	toolbar_row.add_child(_delete_tool)

	# Flow so +Switch / +Server / +PC wrap instead of colliding with TOOLS.
	_palette_row = HFlowContainer.new()
	_palette_row.visible = false
	_palette_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_palette_row.add_theme_constant_override("h_separation", 6)
	_palette_row.add_theme_constant_override("v_separation", 4)
	toolbar_stack.add_child(_palette_row)

	var palette_lbl := Label.new()
	palette_lbl.text = "ADD DEVICE"
	palette_lbl.add_theme_font_size_override("font_size", 10)
	palette_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0, 0.9))
	_palette_row.add_child(palette_lbl)

	for device_type in ["switch", "server", "pc"]:
		var add_btn := Button.new()
		add_btn.text = "+ %s" % _palette_label(device_type)
		add_btn.focus_mode = Control.FOCUS_NONE
		add_btn.add_theme_font_size_override("font_size", 11)
		add_btn.set_meta("device_type", device_type)
		_style_btn(add_btn, false)
		add_btn.pressed.connect(_on_palette_add.bind(device_type))
		_palette_row.add_child(add_btn)

	left.add_child(_status_row())

	var canvas_panel := PanelContainer.new()
	canvas_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var canvas_style := StyleBoxFlat.new()
	canvas_style.bg_color = Color(0.03, 0.08, 0.16, 0.98)
	canvas_style.border_color = Color(0.35, 0.7, 0.88, 0.4)
	canvas_style.set_border_width_all(1)
	canvas_style.set_corner_radius_all(12)
	canvas_style.content_margin_left = 6
	canvas_style.content_margin_right = 6
	canvas_style.content_margin_top = 6
	canvas_style.content_margin_bottom = 6
	canvas_panel.add_theme_stylebox_override("panel", canvas_style)
	left.add_child(canvas_panel)

	_canvas = Control.new()
	_canvas.clip_contents = true
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Kept low so the CLI panel below still fits inside the lab's slot at 720p;
	# the canvas expands into whatever height is left over.
	_canvas.custom_minimum_size = Vector2(0, 200)
	_canvas.resized.connect(_relayout_devices)
	canvas_panel.add_child(_canvas)

	_draw_layer = Control.new()
	_draw_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_layer.draw.connect(_draw_topology)
	_canvas.add_child(_draw_layer)

	var cli_panel := PanelContainer.new()
	cli_panel.custom_minimum_size = Vector2(0, 84)
	var cli_style := StyleBoxFlat.new()
	cli_style.bg_color = Color(0.02, 0.06, 0.1, 0.98)
	cli_style.border_color = Color(0.2, 0.45, 0.35, 0.45)
	cli_style.set_border_width_all(1)
	cli_style.set_corner_radius_all(10)
	cli_style.content_margin_left = 10
	cli_style.content_margin_right = 10
	cli_style.content_margin_top = 8
	cli_style.content_margin_bottom = 8
	cli_panel.add_theme_stylebox_override("panel", cli_style)
	left.add_child(cli_panel)

	var cli_col := VBoxContainer.new()
	cli_col.add_theme_constant_override("separation", 4)
	cli_panel.add_child(cli_col)
	var cli_hdr := Label.new()
	cli_hdr.text = "CLI OUTPUT"
	cli_hdr.add_theme_font_size_override("font_size", 10)
	cli_hdr.add_theme_color_override("font_color", Color(0.45, 0.85, 0.6, 0.9))
	cli_col.add_child(cli_hdr)

	_cli_out = RichTextLabel.new()
	_cli_out.bbcode_enabled = true
	_cli_out.fit_content = false
	_cli_out.scroll_active = true
	_cli_out.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cli_out.custom_minimum_size = Vector2(0, 56)
	_cli_out.add_theme_font_size_override("normal_font_size", 12)
	_cli_out.add_theme_color_override("default_color", Color(0.7, 0.95, 0.75))
	_cli_out.text = "[b]Ready.[/b] Pick a cable type, then click two devices. [color=#7d7]Green[/color] link lights mean the cable is right; [color=#f77]red[/color] means it cannot pass traffic."
	cli_col.add_child(_cli_out)

	# ── Right: inspector (config + ping) ──
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(200, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.72
	right.add_theme_constant_override("separation", 8)
	root.add_child(right)
	_right_col = right

	var inspector := PanelContainer.new()
	inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var insp_style := StyleBoxFlat.new()
	insp_style.bg_color = Color(0.05, 0.12, 0.2, 0.96)
	insp_style.border_color = Color(0.3, 0.6, 0.75, 0.35)
	insp_style.set_border_width_all(1)
	insp_style.set_corner_radius_all(12)
	insp_style.content_margin_left = 12
	insp_style.content_margin_right = 12
	insp_style.content_margin_top = 12
	insp_style.content_margin_bottom = 12
	inspector.add_theme_stylebox_override("panel", insp_style)
	right.add_child(inspector)

	# Addressing fields plus the ping controls are taller than the panel at 720p,
	# which left the Ping button clipped and unreachable.
	var insp_scroll := ScrollContainer.new()
	insp_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insp_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	insp_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inspector.add_child(insp_scroll)

	var insp_col := VBoxContainer.new()
	insp_col.add_theme_constant_override("separation", 8)
	insp_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insp_scroll.add_child(insp_col)

	insp_col.add_child(_section_label("INSPECTOR"))
	var insp_hint := Label.new()
	insp_hint.text = "Select a PC to edit addressing."
	insp_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	insp_hint.add_theme_font_size_override("font_size", 11)
	insp_hint.add_theme_color_override("font_color", Color(0.65, 0.8, 0.9, 0.85))
	insp_col.add_child(insp_hint)

	insp_col.add_child(_divider())
	insp_col.add_child(_section_label("IP Configuration"))
	_config_ip = _field("IP Address", "192.168.1.10")
	_config_mask = _field("Subnet Mask", "255.255.255.0")
	_config_gw = _field("Default Gateway", "192.168.1.1")
	_config_dns = _field("DNS", "8.8.8.8")
	insp_col.add_child(_labeled_field("IP Address", _config_ip))
	insp_col.add_child(_labeled_field("Subnet Mask", _config_mask))
	insp_col.add_child(_labeled_field("Default Gateway", _config_gw))
	insp_col.add_child(_labeled_field("DNS Server", _config_dns))

	var apply_btn := Button.new()
	apply_btn.text = "Apply to Selected Host"
	apply_btn.focus_mode = Control.FOCUS_NONE
	_style_btn(apply_btn, true)
	apply_btn.pressed.connect(_apply_ip)
	_apply_ip_btn = apply_btn
	insp_col.add_child(apply_btn)

	insp_col.add_child(_divider())
	insp_col.add_child(_section_label("Connectivity Test"))
	_ping_target = _field("Ping target", "192.168.1.1")
	insp_col.add_child(_labeled_field("Ping Target", _ping_target))
	var ping_btn := Button.new()
	ping_btn.text = "Ping"
	ping_btn.focus_mode = Control.FOCUS_NONE
	_style_btn(ping_btn, true)
	ping_btn.pressed.connect(_run_ping)
	insp_col.add_child(ping_btn)

	var flow := Label.new()
	flow.text = "Flow\n• Drag icons to place\n• Cable topology\n• Apply PC1 IP\n• Ping gateway"
	flow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flow.add_theme_font_size_override("font_size", 11)
	flow.add_theme_color_override("font_color", Color(0.55, 0.78, 0.9, 0.85))
	insp_col.add_child(flow)

	_sync_tool_styles()


func _status_row() -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.10, 0.16, 0.85)
	style.border_color = Color(0.25, 0.5, 0.65, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	wrap.add_theme_stylebox_override("panel", style)
	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", Color(0.78, 0.9, 0.98, 0.92))
	wrap.add_child(_status)
	return wrap


func _apply_responsive_layout() -> void:
	if _root_row == null:
		return
	var width: float = size.x
	if width < 1.0:
		width = get_viewport().get_visible_rect().size.x
	var compact: bool = width > 0.0 and width < COMPACT_WIDTH
	var stacked: bool = width > 0.0 and width < STACK_WIDTH
	if _root_row.is_vertical() != stacked:
		_root_row.set_vertical(stacked)
	if _right_col != null:
		_right_col.custom_minimum_size.x = 188.0 if compact else 200.0
	_node_size = NODE_SIZE_COMPACT if compact else NODE_SIZE
	_icon_size = ICON_SIZE_COMPACT if compact else ICON_SIZE
	if _reset_links_btn != null:
		_reset_links_btn.text = "Links" if compact else "Reset Links"
	if _reset_layout_btn != null:
		_reset_layout_btn.text = "Layout" if compact else "Reset Layout"
	if _delete_tool != null:
		_delete_tool.text = "Del" if compact else "Delete"
	if _apply_ip_btn != null:
		if _topology_mode:
			_apply_ip_btn.text = "Apply IP" if compact else "Apply to Selected Host"
		else:
			_apply_ip_btn.text = "Apply IP" if compact else "Apply to Selected PC"
	if _palette_row != null:
		for child in _palette_row.get_children():
			if child is Button:
				var dtype: String = str(child.get_meta("device_type", ""))
				if dtype != "":
					(child as Button).text = ("+ %s" % dtype.capitalize()) if compact else (
						"+ %s" % _palette_label(dtype)
					)
	for id in _devices.keys():
		var btn: Button = _devices[id].get("node")
		if btn != null and is_instance_valid(btn):
			btn.custom_minimum_size = _node_size
			btn.size = _node_size
			var icon: TextureRect = _devices[id].get("icon")
			if icon != null:
				icon.custom_minimum_size = _icon_size
	_clamp_all_devices()
	if _draw_layer != null:
		_draw_layer.queue_redraw()


func _spawn_default_topology() -> void:
	for id in DEVICE_ORDER:
		_add_device(id)
	_devices["router"]["ip"] = "192.168.1.1"
	_devices["router"]["mask"] = "255.255.255.0"
	call_deferred("_relayout_devices")


func _clear_topology() -> void:
	for id in _devices.keys():
		var node: Node = _devices[id].get("node")
		if node != null and is_instance_valid(node):
			node.queue_free()
	_devices.clear()
	_links.clear()
	_packets.clear()
	_selected_id = ""
	_cable_from = ""
	_user_arranged = false
	if _draw_layer != null:
		_draw_layer.queue_redraw()


func _device_kind(id: String) -> String:
	if id in ["modem", "router", "switch", "server", "ap"]:
		return id
	if id.begins_with("pc"):
		return "pc"
	return id


func _device_label(id: String) -> String:
	if DEVICE_LABELS.has(id):
		return str(DEVICE_LABELS[id])
	if _device_kind(id) == "pc":
		return id.to_upper()
	return id.capitalize()


func _device_color(id: String) -> Color:
	if DEVICE_COLORS.has(id):
		return DEVICE_COLORS[id]
	var kind := _device_kind(id)
	if kind == "pc":
		return DEVICE_COLORS.get("pc1", Color(0.55, 0.72, 0.95))
	return DEVICE_COLORS.get(kind, Color(0.3, 0.7, 0.9))


func _wiring_class(id: String) -> String:
	return str(DEVICE_WIRING.get(_device_kind(id), DEVICE_WIRING.get(id, "host")))


func _palette_label(device_type: String) -> String:
	return str(DEVICE_LABELS.get(device_type, device_type.capitalize()))


func _on_palette_add(device_type: String) -> void:
	var id := _spawn_device_type(device_type)
	if id == "":
		return
	action_submitted.emit(SimulationAction.new("add_device", device_type, id))
	_refresh_status("Added %s." % _device_label(id))
	call_deferred("_relayout_devices")


func _spawn_device_type(device_type: String) -> String:
	var id := ""
	match device_type:
		"switch":
			if _devices.has("switch"):
				_refresh_status("Switch already on canvas.")
				return ""
			id = "switch"
		"server":
			if _devices.has("server"):
				_refresh_status("File server already on canvas.")
				return ""
			id = "server"
		"pc":
			var n := 1
			while _devices.has("pc%d" % n):
				n += 1
			if n > 4:
				_refresh_status("Canvas supports up to four PCs.")
				return ""
			id = "pc%d" % n
		_:
			return ""
	_add_device(id)
	return id


func _delete_selected_device() -> void:
	if _selected_id == "":
		_refresh_status("Select a device to delete.")
		return
	var id := _selected_id
	_remove_device(id)
	action_submitted.emit(SimulationAction.new("remove_device", id, ""))


func _remove_device(id: String) -> void:
	if not _devices.has(id):
		return
	var node: Node = _devices[id].get("node")
	if node != null and is_instance_valid(node):
		node.queue_free()
	_devices.erase(id)
	var keep: Array = []
	for link in _links:
		if link.a == id or link.b == id:
			continue
		keep.append(link)
	_links = keep
	_packets.clear()
	if _selected_id == id:
		_selected_id = ""
	if _cable_from == id:
		_cable_from = ""
	_highlight_selection()
	if _draw_layer != null:
		_draw_layer.queue_redraw()


func _add_device(id: String) -> void:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = _node_size
	btn.size = _node_size
	btn.clip_text = false
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_MOVE
	btn.gui_input.connect(_on_device_gui_input.bind(id))

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	btn.add_child(col)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = _icon_size
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = _load_device_icon(id)
	col.add_child(icon)

	var title := Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
	title.text = _device_label(id)
	col.add_child(title)

	var sub := Label.new()
	sub.name = "Sub"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color(0.75, 0.88, 0.98, 0.9))
	sub.text = str(DEVICE_SUB.get(_device_kind(id), DEVICE_SUB.get(id, "")))
	col.add_child(sub)

	_canvas.add_child(btn)
	_devices[id] = {
		"node": btn,
		"icon": icon,
		"title": title,
		"sub": sub,
		"type": _device_kind(id),
		"ip": "",
		"mask": "",
		"gateway": "",
		"dns": "",
	}
	_style_device(id)


func _on_device_gui_input(event: InputEvent, id: String) -> void:
	if not _devices.has(id):
		return
	var btn: Button = _devices[id]["node"]
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_drag_id = id
		_drag_moved = false
		_drag_start_pos = btn.position
		_drag_grab = btn.get_local_mouse_position()
		btn.move_to_front()
		btn.accept_event()


func _input(event: InputEvent) -> void:
	if _drag_id == "" or not _devices.has(_drag_id):
		return
	var btn: Button = _devices[_drag_id]["node"]
	if event is InputEventMouseMotion:
		var local_mouse: Vector2 = _canvas.get_local_mouse_position()
		var next_pos: Vector2 = local_mouse - _drag_grab
		if next_pos.distance_to(_drag_start_pos) >= DRAG_THRESHOLD:
			_drag_moved = true
		if _drag_moved:
			btn.position = _clamp_pos(next_pos)
			_user_arranged = true
			if _draw_layer != null:
				_draw_layer.queue_redraw()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var id: String = _drag_id
		var was_drag := _drag_moved
		_drag_id = ""
		_drag_moved = false
		get_viewport().set_input_as_handled()
		if was_drag:
			_user_arranged = true
			_clamp_device(id)
			_refresh_status("Moved %s — cables stay attached." % DEVICE_LABELS.get(id, id))
			if _draw_layer != null:
				_draw_layer.queue_redraw()
		else:
			_on_device_pressed(id)


func _clamp_pos(pos: Vector2) -> Vector2:
	if _canvas == null:
		return pos
	var max_x: float = maxf(_canvas.size.x - _node_size.x, 0.0)
	var max_y: float = maxf(_canvas.size.y - _node_size.y, 0.0)
	return Vector2(clampf(pos.x, 0.0, max_x), clampf(pos.y, 0.0, max_y))


func _clamp_device(id: String) -> void:
	if not _devices.has(id):
		return
	var btn: Button = _devices[id]["node"]
	btn.position = _clamp_pos(btn.position)


func _clamp_all_devices() -> void:
	for id in _devices.keys():
		_clamp_device(str(id))
	if _draw_layer != null:
		_draw_layer.queue_redraw()


func _load_device_icon(id: String) -> Texture2D:
	var kind := _device_kind(id)
	var path: String = str(DEVICE_ICONS.get(id, DEVICE_ICONS.get(kind, "")))
	if path == "" or not ResourceLoader.exists(path):
		return null
	var tex: Variant = load(path)
	return tex as Texture2D if tex is Texture2D else null


func _relayout_devices() -> void:
	if _canvas == null or _devices.is_empty():
		return
	# Keep student placements after they drag devices around.
	if _user_arranged:
		_clamp_all_devices()
		_layout_ready = true
		return
	var w: float = maxf(_canvas.size.x, 420.0)
	var h: float = maxf(_canvas.size.y, 300.0)
	if _topology_mode:
		var ids: Array = _devices.keys()
		ids.sort()
		var count: int = ids.size()
		if count > 0:
			var spacing: float = w / float(count + 1)
			for i in count:
				var dev_id: String = str(ids[i])
				var btn: Button = _devices[dev_id]["node"]
				var center := Vector2(spacing * float(i + 1), h * 0.45)
				btn.position = _clamp_pos(center - _node_size * 0.5)
				btn.size = _node_size
		_layout_ready = true
		_highlight_selection()
		if _draw_layer != null:
			_draw_layer.queue_redraw()
		return
	var top_y: float = h * 0.30
	var bot_y: float = h * 0.72
	# Match student sketch: Modem Router Switch AP on top; PC1 under Switch; PC2 under AP.
	var slots := {
		"modem": Vector2(w * 0.10, top_y),
		"router": Vector2(w * 0.32, top_y),
		"switch": Vector2(w * 0.54, top_y),
		"ap": Vector2(w * 0.76, top_y),
		"pc1": Vector2(w * 0.54, bot_y),
		"pc2": Vector2(w * 0.76, bot_y),
	}
	for id in slots.keys():
		if not _devices.has(id):
			continue
		var btn: Button = _devices[id]["node"]
		var center: Vector2 = slots[id]
		btn.position = _clamp_pos(center - _node_size * 0.5)
		btn.size = _node_size
	_layout_ready = true
	_highlight_selection()
	if _draw_layer != null:
		_draw_layer.queue_redraw()


func _reset_layout() -> void:
	_user_arranged = false
	_drag_id = ""
	_drag_moved = false
	_relayout_devices()
	if _topology_mode:
		_refresh_status("Layout reset — devices re-spaced on the canvas.")
	else:
		_refresh_status("Layout reset to default topology positions.")


func _device_center(id: String) -> Vector2:
	if not _devices.has(id):
		return Vector2.ZERO
	var btn: Button = _devices[id]["node"]
	return btn.position + btn.size * 0.5


func _draw_topology() -> void:
	if _draw_layer == null:
		return
	# Cables carry their type in the line style, and each end shows a link light
	# the way Packet Tracer does: green for up, red for a cable that cannot work.
	for link in _links:
		var a: Vector2 = _device_center(str(link.a))
		var b: Vector2 = _device_center(str(link.b))
		var cable: String = str(link.get("cable", "straight"))
		var tint: Color = CABLE_COLORS.get(cable, Color.WHITE)
		_draw_dashed_line(a, b, Color(0.08, 0.10, 0.14, 0.95), 4.5, 1000.0, 0.0)
		match cable:
			"crossover":
				_draw_dashed_line(a, b, tint, 2.4, 11.0, 6.0)
			"console":
				_draw_dashed_line(a, b, tint, 2.0, 3.0, 5.0)
			_:
				_draw_layer.draw_line(a, b, tint, 2.4, true)
		var light: Color = LINK_UP_COLOR if bool(link.get("up", false)) else LINK_DOWN_COLOR
		if cable == "console":
			light = CABLE_COLORS["console"]
		_draw_link_light(a, b, light)
		_draw_link_light(b, a, light)

	# Preview cable while picking second device.
	if _mode == "cable" and _cable_from != "" and _devices.has(_cable_from):
		var from_pt: Vector2 = _device_center(_cable_from)
		var mouse_pt: Vector2 = _draw_layer.get_local_mouse_position()
		_draw_dashed_line(from_pt, mouse_pt, Color(1.0, 0.85, 0.25, 0.85), 2.5, 8.0, 6.0)

	# Animated green packets along active path (Packet Tracer-style).
	for p in _packets:
		var t: float = float(p.t)
		if t < 0.0 or t > 1.0:
			continue
		var a: Vector2 = _device_center(str(p.from))
		var b: Vector2 = _device_center(str(p.to))
		var pos: Vector2 = a.lerp(b, t)
		var dir: Vector2 = (b - a).normalized()
		if dir.length_squared() < 0.0001:
			dir = Vector2.RIGHT
		_draw_packet_arrow(pos, dir, p.color)


func _draw_dashed_line(a: Vector2, b: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var total: float = a.distance_to(b)
	if total < 1.0:
		return
	var dir: Vector2 = (b - a) / total
	var dist: float = 0.0
	var draw_on := true
	while dist < total:
		var seg: float = dash if draw_on else gap
		var next_dist: float = minf(dist + seg, total)
		if draw_on:
			_draw_layer.draw_line(a + dir * dist, a + dir * next_dist, color, width, true)
		dist = next_dist
		draw_on = not draw_on


## Small square just off the device edge, matching Packet Tracer's port lights.
func _draw_link_light(at: Vector2, toward: Vector2, color: Color) -> void:
	var dir: Vector2 = toward - at
	if dir.length_squared() < 0.0001:
		return
	var pos: Vector2 = at + dir.normalized() * (_node_size.x * 0.42)
	var half := 4.0
	_draw_layer.draw_rect(Rect2(pos - Vector2(half, half), Vector2(half, half) * 2.0), color, true)
	_draw_layer.draw_rect(
		Rect2(pos - Vector2(half, half), Vector2(half, half) * 2.0),
		Color(0.04, 0.08, 0.12, 0.9),
		false,
		1.0
	)


func _draw_packet_arrow(pos: Vector2, dir: Vector2, color: Color) -> void:
	var n: Vector2 = Vector2(-dir.y, dir.x)
	var tip: Vector2 = pos + dir * 10.0
	var left: Vector2 = pos - dir * 7.0 + n * 7.0
	var right: Vector2 = pos - dir * 7.0 - n * 7.0
	_draw_layer.draw_colored_polygon(PackedVector2Array([tip, left, right]), color)


func _on_device_pressed(id: String) -> void:
	if _mode == "cable":
		_handle_cable_click(id)
		return
	_selected_id = id
	_load_config_fields(id)
	var kind := _device_kind(id)
	if kind == "pc" or kind == "server":
		_refresh_status("Selected %s — Apply IP or ping from the inspector." % _device_label(id))
	else:
		_refresh_status("Selected %s. Use Cable to link devices." % _device_label(id))
	_highlight_selection()


func _handle_cable_click(id: String) -> void:
	if _cable_from == "":
		_cable_from = id
		_refresh_status("%s from %s — click the second device." % [
			_cable_name(), DEVICE_LABELS.get(id, id)
		])
		if _draw_layer != null:
			_draw_layer.queue_redraw()
		return
	if _cable_from == id:
		_cable_from = ""
		_refresh_status("Cable cancelled.")
		if _draw_layer != null:
			_draw_layer.queue_redraw()
		return
	var a: String = _cable_from
	var b: String = id
	_cable_from = ""
	_create_link(a, b, _cable_type)
	if _draw_layer != null:
		_draw_layer.queue_redraw()


## The cable a correct install would use between these two device classes.
func _required_cable(a: String, b: String) -> String:
	return "straight" if _wiring_class(a) != _wiring_class(b) else "crossover"


## Console cables are management-only, and only from a PC to a router or switch.
func _console_allowed(a: String, b: String) -> bool:
	var pair: Array = [a, b]
	for index in 2:
		var other: String = str(pair[1 - index])
		if str(pair[index]).begins_with("pc") and (other == "router" or other == "switch"):
			return true
	return false


## Re-cabling an existing pair swaps the cable rather than stacking a second one,
## so a wrong pick is fixed by running the right cable again.
func _create_link(a: String, b: String, cable: String) -> void:
	var label_a: String = _device_label(a)
	var label_b: String = _device_label(b)
	var up: bool = false
	var reason: String = ""
	if cable == "console":
		if _console_allowed(a, b):
			reason = "Console link to %s — management only, carries no data." % label_b
		else:
			reason = "Console cable only runs from a PC to a router or switch."
	else:
		var required: String = _required_cable(a, b)
		up = cable == required
		if not up:
			if required == "crossover":
				reason = "Link down: %s and %s are both end devices — use a crossover." % [label_a, label_b]
			else:
				reason = "Link down: %s and %s are different device types — use a straight-through." % [
					label_a, label_b
				]

	var existing: Dictionary = {}
	for link in _links:
		if (link.a == a and link.b == b) or (link.a == b and link.b == a):
			existing = link
			break
	if existing.is_empty():
		_links.append({"a": a, "b": b, "cable": cable, "up": up})
	else:
		existing["cable"] = cable
		existing["up"] = up

	if up:
		_cli_append("%s cable %s ↔ %s: [color=#7d7]link up[/color]" % [
			CABLE_LABELS.get(cable, cable), label_a, label_b
		])
		_refresh_status("Linked %s ↔ %s" % [label_a, label_b])
		var ordered := _ordered_pair(a, b)
		action_submitted.emit(SimulationAction.new("connect", ordered[0], ordered[1]))
	else:
		_cli_append("[color=#f77]%s[/color]" % reason)
		_refresh_status(reason)


func _reset_links() -> void:
	_links.clear()
	_packets.clear()
	_cable_from = ""
	_refresh_status("All links cleared.")
	if _draw_layer != null:
		_draw_layer.queue_redraw()


func _apply_ip() -> void:
	if _selected_id == "" or not _is_addressable(_selected_id):
		_refresh_status("Select a PC or server before applying IP settings.")
		return
	var dev: Dictionary = _devices[_selected_id]
	dev["ip"] = _config_ip.text.strip_edges()
	dev["mask"] = _config_mask.text.strip_edges()
	dev["gateway"] = _config_gw.text.strip_edges()
	dev["dns"] = _config_dns.text.strip_edges()
	var action := SimulationAction.new("configure", _selected_id, "addressing")
	action_submitted.emit(action)
	_cli_append("Configured %s → IP %s  GW %s" % [_device_label(_selected_id), dev["ip"], dev["gateway"]])
	_refresh_status("Addressing applied on %s." % _device_label(_selected_id))
	_style_device(_selected_id)


func _is_addressable(id: String) -> bool:
	var kind := _device_kind(id)
	return kind == "pc" or kind == "server"


func _run_ping() -> void:
	if _selected_id == "" or not _is_addressable(_selected_id):
		_refresh_status("Select a PC or server as the ping source.")
		return
	var src: Dictionary = _devices[_selected_id]
	var dest_ip: String = _ping_target.text.strip_edges()
	if str(src.get("ip", "")) == "":
		_cli_append("Ping failed: %s has no IP. Apply addressing first." % _selected_id.to_upper())
		return
	var dest_id := _resolve_ip_device(dest_ip)
	var reachable := _can_reach(_selected_id, dest_ip)
	var action := SimulationAction.new("ping", _selected_id, dest_ip)
	if reachable:
		_cli_append("Reply from %s: bytes=32 time<1ms TTL=64" % dest_ip)
		var packet_dest := dest_id if dest_id != "" else _selected_id
		_spawn_ping_packets(_selected_id, packet_dest)
	else:
		_cli_append("Request timed out.%s" % _failure_hint())
	action_submitted.emit(action)


## A red link is the most likely reason a ping died, so name it before the
## generic addressing advice.
func _failure_hint() -> String:
	for link in _links:
		if bool(link.get("up", false)) or str(link.get("cable", "")) == "console":
			continue
		return " %s ↔ %s is miscabled — check the link lights." % [
			_device_label(str(link.a)), _device_label(str(link.b))
		]
	return " Check cables, gateway, and IP plan."


func _resolve_ip_device(dest_ip: String) -> String:
	for id in _devices.keys():
		if str(_devices[id].get("ip", "")) == dest_ip:
			return str(id)
	return ""


func _spawn_ping_packets(src_id: String, dest_id: String) -> void:
	var path := _shortest_path(src_id, dest_id)
	if path.size() < 2:
		return
	_packets.clear()
	# Outbound packets, then return path (echo reply).
	for i in range(path.size() - 1):
		_packets.append({
			"from": path[i],
			"to": path[i + 1],
			"t": -0.18 * float(i),
			"life": 0.55,
			"color": Color(0.25, 0.95, 0.35),
		})
	var back: Array = path.duplicate()
	back.reverse()
	var offset: float = 0.18 * float(path.size())
	for i in range(back.size() - 1):
		_packets.append({
			"from": back[i],
			"to": back[i + 1],
			"t": -offset - 0.18 * float(i),
			"life": 0.55,
			"color": Color(0.35, 1.0, 0.45),
		})
	if _draw_layer != null:
		_draw_layer.queue_redraw()


func _can_reach(src_id: String, dest_ip: String) -> bool:
	var src: Dictionary = _devices[src_id]
	var src_ip: String = str(src.get("ip", ""))
	var mask: String = str(src.get("mask", "255.255.255.0"))
	var gw: String = str(src.get("gateway", ""))
	if dest_ip == src_ip:
		return true
	var dest_id := _resolve_ip_device(dest_ip)
	if dest_id != "":
		var dest_mask: String = str(_devices[dest_id].get("mask", mask))
		return _path_exists(src_id, dest_id) and _same_subnet(src_ip, dest_ip, mask, dest_mask)
	if _devices.has("router") and dest_ip == str(_devices["router"].get("ip", "192.168.1.1")):
		return _path_exists(src_id, "router")
	if gw != "":
		var gw_id := _resolve_ip_device(gw)
		if gw_id != "" and _path_exists(src_id, gw_id):
			return dest_ip == "8.8.8.8" or dest_ip.begins_with("8.8.")
		if _devices.has("router") and gw == str(_devices["router"].get("ip", "")) and _path_exists(src_id, "router"):
			return dest_ip == "8.8.8.8" or dest_ip.begins_with("8.8.")
	return false


func _path_exists(a: String, b: String) -> bool:
	return not _shortest_path(a, b).is_empty()


func _shortest_path(a: String, b: String) -> Array:
	if a == b:
		return [a]
	var visited: Dictionary = {}
	var parent: Dictionary = {}
	var queue: Array = [a]
	visited[a] = true
	while not queue.is_empty():
		var cur: String = str(queue.pop_front())
		for link in _links:
			# A miscabled or console link is physically present but passes no data.
			if not bool(link.get("up", false)):
				continue
			var n: String = ""
			if link.a == cur:
				n = str(link.b)
			elif link.b == cur:
				n = str(link.a)
			if n == "" or visited.has(n):
				continue
			visited[n] = true
			parent[n] = cur
			if n == b:
				var path: Array = [b]
				var walk: String = b
				while walk != a:
					walk = str(parent[walk])
					path.push_front(walk)
				return path
			queue.append(n)
	return []


func _same_subnet(ip_a: String, ip_b: String, mask_a: String = "255.255.255.0", mask_b: String = "") -> bool:
	if mask_b == "":
		mask_b = mask_a
	var pa := ip_a.split(".")
	var pb := ip_b.split(".")
	var ma := mask_a.split(".")
	var mb := mask_b.split(".")
	if pa.size() != 4 or pb.size() != 4 or ma.size() != 4:
		return false
	for i in 4:
		if (int(pa[i]) & int(ma[i])) != (int(pb[i]) & int(mb[i])):
			return false
	return true


func _ordered_pair(a: String, b: String) -> PackedStringArray:
	if a < b:
		return PackedStringArray([a, b])
	return PackedStringArray([b, a])


func _load_config_fields(id: String) -> void:
	if not _devices.has(id):
		return
	var dev: Dictionary = _devices[id]
	_config_ip.text = str(dev.get("ip", ""))
	_config_mask.text = str(dev.get("mask", ""))
	_config_gw.text = str(dev.get("gateway", ""))
	_config_dns.text = str(dev.get("dns", ""))
	if str(dev.get("ip", "")) != "":
		return
	var kind := _device_kind(id)
	if kind == "pc":
		if _topology_mode:
			_config_ip.text = "192.168.10.20" if id == "pc1" else "192.168.10.21"
			_config_mask.text = "255.255.255.0"
			_config_gw.text = "192.168.10.10"
			_config_dns.text = "8.8.8.8"
		else:
			_config_ip.text = "192.168.1.10" if id == "pc1" else "192.168.1.11"
			_config_mask.text = "255.255.255.0"
			_config_gw.text = "192.168.1.1"
			_config_dns.text = "8.8.8.8"
	elif kind == "server":
		_config_ip.text = "192.168.10.10"
		_config_mask.text = "255.255.255.0"
		_config_gw.text = ""
		_config_dns.text = "8.8.8.8"


func _style_device(id: String) -> void:
	if not _devices.has(id):
		return
	var btn: Button = _devices[id]["node"]
	var accent: Color = _device_color(id)
	var selected := id == _selected_id
	var hinted := guided_hints and (_hint_target == id or _hint_destination == id)
	var has_ip := str(_devices[id].get("ip", "")) != ""
	var style := StyleBoxFlat.new()
	# Soft pad behind icon so it still feels selectable, icon stays the main visual.
	style.bg_color = Color(0.05, 0.10, 0.20, 0.55 if selected or hinted else 0.28)
	style.border_color = Color(1.0, 0.88, 0.25) if hinted else accent
	style.set_border_width_all(3 if selected or hinted else 2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.text = ""
	var icon: TextureRect = _devices[id].get("icon")
	if icon != null:
		icon.modulate = Color(1.15, 1.15, 1.1, 1.0) if selected or hinted else Color.WHITE
	var title: Label = _devices[id].get("title")
	var sub: Label = _devices[id].get("sub")
	if title != null:
		title.text = _device_label(id)
	if sub != null:
		if has_ip and _is_addressable(id):
			sub.text = str(_devices[id].get("ip", ""))
		else:
			sub.text = str(DEVICE_SUB.get(_device_kind(id), DEVICE_SUB.get(id, "")))


func _highlight_selection() -> void:
	for id in _devices.keys():
		_style_device(str(id))


func _refresh_hints() -> void:
	_highlight_selection()
	if guided_hints and _hint_target != "" and _hint_destination != "":
		if _hint_destination == "addressing":
			_refresh_status("Hint: Select %s → Apply IP / gateway / DNS." % _device_label(_hint_target))
		elif str(_hint_destination).contains("."):
			_refresh_status("Hint: From %s, ping %s." % [_device_label(_hint_target), _hint_destination])
		else:
			_refresh_status("Hint: Cable %s ↔ %s — choose the cable type first." % [
				_device_label(_hint_target),
				_device_label(_hint_destination)
			])


func _tool_btn(label: String, mode: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func() -> void:
		_mode = mode
		_cable_from = ""
		_sync_tool_styles()
		if mode == "cable":
			_refresh_status("%s armed — click the two devices to cable." % _cable_name())
		else:
			_refresh_status("Tool: Select — click a device to select / configure.")
		if _draw_layer != null:
			_draw_layer.queue_redraw()
	)
	return btn


func _on_cable_type_selected(index: int) -> void:
	if _cable_picker == null:
		return
	_cable_type = str(_cable_picker.get_item_metadata(index))
	_mode = "cable"
	_cable_from = ""
	_sync_tool_styles()
	_refresh_status("%s armed — click the two devices to cable." % _cable_name())
	if _draw_layer != null:
		_draw_layer.queue_redraw()


func _cable_name() -> String:
	return str(CABLE_LABELS.get(_cable_type, _cable_type))


func _sync_tool_styles() -> void:
	if _select_tool != null:
		_style_btn(_select_tool, _mode == "select")
	if _cable_tool != null:
		_style_btn(_cable_tool, _mode == "cable")


func _field(placeholder: String, default_text: String = "") -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.text = default_text
	edit.custom_minimum_size = Vector2(0, 32)
	return edit


func _labeled_field(caption: String, edit: LineEdit) -> VBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 2)
	var lbl := Label.new()
	lbl.text = caption
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.78, 0.9, 0.9))
	wrap.add_child(lbl)
	wrap.add_child(edit)
	return wrap


func _divider() -> ColorRect:
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.color = Color(0.35, 0.55, 0.7, 0.25)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return line


func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	return lbl


func _style_btn(btn: Button, accent: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.45, 0.65, 0.95) if accent else Color(0.05, 0.18, 0.26, 0.95)
	style.border_color = Color(0.35, 0.85, 1.0, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))


func _refresh_status(text: String) -> void:
	if _status != null:
		_status.text = text


func _cli_append(line: String) -> void:
	if _cli_out == null:
		return
	_cli_out.text = str(_cli_out.text) + "\n" + line

