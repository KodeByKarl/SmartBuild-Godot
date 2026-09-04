extends SceneTree

## Live try of Module 1 two-panel PC Build Bench (photos + drag/drop).
## godot --path . --script res://tools/demo_m1_pc_build.gd

var _lines: PackedStringArray = PackedStringArray()
var _problems: int = 0
var _shot_dir := "d:/Projects/SmartBuild/SmartBuild-Godot/.demo_shots"


func _initialize() -> void:
	_run.call_deferred()


func _say(text: String) -> void:
	_lines.append(text)
	print(text)


func _fail(text: String) -> void:
	_problems += 1
	_say("FAIL: %s" % text)


func _ok(text: String) -> void:
	_say("OK   : %s" % text)


func _wait(n: int = 6) -> void:
	for i in n:
		await process_frame


func _finish(code: int = 0) -> void:
	var path := "user://demo_m1_pc_build.txt"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_lines))
		f.close()
		print("report: %s" % ProjectSettings.globalize_path(path))
	quit(code)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		_fail("screenshot %s — no viewport image" % name)
		return
	DirAccess.make_dir_recursive_absolute(_shot_dir)
	var path := "%s/%s.png" % [_shot_dir, name]
	var err := img.save_png(path)
	if err != OK:
		_fail("screenshot %s save error %s" % [name, err])
	else:
		_say("SHOT : %s" % path)


func _run() -> void:
	DisplayServer.window_set_title("SmartBuild — Module 1 PC Build try")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await _wait(3)

	_say("============================================================")
	_say("  SMARTBUILD — MODULE 1 PC BUILD BENCH (LIVE TRY)")
	_say("  Two-panel layout · photo tray · drag onto case")
	_say("============================================================")
	_say("")

	var packed: PackedScene = load("res://modules/module_1/Main.tscn")
	if packed == null:
		_fail("module_1 Main.tscn missing")
		_finish(1)
		return

	var main: Node = packed.instantiate()
	root.add_child(main)
	await _wait(8)
	if main.has_method("configure"):
		main.configure(1, 0, 0.0)
	await _wait(12)

	var shell: Node = main.get("shell")
	if shell == null:
		_fail("shell missing")
		_finish(1)
		return

	var pages: Array = shell.module_data.get("pages", [])
	var build_index := -1
	for i in pages.size():
		var p: Dictionary = pages[i] as Dictionary
		if str(p.get("sim_mode", "")) == "pc_build" and str(p.get("type", "")) == "guided_simulation":
			build_index = i
			break
	if build_index < 0:
		_fail("pc_build guided page not found")
		_finish(1)
		return

	shell.current_page_index = build_index
	shell._render_page()
	await _wait(20)

	var bench: Node = shell.active_build_bench
	if bench == null:
		_fail("active_build_bench missing after render")
		_finish(1)
		return

	_inspect_layout(bench)
	await _shot("01_open_two_panel")

	var first_ok := await _drag_install(bench, "psu", "psu_bay")
	await _wait(8)
	await _shot("02_after_psu_drop")
	if first_ok:
		_ok("PSU dropped onto psu_bay")
	else:
		_fail("PSU drag/drop did not seat")

	var second_ok := await _drag_install(bench, "motherboard", "board_mount")
	await _wait(8)
	await _shot("03_after_motherboard_drop")
	if second_ok:
		_ok("Motherboard dropped onto board_mount")
	else:
		_fail("Motherboard drag/drop did not seat")

	# Wrong bay: CPU onto PSU bay (already filled) should not crash.
	var before_cpu: bool = bench.installed_parts.has("cpu")
	await _drag_install(bench, "cpu", "psu_bay")
	await _wait(4)
	if bench.installed_parts.has("cpu") and not before_cpu:
		_fail("CPU seated on the PSU bay — should have been rejected")
	else:
		_ok("Wrong-bay drop was rejected (CPU still in tray)")
	await _shot("04_wrong_bay_rejected")

	var cpu_ok := await _drag_install(bench, "cpu", "cpu_socket")
	await _wait(8)
	await _shot("05_after_cpu_drop")
	if cpu_ok:
		_ok("CPU dropped onto cpu_socket")
	else:
		_fail("CPU drag/drop did not seat")

	_say("")
	_say("SEATED NOW: %s" % str(bench.installed_parts.keys()))
	if _problems == 0:
		_say("RESULT: two-panel bench + photo tray + drag/drop works")
		_finish(0)
	else:
		_say("RESULT: %d problem(s) — see FAIL lines" % _problems)
		_finish(1)


