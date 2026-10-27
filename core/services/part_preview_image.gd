class_name PartPreviewImage
extends RefCounted

## 2D part previews for the Parts Catalog and simulation part trays.
## Loads PNG if present, otherwise draws a readable teaching illustration.

const PART_ICON_DIR := "res://assets/images/parts"
static var _cache: Dictionary = {}


static func texture_for(item: Dictionary) -> Texture2D:
	var part_id := _resolve_id(item)
	var title := str(item.get("title", part_id))
	return texture_for_id(part_id, title)


static func texture_for_id(part_id: String, title: String = "") -> Texture2D:
	var key := part_id if part_id != "" else title.to_lower().replace(" ", "_")
	if key == "":
		key = "part"
	if _cache.has(key):
		return _cache[key] as Texture2D

	var png := "%s/%s.png" % [PART_ICON_DIR, key]
	if ResourceLoader.exists(png):
		var loaded: Resource = load(png)
		if loaded is Texture2D:
			_cache[key] = loaded
			return loaded as Texture2D

	var alt := "%s/part_%s.png" % [PART_ICON_DIR, key]
	if ResourceLoader.exists(alt):
		var loaded_alt: Resource = load(alt)
		if loaded_alt is Texture2D:
			_cache[key] = loaded_alt
			return loaded_alt as Texture2D

	# Prefer recognizable teaching cards over procedural sketches.
	var card := _card_fallback(key)
	if card != "":
		var card_path := "res://assets/images/cards/%s" % card
		if ResourceLoader.exists(card_path):
			var card_tex: Resource = load(card_path)
			if card_tex is Texture2D:
				_cache[key] = card_tex
				return card_tex as Texture2D

	var drawn := _draw_preview(key, title if title != "" else key)
	_cache[key] = drawn
	return drawn


static func _card_fallback(part_id: String) -> String:
	match part_id:
		"motherboard", "mb":
			return "card_motherboard.png"
		"cpu", "chips":
			return "card_cpu.png"
		"ram", "memory":
			return "card_ram.png"
		"psu", "power_supply", "atx":
			return "card_psu.png"
		"hdd", "ssd", "storage", "flash":
			return "card_storage.png"
		"cpu_fan", "cooler", "fan", "cooling":
			return "card_cooling.png"
		"case", "chassis", "optical_drive":
			return "card_system_unit.png"
		"nic", "network_card":
			return "card_network.png"
		"gpu", "graphics", "expansion":
			return "card_expansion.png"
		"rj45", "port":
			return "card_port.png"
		"ethernet_cable", "fiber_cable", "cable":
			return "card_connector.png"
		"crimper", "cable_tester", "tools":
			return "card_tools.png"
		"monitor", "display":
			return "card_monitor.png"
		"router", "switch", "modem", "access_point", "hub", "firewall", "repeater", "patch_panel":
			return "card_network.png"
		_:
			return ""


static func _resolve_id(item: Dictionary) -> String:
	var part_id := str(item.get("part_id", ""))
	if part_id != "":
		return part_id
	var scene_path := str(item.get("scene_path", ""))
	if scene_path.ends_with("model.tscn"):
		return scene_path.get_base_dir().get_file()
	var title := str(item.get("title", "")).to_lower()
	title = title.replace("(", "").replace(")", "").replace("/", " ")
	return title.replace(" ", "_").replace("__", "_").strip_edges()


static func _draw_preview(part_id: String, title: String) -> Texture2D:
	# Keep small — fills_rect is fast; pixel loops previously froze phones on first tap.
	var w := 320
	var h := 240
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.16, 0.24, 1))

	_fill_rect(img, 16, 16, w - 32, h - 32, Color(0.12, 0.22, 0.32, 1))
	_stroke_rect(img, 16, 16, w - 32, h - 32, Color(0.35, 0.75, 0.95, 0.75), 2)

	var accent := _accent(part_id)
	_draw_shape(img, part_id, accent)
	_draw_label_bar(img, title if title != "" else part_id.replace("_", " "), accent)

	return ImageTexture.create_from_image(img)


