extends SceneTree

## Live walkthrough of Module 2 Capstone crossover flow (client demo log).
## godot --headless --path . --script res://tools/demo_m2_crossover_flow.gd

var _lines: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _say(text: String) -> void:
	_lines.append(text)
	print(text)


func _wait(n: int = 4) -> void:
	for i in n:
		await process_frame


func _finish(code: int = 0) -> void:
	var path := "user://demo_m2_crossover_flow.txt"
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
	_say("  SMARTBUILD — MODULE 2 CAPSTONE FLOW (LIVE SIMULATION)")
	_say("  Create a Crossover Connector")
	_say("============================================================")
	_say("")
	_say("APP HANDOFF")
	_say("  1) Mobile: Login / Sign Up (Compose)")
	_say("  2) Mobile: Home → Module 2 → Assessment")
	_say("  3) Compose → Godot: prepare(moduleId=2, simulationType=1)")
	_say("  4) Godot loads Module 2 Capstone (Crimping Bench + Site)")
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
		main.configure(2, 1, 0.0)
	await _wait(10)

	var shell: Node = main.get("shell")
	if shell == null:
		_say("FAIL: shell missing")
		_finish(1)
		return

	var pages: Array = shell.module_data.get("pages", [])
	var capstone_index := -1
	for i in pages.size():
		var p: Dictionary = pages[i] as Dictionary
		if str(p.get("sim_mode", "")) == "crossover_task":
			capstone_index = i
			break
	if capstone_index < 0:
		_say("FAIL: crossover_task page not found")
		_finish(1)
		return

	shell.current_page_index = capstone_index
	shell._render_page()
	await _wait(16)

	var page: Dictionary = pages[capstone_index] as Dictionary
	_say("OPENED PAGE")
	_say("  Title   : %s" % str(page.get("title", "")))
	_say("  Eyebrow : %s" % str(page.get("eyebrow", "")))
	_say("  Mode    : crossover_task (Crimping Bench ↔ Workstation Site)")
	_say("")

	var mgr = shell.simulation_manager_instance
	if mgr == null or mgr.steps.is_empty():
		_say("FAIL: simulation manager not started")
		_finish(1)
		return

	_say("RUNNING %d STEPS..." % mgr.steps.size())
	_say("------------------------------------------------------------")

	var content_steps: Array = page.get("steps", [])
	var guard := 0
	while not mgr.is_finished() and guard < 80:
		guard += 1
		var step = mgr.steps[mgr.current_step_index]
		var before: int = mgr.current_step_index
		var n: int = before + 1
		var total: int = mgr.steps.size()
		var phase: String = "CRIMPING BENCH" if str(step.action) == "crimp" else "WORKSTATION SITE"

		var coach := ""
		if before < content_steps.size():
			var raw = content_steps[before]
			if typeof(raw) == TYPE_DICTIONARY:
				coach = str((raw as Dictionary).get("question", (raw as Dictionary).get("hint", "")))
			elif raw != null:
				# registry steps may be Dictionaries already from page build
				pass

		# Prefer shell step content lookup
		if shell.has_method("_find_step_content"):
			var info: Dictionary = shell._find_step_content(str(step.id))
			if not info.is_empty():
				if coach == "":
					coach = str(info.get("question", info.get("hint", "")))
				if str(info.get("title", "")) != "":
					pass

		var title := str(step.instruction)
		if shell.has_method("_find_step_content"):
			var info2: Dictionary = shell._find_step_content(str(step.id))
			if str(info2.get("title", "")) != "":
				title = str(info2.get("title"))
			if str(info2.get("question", "")) != "":
				coach = str(info2.get("question"))
			elif str(info2.get("hint", "")) != "":
				coach = str(info2.get("hint"))

		_say("")
		_say("STEP %d / %d  ·  %s" % [n, total, phase])
		_say("  ID    : %s" % step.id)
		_say("  Title : %s" % title)
		if coach != "":
			_say("  Coach : %s" % coach)
		_say("  Need  : action=%s target=%s dest=%s" % [step.action, step.target, step.destination])

		var ok: bool = _perform(shell, step, page)
		if str(step.action) == "crimp" and str(step.target).begins_with("order_end_"):
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
		elif str(step.action) == "crimp":
			_say("  Tool  : %s" % step.target)
		elif str(step.action) == "connect":
			_say("  Link  : %s ↔ %s (crossover cable)" % [step.target, step.destination])
		elif str(step.action) == "configure":
			_say("  IP    : apply addressing on %s" % step.target)
		elif str(step.action) == "ping":
			_say("  Ping  : %s → %s" % [step.target, step.destination])

		if not ok:
			_say("  Result: FAIL (unhandled)")
			_finish(1)
			return

		await _wait(4)
		if mgr.current_step_index == before and not mgr.is_finished():
			_say("  Result: STUCK (step did not advance)")
			_finish(1)
			return

		_say("  Result: PASSED ✓")

	if not mgr.is_finished():
		_say("FAIL: incomplete after loop")
		_finish(1)
		return

	_say("")
	_say("------------------------------------------------------------")
	_say("CAPSTONE COMPLETE ✓")
	_say("  Godot event → assessment_completed")
	_say("  Mobile     → marks Module 2 complete → returns to Home")
	_say("============================================================")
	main.queue_free()
	await _wait(2)
	_finish(0)


func _perform(shell: Node, step, page: Dictionary) -> bool:
	var act := str(step.action)
	var target := str(step.target)
	var dest := str(step.destination)
	if act == "crimp":
		return _drive_crimp(shell.active_crimp_lab, target)
	return _drive_network(shell.active_network_lab, act, target, dest, page)


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


func _drive_network(lab: Node, act: String, target: String, dest: String, page: Dictionary) -> bool:
	if lab == null:
		return false
	var topology := typeof(page.get("topology", {})) == TYPE_DICTIONARY and not (page.get("topology", {}) as Dictionary).is_empty()
	match act:
		"connect":
			lab._create_link(target, dest, lab._required_cable(target, dest))
		"configure":
			lab._selected_id = target
			if topology:
				if target == "server":
					lab._config_ip.text = "192.168.10.10"
					lab._config_mask.text = "255.255.255.0"
					lab._config_gw.text = ""
					lab._config_dns.text = "8.8.8.8"
				else:
					lab._config_ip.text = "192.168.10.20" if target == "pc1" else "192.168.10.21"
					lab._config_mask.text = "255.255.255.0"
					lab._config_gw.text = "192.168.10.10"
					lab._config_dns.text = "8.8.8.8"
			else:
				lab._config_ip.text = "192.168.1.10" if target == "pc1" else "192.168.1.11"
				lab._config_mask.text = "255.255.255.0"
				lab._config_gw.text = "192.168.1.1"
				lab._config_dns.text = "8.8.8.8"
			lab._apply_ip()
		"ping":
			lab._selected_id = target
			lab._ping_target.text = dest
			lab._run_ping()
		_:
			return false
	return true
