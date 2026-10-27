class_name ModuleFlow
extends LessonDeck

## One flow for Modules 1–4, built only from ModuleContentRegistry data:
##
##   Lesson pages (swipe) → Guided Simulation → Be Ready for Assessment
##   → Assessment Simulation → Completion
##
## Page entries carry a "kind":
##   lesson        LessonLayouts page (default)
##   simulation    full-screen Guided Simulation (SimulationPage)
##   assessment    full-screen Assessment Simulation (SimulationPage, no hints)
##   be_ready      bridge page before the assessment
##   external_lab  hand-off to a simulation hosted by the Android app (Modules 2–4)
##   completion    Congratulations + Proceed to Home / Retake Module
##
## Host simulationType picks the entry point:
##   0 = start (or resume) at the lessons
##   1 = Be Ready → Assessment
##   3 = Completion (Modules 2–4, after the Android assessment lab)
##
## Host events: progress_update, guided_saved (guided done, stay in module),
## assessment_saved (assessment done, stay), assessment_completed (leave from
## completion), start_guided_lab / start_assessment_lab (Modules 2–4 labs),
## progress_reset (Retake), destroy (Back).

const SIM_ENTRY_BE_READY := 1
const SIM_ENTRY_COMPLETION := 3

var simulation_type := 0
var progress := 0.0
var module_data: Dictionary = {}

var _cleared: Dictionary = {}
## Page index -> true once every row of a required checklist is ticked.
var _checklists_done: Dictionary = {}
var _guided_saved := false
var _assessment_saved := false


func configure(new_module_id: int, new_simulation_type: int = 0, new_progress: float = 0.0) -> void:
	module_id = new_module_id
	simulation_type = new_simulation_type
	progress = new_progress
	module_data = ModuleContentRegistry.get_module(module_id)
	module_title = str(module_data.get("header", "Module %d" % module_id))
	_cleared.clear()
	_checklists_done.clear()
	_guided_saved = false
	_assessment_saved = false
	var flow_pages: Array = module_data.get("pages", [])
	var start := _resolve_start_index(flow_pages)
	if is_node_ready():
		LessonHeader.style_module_label(module_label, module_title)
		set_pages(flow_pages, start)
	else:
		pages = flow_pages
		current_index = start


func _ready() -> void:
	if module_data.is_empty():
		configure(module_id if module_id > 0 else 1, simulation_type, progress)
	if ResourceWarmup != null and ResourceWarmup.has_method("prefetch_module"):
		ResourceWarmup.prefetch_module(module_id)
	super._ready()


func kind_of(index: int) -> String:
	if index < 0 or index >= page_count() or not (pages[index] is Dictionary):
		return ""
	return str((pages[index] as Dictionary).get("kind", "lesson"))


func index_of_kind(kind: String) -> int:
	for i in page_count():
		if kind_of(i) == kind:
			return i
	return -1


func lesson_count() -> int:
	var n := 0
	for i in page_count():
		if kind_of(i) == "lesson":
			n += 1
	return n


# --- Entry point / resume ------------------------------------------------------------

func _resolve_start_index(flow_pages: Array) -> int:
	if flow_pages.is_empty():
		return 0
	var first_of := func(kind: String) -> int:
		for i in flow_pages.size():
			if str((flow_pages[i] as Dictionary).get("kind", "lesson")) == kind:
				return i
		return -1
	if simulation_type == SIM_ENTRY_BE_READY:
		var be_ready: int = first_of.call("be_ready")
		return be_ready if be_ready >= 0 else 0
	if simulation_type == SIM_ENTRY_COMPLETION:
		var done: int = first_of.call("completion")
		return done if done >= 0 else 0
	# Guided: resume from saved page progress, but never past the guided
	# simulation (it has to be finished before anything after it).
	if progress <= 0.5:
		return 0
	var total := flow_pages.size()
	var from_pct := clampi(int(ceil((progress / 100.0) * float(total))) - 1, 0, total - 1)
	for i in range(0, from_pct + 1):
		var kind := str((flow_pages[i] as Dictionary).get("kind", "lesson"))
		if kind != "lesson":
			return i
	return from_pct


# --- Pages ------------------------------------------------------------------------

func _make_custom_page(index: int, entry: Variant) -> Control:
	var kind := kind_of(index)
	if kind != "simulation" and kind != "assessment":
		return null
	var sim := SimulationPage.create(entry as Dictionary, kind == "assessment")
	sim.completed.connect(func(_stats: Dictionary) -> void: _on_simulation_completed(index))
	sim.finished.connect(func() -> void: _advance_from(index))
	sim.back_requested.connect(_on_back_pressed)
	sim.help_requested.connect(_toggle_help)
	return sim


