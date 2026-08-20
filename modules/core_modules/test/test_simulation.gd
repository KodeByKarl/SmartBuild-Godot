extends Node

var sm := load("res://core/simulation_scripts/simulation_manager.gd")
var simulation_manager = sm.new()


func _ready() -> void:
	add_child(simulation_manager)

	simulation_manager.step_changed.connect(_on_step_changed)
	simulation_manager.step_completed.connect(_on_step_completed)
	simulation_manager.action_incorrect.connect(_on_action_incorrect)
	simulation_manager.simulation_completed.connect(_on_simulation_completed)

	var steps: Array[SimulationStep] = [
		SimulationStep.new(
			"install_ram",
			"Install the RAM into the appropriate memory slot.",
			"install",
			"ram",
			"ram_slot"
		),
		SimulationStep.new(
			"install_cpu",
			"Install the CPU into the CPU socket.",
			"install",
			"cpu",
			"cpu_socket"
		)
	]

	simulation_manager.start(
		steps,
		SimulationMode.Type.ASSESSMENT
	)
	
	simulation_manager.receive_action(
		SimulationAction.new(
			"install",
			"ram",
			"pcie_slot"
		)
	)


func _on_step_changed(step: SimulationStep) -> void:
	print("CURRENT STEP:")
	print(step.instruction)


func _on_step_completed(step: SimulationStep) -> void:
	print("STEP COMPLETED: ", step.id)


func _on_action_incorrect(action: SimulationAction) -> void:
	print(
		"INCORRECT ACTION: ",
		action.action,
		" / ",
		action.target,
		" / ",
		action.destination
	)

func _on_simulation_completed() -> void:
	print("SIMULATION COMPLETED!")
	print("Progress: ", simulation_manager.get_progress() * 100.0, "%")
	print("Score: ", simulation_manager.get_score(), "%")
