extends Node

@onready var label: Label = $Container/VBox1/Label
@onready var button: Button = $Container/VBox1/Button

var app_plugin

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		send_event("destroy")

func _ready():
	button.pressed.connect(_on_button_pressed)
	_print_func_message("_ready", "_on_button_pressed is connected.")
	
	app_plugin = Engine.get_singleton("SmartBuildBridge")
	
	if app_plugin:
		_print_func_message("_ready", "SmartBuildBridge FOUND.")
		print("Plugin methods: ", app_plugin.get_method_list())
		app_plugin.message_from_compose.connect(_on_message_from_compose)
		#app_plugin.message_from_compose.connect(_prepare_environment)
		_print_func_message("_ready", "app_plugin.message_from_compose.connect is connected!")
		
		_print_func_message("_ready", "Engine is initialized.")
		send_event("engine_initialized")
		#send_ready(0)
	else:
		_print_func_message("_ready", "SmartBuildBridge NOT FOUND.")

func _on_message_from_compose(message: String):
	_print_func_message("_on_message_from_compose", "Received message from compose.")
	var mess = JSON.parse_string(message)
	
	if mess == null:
		_print_func_message("_on_message_from_compose", "Invalid JSON received.")
		return
	
	_print_func_message("_on_message_from_compose", "Received from compose: " + JSON.stringify(mess))
	
	_print_func_message("_on_message_from_compose", str("Type: ", mess["type"]))
	if mess["type"] != "command":
		_print_func_message("_on_message_from_compose", "Ignoring non-command type.")
		return
	
	var action = mess["action"]
	_print_func_message("_on_message_from_compose", str("Action: " + action))
	match action:
		"prepare":
			#start_simulation(mess["simulationId"])
			_prepare_module(mess)
			
		_:
			print("Unknown action: ", action)

func _prepare_module(mess: Dictionary):
	var data = mess.get("data", {})
	
	if data.is_empty():
		print("Data key is empty.")
		return
	
	var module_id: int = data.get("moduleId", -1)
	var simulation_type: int = data.get("simulationType", -1)
	var progress: float = data.get("progress", 0.0)
	
	print("Preparing Module: ", module_id)
	print("Simulation Type: ", simulation_type)
	print("Progress: ", progress)

	if module_id == 0:
		_load_module_0()

func _load_module_0():
	_print_func_message("_load_module_0", "Loading Module 0.")
	send_event("loading", 0)
	
	var module_scene = preload("res://modules/module_0/Main.tscn")
	var module_instance = module_scene.instantiate()
	
	if module_instance == null:
		_print_func_message("_load_module_0", "module_instance is null")
		return
		
	add_child(module_instance)
	
	_print_func_message("_load_module_0", "Module 0 is ready.")
	send_event("ready", 0)

func send_event(event: String, moduleId: int = -1):
	_print_func_message("send_event", "Preparing event.")
	
	var response = {
		"type": "event",
		"event": event,
		"moduleId": moduleId
	}
	
	app_plugin.sendMessageToCompose(JSON.stringify(response))
	_print_func_message("send_event", "Event sent.")

func _print_func_message(func_name: String, message: String):
	print("func ", func_name, "(): ", message)



#################################################



func _on_button_pressed():
	if app_plugin:
		label.text = "Exiting..."
		var data = {
			"type": "event",
			"event": "exit"
		}
		var message = JSON.parse_string(data)
		app_plugin.sendMessageToCompose(JSON.stringify(message))
	else: 
		label.text = "NOT FOUND"

func _prepare_environment(message: String):
	print("_prepare_environment func")
	var mess = JSON.parse_string(message)
	
	print("Checking if mess is null.")
	if mess == null:
		print("Invalid JSON received!")
		return
	print("mess is not null.")
	
	print("Checking if mess['type'] is not 'command'.")
	if mess["type"] != "command":
		print("Ignoring non-command message.")
		return
	print("mess['type'] is 'command'.")
	
	var data = mess.get("data", {})
	
	var moduleId = data.get("moduleId", -1)
	var simulationType = data.get("simulationType", -1)
	var progress = data.get("progress", 0.0)
	
	print("Preparing Environtment...")
	print("Module Id: ", moduleId)
	print("Simulation Type: ", simulationType)
	print("Progress: ", progress)
	
	# Temporary.
	send_ready(moduleId)

func send_ready(moduleId: int):
	label.text = str("Module ", moduleId)
	
	var response = {
		"type": "event",
		"event": "ready"
	}
	
	app_plugin.sendMessageToCompose(JSON.stringify(response))

func start_simulation(simulationId: String):
	print("Simulation Id: ", simulationId)
	label.text = simulationId
	send_simulation_started(simulationId)

func send_simulation_started(simulationId: String):
	var response = {
		"type": "event",
		"event": "simulation_started",
		"simulationId": simulationId
	}
	
	app_plugin.sendMessageToCompose(JSON.stringify(response))
