class_name Module0SlideTheme
extends RefCounted

## Shared dark navy + cyan look for Module 0 lesson slides.

const NAVY := Color(0.003921569, 0.09019608, 0.13725491, 1)
const PANEL := Color(0.04, 0.14, 0.22, 0.96)
const PANEL_BORDER := Color(0.35, 0.82, 0.95, 0.35)
const CYAN := Color(0.09, 0.65, 0.87, 1)
const WHITE := Color(0.95, 0.98, 0.99, 1)
const MUTED := Color(0.72, 0.86, 0.95, 0.9)
const CARD_DARK := Color(0.03, 0.12, 0.2, 0.95)
const CARD_CYAN := Color(0.07, 0.42, 0.58, 0.95)

const FONT_TITLE := "res://assets/fonts/gscode_extrabold.ttf"
const FONT_SUB := "res://assets/fonts/gsflex_medium.ttf"
const FONT_BODY := "res://assets/fonts/gsflex_regular.ttf"
const FONT_CARD := "res://assets/fonts/gsflex_bold.ttf"


static func load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path) as Font
	return ThemeDB.fallback_font


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


static func card_style(accent: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = CARD_CYAN if accent else CARD_DARK
	s.border_color = Color(0.35, 0.82, 0.95, 0.45 if accent else 0.22)
	s.set_border_width_all(1)
	s.set_corner_radius_all(14)
	s.content_margin_left = 16
	s.content_margin_top = 14
	s.content_margin_right = 16
	s.content_margin_bottom = 14
	return s


static func title_settings(size: int = 36) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load_font(FONT_TITLE)
	ls.font_size = size
	ls.font_color = WHITE
	ls.line_spacing = -4
	return ls


static func subtitle_settings(size: int = 18) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load_font(FONT_SUB)
	ls.font_size = size
	ls.font_color = CYAN
	return ls


static func body_settings(size: int = 16) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load_font(FONT_BODY)
	ls.font_size = size
	ls.font_color = MUTED
	return ls


static func card_title_settings(size: int = 16) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load_font(FONT_CARD)
	ls.font_size = size
	ls.font_color = WHITE
	return ls


static func card_body_settings(size: int = 13) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load_font(FONT_BODY)
	ls.font_size = size
	ls.font_color = Color(0.82, 0.92, 0.98, 0.92)
	return ls
