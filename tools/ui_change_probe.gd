extends Node

## Temporary probe: verifies the nav-chrome relayout, the assessment start page
## and the touch-scroll attachment. Run with:
##   godot --headless --path . tools/UiChangeProbe.tscn

var _failures: int = 0
var _events: Array[String] = []


## The shell walks up its parents looking for a host with send_event().
func send_event(event: String, _module_id: int = -1, _percent: float = -1.0) -> void:
	_events.append(event)


func _ready() -> void:
	await get_tree().process_frame
	_check_module_zero()
	for module_id in [1, 2, 3, 4]:
		await _check_module_shell(module_id)
	await _check_touch_scroll()
	await _check_completion_flow()
	print("")
	if _failures == 0:
		print("PROBE OK — all checks passed")
	else:
		print("PROBE FAILED — %d check(s) failed" % _failures)
	get_tree().quit(0 if _failures == 0 else 1)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  ok   %s" % label)
	else:
		print("  FAIL %s" % label)
		_failures += 1


func _check_module_zero() -> void:
	print("module 0 shell")
	var packed := load("res://modules/module_0/Main.tscn") as PackedScene
	var shell: Control = packed.instantiate()
	add_child(shell)
	var exit_btn: Node = shell.get_node_or_null("Wrapper/Header/ExitButton")
	_expect(exit_btn != null, "Back/Exit lives in the header")
	_expect(exit_btn != null and exit_btn.get_index() == 0, "Back/Exit is the leftmost header item")
	_expect(exit_btn is Button and (exit_btn as Button).text == "Back", "header control is labeled Back")
	_expect(shell.get_node_or_null("Wrapper/Navigation/PreviousButton") != null, "Prev in nav bar")
	_expect(shell.get_node_or_null("Wrapper/Navigation/PageNumberLabel") != null, "Page label in nav bar")
	_expect(shell.get_node_or_null("Wrapper/Navigation/NextButton") != null, "Next in nav bar")
	_expect(shell.get_node_or_null("Wrapper/Presentation/PageScroll/Content") != null, "Slides sit in a scroll")
	var nav: Control = shell.get_node("Wrapper/Navigation")
	var prev_index: int = shell.get_node("Wrapper/Navigation/PreviousButton").get_index()
	var label_index: int = shell.get_node("Wrapper/Navigation/PageNumberLabel").get_index()
	var next_index: int = shell.get_node("Wrapper/Navigation/NextButton").get_index()
	_expect(prev_index < label_index and label_index < next_index, "Prev / page / Next ordered")
	_expect(nav.custom_minimum_size.y >= 80.0, "Nav bar has room (%d px)" % int(nav.custom_minimum_size.y))
	shell.queue_free()


func _check_module_shell(module_id: int) -> void:
	print("module %d shell" % module_id)
	var packed := load("res://modules/module_%d/Main.tscn" % module_id) as PackedScene
	var host: Control = packed.instantiate()
	host.configure(module_id, 1, 0.0)
	add_child(host)
	await get_tree().process_frame
	await get_tree().process_frame
	var shell: Node = host.get_node_or_null("ModuleShell")
	if shell == null:
		for child in host.get_children():
			if child.has_method("configure") and child.get("current_page_index") != null:
				shell = child
				break
	if shell == null:
		_expect(false, "found the ModuleShell node")
		host.queue_free()
		return
	var exit_btn: Node = shell.get_node_or_null("Wrapper/Header/ExitButton")
	_expect(exit_btn != null, "Exit lives in the header")
	_expect(exit_btn != null and exit_btn.get_index() == 0, "Exit is the leftmost header item")
	_expect(shell.get_node_or_null("Wrapper/Navigation/PreviousButton") != null, "Prev in nav bar")
	_expect(shell.get_node_or_null("Wrapper/Navigation/NextButton") != null, "Next in nav bar")

	var pages: Array = ModuleContentRegistry.get_module(module_id).get("pages", [])
	var expected := -1
	for index in pages.size():
		if str((pages[index] as Dictionary).get("type", "")) == "assessment":
			expected = index
			break
	var actual: int = int(shell.get("current_page_index"))
	_expect(
		expected >= 0 and actual == expected,
		"assessment opens on page %d (got %d)" % [expected + 1, actual + 1]
	)
	# Bridge page must sit immediately before the first assessment.
	if expected > 0:
		var before: Dictionary = pages[expected - 1] as Dictionary
		_expect(
			str(before.get("type", "")) == "checklist",
			"be-ready bridge sits before assessment (got %s)" % str(before.get("type", ""))
		)

	# Next is locked on an unfinished assessment page.
	if shell.has_method("_can_advance_from_current_page"):
		_expect(
			not bool(shell.call("_can_advance_from_current_page")),
			"Next locked until assessment simulation is finished"
		)
	host.queue_free()
	await get_tree().process_frame


func _check_completion_flow() -> void:
	print("completion flow (module 1, guided)")
	var packed := load("res://modules/module_1/Main.tscn") as PackedScene
	var host: Control = packed.instantiate()
	host.configure(1, 0, 0.0)
	add_child(host)
	await get_tree().process_frame
	await get_tree().process_frame
	var shell: Node = host.get_node_or_null("ModuleShell")
	_expect(int(shell.get("current_page_index")) == 0, "guided still starts on page 1")

	var pages: Array = ModuleContentRegistry.get_module(1).get("pages", [])
	_events.clear()
	shell.set("current_page_index", pages.size() - 1)
	shell.call("_turn_page_now")
	await get_tree().process_frame
	_expect(
		not _events.has("guided_completed"),
		"rendering the completion page does not exit yet (saw %s)" % [_events]
	)

	shell.call("_on_exit_btn_pressed")
	await get_tree().process_frame
	_expect(
		not _events.has("guided_completed"),
		"exit is ignored for a moment after landing on completion (saw %s)" % [_events]
	)
	shell.set("_nav_ignore_until_ms", 0)
	shell.call("_on_exit_btn_pressed")
	await get_tree().process_frame
	_expect(_events.has("guided_completed"), "leaving the completion page saves progress")
	host.queue_free()
	await get_tree().process_frame


func _check_touch_scroll() -> void:
	print("touch scroll service")
	var scroll := ScrollContainer.new()
	add_child(scroll)
	await get_tree().process_frame
	var attached := false
	for child in scroll.get_children():
		if child is TouchDragScroll:
			attached = true
	_expect(attached, "helper auto-attaches to a new ScrollContainer")
	_expect(scroll.scroll_deadzone > 0, "container deadzone raised to %d" % scroll.scroll_deadzone)
	scroll.queue_free()
