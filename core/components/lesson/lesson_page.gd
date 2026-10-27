class_name LessonPage
extends Control

## One lesson page built from data (see LessonLayouts.build_page). Replaces the
## per-slide scenes: a module supplies Dictionaries, never its own page scenes.

## Emitted by interactive sections (checklists, completion buttons) so the deck
## or module can react without each page knowing who is listening.
signal action(name: String, payload: Variant)

var page: Dictionary = {}


static func create(page_data: Dictionary) -> LessonPage:
	var node := LessonPage.new()
	node.page = page_data
	node.name = "LessonPage"
	return node


func _ready() -> void:
	LessonLayouts.build_page(self, page)


func emit_action(action_name: String, payload: Variant = null) -> void:
	action.emit(action_name, payload)
