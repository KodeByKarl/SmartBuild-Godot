class_name StepValidator
extends RefCounted

static func validate(
	step: SimulationStep,
	user_action: SimulationAction
) -> bool:
	if step.action != user_action.action:
		return false

	if step.target != user_action.target:
		return false

	if step.destination != user_action.destination:
		return false

	if step.value != null:
		if step.value != user_action.value:
			return false

	return true
