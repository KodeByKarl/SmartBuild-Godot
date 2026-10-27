class_name TouchSwipePager
extends Container

## Horizontal finger-swipe paging: the page follows the finger, then snaps to
## the neighbour page or back — the same feel as the Home module-card pager.
##
## Gesture handling mirrors TouchDragScroll: events are read in _input() so a
## swipe that starts on a card or panel still works, the gesture is only
## claimed after DRAG_THRESHOLD of mostly-horizontal travel (vertical drags are
## left to TouchDragScroll), and claimed presses are cancelled so lifting the
## finger does not click whatever the swipe started on. Mouse drags arrive as
## touch events via input_devices/pointing/emulate_touch_from_mouse.
##
## The owner decides what the pages are:
##   - set_current(page) shows a page (any visible child is laid out full size)
##   - neighbor_provider(direction) -> Control returns the page at ±1, or null
##   - has_prev / has_next bound the swipe; past an edge the page rubber-bands
##   - page_committed(direction) fires after the snap lands on a neighbour
##
## Swipes never start over interactive controls: 3D viewers
## (SubViewportContainer), buttons, sliders, text fields, lists, and scroll
## areas that can actually scroll. Mark a scroll that is just page chrome with
## meta "swipe_passthrough" = true, or any control with meta "no_swipe" = true
## to opt it out.

signal page_committed(direction: int)

const DRAG_THRESHOLD := 10.0
## Gap between pages while they slide, so the edges never touch.
const PAGE_GAP := 24.0
## Fraction of the width that commits a slow drag (Compose pager uses half).
const COMMIT_FRACTION := 0.5
## Fling speed (px/s) that commits regardless of distance.
const FLING_SPEED := 500.0
## Drag resistance past the first or last page.
const EDGE_RESISTANCE := 0.3
const SNAP_MIN_TIME := 0.12
const SNAP_MAX_TIME := 0.28

var neighbor_provider: Callable = Callable()
var has_prev := false
var has_next := false

var _current: Control = null
var _neighbor: Control = null
var _neighbor_dir := 0
var _offset := 0.0

var _touch_index := -1
var _tracking := false
var _dragging := false
var _press_position := Vector2.ZERO
var _last_position := Vector2.ZERO
var _velocity := 0.0
var _snap: Tween = null


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_current(page: Control) -> void:
	_kill_snap()
	_release_neighbor()
	_current = page
	_offset = 0.0
	queue_sort()


func is_animating() -> bool:
	return _dragging or (_snap != null and _snap.is_valid() and _snap.is_running())


# --- Layout -----------------------------------------------------------------

func _get_minimum_size() -> Vector2:
	# Width comes from the parent so a wide page cannot widen the slide area.
	var height := 0.0
	for child in get_children():
		var control := child as Control
		if control != null and control.visible:
			height = maxf(height, control.get_combined_minimum_size().y)
	return Vector2(0, height)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout_pages()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_reset_gesture()
		_settle(0.0, 0)


func _layout_pages() -> void:
	var step := size.x + PAGE_GAP
	for child in get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		var x := _offset
		if control == _neighbor:
			x += float(_neighbor_dir) * step
		fit_child_in_rect(control, Rect2(x, 0, size.x, size.y))


func _set_offset(value: float) -> void:
	_offset = value
	queue_sort()


# --- Gesture ----------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _tracking or is_animating() or not _owns_point(event.position):
			return
		_touch_index = event.index
		_tracking = true
		_dragging = false
		_press_position = event.position
		_last_position = event.position
		_velocity = 0.0
		return
	if not _tracking or event.index != _touch_index:
		return
	var was_dragging := _dragging
	_reset_gesture()
	if was_dragging:
		# Leave the release itself unhandled so the viewport clears GUI focus.
		_finish_swipe()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if not _tracking or event.index != _touch_index:
		return
	var delta_x: float = event.position.x - _last_position.x
	_last_position = event.position
	if not _dragging:
		var travel: Vector2 = event.position - _press_position
		# Horizontal intent only; vertical drags belong to TouchDragScroll.
		if absf(travel.x) < DRAG_THRESHOLD or absf(travel.x) <= absf(travel.y):
			if absf(travel.y) >= DRAG_THRESHOLD:
				_reset_gesture()
			return
		_dragging = true
		TouchDragScroll.cancel_presses(self)
		# Start from the finger's current position so the page does not jump.
		delta_x = travel.x
	_velocity = lerpf(_velocity, event.velocity.x, 0.5)
	_drag_by(delta_x)
	get_viewport().set_input_as_handled()