static func _accent(part_id: String) -> Color:
	match part_id:
		"nic", "motherboard", "gpu":
			return Color(0.35, 0.82, 0.55, 1)
		"cpu", "chips", "ram":
			return Color(0.85, 0.88, 0.92, 1)
		"router", "switch", "hub", "firewall", "modem", "access_point", "repeater":
			return Color(0.25, 0.35, 0.48, 1)
		"ethernet_cable", "fiber_cable", "rj45":
			return Color(0.3, 0.65, 1.0, 1)
		"ssd", "hdd", "flash":
			return Color(0.5, 0.55, 0.62, 1)
		"psu", "atx", "case", "fan":
			return Color(0.35, 0.38, 0.45, 1)
		_:
			var hue := float(abs(part_id.hash()) % 360) / 360.0
			return Color.from_hsv(hue, 0.45, 0.7, 1)


static func _draw_shape(img: Image, part_id: String, accent: Color) -> void:
	var cx := img.get_width() / 2
	var cy := img.get_height() / 2 - 10
	match part_id:
		"nic", "gpu", "motherboard":
			_fill_rect(img, cx - 110, cy - 45, 220, 90, accent.darkened(0.1))
			_fill_rect(img, cx + 85, cy - 58, 18, 116, Color(0.85, 0.88, 0.92, 1))
			for i in 5:
				_fill_rect(img, cx - 90 + i * 32, cy - 25, 20, 14, Color(0.1, 0.12, 0.16, 1))
			_fill_rect(img, cx - 95, cy + 20, 60, 16, Color(0.65, 0.7, 0.75, 1))
		"cpu", "chips":
			_fill_rect(img, cx - 45, cy - 45, 90, 90, accent)
			for i in 6:
				_fill_rect(img, cx - 52, cy - 38 + i * 12, 6, 6, Color(0.95, 0.85, 0.4, 1))
				_fill_rect(img, cx + 46, cy - 38 + i * 12, 6, 6, Color(0.95, 0.85, 0.4, 1))
		"ram":
			_fill_rect(img, cx - 105, cy - 18, 210, 36, accent)
			for i in 4:
				_fill_rect(img, cx - 90 + i * 45, cy - 10, 28, 20, Color(0.1, 0.12, 0.16, 1))
			_fill_rect(img, cx - 105, cy + 18, 210, 6, Color(0.85, 0.88, 0.92, 1))
		"router", "modem", "firewall", "hub", "switch", "access_point", "repeater", "cable_tester", "crimper", "patch_panel":
			_fill_rect(img, cx - 100, cy - 36, 200, 72, accent)
			for i in 6:
				_fill_rect(img, cx - 85 + i * 28, cy + 12, 14, 10, Color(0.2, 0.85, 0.4, 1) if i % 2 == 0 else Color(0.95, 0.6, 0.15, 1))
			if part_id == "access_point" or part_id == "repeater":
				_fill_rect(img, cx - 5, cy - 72, 10, 36, Color(0.75, 0.78, 0.82, 1))
			if part_id == "router" or part_id == "modem":
				_fill_rect(img, cx - 65, cy - 62, 8, 26, Color(0.75, 0.78, 0.82, 1))
				_fill_rect(img, cx + 57, cy - 62, 8, 26, Color(0.75, 0.78, 0.82, 1))
		"ethernet_cable", "fiber_cable":
			for i in 4:
				var y := cy - 28 + i * 14
				_fill_rect(img, cx - 105, y, 210, 6, Color(0.25, 0.55, 1.0, 1) if part_id == "ethernet_cable" else Color(0.95, 0.75, 0.2, 1))
			_fill_rect(img, cx - 115, cy - 32, 18, 64, Color(0.8, 0.84, 0.9, 1))
			_fill_rect(img, cx + 97, cy - 32, 18, 64, Color(0.8, 0.84, 0.9, 1))
		"rj45":
			_fill_rect(img, cx - 32, cy - 45, 64, 90, Color(0.8, 0.84, 0.9, 1))
			_fill_rect(img, cx - 24, cy - 35, 48, 58, Color(0.1, 0.12, 0.16, 1))
			for i in 8:
				_fill_rect(img, cx - 20 + i * 6, cy + 28, 4, 12, Color(0.95, 0.8, 0.3, 1))
		"ssd", "hdd", "flash":
			_fill_rect(img, cx - 90, cy - 32, 180, 64, accent)
			_fill_rect(img, cx - 75, cy - 18, 100, 36, Color(0.08, 0.1, 0.14, 1))
			_fill_rect(img, cx + 45, cy - 6, 32, 14, Color(0.65, 0.7, 0.75, 1))
		"monitor":
			_fill_rect(img, cx - 90, cy - 52, 180, 100, Color(0.2, 0.22, 0.26, 1))
			_fill_rect(img, cx - 78, cy - 40, 156, 76, Color(0.2, 0.55, 0.85, 1))
			_fill_rect(img, cx - 18, cy + 50, 36, 16, Color(0.3, 0.32, 0.36, 1))
			_fill_rect(img, cx - 45, cy + 66, 90, 8, Color(0.25, 0.27, 0.3, 1))
		"keyboard":
			_fill_rect(img, cx - 115, cy - 26, 230, 64, Color(0.2, 0.22, 0.26, 1))
			for row in 3:
				for col in 10:
					_fill_rect(img, cx - 105 + col * 22, cy - 16 + row * 18, 16, 12, Color(0.32, 0.36, 0.42, 1))
		"mouse", "workstation", "laptop":
			_fill_rect(img, cx - 85, cy - 45, 170, 100, Color(0.25, 0.28, 0.34, 1))
			_fill_rect(img, cx - 72, cy - 32, 144, 74, Color(0.15, 0.45, 0.7, 1))
			_fill_rect(img, cx - 85, cy + 58, 170, 12, Color(0.32, 0.35, 0.4, 1))
		"psu", "case", "fan", "atx", "antistatic", "screwdriver":
			_fill_rect(img, cx - 75, cy - 50, 150, 100, accent)
			_fill_rect(img, cx - 28, cy - 28, 56, 56, Color(0.45, 0.5, 0.58, 1))
			_stroke_rect(img, cx - 28, cy - 28, 56, 56, Color(0.85, 0.9, 0.95, 1), 2)
		_:
			_fill_rect(img, cx - 70, cy - 45, 140, 90, accent)
			_stroke_rect(img, cx - 70, cy - 45, 140, 90, Color(0.9, 0.95, 1.0, 0.85), 3)


static func _draw_label_bar(img: Image, text: String, accent: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_fill_rect(img, 16, h - 42, w - 32, 26, Color(0.05, 0.1, 0.16, 0.95))
	_fill_rect(img, 16, h - 42, 6, 26, accent)
	var label := text.to_upper()
	var n := mini(label.length(), 16)
	for i in n:
		_fill_rect(img, 32 + i * 12, h - 32, 8, 10, Color(0.9, 0.95, 1.0, 0.95))


static func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	if w <= 0 or h <= 0:
		return
	var rect := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	img.fill_rect(rect, color)


static func _stroke_rect(img: Image, x: int, y: int, w: int, h: int, color: Color, thickness: int = 1) -> void:
	for t in thickness:
		_fill_rect(img, x + t, y + t, w - t * 2, 1, color)
		_fill_rect(img, x + t, y + h - 1 - t, w - t * 2, 1, color)
		_fill_rect(img, x + t, y + t, 1, h - t * 2, color)
		_fill_rect(img, x + w - 1 - t, y + t, 1, h - t * 2, color)
