class_name LessonTheme
extends RefCounted

## Shared look for every lesson page (Modules 0–4), from the SMARTBUILD Figma file.
## Module 0's original navy + cyan tokens are kept as-is so its slides render
## exactly as before; the FIGMA_* tokens drive the Module 1–4 page format.

## Colour tokens are static vars (not consts) so Light mode can swap them at
## runtime; set_light_mode() rewrites every one and pages are rebuilt after.
static var NAVY := Color(0.003921569, 0.09019608, 0.13725491, 1)
static var PANEL := Color(0.04, 0.14, 0.22, 0.96)
static var PANEL_BORDER := Color(0.35, 0.82, 0.95, 0.35)
static var CYAN := Color(0.09, 0.65, 0.87, 1)
static var WHITE := Color(0.95, 0.98, 0.99, 1)
static var MUTED := Color(0.72, 0.86, 0.95, 0.9)
static var CARD_DARK := Color(0.03, 0.12, 0.2, 0.95)
static var CARD_CYAN := Color(0.07, 0.42, 0.58, 0.95)

## Figma SMARTBUILD tokens (frames 1:220, 1:372, 1:904, 19:4, 1:1679).
static var FIGMA_PANEL := Color("#0a2337")
static var FIGMA_PANEL_BORDER := Color("#2f5867")
static var FIGMA_CHIP := Color("#0a2c46")
static var FIGMA_CHIP_BORDER := Color("#2fb6e6")
static var FIGMA_TEXT := Color("#f3fafd")
## Checked checklist row / selected tool card.
static var FIGMA_DONE_FILL := Color("#163d36")
static var FIGMA_DONE_BORDER := Color("#20c997")
## Completion page: progress bar, Proceed and Retake buttons.
static var FIGMA_BAR := Color("#14a5dc")
static var FIGMA_BAR_TRACK := Color("#29506e")
static var FIGMA_PROCEED := Color("#17a6df")
static var FIGMA_RETAKE := Color("#29506e")
static var FIGMA_RETAKE_BORDER := Color("#00d4c9")
## Simulation goal card: the guide line is yellow in Figma.
static var FIGMA_GUIDE := Color("#f5e663")

const SETTINGS_PATH := "user://display.cfg"
static var light_mode := false
static var _mode_loaded := false


## Reads the saved Light / Dark choice once per launch.
static func ensure_mode_loaded() -> void:
	if _mode_loaded:
		return
	_mode_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		_apply_palette(bool(cfg.get_value("display", "light_mode", false)))


static func set_light_mode(on: bool) -> void:
	_mode_loaded = true
	_apply_palette(on)
	var cfg := ConfigFile.new()
	cfg.set_value("display", "light_mode", on)
	cfg.save(SETTINGS_PATH)


static func _apply_palette(light: bool) -> void:
	light_mode = light
	if light:
		NAVY = Color("#eaf2f8")
		PANEL = Color(1, 1, 1, 0.98)
		PANEL_BORDER = Color("#9fc3d6")
		CYAN = Color("#0b7fae")
		WHITE = Color("#0b2438")
		MUTED = Color("#2c4a60")
		CARD_DARK = Color("#f4f9fc")
		CARD_CYAN = Color("#d3ebf6")
		FIGMA_PANEL = Color("#ffffff")
		FIGMA_PANEL_BORDER = Color("#9fc3d6")
		FIGMA_CHIP = Color("#d9ecf7")
		FIGMA_CHIP_BORDER = Color("#0b7fae")
		FIGMA_TEXT = Color("#0b2438")
		FIGMA_DONE_FILL = Color("#d7f3e8")
		FIGMA_DONE_BORDER = Color("#119a73")
		FIGMA_BAR = Color("#0b8fc4")
		FIGMA_BAR_TRACK = Color("#bcd6e6")
		FIGMA_PROCEED = Color("#0b8fc4")
		FIGMA_RETAKE = Color("#e2eff7")
		FIGMA_RETAKE_BORDER = Color("#0b8f89")
		FIGMA_GUIDE = Color("#9a7b00")
	else:
		NAVY = Color(0.003921569, 0.09019608, 0.13725491, 1)
		PANEL = Color(0.04, 0.14, 0.22, 0.96)
		PANEL_BORDER = Color(0.35, 0.82, 0.95, 0.35)
		CYAN = Color(0.09, 0.65, 0.87, 1)
		WHITE = Color(0.95, 0.98, 0.99, 1)
		MUTED = Color(0.72, 0.86, 0.95, 0.9)
		CARD_DARK = Color(0.03, 0.12, 0.2, 0.95)
		CARD_CYAN = Color(0.07, 0.42, 0.58, 0.95)
		FIGMA_PANEL = Color("#0a2337")
		FIGMA_PANEL_BORDER = Color("#2f5867")
		FIGMA_CHIP = Color("#0a2c46")
		FIGMA_CHIP_BORDER = Color("#2fb6e6")
		FIGMA_TEXT = Color("#f3fafd")
		FIGMA_DONE_FILL = Color("#163d36")
		FIGMA_DONE_BORDER = Color("#20c997")
		FIGMA_BAR = Color("#14a5dc")
		FIGMA_BAR_TRACK = Color("#29506e")
		FIGMA_PROCEED = Color("#17a6df")
		FIGMA_RETAKE = Color("#29506e")
		FIGMA_RETAKE_BORDER = Color("#00d4c9")
		FIGMA_GUIDE = Color("#f5e663")


