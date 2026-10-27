extends LessonDeck

## Module 0 — Introduction to Computer Systems Servicing.
## Content lives in Module0Content; this script only adds the intro's rules:
## progress per slide (capped at 99%), the completion slide, and Retake.

const MODULE_ID := 0

## Exit only counts as finishing the module once the celebration slide is reached.
var _completion_slide_seen := false


func _init() -> void:
	module_id = MODULE_ID
	module_title = "Preparatory Module | Introduction to Computer Systems Servicing"
	page_noun = "slide"
	pages = Module0Content.pages()


## Host entry point. simulationType 3 = finished module: reopen on the
## Congratulations slide (Proceed to Home / Retake Module); anything else starts at slide 1.
func configure(_new_module_id: int, simulation_type: int = 0, _new_progress: float = 0.0) -> void:
	current_index = maxi(page_count() - 1, 0) if simulation_type == 3 else 0
	_completion_slide_seen = false
	if is_node_ready():
		show_page(current_index)


func _ready() -> void:
	if ResourceWarmup != null and ResourceWarmup.has_method("prefetch_module"):
		ResourceWarmup.prefetch_module(MODULE_ID)
	super._ready()


func _on_page_shown(index: int) -> void:
	# Never mark 100% from page position — only "Proceed to Home" completes intro.
	var pct: float = minf((float(index + 1) / float(maxi(page_count(), 1))) * 100.0, 99.0)
	send_host_event("progress_update", pct)


## Completion page buttons (shared "completion" layout, same as Modules 1–4).
func _on_page_action(_index: int, action_name: String, _payload: Variant) -> void:
	match action_name:
		"proceed_home":
			_finish_module()
		"retake":
			_retake_intro()


func _can_swipe_forward(index: int) -> bool:
	var on_completion := index == page_count() - 1
	if on_completion:
		_completion_slide_seen = true
	# Celebration page uses in-slide "Proceed to Home" instead of swiping on.
	return not on_completion


func _on_back_pressed() -> void:
	# Quitting part-way through must not bank the module as finished — only
	# reaching the celebration slide does that.
	if _completion_slide_seen:
		_finish_module()
		return
	send_host_event("destroy")


func _finish_module() -> void:
	# Flowchart: Intro lesson complete → save progress → Home.
	send_host_event("assessment_completed")


func _retake_intro() -> void:
	# Clear saved intro progress and restart from slide 1.
	_completion_slide_seen = false
	send_host_event("progress_reset")
	show_page(0)
