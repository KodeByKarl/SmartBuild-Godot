extends Node

## Tiny host stand-in for progress_completion_probe.gd — ModuleFlow walks parents
## looking for send_event().

var events: PackedStringArray = PackedStringArray()


func clear_events() -> void:
	events.clear()


func get_events() -> PackedStringArray:
	return events


func send_event(event: String, _module_id: int = -1, _percent: float = -1.0) -> void:
	events.append(event)
