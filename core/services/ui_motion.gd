extends Node

## Lightweight shared tweens for module pages, slides, and cards.


func play_enter(node: CanvasItem, delay: float = 0.0) -> Tween:
	if node == null or not is_instance_valid(node):
		return null

	var allow_motion := true
	var profile := get_node_or_null("/root/PerformanceProfile")
	if profile != null and "enable_page_motion" in profile:
		allow_motion = bool(profile.get("enable_page_motion"))

	if not allow_motion:
		node.modulate.a = 1.0
		return null

	# Keep a safe visible end-state even if the tween is interrupted.
	node.modulate.a = 0.0
	var use_slide: bool = false
	var start_y: float = 0.0
	if node is Control:
		var control: Control = node as Control
		use_slide = not (
			is_equal_approx(control.anchor_right - control.anchor_left, 1.0)
			and is_equal_approx(control.anchor_bottom - control.anchor_top, 1.0)
		)
		if use_slide:
			start_y = control.position.y
			control.position.y = start_y + 18.0

	var tween: Tween = node.create_tween()
	if tween == null:
		node.modulate.a = 1.0
		return null
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_property(node, "modulate:a", 1.0, 0.32).set_delay(delay)
		if use_slide:
			tween.tween_property(node, "position:y", start_y, 0.34).set_delay(delay)
	else:
		tween.tween_property(node, "modulate:a", 1.0, 0.32)
		if use_slide:
			tween.tween_property(node, "position:y", start_y, 0.34)
	tween.finished.connect(func() -> void:
		if is_instance_valid(node):
			node.modulate.a = 1.0
	)
	return tween


func play_exit(node: CanvasItem, on_done: Callable = Callable()) -> Tween:
	if node == null or not is_instance_valid(node):
		if on_done.is_valid():
			on_done.call()
		return null
	var profile := get_node_or_null("/root/PerformanceProfile")
	if profile != null and "enable_page_motion" in profile and not bool(profile.get("enable_page_motion")):
		if on_done.is_valid():
			on_done.call()
		return null

	var tween: Tween = node.create_tween()
	if tween == null:
		if on_done.is_valid():
			on_done.call()
		return null
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "modulate:a", 0.0, 0.18)
	if on_done.is_valid():
		tween.finished.connect(on_done)
	return tween


func pulse_button(button: CanvasItem) -> void:
	if button == null or not is_instance_valid(button):
		return
	var tween: Tween = button.create_tween()
	if tween == null:
		return
	tween.tween_property(button, "modulate", Color(1.15, 1.15, 1.15, 1.0), 0.08)
	tween.tween_property(button, "modulate", Color.WHITE, 0.14)


func stagger_children(parent: Node, base_delay: float = 0.04) -> void:
	if parent == null:
		return
	var i: int = 0
	for child in parent.get_children():
		if child is CanvasItem:
			play_enter(child as CanvasItem, float(i) * base_delay)
			i += 1
