extends SceneTree

## Headless smoke for host progress events from the shared ModuleFlow.
## Progress/completion now come only from the simulations (no quiz):
##   - lesson pages send progress_update (capped at 99%)
##   - finishing the Guided Simulation sends guided_saved (no exit)
##   - finishing the Assessment Simulation sends assessment_saved (no exit)
##   - Proceed to Home / Back on Completion sends assessment_completed
##   - Modules 2–4 hand off to the Android labs (start_guided_lab / start_assessment_lab)
## Run: godot --headless --path . --script res://tools/progress_completion_probe.gd

const FLOW_SCENE := "res://core/components/lesson/ModuleFlow.tscn"

var _lines: PackedStringArray = PackedStringArray()
var _problems: int = 0
var _percents: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _say(text: String) -> void:
	_lines.append(text)
	print(text)


func _wait(frames: int = 4) -> void:
	for i in frames:
		await process_frame


func _expect(ok: bool, label: String) -> void:
	if ok:
		_say("ok: %s" % label)
	else:
		_problems += 1
		_say("FAIL: %s" % label)


func _finish() -> void:
	_say("\nproblems: %d" % _problems)
	var report := "user://progress_completion_probe.txt"
	var f := FileAccess.open(report, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_lines))
		f.close()
		print("report: %s" % ProjectSettings.globalize_path(report))
	quit(1 if _problems > 0 else 0)


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await _wait(2)
	await _check_module_1()
	for module_id in [2, 3, 4]:
		await _check_android_module(module_id)
	_finish()


## Capture host: ModuleFlow walks its parents for send_event().
func _make(module_id: int, sim_type: int, progress: float = 0.0) -> Array:
	var capture := Node.new()
	capture.set_script(load("res://tools/progress_event_capture.gd"))
	root.add_child(capture)
	var flow: Node = (load(FLOW_SCENE) as PackedScene).instantiate()
	flow.call("configure", module_id, sim_type, progress)
	capture.add_child(flow)
	await _wait(8)
	return [capture, flow]


func _events(capture: Node) -> PackedStringArray:
	return capture.call("get_events")


func _check_module_1() -> void:
	_say("\n##### module 1 #####")
	var made := await _make(1, 0)
	var capture: Node = made[0]
	var flow: Node = made[1]
	_expect(_events(capture).has("progress_update"), "lesson page reports progress")

	var last_lesson := 0
	for i in int(flow.call("page_count")):
		if flow.call("kind_of", i) == "lesson":
			last_lesson = i
	flow.call("show_page", last_lesson)
	await _wait(4)
	_expect(not _events(capture).has("guided_completed") and not _events(capture).has("assessment_completed"),
		"reading lessons never completes the module")

	capture.call("clear_events")
	flow.call("_on_simulation_completed", int(flow.call("index_of_last", "simulation")))
	_expect(_events(capture).has("guided_saved"), "Guided Simulation finished → guided_saved")
	_expect(not _events(capture).has("destroy"), "guided_saved keeps the learner in the module")

	capture.call("clear_events")
	flow.call("_on_simulation_completed", int(flow.call("index_of_kind", "assessment")))
	_expect(_events(capture).has("assessment_saved"), "Assessment Simulation finished → assessment_saved")

	var completion: int = flow.call("index_of_kind", "completion")
	flow.call("show_page", completion)
	await _wait(4)
	capture.call("clear_events")
	flow.call("_on_back_pressed")
	_expect(_events(capture).has("assessment_completed"), "Back on Completion → assessment_completed")
	capture.call("clear_events")
	flow.call("_on_page_action", completion, "proceed_home", null)
	_expect(_events(capture).has("assessment_completed"), "Proceed to Home → assessment_completed")
	capture.queue_free()
	await _wait(4)

	# Resuming Guided never skips past the guided simulation.
	var resumed := await _make(1, 0, 98.0)
	var rflow: Node = resumed[1]
	_expect(rflow.call("kind_of", rflow.get("current_index")) == "simulation", "resume at 98% lands on the guided simulation, not past it")
	(resumed[0] as Node).queue_free()
	await _wait(4)


func _check_android_module(module_id: int) -> void:
	_say("\n##### module %d #####" % module_id)
	var made := await _make(module_id, 0)
	var capture: Node = made[0]
	var flow: Node = made[1]
	var guided: int = flow.call("index_of_kind", "external_lab")
	flow.call("show_page", guided)
	await _wait(4)
	capture.call("clear_events")
	flow.call("_on_page_action", guided, "start_guided_lab", null)
	_expect(_events(capture).has("start_guided_lab"), "lessons hand off to the Android guided lab")
	capture.queue_free()
	await _wait(4)

	var ready := await _make(module_id, 1)
	var rflow: Node = ready[1]
	_expect(rflow.call("kind_of", rflow.get("current_index")) == "be_ready", "Assessment entry opens Be Ready")
	(ready[0] as Node).queue_free()
	await _wait(4)

	var done := await _make(module_id, 3)
	var dflow: Node = done[1]
	var dcap: Node = done[0]
	dcap.call("clear_events")
	dflow.call("_on_page_action", dflow.get("current_index"), "proceed_home", null)
	_expect(_events(dcap).has("assessment_completed"), "Completion (after Android assessment) → assessment_completed")
	dcap.queue_free()
	await _wait(4)
