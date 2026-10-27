class_name SimulationPage
extends Control

## Full-screen PC-build simulation (Guided or Assessment) for the module flow.
##
## The 3D bench fills the screen. Every panel — step instructions, parts tray,
## page info — starts hidden and slides in over the 3D view from a small
## floating toggle. Panels only move; opening or closing one never rebuilds the
## bench or touches the SimulationManager, so the current step is kept.
##
## Simulation rules (steps, grading, feedback dialog, seeding) were ported from
## the old ModuleShell pc_build path unchanged.

## All steps done (bench locked). The flow may now allow moving on.
signal completed(stats: Dictionary)
## Learner pressed Continue on the "done" dialog.
signal finished
signal back_requested
signal help_requested

const PC_BUILD_BENCH_PATH := "res://core/simulation/PcBuildBench.tscn"
const PANEL_TOP := 64.0
const PANEL_MARGIN := 12.0
const SLIDE_TIME := 0.22

var page: Dictionary = {}
var is_assessment := false

var bench: Control = null
var manager: SimulationManager = null

var _steps: Array = []
var _seed: Array = []
var _completed_ids: Dictionary = {}
var _pending_tip := ""
var _current_step_id := ""
var _done := false

var _overlay: Control = null
var _panels: Dictionary = {}
var _toggles: Dictionary = {}
var _instruction: RichTextLabel = null
var _feedback: Label = null
var _progress_label: Label = null


static func create(page_data: Dictionary, assessment: bool) -> SimulationPage:
	var node := SimulationPage.new()
	node.page = page_data
	node.is_assessment = assessment
	node.name = "SimulationPage"
	return node


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_steps = page.get("steps", [])
	_seed = page.get("seed_state", [])

	var bg := ColorRect.new()
	bg.color = LessonTheme.NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var holder := MarginContainer.new()
	holder.name = "BenchHolder"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Swipes never start on the 3D stage — it orbits and takes drops.
	holder.set_meta("no_swipe", true)
	add_child(holder)

	bench = _make_bench()
	if bench == null:
		var missing := Label.new()
		missing.text = "Loading workstation…"
		missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		missing.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		holder.add_child(missing)
		return
	holder.add_child(bench)
	var floating: Dictionary = bench.take_overlay_panels() if bench.has_method("take_overlay_panels") else {}
	_build_overlay(floating)

	if bench.has_signal("action_submitted"):
		bench.action_submitted.connect(_on_bench_action)
	if bench.has_signal("coach_message"):
		bench.coach_message.connect(_on_bench_coach_message)

	manager = SimulationManager.new()
	manager.name = "SimulationManager"
	add_child(manager)
	manager.step_changed.connect(_on_step_changed)
	manager.step_completed.connect(_on_step_completed)
	manager.action_incorrect.connect(_on_action_incorrect)
	manager.simulation_completed.connect(_on_simulation_completed)

	var parts: Array = page.get("build_parts", [])
	if parts.is_empty():
		parts = ModuleContentRegistry.module_1_build_parts()
	bench.call_deferred("setup", parts, not is_assessment, _seed)
	if _seed.is_empty():
		call_deferred("_start")
	else:
		call_deferred("_finalize_seeded")


func is_complete() -> bool:
	return _done


## Help overlay content for the current step (used by the module flow).
func help_info() -> Dictionary:
	var lines: PackedStringArray = []
	lines.append(str(page.get("description", "")))
	if _current_step_id != "":
		var step := _find_step(_current_step_id)
		lines.append("\n[b]Current step[/b]\n%s" % str(step.get("instruction", step.get("question", ""))))
		var tip := str(step.get("tip", ""))
		if tip != "" and not is_assessment:
			lines.append("\n[color=#fd8]Tip:[/color] %s" % tip)
	for pitfall in page.get("pitfalls", []):
		lines.append("[color=#f96]Watch out:[/color] %s" % str(pitfall))
	lines.append("\nUse [b]Steps[/b], [b]Parts[/b] and [b]Info[/b] at the top right to show or hide each panel.")
	return {"title": str(page.get("title", "Simulation")), "body": "\n".join(lines)}


