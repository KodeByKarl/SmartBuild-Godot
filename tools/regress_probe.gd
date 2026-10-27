extends SceneTree

## Canonical headless CI suite for the shared ModuleFlow (Modules 1–4).
## - Every lesson page builds (and reports when it needs to scroll).
## - Module 1 Guided + Assessment simulations play to completion on the real
##   PcBuildBench, with every panel toggled mid-run (step must not move).
## Modules 2–4 simulations are Android labs — only their hand-off pages are built.
## Run: godot --headless --path . --script res://tools/regress_probe.gd

const FLOW_SCENE := "res://core/components/lesson/ModuleFlow.tscn"

var _lines: PackedStringArray = PackedStringArray()
var _problems: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _say(text: String) -> void:
	_lines.append(text)
	print(text)


func _wait(frames: int = 4) -> void:
	for i in frames:
		await process_frame


func _finish() -> void:
	_say("\nproblems: %d" % _problems)
	var report := "user://regress_probe.txt"
	var f := FileAccess.open(report, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_lines))
		f.close()
		print("report: %s" % ProjectSettings.globalize_path(report))
	quit(1 if _problems > 0 else 0)


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await _wait(2)
	for module_id in [1, 2, 3, 4]:
		await _walk(module_id)
	_finish()


func _walk(module_id: int) -> void:
	var packed := load(FLOW_SCENE) as PackedScene
	var flow: Node = packed.instantiate()
	flow.call("configure", module_id, 0, 0.0)
	root.add_child(flow)
	await _wait(8)
	var count: int = flow.call("page_count")
	_say("\n##### module %d — %d pages #####" % [module_id, count])
	for index in count:
		flow.call("show_page", index)
		var kind: String = flow.call("kind_of", index)
		await _wait(40 if kind in ["simulation", "assessment"] else 8)
		var note := "-"
		if kind in ["simulation", "assessment"]:
			note = await _drive_simulation(flow.get("current_page"))
		var fit := _fit_note(flow)
		_say("  p%-2d %-13s %s %s" % [index + 1, kind, note, fit])
	flow.queue_free()
	await _wait(4)


func _fit_note(flow: Node) -> String:
	var scroll: ScrollContainer = flow.get_node_or_null("Wrapper/Presentation/PageScroll")
	var page: Control = flow.get("current_page")
	if scroll == null or page == null:
		return ""
	var inner := page.find_child("Content", true, false) as Control
	if inner == null:
		return ""
	var over: float = inner.get_combined_minimum_size().y - scroll.size.y
	# Soft warning only — overflow scrolls inside the card, not a CI fail.
	if over > 24.0:
		return "[scrolls +%dpx]" % int(over)
	return ""


func _drive_simulation(sim: Node) -> String:
	if sim == null or not sim.has_method("set_panel_open"):
		_problems += 1
		return "NO SIMULATION PAGE"
	var mgr: Node = sim.get("manager")
	var bench: Node = sim.get("bench")
	if mgr == null or bench == null:
		_problems += 1
		return "NO MANAGER/BENCH"
	var steps: Array = mgr.get("steps")
	var guard := 0
	var toggled := false
	while not bool(mgr.call("is_finished")) and guard < 80:
		guard += 1
		_close_feedback(sim)
		var step = steps[int(mgr.get("current_step_index"))]
		var before: int = int(mgr.get("current_step_index"))
		# Mid-run: open and close every panel — the step must stay put.
		if not toggled and before >= 3:
			toggled = true
			for key in ["steps", "parts", "info"]:
				sim.call("set_panel_open", key, true)
				await _wait(12)
				sim.call("set_panel_open", key, false)
				await _wait(12)
			if int(mgr.get("current_step_index")) != before:
				_problems += 1
				return "PANEL TOGGLE MOVED STEP %d→%d" % [before, int(mgr.get("current_step_index"))]
		bench.call("set_interaction_locked", false)
		if str(step.action) == "remove":
			bench.call("_try_remove", str(step.destination))
		else:
			bench.set("selected_part_id", str(step.target))
			bench.call("_try_install", str(step.destination))
		await _wait(3)
		if int(mgr.get("current_step_index")) == before and not bool(mgr.call("is_finished")):
			_problems += 1
			return "STUCK@%s" % str(step.id)
	if not bool(mgr.call("is_finished")):
		_problems += 1
		return "INCOMPLETE"
	if not bool(sim.call("is_complete")):
		_problems += 1
		return "NOT MARKED COMPLETE"
	return "ok %d/%d%s" % [int(mgr.get("current_step_index")), steps.size(), " (panels toggled)" if toggled else ""]


func _close_feedback(sim: Node) -> void:
	var dialog := sim.get_node_or_null("RuleFeedbackDialog")
	if dialog != null and dialog.visible and dialog.has_method("dismiss"):
		# Leave the done dialog alone — it advances the flow.
		if not bool(dialog.get("_proceed_on_confirm")):
			dialog.call("dismiss")
