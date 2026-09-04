extends Node

## Breakpoints and helpers for phone-friendly layouts.

const PHONE_MAX_WIDTH := 720.0
const COMPACT_MAX_WIDTH := 960.0


func viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func is_phone() -> bool:
	var size := viewport_size()
	return size.x < PHONE_MAX_WIDTH or size.y < 480.0


func is_compact() -> bool:
	return viewport_size().x < COMPACT_MAX_WIDTH


func is_landscape() -> bool:
	var size := viewport_size()
	return size.x >= size.y


func content_scale() -> float:
	var w := viewport_size().x
	if w <= 0.0:
		return 1.0
	if w < 480.0:
		return 0.82
	if w < 720.0:
		return 0.9
	return 1.0


func scaled_font(base: int) -> int:
	return maxi(int(round(float(base) * content_scale())), 11)


func fit_full_rect(control: Control) -> void:
	if control == null:
		return
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vp := viewport_size()
	if vp.x > 1.0 and vp.y > 1.0:
		control.size = vp