# --- Bench ------------------------------------------------------------------------

func _make_bench() -> Control:
	var packed: PackedScene = null
	# Looked up at runtime so tools/probes can compile this class before autoloads exist.
	var warmup := get_node_or_null("/root/ResourceWarmup")
	if warmup != null and warmup.has_method("get_packed"):
		packed = warmup.get_packed(PC_BUILD_BENCH_PATH)
	if packed == null:
		packed = load(PC_BUILD_BENCH_PATH) as PackedScene
	if packed == null:
		return null
	var node := packed.instantiate() as Control
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


func _start() -> void:
	var steps: Array[SimulationStep] = []
	for step_variant in _steps:
		var step_data: Dictionary = step_variant as Dictionary
		var step_id: String = str(step_data.get("id", ""))
		steps.append(SimulationStep.new(
			step_id,
			str(step_data.get("instruction", "")),
			str(step_data.get("action", "tap")),
			str(step_data.get("target", step_id)),
			str(step_data.get("destination", "")),
			step_data.get("value", null)
		))
	var mode := SimulationMode.Type.ASSESSMENT if is_assessment else SimulationMode.Type.GUIDED
	manager.start(steps, mode)


func _finalize_seeded() -> void:
	# Let deferred bench.setup / _apply_setup finish first (same idle frame queue).
	await get_tree().process_frame
	if not is_instance_valid(self) or bench == null or not is_instance_valid(bench):
		return
	if bench.get("_has_pending_setup") == true:
		call_deferred("_finalize_seeded")
		return
	# Seed only if setup did not already place the machine (avoid wiping bookkeeping).
	var real_count := 0
	var installed: Dictionary = bench.get("installed_parts")
	for pid in installed.keys():
		if str(pid) != "side_panel":
			real_count += 1
	if real_count == 0 and bench.has_method("apply_seed_state"):
		bench.apply_seed_state(_seed)
	if bench.has_method("ensure_open_chassis_bookkeeping"):
		bench.ensure_open_chassis_bookkeeping()
	_start()


func _reset_assessment() -> void:
	if not is_assessment or manager == null:
		return
	_completed_ids.clear()
	_pending_tip = ""
	_done = false
	if bench != null and bench.has_method("reset_scenario"):
		bench.reset_scenario()
		if bench.has_method("set_interaction_locked"):
			bench.set_interaction_locked(false)
	_start()
	_update_progress()
	_set_feedback("Assessment reset — start again from step 1.", _info_color())


func _on_bench_action(action: SimulationAction) -> void:
	if manager != null:
		manager.receive_action(action)


# --- Simulation events ----------------------------------------------------------------

func _on_step_changed(step) -> void:
	var step_id: String = str(step.id)
	_current_step_id = step_id
	var content: Dictionary = _find_step(step_id)
	var question: String = str(content.get("question", step.instruction))
	var heading := "Install"
	if str(step.action) == "remove":
		heading = "Remove"
	elif is_assessment:
		heading = "Fix"
	if _instruction != null:
		_instruction.text = "[b]%s:[/b] %s" % [heading, question]

	if _pending_tip != "":
		_set_feedback("Correct — %s" % _pending_tip, _ok_color())
		_pending_tip = ""
	else:
		var part_name := _part_title(str(step.target))
		var slot_name := _slot_title(str(step.destination))
		var text := ""
		if str(step.action) == "remove":
			text = (
				"Tap the glowing %s to remove it — do not drop from the tray." % part_name
				if not is_assessment
				else "Tap the %s in the case to remove it — do not drop from the tray." % part_name
			)
		elif not is_assessment:
			text = "Drop %s onto the %s (yellow)." % [part_name, slot_name]
		else:
			text = "Drop %s onto the %s." % [part_name, slot_name]
		_set_feedback(text, _info_color())

	if bench != null:
		if bench.has_method("set_step_hint"):
			bench.set_step_hint(str(step.target), str(step.destination), str(step.action))
		if bench.has_method("highlight_part"):
			bench.highlight_part(str(step.target))
	_update_progress()


