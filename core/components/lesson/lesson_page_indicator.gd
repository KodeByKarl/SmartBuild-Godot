class_name LessonPageIndicator
extends Label

## Page position under the lesson card: "3 / 21", with an optional hint on the
## first page ("Swipe to continue  ›"). Kept small so the card gets the height.

var first_page_hint := "Swipe to continue  ›"


func _ready() -> void:
	refresh_theme()
	add_theme_font_size_override("font_size", LessonTheme.readable(12))


func refresh_theme() -> void:
	add_theme_color_override("font_color", Color(LessonTheme.WHITE, 0.8))


func show_text(message: String) -> void:
	text = message


func show_position(index: int, count: int) -> void:
	var counter := "%d / %d" % [index + 1, maxi(count, 1)]
	text = (first_page_hint + "    " + counter) if index == 0 and first_page_hint != "" else counter