func _should_prewarm(index: int) -> bool:
	return not (kind_of(index) in ["simulation", "assessment"])


func _on_page_shown(index: int) -> void:
	# Cap at 99 — 100% only via assessment_completed.
	var pct: float = minf((float(index + 1) / float(maxi(page_count(), 1))) * 100.0, 99.0)
	send_host_event("progress_update", pct)


func _update_indicator(index: int) -> void:
	match kind_of(index):
		"lesson":
			if _needs_checklist(index) and not _checklists_done.has(index):
				page_indicator.show_text("Tick every item to continue")
				return
			var lesson_no := 0
			for i in range(0, index + 1):
				if kind_of(i) == "lesson":
					lesson_no += 1
			page_indicator.show_position(lesson_no - 1, lesson_count())
		"be_ready":
			page_indicator.show_text("Swipe to begin the assessment  ›" if _can_swipe_forward(index) else "")
		_:
			page_indicator.show_text("")


func _help_for(index: int) -> Dictionary:
	if current_page != null and is_instance_valid(current_page) and current_page.has_method("help_info"):
		return current_page.help_info()
	return super._help_for(index)


# --- Navigation rules ----------------------------------------------------------------

func _can_swipe_back(index: int) -> bool:
	# Back only into lessons. Simulations, Be Ready and Completion are one-way.
	return kind_of(index) in ["lesson", "external_lab"] and index > 0 and kind_of(index - 1) == "lesson"


func _can_swipe_forward(index: int) -> bool:
	if index >= page_count() - 1:
		return false
	match kind_of(index):
		"lesson":
			if _needs_checklist(index) and not _checklists_done.has(index):
				return false
			return kind_of(index + 1) in ["lesson", "simulation", "external_lab"]
		"simulation":
			return _cleared.has(index)
		"be_ready":
			return kind_of(index + 1) in ["assessment", "external_lab"]
		_:
			# assessment advances via its Continue dialog; external_lab and
			# completion leave through buttons.
			return false


func _needs_checklist(index: int) -> bool:
	return index >= 0 and index < page_count() and bool((pages[index] as Dictionary).get("require_checklist", false))


func _advance_from(index: int) -> void:
	if index != current_index or index + 1 >= page_count():
		return
	show_page(index + 1)


func _on_simulation_completed(index: int) -> void:
	_cleared[index] = true
	match kind_of(index):
		"simulation":
			# Last guided simulation done → Guided is complete; stay in the module.
			if not _guided_saved and index_of_last("simulation") == index:
				_guided_saved = true
				send_host_event("guided_saved")
		"assessment":
			if not _assessment_saved:
				_assessment_saved = true
				send_host_event("assessment_saved")
	refresh_navigation()


func index_of_last(kind: String) -> int:
	var found := -1
	for i in page_count():
		if kind_of(i) == kind:
			found = i
	return found


# --- Page actions / Back -----------------------------------------------------------------

func _on_page_action(index: int, action_name: String, _payload: Variant) -> void:
	match action_name:
		"checklist":
			if _needs_checklist(index) and typeof(_payload) == TYPE_DICTIONARY:
				if bool((_payload as Dictionary).get("all_checked", false)):
					_checklists_done[index] = true
				else:
					_checklists_done.erase(index)
				refresh_navigation()
				_update_indicator(current_index)
		"proceed_home":
			send_host_event("assessment_completed")
		"retake":
			_retake()
		"advance_page":
			_advance_from(index)
		"start_guided_lab":
			send_host_event("start_guided_lab")
		"start_assessment_lab":
			send_host_event("start_assessment_lab")
		"start_lab":
			# Generic hand-off: guided before Be Ready, assessment after it.
			var be_ready := index_of_kind("be_ready")
			send_host_event("start_assessment_lab" if be_ready >= 0 and index > be_ready else "start_guided_lab")


func _on_back_pressed() -> void:
	# Leaving from the completion page banks the module, like Proceed to Home.
	if kind_of(current_index) == "completion":
		send_host_event("assessment_completed")
		return
	send_host_event("destroy")


func _retake() -> void:
	_cleared.clear()
	_checklists_done.clear()
	_guided_saved = false
	_assessment_saved = false
	send_host_event("progress_reset")
	# Fresh simulations: drop cached page nodes so benches rebuild from scratch.
	set_pages(pages, 0)