func _on_step_completed(step) -> void:
	var step_id: String = str(step.id)
	_completed_ids[step_id] = true
	var content: Dictionary = _find_step(step_id)
	_pending_tip = str(content.get("tip", content.get("instruction", "Correct.")))
	if bench != null and str(step.action) != "remove" and bench.has_method("mark_installed"):
		bench.mark_installed(str(step.target), str(step.destination))
	_show_feedback(
		true,
		str(content.get("label", content.get("instruction", "Step complete"))),
		_pending_tip if _pending_tip != "" else "Keep going with the next action."
	)
	_update_progress()


func _on_action_incorrect(action) -> void:
	_pending_tip = ""
	var detail := "Wrong part or slot — check the yellow bay and try again."
	if action != null:
		var part_name := _part_title(str(action.target))
		var slot_name := _slot_title(str(action.destination))
		if part_name != "" and slot_name != "":
			if str(action.action) == "remove":
				detail = (
					"You removed: %s → %s — tap only the glowing part for this step." % [part_name, slot_name]
					if not is_assessment
					else "You removed: %s → %s — tap only the part this step asks for." % [part_name, slot_name]
				)
			else:
				detail = "You placed: %s → %s — see the case tip for Expected / Why." % [part_name, slot_name]
	_set_feedback(detail, _bad_color())
	_show_feedback(false, "Wrong part or bay" if action != null else "Not the expected action", detail)
	if bench != null and bench.has_method("flash_incorrect"):
		var placed_part := ""
		var placed_slot := ""
		if action != null:
			placed_part = str(action.target)
			placed_slot = str(action.destination)
			# Safety net: if a wrong removal somehow left the bay, put it back.
			if str(action.action) == "remove" and bench.has_method("restore_removed_part"):
				bench.restore_removed_part(placed_part, placed_slot)
		bench.flash_incorrect(placed_part, placed_slot)
		_lock_bench_until_feedback_closed()


func _on_simulation_completed() -> void:
	var tip := _pending_tip
	_pending_tip = ""
	_done = true
	if _instruction != null:
		_instruction.text = "[b]Complete[/b]\n%s" % str(page.get("completion_message", "Simulation complete."))
	var correct: int = int(manager.correct_actions)
	var misses: int = int(manager.incorrect_actions)
	var accuracy: float = (float(correct) / float(maxi(correct + misses, 1))) * 100.0
	var line := "Accuracy %.0f%%  ·  %d correct  ·  %d misses" % [accuracy, correct, misses]
	if tip != "":
		line = "Correct — %s\n%s" % [tip, line]
	_set_feedback(line, _ok_color())
	_update_progress()
	if bench != null:
		if bench.has_method("set_interaction_locked"):
			bench.set_interaction_locked(true)
		if bench.has_method("clear_step_guides"):
			bench.clear_step_guides()
	completed.emit({"correct": correct, "misses": misses, "accuracy": accuracy})
	var dialog := RuleFeedbackDialog.ensure(self)
	if dialog != null:
		if not dialog.proceed_pressed.is_connected(_on_done_proceed):
			dialog.proceed_pressed.connect(_on_done_proceed)
		var detail := str(page.get("completion_message", "")).strip_edges()
		dialog.present_done(detail if detail != "" else "Simulation complete.", str(page.get("done_button", "Continue")))


func _on_done_proceed() -> void:
	finished.emit()


func _on_bench_coach_message(correct: bool, title: String, detail: String) -> void:
	_show_feedback(correct, title, detail)
	if not correct:
		_lock_bench_until_feedback_closed()


func _show_feedback(correct: bool, heading: String, detail: String) -> void:
	var dialog := RuleFeedbackDialog.ensure(self)
	if dialog != null:
		dialog.present(correct, heading, detail)


