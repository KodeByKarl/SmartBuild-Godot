extends Control

## Optional reusable chrome root. Prefer Module0SlideBuilder.mount for lesson slides.

signal content_ready(content: VBoxContainer)

var content_root: VBoxContainer


func _ready() -> void:
	content_root = Module0SlideBuilder.mount(self)
	content_ready.emit(content_root)


func get_content() -> VBoxContainer:
	return content_root
