extends Node

## UI probe: Module 0 deck + swipe, the shared ModuleFlow for Modules 1–4
## (entry points, no quiz, flow events, Android hand-offs, full-screen
## simulation panels) and the touch-scroll attachment. Run with:
##   godot --headless --path . tools/UiChangeProbe.tscn

var _failures: int = 0
var _events: Array[String] = []


## The shell walks up its parents looking for a host with send_event().
func send_event(event: String, _module_id: int = -1, _percent: float = -1.0) -> void:
	_events.append(event)


func _ready() -> void:
	await get_tree().process_frame
	_check_module_zero()
	await _check_module_zero_swipe()
	for module_id in [1, 2, 3, 4]:
		await _check_module_flow(module_id)
	await _check_module_1_flow_events()
	await _check_external_lab_events()
	await _check_simulation_panels()
	await _check_touch_scroll()
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
	_expect(shell.get_node_or_null("Wrapper/Navigation/PreviousButton") == null, "no Prev button (swipe instead)")
	_expect(shell.get_node_or_null("Wrapper/Navigation/NextButton") == null, "no Next button (swipe instead)")
	_expect(shell.get_node_or_null("Wrapper/Navigation/PageNumberLabel") != null, "page indicator kept")
	_expect(shell.get_node_or_null("Wrapper/Presentation/PageScroll/Content") is TouchSwipePager, "slides sit in a swipe pager")
	_expect(shell is LessonDeck, "Module 0 runs on the shared LessonDeck")
	shell.queue_free()


func _check_module_zero_swipe() -> void:
	print("module 0 swipe")
	var shell: Control = (load("res://modules/module_0/Main.tscn") as PackedScene).instantiate()
	add_child(shell)
	for i in 30:
		await get_tree().process_frame
	var pager := shell.get_node("Wrapper/Presentation/PageScroll/Content") as TouchSwipePager
	var rect: Rect2 = pager.get_global_rect()
	var mid: Vector2 = rect.get_center()
	var reach: float = rect.size.x * 0.6

	await _swipe(mid, Vector2(reach, 0))
	_expect(int(shell.get("current_index")) == 0, "swipe right on slide 1 stays on slide 1")

	_events.clear()
	await _swipe(mid, Vector2(-reach, 0))
	_expect(int(shell.get("current_index")) == 1, "swipe left goes to slide 2")
	_expect(_events.has("progress_update"), "progress saved after swipe (saw %s)" % [_events])
	var total: int = int(shell.call("page_count"))
	_expect((shell.get("page_indicator") as Label).text == "2 / %d" % total, "indicator reads 2 / %d" % total)

	await _swipe(mid, Vector2(-30, 0))
	_expect(int(shell.get("current_index")) == 1, "short slow drag snaps back")

	await _swipe(mid, Vector2(6, -reach))
	_expect(int(shell.get("current_index")) == 1, "vertical drag does not change slide")

	await _swipe(mid, Vector2(reach, 0))
	_expect(int(shell.get("current_index")) == 0, "swipe right goes back to slide 1")

	# Interactive areas keep the gesture: drop a 3D viewer and a button on the slide.
	var slide := shell.get("current_page") as Control
	var viewer := SubViewportContainer.new()
	viewer.position = Vector2(0, 0)
	viewer.size = Vector2(200, 200)
	slide.add_child(viewer)
	var quiz := Button.new()
	quiz.text = "Answer A"
	quiz.position = Vector2(slide.size.x - 220, 0)
	quiz.size = Vector2(200, 120)
	slide.add_child(quiz)
	await get_tree().process_frame
	await _swipe(viewer.get_global_rect().get_center(), Vector2(-reach, 0))
	_expect(int(shell.get("current_index")) == 0, "swipe starting on a 3D viewer is ignored")
	await _swipe(quiz.get_global_rect().get_center(), Vector2(-reach, 0))
	_expect(int(shell.get("current_index")) == 0, "swipe starting on a quiz button is ignored")
	viewer.queue_free()
	quiz.queue_free()

	# Last slide: no swiping past the completion screen; its signals still reach the host.
	shell.call("show_page", int(shell.call("page_count")) - 1)
	for i in 20:
		await get_tree().process_frame
	await _swipe(mid, Vector2(-reach, 0))
	_expect(int(shell.get("current_index")) == int(shell.call("page_count")) - 1, "cannot swipe past the completion slide")
	_expect(bool(shell.get("_completion_slide_seen")), "completion slide marked seen")
	_events.clear()
	shell.call("_on_page_action", int(shell.call("page_count")) - 1, "proceed_home", null)
	_expect(_events.has("assessment_completed"), "Proceed to Home still completes Module 0")
	shell.queue_free()
	await get_tree().process_frame


