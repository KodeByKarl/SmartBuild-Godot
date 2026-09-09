class_name TouchDragScroll
extends Node

## Finger-drag scrolling for the ScrollContainer this node is parented to.
##
## Godot only runs a ScrollContainer's built-in touch scrolling when the drag
## event actually reaches it. Lesson and simulation pages are almost entirely
## Buttons and Panels, which use MOUSE_FILTER_STOP and swallow the drag, so a
## finger placed on a card did nothing and the page could only be moved by
## grabbing the thin scrollbar. Listening in _input() instead gets the events
## before GUI routing, so a drag started anywhere over the scroll area works.

const DRAG_THRESHOLD := 10.0
const FLICK_DECAY := 7.0
const MIN_FLICK_SPEED := 24.0
const MAX_FLICK_SPEED := 3600.0

var _scroll: ScrollContainer = null
var _touch_index := -1
var _tracking := false
var _dragging := false
var _press_position := Vector2.ZERO
var _last_position := Vector2.ZERO
var _velocity := 0.0
## scroll_vertical is an int, so sub-pixel movement is carried over instead of
## being rounded away — without this a slow drag stutters or does nothing.
var _remainder := 0.0


## Idempotent — safe to call on a ScrollContainer that already has a helper.
static func attach(scroll: ScrollContainer) -> void:
	if scroll == null:
		return
	for child in scroll.get_children():
		if child is TouchDragScroll:
			return
	var helper := TouchDragScroll.new()
	helper.name = "TouchDragScroll"
	# Deferred: node_added fires while the parent is still wiring up children.
	scroll.add_child.call_deferred(helper)


func _ready() -> void:
	set_process(false)
	_scroll = get_parent() as ScrollContainer
	if _scroll == null:
		set_process_input(false)
		return
	# Hold off the container's own touch handling until we have claimed the drag,
	# otherwise both scroll the page for the first few pixels.
	_scroll.scroll_deadzone = int(DRAG_THRESHOLD)


func _input(event: InputEvent) -> void:
	if _scroll == null or not _scroll.is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _process(delta: float) -> void:
	if _scroll == null:
		set_process(false)
		return
	_apply_scroll(-_velocity * delta)
	_velocity = lerpf(_velocity, 0.0, clampf(FLICK_DECAY * delta, 0.0, 1.0))
	if absf(_velocity) < MIN_FLICK_SPEED:
		_velocity = 0.0
		set_process(false)


func _apply_scroll(pixels: float) -> void:
	var total: float = pixels + _remainder
	var whole: int = int(total)
	_remainder = total - float(whole)
	if whole != 0:
		_scroll.scroll_vertical += whole


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _tracking or not _can_scroll() or not _owns_point(event.position):
			return
		_touch_index = event.index
		_tracking = true
		_dragging = false
		_press_position = event.position
		_last_position = event.position
		_velocity = 0.0
		_remainder = 0.0
		set_process(false)
		return
	if not _tracking or event.index != _touch_index:
		return
	_tracking = false
	_touch_index = -1
	if not _dragging:
		return
	_dragging = false
	# The release itself is left alone so the viewport can clear its GUI focus.
	if absf(_velocity) >= MIN_FLICK_SPEED:
		set_process(true)


func _handle_drag(event: InputEventScreenDrag) -> void:
	if not _tracking or event.index != _touch_index:
		return
	var delta: Vector2 = event.position - _last_position
	_last_position = event.position
	if not _dragging:
		var travel: Vector2 = event.position - _press_position
		# Vertical intent only, so horizontal swipes still reach chip rows.
		if absf(travel.y) < DRAG_THRESHOLD or absf(travel.y) <= absf(travel.x):
			return
		_dragging = true
		_cancel_touched_buttons()
	_apply_scroll(-delta.y)
	var frame: float = get_process_delta_time()
	if frame > 0.0:
		_velocity = clampf(delta.y / frame, -MAX_FLICK_SPEED, MAX_FLICK_SPEED)
	get_viewport().set_input_as_handled()


func _can_scroll() -> bool:
	var bar: VScrollBar = _scroll.get_v_scroll_bar()
	if bar == null:
		return false
	return bar.max_value - bar.min_value > bar.page + 1.0


func _owns_point(point: Vector2) -> bool:
	if not _scroll.get_global_rect().has_point(point):
		return false
	# A nested scroll under the finger owns the gesture instead of this one.
	return not _inner_claim(_scroll, point)


func _inner_claim(node: Node, point: Vector2) -> bool:
	for child in node.get_children():
		var control := child as Control
		if control != null and control.is_visible_in_tree():
			if not control.get_global_rect().has_point(point):
				continue
			# 3D part viewers orbit on drag; never steal from them.
			if control is SubViewportContainer:
				return true
			var inner := control as ScrollContainer
			if inner != null:
				var bar: VScrollBar = inner.get_v_scroll_bar()
				if bar != null and bar.max_value - bar.min_value > bar.page + 1.0:
					return true
		if _inner_claim(child, point):
			return true
	return false


## Clears the in-progress press so lifting the finger after a drag does not
## activate whatever card or button the gesture started on.
func _cancel_touched_buttons() -> void:
	_cancel_hovered(_scroll)


func _cancel_hovered(node: Node) -> void:
	for child in node.get_children():
		var button := child as BaseButton
		if button != null and (button.is_pressed() or button.is_hovered()):
			# Toggling disabled is the only public way to drop press_attempt.
			# It leaves toggle buttons' checked state alone.
			var was_disabled: bool = button.disabled
			button.disabled = true
			button.disabled = was_disabled
		_cancel_hovered(child)
