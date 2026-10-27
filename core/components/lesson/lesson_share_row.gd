class_name LessonShareRow
extends Container

## Equal columns that stay inside this control's width.
## HBox will not shrink a child below its minimum width, so a long label
## used to push the last card off the right edge of the phone.

var separation: int = 10
var _last_width := -1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)


func _on_resized() -> void:
	if absf(size.x - _last_width) < 1.0:
		return
	_last_width = size.x
	update_minimum_size()


func _get_minimum_size() -> Vector2:
	var height := 0.0
	for child in get_children():
		if child is Control and (child as Control).visible:
			height = maxf(height, (child as Control).get_combined_minimum_size().y)
	# Width is whatever the parent assigns. Reporting 0 stops the row from
	# growing wider than the slide and getting clipped.
	return Vector2(0, height)


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var kids: Array[Control] = []
	for child in get_children():
		if child is Control and (child as Control).visible:
			kids.append(child)
	if kids.is_empty() or size.x <= 1.0:
		return
	var gaps := float(separation * maxi(kids.size() - 1, 0))
	var usable := maxf(size.x - gaps, 0.0)
	var weight_sum := 0.0
	var weights: Array[float] = []
	for child in kids:
		var weight := child.size_flags_stretch_ratio
		if weight <= 0.0:
			weight = 1.0
		weights.append(weight)
		weight_sum += weight
	if weight_sum <= 0.0:
		weight_sum = 1.0
	var x := 0.0
	for i in kids.size():
		var slice := usable * (weights[i] / weight_sum)
		fit_child_in_rect(kids[i], Rect2(x, 0, slice, size.y))
		x += slice + float(separation)