func _inspect_layout(bench: Node) -> void:
	var root_box := bench.get_node_or_null("Root") as HBoxContainer
	var viewport_card := bench.get_node_or_null("Root/ViewportCard")
	var tray_card := bench.get_node_or_null("Root/TrayCard")
	var tray_list := bench.get_node_or_null("Root/TrayCard/TrayMargin/TrayVBox/TrayScroll/TrayList")
	if root_box == null or viewport_card == null or tray_card == null:
		_fail("two-panel nodes missing (Root/ViewportCard/TrayCard)")
	else:
		_ok("HBox two-panel: left ViewportCard + right TrayCard")
		_say("       viewport %.0fx%.0f  tray %.0fx%.0f" % [
			viewport_card.size.x, viewport_card.size.y,
			tray_card.size.x, tray_card.size.y
		])
	if tray_list == null:
		_fail("TrayList missing — parts tray not vertical")
	else:
		_ok("Vertical TrayList with %d cards" % tray_list.get_child_count())
	if bench.get_node_or_null("Root/Split") != null:
		_fail("old stacked Split layout still present")
	if bench.get_node_or_null("Root/SlotButtons") != null:
		_fail("old SlotButtons text row still present")
	else:
		_ok("old text slot-chip row is gone")

	var photo_count := 0
	var buttons: Variant = bench.get("_part_buttons")
	if typeof(buttons) == TYPE_DICTIONARY:
		for part_id in (buttons as Dictionary).keys():
			var card: Node = (buttons as Dictionary)[part_id]
			if card == null or not card.has_meta("thumb"):
				continue
			var thumb: TextureRect = card.get_meta("thumb")
			if thumb == null or thumb.texture == null:
				_fail("part %s has no image" % part_id)
				continue
			var path := str(thumb.texture.resource_path)
			if path.begins_with("res://assets/ui/parts/part_"):
				photo_count += 1
			else:
				_say("WARN : %s texture is %s (%s)" % [part_id, thumb.texture.get_class(), path])
	_say("       photo cards using real part PNGs: %d" % photo_count)
	if photo_count < 8:
		_fail("expected real part photos on the tray cards")
	else:
		_ok("tray uses real component photos")


func _drag_install(bench: Node, part_id: String, slot_id: String) -> bool:
	if bench.installed_parts.has(part_id):
		return true
	var drop_at := _slot_global_point(bench, slot_id)
	if drop_at == Vector2.ZERO:
		_say("WARN : no screen point for %s — using install API" % slot_id)
		bench.selected_part_id = part_id
		bench._try_install(slot_id)
		await _wait(4)
		return bench.installed_parts.has(part_id)

	var grab_at := _card_global_point(bench, part_id)
	_say("DRAG : %s  grab(%.0f,%.0f) → drop(%.0f,%.0f) on %s" % [
		part_id, grab_at.x, grab_at.y, drop_at.x, drop_at.y, slot_id
	])
	bench._begin_part_press(part_id, grab_at)
	await _wait(2)
	bench._start_part_drag(part_id)
	await _wait(2)
	bench._move_drag_ghost(drop_at)
	await _wait(2)
	var resolved: String = bench._slot_under_pointer(drop_at)
	_say("DROP : pointer resolved to '%s' (want %s)" % [resolved, slot_id])
	bench._finish_part_drag(drop_at)
	await _wait(6)
	return bench.installed_parts.has(part_id)


func _card_global_point(bench: Node, part_id: String) -> Vector2:
	var buttons: Variant = bench.get("_part_buttons")
	if typeof(buttons) != TYPE_DICTIONARY:
		return Vector2.ZERO
	var card: Control = (buttons as Dictionary).get(part_id, null)
	if card == null:
		return Vector2.ZERO
	return card.global_position + (card.size * 0.5)


func _slot_global_point(bench: Node, slot_id: String) -> Vector2:
	if not bench.slots.has(slot_id):
		return Vector2.ZERO
	var slot: Node3D = bench.slots[slot_id]
	var camera: Camera3D = bench.get("_camera")
	var container: Control = bench.get("_viewport_container")
	var sub: SubViewport = bench.get("_subviewport")
	if camera == null or container == null or sub == null:
		return Vector2.ZERO
	var vp_pos: Vector2 = camera.unproject_position(slot.global_position)
	var vp_size := Vector2(sub.size)
	if vp_size.x <= 1.0 or vp_size.y <= 1.0 or container.size.x <= 1.0:
		return container.get_global_rect().get_center()
	return container.global_position + (vp_pos * (container.size / vp_size))