func _lock_bench_until_feedback_closed() -> void:
	if bench != null and bench.has_method("set_interaction_locked"):
		bench.set_interaction_locked(true)
	var dialog := RuleFeedbackDialog.ensure(self)
	if dialog == null or not dialog.visible:
		# No modal on screen means no "closed" signal will ever unlock the bench.
		_unlock_bench_after_feedback()
		return
	if dialog.closed.is_connected(_unlock_bench_after_feedback):
		dialog.closed.disconnect(_unlock_bench_after_feedback)
	dialog.closed.connect(_unlock_bench_after_feedback, CONNECT_ONE_SHOT)


func _unlock_bench_after_feedback() -> void:
	# Wait one frame so the Got it / dimmer tap cannot hit the case underneath.
	await get_tree().process_frame
	if _done:
		return
	if bench != null and is_instance_valid(bench) and bench.has_method("set_interaction_locked"):
		bench.set_interaction_locked(false)


# --- Overlay: floating toggles + slide-in panels ------------------------------------------

func _build_overlay(floating: Dictionary) -> void:
	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.z_index = 10
	add_child(_overlay)

	# Top-left: Back + Help (same Figma chips as the lesson header).
	var left_bar := HBoxContainer.new()
	left_bar.add_theme_constant_override("separation", 8)
	left_bar.position = Vector2(PANEL_MARGIN, PANEL_MARGIN)
	_overlay.add_child(left_bar)
	var back := Button.new()
	LessonHeader.style_back(back)
	back.pressed.connect(func() -> void: back_requested.emit())
	left_bar.add_child(back)
	var help := Button.new()
	help.text = "Help"
	LessonHeader.style_help(help)
	help.pressed.connect(func() -> void: help_requested.emit())
	left_bar.add_child(help)

	# Top-centre: zoom controls (controls, not a panel — always visible).
	var zoom: Control = floating.get("zoom")
	if zoom != null:
		var zoom_holder := CenterContainer.new()
		zoom_holder.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		zoom_holder.offset_top = PANEL_MARGIN
		zoom_holder.offset_left = -200
		zoom_holder.offset_right = 200
		zoom_holder.offset_bottom = PANEL_MARGIN + 44
		zoom_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zoom.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		zoom_holder.add_child(zoom)
		_overlay.add_child(zoom_holder)

	# Top-right: panel toggles.
	var right_bar := HBoxContainer.new()
	right_bar.add_theme_constant_override("separation", 8)
	right_bar.alignment = BoxContainer.ALIGNMENT_END
	right_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right_bar.offset_left = -420
	right_bar.offset_right = -PANEL_MARGIN
	right_bar.offset_top = PANEL_MARGIN
	right_bar.offset_bottom = PANEL_MARGIN + 46
	right_bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_overlay.add_child(right_bar)
	for key in ["steps", "parts", "info"]:
		var toggle := Button.new()
		toggle.name = "Toggle_%s" % key
		toggle.text = {"steps": "Steps", "parts": "Parts", "info": "Info"}[key]
		toggle.toggle_mode = true
		LessonHeader.apply_chip(toggle)
		toggle.custom_minimum_size = Vector2(88, 40)
		toggle.add_theme_font_size_override("font_size", LessonTheme.readable(12))
		toggle.toggled.connect(func(on: bool) -> void: set_panel_open(key, on))
		right_bar.add_child(toggle)
		_toggles[key] = toggle

	_add_panel("steps", "left", 380.0, _build_steps_panel(floating.get("hint")))
	var tray: Control = floating.get("tray")
	if tray is PanelContainer:
		# The slide-in panel already draws the card; avoid a frame inside a frame.
		if LessonTheme.light_mode:
			# Tray text is light-on-dark; on the white Light-mode panel it vanished.
			var dark := StyleBoxFlat.new()
			dark.bg_color = Color(0.03, 0.08, 0.12, 0.96)
			dark.set_corner_radius_all(14)
			tray.add_theme_stylebox_override("panel", dark)
		else:
			tray.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_add_panel("parts", "right", 300.0, tray)
	_add_panel("info", "right", 380.0, _build_info_panel())
	_update_progress()