## Press, drag in 8 steps, release — the same path a finger or emulated mouse takes.
func _swipe(from: Vector2, travel: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = from
	press.pressed = true
	get_viewport().push_input(press, true)
	var steps := 8
	for i in range(1, steps + 1):
		await get_tree().process_frame
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = from + travel * (float(i) / steps)
		drag.relative = travel / steps
		drag.velocity = travel / steps * 60.0 * 0.2
		get_viewport().push_input(drag, true)
	await get_tree().process_frame
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = from + travel
	release.pressed = false
	get_viewport().push_input(release, true)
	await get_tree().create_timer(0.5).timeout
	await get_tree().process_frame


func _make_flow(module_id: int, sim_type: int) -> LessonDeck:
	var flow: LessonDeck = (load("res://core/components/lesson/ModuleFlow.tscn") as PackedScene).instantiate()
	flow.call("configure", module_id, sim_type, 0.0)
	add_child(flow)
	for i in 6:
		await get_tree().process_frame
	return flow


func _check_module_flow(module_id: int) -> void:
	print("module %d flow" % module_id)
	var flow := await _make_flow(module_id, 0)
	var exit_btn: Node = flow.get_node_or_null("Wrapper/Header/ExitButton")
	_expect(exit_btn != null and exit_btn.get_index() == 0, "Back is the leftmost header item")
	_expect(flow.get_node_or_null("Wrapper/Navigation/PreviousButton") == null, "no Prev/Next buttons (swipe)")
	_expect((flow.get_node("Wrapper/Header/ModuleLabel") as Label).text.begins_with("Module %d |" % module_id), "Figma header 'Module %d | …'" % module_id)
	_expect(flow.current_index == 0, "Guided entry opens on the first lesson")
	_expect(flow.call("kind_of", 0) == "lesson", "flow starts with lesson pages")

	var kinds: Array = []
	var quiz_steps := 0
	for i in flow.page_count():
		var page: Dictionary = flow.pages[i]
		kinds.append(str(page.get("kind", "lesson")))
		if str(page.get("type", "")) == "guided_simulation" and str(page.get("sim_mode", "")) == "":
			quiz_steps += 1
	_expect(quiz_steps == 0, "no quiz pages left")
	var allowed := ["lesson", "simulation", "assessment", "be_ready", "external_lab", "completion"]
	var unknown := kinds.filter(func(k): return not (k in allowed))
	_expect(unknown.is_empty(), "only flow page kinds (%s)" % [unknown])
	var be_ready: int = kinds.find("be_ready")
	var completion: int = kinds.find("completion")
	_expect(be_ready > 0 and completion == kinds.size() - 1, "Be Ready before the end, Completion last")
	_expect(kinds.slice(0, kinds.find("lesson", 0) + 1).size() > 0 and kinds.rfind("lesson") < be_ready, "all lessons come before Be Ready")
	if module_id == 1:
		_expect(kinds.count("simulation") == 2 and kinds.count("assessment") == 1, "Module 1: 2 guided sims + 1 assessment")
		_expect(kinds.find("simulation") > kinds.rfind("lesson"), "guided simulation follows the lessons")
	else:
		_expect(kinds.count("external_lab") == 2, "Module %d: guided + assessment hand-offs to Android labs" % module_id)
	flow.queue_free()
	await get_tree().process_frame

	var assess := await _make_flow(module_id, 1)
	_expect(assess.call("kind_of", assess.current_index) == "be_ready", "Assessment entry opens on Be Ready")
	assess.queue_free()
	await get_tree().process_frame
	if module_id >= 2:
		var done := await _make_flow(module_id, 3)
		_expect(done.call("kind_of", done.current_index) == "completion", "entry 3 opens the Completion page")
		done.queue_free()
		await get_tree().process_frame


func _check_module_1_flow_events() -> void:
	print("module 1 flow events")
	var flow := await _make_flow(1, 0)
	var last_guided: int = flow.call("index_of_last", "simulation")
	var assessment: int = flow.call("index_of_kind", "assessment")
	var completion: int = flow.call("index_of_kind", "completion")
	_events.clear()
	flow.call("_on_simulation_completed", last_guided - 1)
	_expect(not _events.has("guided_saved"), "first guided sim alone does not complete Guided")
	flow.call("_on_simulation_completed", last_guided)
	_expect(_events.has("guided_saved"), "finishing the guided simulation saves Guided (saw %s)" % [_events])
	_expect(not _events.has("guided_completed") and not _events.has("destroy"), "Guided save does not leave the module")
	_events.clear()
	flow.call("_on_simulation_completed", assessment)
	_expect(_events.has("assessment_saved"), "finishing the assessment saves it (saw %s)" % [_events])
	flow.show_page(completion)
	await get_tree().process_frame
	_events.clear()
	flow.call("_on_page_action", completion, "proceed_home", null)
	_expect(_events.has("assessment_completed"), "Proceed to Home completes the module")
	_events.clear()
	flow.call("_on_page_action", completion, "retake", null)
	await get_tree().process_frame
	_expect(_events.has("progress_reset") and flow.current_index == 0, "Retake resets progress and restarts")
	flow.queue_free()
	await get_tree().process_frame


func _check_external_lab_events() -> void:
	print("modules 2–4 android hand-offs")
	for module_id in [2, 3, 4]:
		var flow := await _make_flow(module_id, 0)
		var guided: int = flow.call("index_of_kind", "external_lab")
		var be_ready: int = flow.call("index_of_kind", "be_ready")
		_events.clear()
		flow.call("_on_page_action", guided, "start_guided_lab", null)
		flow.call("_on_page_action", be_ready + 1, "start_assessment_lab", null)
		_expect(Array(_events) == ["start_guided_lab", "start_assessment_lab"], "module %d emits lab hand-offs (saw %s)" % [module_id, _events])
		flow.queue_free()
		await get_tree().process_frame


func _check_simulation_panels() -> void:
	print("full-screen simulation panels")
	var flow := await _make_flow(1, 0)
	var sim_index: int = flow.call("index_of_kind", "simulation") + 1
	flow.show_page(sim_index)
	for i in 30:
		await get_tree().process_frame
	var sim: Node = flow.current_page
	_expect(sim != null and sim.has_method("set_panel_open"), "guided simulation page is shown")
	_expect(not (flow.get_node("Wrapper/Header") as Control).visible, "simulation is full screen (header hidden)")
	var all_closed := true
	for key in ["steps", "parts", "info"]:
		all_closed = all_closed and not bool(sim.call("is_panel_open", key))
	_expect(all_closed, "all panels hidden by default")
	var manager: Node = sim.get("manager")
	var before: int = int(manager.get("current_step_index"))
	for key in ["steps", "parts", "info", "steps"]:
		sim.call("set_panel_open", key, true)
		for i in 15:
			await get_tree().process_frame
		sim.call("set_panel_open", key, false)
		for i in 15:
			await get_tree().process_frame
	_expect(int(manager.get("current_step_index")) == before, "toggling panels keeps the current step (%d)" % before)
	sim.call("set_panel_open", "parts", true)
	sim.call("set_panel_open", "info", true)
	_expect(not bool(sim.call("is_panel_open", "parts")), "Parts and Info share the right edge (one at a time)")
	_expect(not flow.content.has_next and not flow.content.has_prev, "no swiping out of an unfinished simulation")
	flow.queue_free()
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
