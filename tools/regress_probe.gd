extends SceneTree

## Canonical headless CI suite for Modules 1–4.
## Drives every simulation page to completion and fails on stuck/unhandled steps.
## Run: godot --headless --path . --script res://tools/regress_probe.gd

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
	var packed: PackedScene = load("res://modules/module_%d/Main.tscn" % module_id)
	if packed == null:
		_problems += 1
		_say("FAIL: missing module_%d Main.tscn" % module_id)
		return
	var main: Node = packed.instantiate()
	root.add_child(main)
	await _wait(6)
	if main.has_method("configure"):
		main.configure(module_id, 0, 0.0)
	await _wait(10)

	var shell: Node = main.get("shell")
	if shell == null:
		_problems += 1
		_say("FAIL: module %d has no shell" % module_id)
		main.queue_free()
		return

	var pages: Array = shell.module_data.get("pages", [])
	_say("\n##### module %d — %d pages #####" % [module_id, pages.size()])

	for index in pages.size():
		var page: Dictionary = pages[index] as Dictionary
		shell.current_page_index = index
		shell._render_page()
		await _wait(12)
		var kind := str(page.get("type", "?"))
		var mode := str(page.get("sim_mode", ""))
		var note := await _drive(shell, mode, page)
		var fit := _fit_note(shell)
		_say("  p%-2d %-20s %-18s %s %s" % [index, kind, mode, note, fit])

	main.queue_free()
	await _wait(4)


func _fit_note(shell: Node) -> String:
	var scroll: ScrollContainer = shell.get_node_or_null("Wrapper/Presentation/PageScroll")
	var page_root: Control = shell.current_page_root
	if scroll == null or page_root == null:
		return ""
	var over: float = page_root.get_combined_minimum_size().y - scroll.size.y
	# Soft warning only — layout scroll is informational, not a CI fail.
	if over > 24.0:
		return "[scrolls +%dpx]" % int(over)
	return ""


func _drive(shell: Node, mode: String, page: Dictionary) -> String:
	var mgr = shell.simulation_manager_instance
	if mgr == null or mgr.steps.is_empty():
		return "-"
	var lab: Node = _lab_for(shell, mode)
	var guard := 0
	while not mgr.is_finished() and guard < 80:
		guard += 1
		var step = mgr.steps[mgr.current_step_index]
		var before: int = mgr.current_step_index
		var ok: bool = await _perform(shell, lab, mode, step, page)
		if not ok:
			_problems += 1
			return "UNHANDLED(%s)" % step.action
		await _wait(3)
		if mgr.current_step_index == before and not mgr.is_finished():
			_problems += 1
			return "STUCK@%s" % step.id
	if not mgr.is_finished():
		_problems += 1
		return "INCOMPLETE"
	return "ok %d/%d" % [mgr.current_step_index, mgr.steps.size()]


func _lab_for(shell: Node, mode: String) -> Node:
	match mode:
		"pc_build":
			return shell.active_build_bench
		"network_lab":
			return shell.active_network_lab
		"server_lab":
			return shell.active_server_lab
		"maintenance_bench":
			return shell.active_maintenance_bench
		"crimp_lab":
			return shell.active_crimp_lab
		"crossover_task":
			return null
		_:
			return null


func _perform(shell: Node, lab: Node, mode: String, step, page: Dictionary) -> bool:
	var act := str(step.action)
	var target := str(step.target)
	var dest := str(step.destination)
	match mode:
		"pc_build":
			return _drive_pc_build(lab, act, target, dest)
		"network_lab":
			return _drive_network(lab, act, target, dest, page)
		"server_lab":
			return _drive_server(lab, act, target, dest)
		"maintenance_bench":
			return _drive_maintenance(lab, str(step.id), target)
		"crimp_lab":
			return _drive_crimp(lab, act, target)
		"crossover_task":
			return _drive_crossover(shell, act, target, dest)
		_:
			return _press_quiz_choice(shell, step)


func _drive_pc_build(lab: Node, act: String, target: String, dest: String) -> bool:
	if lab == null:
		return false
	if act == "remove":
		lab._try_remove(dest)
	else:
		lab.selected_part_id = target
		lab._try_install(dest)
	return true


func _drive_network(lab: Node, act: String, target: String, dest: String, page: Dictionary) -> bool:
	if lab == null:
		return false
	var topology := typeof(page.get("topology", {})) == TYPE_DICTIONARY and not (page.get("topology", {}) as Dictionary).is_empty()
	match act:
		"add_device":
			lab._on_palette_add(target)
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


func _drive_server(lab: Node, act: String, target: String, dest: String) -> bool:
	if lab == null:
		return false
	var buttons: Dictionary = lab.get("_action_buttons")
	match act:
		"identify":
			return _press_key(buttons, "role:%s" % target)
		"mkdir":
			return _press_key(buttons, "folder:%s" % target)
		"create_group":
			return _press_key(buttons, "group:%s" % target)
		"create_user":
			return _press_key(buttons, "user:%s" % target)
		"add_to_group":
			return _press_key(buttons, "nest:%s" % target)
		"set_ntfs":
			return _press_key(buttons, "ntfs:%s" % target)
		"share":
			return _press_key(buttons, "share:%s" % target)
		"access_test":
			if lab._client_user == null or lab._client_share == null:
				return false
			# Anna for Accounting allow/deny tests in the curriculum.
			lab._client_user.select(0)
			for i in lab._client_share.item_count:
				if str(lab._client_share.get_item_metadata(i)) == target:
					lab._client_share.select(i)
					break
			return _press_key(buttons, "access_test")
		_:
			return false


func _drive_maintenance(lab: Node, step_id: String, target: String) -> bool:
	if lab == null:
		return false
	if step_id == "pick_root" and lab._root_option != null:
		for i in lab._root_option.item_count:
			if str(lab._root_option.get_item_metadata(i)) == "dust_thermal":
				lab._root_option.select(i)
				break
	var buttons: Dictionary = lab.get("_action_buttons")
	if buttons != null:
		for key in [step_id, target]:
			if buttons.has(key):
				(buttons[key] as Button).pressed.emit()
				return true
	return false


func _drive_crimp(lab: Node, act: String, tool_act: String) -> bool:
	if lab == null or act != "crimp":
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


func _drive_crossover(shell: Node, act: String, target: String, dest: String) -> bool:
	if act == "crimp":
		return _drive_crimp(shell.active_crimp_lab, act, target)
	return _drive_network(shell.active_network_lab, act, target, dest, {})


func _press_key(buttons: Dictionary, key: String) -> bool:
	if buttons == null or not buttons.has(key):
		return false
	(buttons[key] as Button).pressed.emit()
	return true


func _press_quiz_choice(shell: Node, step) -> bool:
	var mgr = shell.simulation_manager_instance
	if mgr == null:
		return false
	# Inject the correct step action — quiz UI shuffle is not needed for CI.
	mgr.receive_action(SimulationAction.new(
		str(step.action),
		str(step.target),
		str(step.destination)
	))
	return true