func _add_panel(key: String, side: String, width: float, body: Control) -> void:
	if body == null:
		var t: Button = _toggles.get(key)
		if t != null:
			t.visible = false
		return
	var panel := PanelContainer.new()
	panel.name = "Panel_%s" % key
	var style := LessonTheme.figma_card_style()
	style.bg_color = Color(LessonTheme.FIGMA_PANEL, 0.96)
	style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_top = PANEL_TOP
	panel.offset_bottom = -PANEL_MARGIN
	if side == "left":
		panel.anchor_left = 0.0
		panel.anchor_right = 0.0
	else:
		panel.anchor_left = 1.0
		panel.anchor_right = 1.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_meta("no_swipe", true)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(body)
	panel.visible = false
	_overlay.add_child(panel)
	_panels[key] = {"panel": panel, "side": side, "width": width, "open": false, "tween": null}
	_place_panel(key, 0.0)


## Slides a panel in or out. Pure presentation: the bench, tray contents and
## the simulation step are untouched.
func set_panel_open(key: String, open: bool) -> void:
	if not _panels.has(key):
		return
	var info: Dictionary = _panels[key]
	if bool(info["open"]) == open:
		_sync_toggle(key, open)
		return
	# Parts and Info share the right edge — only one at a time.
	if open and str(info["side"]) == "right":
		for other in _panels.keys():
			if other != key and str((_panels[other] as Dictionary)["side"]) == "right":
				set_panel_open(other, false)
	info["open"] = open
	_sync_toggle(key, open)
	var panel: Control = info["panel"]
	var tw: Tween = info.get("tween")
	if tw != null and tw.is_valid():
		tw.kill()
	panel.visible = true
	var from := 1.0 if open else 0.0
	var to := 0.0 if open else 1.0
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void: _place_panel(key, t), from, to, SLIDE_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if not open:
		tween.finished.connect(func() -> void:
			if not bool((_panels[key] as Dictionary)["open"]):
				panel.visible = false
		)
	info["tween"] = tween


func is_panel_open(key: String) -> bool:
	return _panels.has(key) and bool((_panels[key] as Dictionary)["open"])


## hidden_t: 0 = fully on screen, 1 = fully off screen.
func _place_panel(key: String, hidden_t: float) -> void:
	var info: Dictionary = _panels[key]
	var panel: Control = info["panel"]
	var width: float = float(info["width"])
	var shift: float = (width + PANEL_MARGIN * 2.0) * hidden_t
	if str(info["side"]) == "left":
		panel.offset_left = PANEL_MARGIN - shift
		panel.offset_right = PANEL_MARGIN + width - shift
	else:
		panel.offset_left = -PANEL_MARGIN - width + shift
		panel.offset_right = -PANEL_MARGIN + shift


func _sync_toggle(key: String, open: bool) -> void:
	var toggle: Button = _toggles.get(key)
	if toggle != null and toggle.button_pressed != open:
		toggle.set_pressed_no_signal(open)
	if toggle != null:
		var style := LessonTheme.chip_style()
		if open:
			style.border_color = LessonTheme.CYAN
			style.bg_color = Color("#bfe2f3") if LessonTheme.light_mode else Color("#123d5c")
		toggle.add_theme_stylebox_override("normal", style)


