extends Control

## Thin Module 0 lesson slide. Set slide_id in the scene (1–10, 13–20).

@export var slide_id: int = 1


func _ready() -> void:
	Module0LessonContent.build(self, slide_id)
