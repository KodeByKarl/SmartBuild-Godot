extends Node3D

## Drop-in Module 1 part. Set `part_id` to match the folder name
## (ssd, hdd, fan, …). Geometry is built at runtime by Module1PartFactory.

@export var part_id: String = "ssd"

var _spin: Node3D = null


func _ready() -> void:
	set_meta("sb_procedural", true)
	while get_child_count() > 0:
		var child := get_child(0)
		remove_child(child)
		child.free()
	Module1PartFactory.build_into(self, part_id)
	_spin = find_child("Blades", true, false) as Node3D


func _process(delta: float) -> void:
	if _spin != null:
		_spin.rotate_z(delta * 7.5)
