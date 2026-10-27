class_name LessonFitLabel
extends Label

## Wraps to the width the parent assigns and does not widen the row.
## A normal Label's minimum width is the unwrapped line, which pushed card
## rows past the phone edge so the right column was clipped.

var _last_width := -1.0


func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resized.connect(_on_resized)
	call_deferred("_on_resized")


func _on_resized() -> void:
	if absf(size.x - _last_width) < 1.0:
		return
	_last_width = size.x
	update_minimum_size()


func _get_minimum_size() -> Vector2:
	var width := size.x
	if width < 48.0:
		return Vector2(0, _line_step() * _paragraph_count())
	return Vector2(0, _wrapped_height(width))


func _font() -> Font:
	if label_settings != null and label_settings.font != null:
		return label_settings.font
	return ThemeDB.fallback_font


func _font_size() -> int:
	if label_settings != null and label_settings.font_size > 0:
		return label_settings.font_size
	return 16


func _line_step() -> float:
	var font := _font()
	var fs := _font_size()
	var step := font.get_height(fs)
	if label_settings != null:
		step += label_settings.line_spacing
	return maxf(step, float(fs))


func _paragraph_count() -> int:
	if text.is_empty():
		return 1
	return text.split("\n", true).size()


func _wrapped_height(width: float) -> float:
	var font := _font()
	var fs := _font_size()
	var step := _line_step()
	var lines := 0
	for paragraph in text.split("\n", true):
		lines += _wrap_lines(paragraph, width, font, fs)
	if lines < 1:
		lines = 1
	# Small pad so the last line is not flush with the next control.
	return lines * step + 4.0


func _wrap_lines(paragraph: String, width: float, font: Font, fs: int) -> int:
	if paragraph.is_empty():
		return 1
	var space := font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lines := 1
	var row := 0.0
	for word in paragraph.split(" ", false):
		var word_w := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		if row > 0.0 and row + space + word_w > width:
			lines += 1
			row = word_w
		else:
			row = word_w if row <= 0.0 else row + space + word_w
	return lines