func _build_steps_panel(hint_bar: Control) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	var head := HBoxContainer.new()
	col.add_child(head)
	var title := LessonBlocks.make_label(
		str(page.get("eyebrow", "Assessment" if is_assessment else "Guided Simulation")).to_upper(),
		LessonTheme.figma_text(11, true, 1)
	)
	title.label_settings.font_color = LessonTheme.CYAN
	head.add_child(title)
	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", LessonTheme.readable(11))
	_progress_label.add_theme_color_override("font_color", _info_color())
	head.add_child(_progress_label)

	_instruction = RichTextLabel.new()
	_instruction.bbcode_enabled = true
	_instruction.fit_content = true
	_instruction.scroll_active = false
	_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instruction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_instruction.add_theme_font_override("normal_font", LessonTheme.load_font(LessonTheme.FONT_BODY))
	_instruction.add_theme_font_override("bold_font", LessonTheme.load_font(LessonTheme.FONT_CARD))
	_instruction.add_theme_font_size_override("normal_font_size", LessonTheme.readable(14))
	_instruction.add_theme_font_size_override("bold_font_size", LessonTheme.readable(14))
	_instruction.add_theme_color_override("default_color", LessonTheme.FIGMA_TEXT)
	col.add_child(_instruction)

	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.add_theme_font_size_override("font_size", LessonTheme.readable(12))
	col.add_child(_feedback)

	if hint_bar != null:
		hint_bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		col.add_child(hint_bar)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)

	if is_assessment:
		var reset := Button.new()
		reset.text = "Reset scenario"
		reset.focus_mode = Control.FOCUS_NONE
		LessonHeader.apply_chip(reset)
		reset.pressed.connect(_reset_assessment)
		col.add_child(reset)
	return col


func _build_info_panel() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	col.add_child(LessonBlocks.make_label(str(page.get("title", "")), LessonTheme.figma_text(18, true, 1)))
	var description := str(page.get("description", ""))
	if description != "":
		col.add_child(LessonBlocks.make_rich(description, 12, []))
	var objectives: Array = page.get("objectives", [])
	if not objectives.is_empty():
		col.add_child(LessonBlocks.make_label("Objectives", LessonTheme.figma_text(13, true)))
		col.add_child(LessonBlocks.make_rich(LessonFigmaLayouts._bullets_text(objectives), 12, []))
	var pitfalls: Array = page.get("pitfalls", [])
	if not pitfalls.is_empty():
		col.add_child(LessonBlocks.make_label("Watch out", LessonTheme.figma_text(13, true)))
		col.add_child(LessonBlocks.make_rich(LessonFigmaLayouts._bullets_text(pitfalls), 12, []))
	return scroll


# --- Helpers ---------------------------------------------------------------------------

func _update_progress() -> void:
	var total: int = maxi(_steps.size(), 1)
	var done: int = _completed_ids.size()
	var text := "Complete · %d / %d" % [done, total] if done >= total else "Step %d / %d" % [mini(done + 1, total), total]
	if _progress_label != null:
		_progress_label.text = "   " + text
	var steps_toggle: Button = _toggles.get("steps")
	if steps_toggle != null:
		steps_toggle.text = "Steps %d/%d" % [mini(done + (0 if done >= total else 1), total), total]


func _set_feedback(text: String, color: Color) -> void:
	if _feedback == null:
		return
	_feedback.text = text
	_feedback.add_theme_color_override("font_color", color)


func _find_step(step_id: String) -> Dictionary:
	for step_variant in _steps:
		var step_data: Dictionary = step_variant as Dictionary
		if str(step_data.get("id", "")) == step_id:
			return step_data
	return {}


func _part_title(part_id: String) -> String:
	if bench != null and bench.has_method("_part_title"):
		return str(bench.call("_part_title", part_id))
	return part_id.replace("_", " ")


func _slot_title(slot_id: String) -> String:
	if bench != null and bench.has_method("_slot_title"):
		return str(bench.call("_slot_title", slot_id))
	return slot_id.replace("_", " ")


## Feedback colours that stay readable on the white Light-mode panel.
func _info_color() -> Color:
	return LessonTheme.MUTED if LessonTheme.light_mode else Color(0.75, 0.88, 0.95, 0.9)


func _ok_color() -> Color:
	return Color("#0f7a4f") if LessonTheme.light_mode else Color(0.45, 0.95, 0.7, 1)


func _bad_color() -> Color:
	return Color("#b3261e") if LessonTheme.light_mode else Color(1.0, 0.55, 0.55, 1)
