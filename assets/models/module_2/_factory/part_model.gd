extends Node3D

## Drop-in Module 2 part. Set `part_id` to match the folder name.
## Geometry is built at runtime by Module2PartFactory.

@export var part_id: String = "router"


func _ready() -> void:
	set_meta("sb_procedural", true)
	while get_child_count() > 0:
		var child := get_child(0)
		remove_child(child)
		child.free()
	Module2PartFactory.build_into(self, part_id)
