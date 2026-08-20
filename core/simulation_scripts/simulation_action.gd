class_name SimulationAction
extends RefCounted

var action: String
var target: String
var destination: String
var value: Variant


func _init(
	action_name: String,
	target_name: String = "",
	destination_name: String = "",
	action_value: Variant = null
) -> void:
	action = action_name
	target = target_name
	destination = destination_name
	value = action_value
