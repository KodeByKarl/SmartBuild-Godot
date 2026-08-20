class_name SimulationStep
extends RefCounted

var id: String
var instruction: String

var action: String
var target: String
var destination: String
var value: Variant


func _init(
	step_id: String,
	step_instruction: String,
	step_action: String,
	step_target: String = "",
	step_destination: String = "",
	step_value: Variant = null
) -> void:
	id = step_id
	instruction = step_instruction

	action = step_action
	target = step_target
	destination = step_destination
	value = step_value