func _drag_by(delta_x: float) -> void:
	var proposed := _offset + delta_x
	var dir := -1 if proposed > 0.0 else 1  # finger right → previous page
	if proposed == 0.0:
		_set_offset(0.0)
		return
	if not _can_go(dir):
		_release_neighbor()
		_set_offset(_offset + delta_x * EDGE_RESISTANCE)
		return
	_ensure_neighbor(dir)
	var step := size.x + PAGE_GAP
	_set_offset(clampf(proposed, -step, step))


func _finish_swipe() -> void:
	var step := size.x + PAGE_GAP
	var dir := 0
	if _neighbor != null and _can_go(_neighbor_dir):
		var toward := -float(_neighbor_dir)  # sign of _offset that reveals the neighbour
		var far_enough := _offset * toward > size.x * COMMIT_FRACTION
		var flung := _velocity * toward > FLING_SPEED
		var flung_back := _velocity * toward < -FLING_SPEED
		if (far_enough or flung) and not flung_back:
			dir = _neighbor_dir
	_settle(-float(dir) * step, dir)


func _settle(target: float, dir: int) -> void:
	_kill_snap()
	var distance := absf(target - _offset)
	if distance < 0.5 or not is_inside_tree():
		_on_settled(target, dir)
		return
	var span := maxf(size.x, 1.0)
	var time := lerpf(SNAP_MIN_TIME, SNAP_MAX_TIME, clampf(distance / span, 0.0, 1.0))
	_snap = create_tween()
	_snap.tween_method(_set_offset, _offset, target, time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_snap.finished.connect(_on_settled.bind(target, dir))


func _on_settled(target: float, dir: int) -> void:
	_snap = null
	_set_offset(target)
	if dir == 0:
		_release_neighbor()
		_set_offset(0.0)
		return
	# The neighbour now sits exactly where the current page was; the owner swaps
	# it in with set_current(), which resets the offset with no visible jump.
	page_committed.emit(dir)


func _ensure_neighbor(dir: int) -> void:
	if _neighbor != null and _neighbor_dir == dir and is_instance_valid(_neighbor):
		return
	_release_neighbor()
	if not neighbor_provider.is_valid():
		return
	var page := neighbor_provider.call(dir) as Control
	if page == null or page == _current:
		return
	_neighbor = page
	_neighbor_dir = dir
	_neighbor.visible = true
	queue_sort()


func _release_neighbor() -> void:
	if _neighbor != null and is_instance_valid(_neighbor) and _neighbor != _current:
		_neighbor.visible = false
	_neighbor = null
	_neighbor_dir = 0


func _can_go(dir: int) -> bool:
	return has_next if dir > 0 else has_prev


func _reset_gesture() -> void:
	_tracking = false
	_dragging = false
	_touch_index = -1


func _kill_snap() -> void:
	if _snap != null and _snap.is_valid():
		_snap.kill()
	_snap = null


# --- Hit testing ------------------------------------------------------------

func _owns_point(point: Vector2) -> bool:
	if not get_global_rect().has_point(point):
		return false
	if _current == null or not is_instance_valid(_current):
		return false
	return not _blocked_at(_current, point)


## True when an interactive control under the finger should keep the gesture.
func _blocked_at(node: Node, point: Vector2) -> bool:
	for child in node.get_children():
		var control := child as Control
		if control == null:
			if _blocked_at(child, point):
				return true
			continue
		if not control.is_visible_in_tree() or not control.get_global_rect().has_point(point):
			continue
		if _is_interactive(control):
			return true
		if _blocked_at(control, point):
			return true
	return false


func _is_interactive(control: Control) -> bool:
	if control.has_meta("no_swipe") and bool(control.get_meta("no_swipe")):
		return true
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE and not (control is ScrollContainer):
		return false
	if control is SubViewportContainer:
		return true  # 3D viewers orbit on drag
	if control is BaseButton and not (control as BaseButton).disabled:
		return true
	if control is Range or control is LineEdit or control is TextEdit:
		return true
	if control is ItemList or control is Tree:
		return true
	var scroll := control as ScrollContainer
	if scroll != null:
		if scroll.has_meta("swipe_passthrough") and bool(scroll.get_meta("swipe_passthrough")):
			return false
		return _scrolls(scroll.get_h_scroll_bar()) or _scrolls(scroll.get_v_scroll_bar())
	return false


static func _scrolls(bar: ScrollBar) -> bool:
	return bar != null and bar.max_value - bar.min_value > bar.page + 1.0
