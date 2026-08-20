class_name SimulationManager
extends Node

signal simulation_started
signal step_changed(step: SimulationStep)
signal step_completed(step: SimulationStep)
signal action_incorrect(action: SimulationAction)
signal simulation_completed

var steps: Array[SimulationStep] = []
var current_step_index: int = 0

var mode: SimulationMode.Type = SimulationMode.Type.GUIDED

var correct_actions: int = 0
var incorrect_actions: int = 0

func start(
	new_steps: Array[SimulationStep],
	simulation_mode: SimulationMode.Type = SimulationMode.Type.GUIDED
) -> void:
	steps = new_steps
	current_step_index = 0

	correct_actions = 0
	incorrect_actions = 0

	mode = simulation_mode

	if steps.is_empty():
		return

	simulation_started.emit()

	step_changed.emit(steps[current_step_index])


func receive_action(action: SimulationAction) -> void:
	if steps.is_empty():
		return

	if is_finished():
		return

	var current_step := steps[current_step_index]

	if StepValidator.validate(current_step, action):
		correct_actions += 1
		step_completed.emit(current_step)
		current_step_index += 1

		if is_finished():
			simulation_completed.emit()
		else:
			step_changed.emit(steps[current_step_index])
	else:
		incorrect_actions += 1
		action_incorrect.emit(action)

func is_finished() -> bool:
	return current_step_index >= steps.size()

func get_progress() -> float:
	if steps.is_empty():
		return 0.0
	return float(current_step_index) / float(steps.size())


func get_score() -> float:
	if steps.is_empty():
		return 0.0

	return float(correct_actions) / float(steps.size()) * 100.0
