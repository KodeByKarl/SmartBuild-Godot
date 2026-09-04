extends SceneTree

## Live walkthrough of Module 2 guided Station 02 (straight) + Station 03 (crossover).
## godot --headless --path . --script res://tools/demo_m2_stations_02_03.gd

var _lines: PackedStringArray = PackedStringArray()
var _problems: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _say(text: String) -> void:
	_lines.append(text)
	print(text)


func _wait(n: int = 4) -> void:
	for i in n:
		await process_frame


func _finish(code: int = 0) -> void:
	var path := "user://demo_m2_stations_02_03.txt"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_lines))
		f.close()
		print("report: %s" % ProjectSettings.globalize_path(path))
	quit(code)


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await _wait(2)

	_say("============================================================")
	_say("  SMARTBUILD — MODULE 2 GUIDED STATIONS (LIVE SIMULATION)")
	_say("  Station 02 Straight-Through  +  Station 03 Crossover")
	_say("============================================================")
	_say("")
	_say("APP HANDOFF")
	_say("  Mobile: Login → Home → Module 2 → Guided")
	_say("  Compose → Godot: prepare(moduleId=2, simulationType=0)")
	_say("  Godot loads Module 2 learning path (stations)")
	_say("")

	var packed: PackedScene = load("res://modules/module_2/Main.tscn")
	if packed == null:
		_say("FAIL: module_2 Main.tscn missing")
		_finish(1)
		return

	var main: Node = packed.instantiate()
	root.add_child(main)
	await _wait(6)
	if main.has_method("configure"):
		main.configure(2, 0, 0.0)
	await _wait(10)

	var shell: Node = main.get("shell")
	if shell == null:
		_say("FAIL: shell missing")
		_finish(1)
		return

	var pages: Array = shell.module_data.get("pages", [])
	var station_pages: Array[Dictionary] = []
	for i in pages.size():
		var p: Dictionary = pages[i] as Dictionary
		var mode := str(p.get("sim_mode", ""))
		if mode == "crimp_lab":
			station_pages.append({"index": i, "page": p})

	if station_pages.is_empty():
		_say("FAIL: no crimp_lab stations found")
		_finish(1)
		return

	_say("FOUND %d CRIMP STATIONS" % station_pages.size())
	_say("")

	for entry in station_pages:
		var idx: int = int(entry["index"])
		var page: Dictionary = entry["page"] as Dictionary
		await _walk_station(shell, idx, page)

	_say("------------------------------------------------------------")
	if _problems == 0:
		_say("STATIONS 02 + 03 COMPLETE ✓")
		_say("  Next in path: topology / addressing / wireless / validate")
		_say("  Then Capstone assessment (crossover_task) — already demoed")
	else:
		_say("FINISHED WITH %d PROBLEM(S)" % _problems)
	_say("============================================================")
	main.queue_free()
	await _wait(2)
	_finish(0 if _problems == 0 else 1)


func _walk_station(shell: Node, page_index: int, page: Dictionary) -> void:
	var title := str(page.get("title", "Crimp station"))
	var eyebrow := str(page.get("eyebrow", ""))
	var end_a := str(page.get("end_a", "t568b"))
	var end_b := str(page.get("end_b", "t568b"))
	var kind := "straight-through" if end_a == end_b else "crossover"

	_say("------------------------------------------------------------")
	_say("OPENED STATION")
	_say("  Title   : %s" % title)
	_say("  Eyebrow : %s" % eyebrow)
	_say("  Cable   : %s  (End A=%s · End B=%s)" % [
		kind, end_a.to_upper(), end_b.to_upper()
	])
	_say("")

	shell.current_page_index = page_index
	shell._render_page()
	await _wait(16)

	var mgr = shell.simulation_manager_instance
	if mgr == null or mgr.steps.is_empty():
		_say("  FAIL: simulation manager not started")
		_problems += 1
		return

	_say("RUNNING %d STEPS..." % mgr.steps.size())

	var guard := 0
	while not mgr.is_finished() and guard < 80:
		guard += 1
		var step = mgr.steps[mgr.current_step_index]
		var before: int = mgr.current_step_index
		var n: int = before + 1
		var total: int = mgr.steps.size()

		var title_txt := str(step.instruction)
		var coach := ""
		if shell.has_method("_find_step_content"):
			var info: Dictionary = shell._find_step_content(str(step.id))
			if str(info.get("title", "")) != "":
				title_txt = str(info.get("title"))
			if str(info.get("question", "")) != "":
				coach = str(info.get("question"))
			elif str(info.get("hint", "")) != "":
				coach = str(info.get("hint"))

		_say("")
		_say("STEP %d / %d  ·  CRIMPING BENCH" % [n, total])
		_say("  ID    : %s" % step.id)
		_say("  Title : %s" % title_txt)
		if coach != "":
			_say("  Coach : %s" % coach)
		_say("  Need  : action=%s target=%s" % [step.action, step.target])

		var ok: bool = _drive_crimp(shell.active_crimp_lab, str(step.target))
		if str(step.target).begins_with("order_end_"):
			var lab = shell.active_crimp_lab
			if lab != null:
				var end_id := str(step.target).trim_prefix("order_end_")
				var std: String = lab._standard_name(lab._target_for(end_id))
				var order: Array = lab._standard_order(lab._target_for(end_id))
				var pins: PackedStringArray = PackedStringArray()
				for i in order.size():
					pins.append("P%d %s" % [i + 1, lab.WIRE_LABELS[str(order[i])]])
				_say("  Wire  : End %s = %s" % [end_id.to_upper(), std])
				_say("         %s" % " · ".join(pins))
		else:
			_say("  Tool  : %s" % step.target)

		if not ok:
			_say("  Result: FAIL (unhandled)")
			_problems += 1
			return

		await _wait(4)
		if mgr.current_step_index == before and not mgr.is_finished():
			_say("  Result: STUCK")
			_problems += 1
			return

		_say("  Result: PASSED ✓")

	if not mgr.is_finished():
		_say("  FAIL: incomplete")
		_problems += 1
		return

	_say("")
	_say("STATION COMPLETE ✓  (%s certified)" % kind)
	_say("")


func _drive_crimp(lab: Node, tool_act: String) -> bool:
	if lab == null:
		return false
	if tool_act.begins_with("order_end_"):
		var end_id := tool_act.trim_prefix("order_end_")
		lab._switch_end(end_id)
		var order: Array = lab._standard_order(lab._target_for(end_id))
		for i in order.size():
			lab._select_wire(str(order[i]))
			lab._on_pin_pressed(i)
		return true
	if tool_act.ends_with("_a"):
		lab._switch_end("a")
	elif tool_act.ends_with("_b"):
		lab._switch_end("b")
	var tool := tool_act
	if tool_act.begins_with("insert_end_"):
		tool = "insert_end"
	elif tool_act.begins_with("crimp_end_"):
		tool = "crimp_end"
	lab._perform(tool)
	return true