const RESPONSIVE := preload("res://core/services/responsive_layout.gd")

const FONT_TITLE := "res://assets/fonts/gscode_extrabold.ttf"
const FONT_SUB := "res://assets/fonts/gsflex_medium.ttf"
const FONT_BODY := "res://assets/fonts/gsflex_regular.ttf"
const FONT_CARD := "res://assets/fonts/gsflex_bold.ttf"

const ICON_CHECK := "res://core/components/lesson/assets/check.png"
const ICON_BADGE_OFF := "res://core/components/lesson/assets/badge_off.svg"
const ICON_BADGE_ON := "res://core/components/lesson/assets/badge_on.svg"
const ICON_DONE_DOT := "res://core/components/lesson/assets/done_dot.svg"
const ICON_BACK := "res://core/components/lesson/assets/back_circle_blue.svg"


## Mirrors ResponsiveLayout.readable_font. Floor stays at the phone minimum
## so lesson titles, card copy, and bullets stay readable.
static func readable(size: int) -> int:
	return clampi(
		int(round(float(size) * RESPONSIVE.READABLE_FONT_BOOST)),
		RESPONSIVE.READABLE_FONT_MIN,
		RESPONSIVE.READABLE_FONT_MAX
	)


static func load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path) as Font
	return ThemeDB.fallback_font


static func load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = PANEL
	s.border_color = PANEL_BORDER
	s.set_border_width_all(1)
	s.set_corner_radius_all(20)
	s.content_margin_left = 0
	s.content_margin_top = 0
	s.content_margin_right = 0
	s.content_margin_bottom = 0
	return s


## Figma content card: flat navy, muted teal hairline, 24px corners.
static func welcome_panel_style() -> StyleBoxFlat:
	var s := panel_style()
	s.bg_color = FIGMA_PANEL
	s.border_color = FIGMA_PANEL_BORDER
	s.set_corner_radius_all(24)
	return s


## Figma sub-card inside the content card (step cards, device cards).
static func figma_card_style(done: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = FIGMA_DONE_FILL if done else FIGMA_PANEL
	s.border_color = FIGMA_DONE_BORDER if done else FIGMA_PANEL_BORDER
	s.set_border_width_all(1)
	s.set_corner_radius_all(24)
	s.content_margin_left = 12
	s.content_margin_top = 10
	s.content_margin_right = 12
	s.content_margin_bottom = 12
	return s


## Checklist row (Figma 19:4): 52px tall pill, green when checked.
static func checklist_row_style(done: bool) -> StyleBoxFlat:
	var s := figma_card_style(done)
	s.set_corner_radius_all(25)
	s.content_margin_left = 8
	s.content_margin_top = 6
	s.content_margin_right = 16
	s.content_margin_bottom = 6
	return s


## Header chip (Back / Help) from Figma: navy fill, 7px corners.
static func chip_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = FIGMA_CHIP
	s.border_color = FIGMA_CHIP_BORDER
	s.set_border_width_all(2)
	s.set_corner_radius_all(9)
	s.content_margin_left = 10
	s.content_margin_right = 12
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


## Completion buttons (Figma 1:1679): 22px pills.
static func pill_style(fill: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(22)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


## Google Sans Flex with optional letter spacing (Figma tracking).
static func tracked_font(path: String, tracking: int) -> Font:
	var base := load_font(path)
	if tracking == 0:
		return base
	var fv := FontVariation.new()
	fv.base_font = base
	fv.spacing_glyph = tracking
	return fv


static func welcome_title_settings() -> LabelSettings:
	return figma_text(32, true, 1)


static func welcome_body_settings() -> LabelSettings:
	var ls := figma_text(15, false)
	ls.line_spacing = 2
	return ls


## Figma text: Google Sans Flex, #f3fafd, optional bold and tracking.
static func figma_text(size: int, bold: bool, tracking: int = 0) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = tracked_font(FONT_CARD if bold else FONT_BODY, tracking)
	ls.font_size = readable(size)
	ls.font_color = FIGMA_TEXT
	ls.line_spacing = 0
	return ls


static func card_style(accent: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = CARD_CYAN if accent else CARD_DARK
	s.border_color = Color(0.35, 0.82, 0.95, 0.45 if accent else 0.22)
	s.set_border_width_all(1)
	s.set_corner_radius_all(10)
	s.content_margin_left = 10
	s.content_margin_top = 8
	s.content_margin_right = 10
	s.content_margin_bottom = 8
	return s


static func title_settings(size: int = 28) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load_font(FONT_TITLE)
	ls.font_size = readable(size)
	ls.font_color = WHITE
	ls.line_spacing = 6
	return ls


static func subtitle_settings(size: int = 18) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load_font(FONT_SUB)
	ls.font_size = readable(size)
	ls.font_color = CYAN
	ls.line_spacing = 4
	return ls


static func body_settings(size: int = 16) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load_font(FONT_BODY)
	ls.font_size = readable(size)
	ls.font_color = MUTED
	ls.line_spacing = 6
	return ls


static func card_title_settings(size: int = 16) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load_font(FONT_CARD)
	ls.font_size = readable(size)
	ls.font_color = WHITE
	ls.line_spacing = 4
	return ls


static func card_body_settings(size: int = 15) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load_font(FONT_BODY)
	ls.font_size = readable(size)
	ls.font_color = Color(0.82, 0.92, 0.98, 0.92)
	ls.line_spacing = 6
	return ls
