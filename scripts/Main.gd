extends Control

## Simulation host entry. Auth + Dashboard live in Compose — not here.
## Hosted: wait for SmartBuildBridge prepare(module + optional session).
## Standalone debug: mock session + optional module picker / auto-boot.

const DEBUG_LAUNCHER := preload("res://core/scenes/debug_module_launcher.gd")

@onready var label: Label = $Container/VBox1/Label
@onready var button: Button = $Container/VBox1/Button

var app_plugin
var loaded_module: Node = null
var _debug_launcher: Control = null
var _standalone_mode := false
var _scene_cache: Dictionary = {}
var _active_module_id: int = -1
var _active_sim_type: int = -1
var _load_in_progress := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _standalone_mode:
			if loaded_module != null:
				_unload_module()
				_boot_standalone_debug()
			else:
				send_event("destroy")
		else:
			send_event("destroy")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_button_pressed)
	_print_func_message("_ready", "_on_button_pressed is connected.")

	if Engine.has_singleton("SmartBuildBridge"):
		app_plugin = Engine.get_singleton("SmartBuildBridge")
		_print_func_message("_ready", "SmartBuildBridge FOUND.")
		print("Plugin methods: ", app_plugin.get_method_list())
		app_plugin.message_from_compose.connect(_on_message_from_compose)
		_print_func_message("_ready", "app_plugin.message_from_compose.connect is connected!")
		_print_func_message("_ready", "Engine is initialized.")
		send_event("engine_initialized")
		# Compose owns Sign In → Home; wait for prepare(module).
		_hide_debug_chrome()
	else:
		app_plugin = null
		_standalone_mode = true
		_print_func_message("_ready", "SmartBuildBridge NOT FOUND (standalone preview).")
		_hide_debug_chrome()
		_boot_standalone_debug()


func _hide_debug_chrome() -> void:
	var container := get_node_or_null("Container")
	if container != null:
		container.visible = false


func _env_bool(key: String, default: bool) -> bool:
	if EnvConfig != null and EnvConfig.has_method("get_bool"):
		return bool(EnvConfig.get_bool(key, default))
	return default


func _env_int(key: String, default: int) -> int:
	if EnvConfig != null and EnvConfig.has_method("get_value"):
		var raw: String = str(EnvConfig.get_value(key, "")).strip_edges()
		if raw.is_valid_int():
			return int(raw)
	return default


func _allow_debug_fallback() -> bool:
	# Never use mock session / picker in release exports when hosted.
	if not _standalone_mode:
		return false
	if _env_bool("DEBUG_MOCK_SESSION", OS.is_debug_build()):
		return true
	return OS.is_debug_build()


func _boot_standalone_debug() -> void:
	if not _allow_debug_fallback():
		_print_func_message("_boot_standalone_debug", "No debug fallback — waiting idle.")
		return
	if SupabaseService != null and SupabaseService.has_method("apply_debug_mock_session"):
		SupabaseService.apply_debug_mock_session()
		_print_func_message("_boot_standalone_debug", "Injected debug mock session.")

	var forced_module: int = _env_int("DEBUG_STANDALONE_MODULE_ID", -1)
	if forced_module >= 0 and forced_module <= 4:
		var sim_type: int = _env_int("DEBUG_STANDALONE_SIMULATION_TYPE", 0)
		_prepare_module({
			"data": {
				"moduleId": forced_module,
				"simulationType": sim_type,
				"progress": 0.0
			}
		})
		return

	if _env_bool("DEBUG_SHOW_MODULE_PICKER", true):
		_show_debug_launcher()
	else:
		# Default editor path: Module 0 guided.
		_prepare_module({"data": {"moduleId": 0, "simulationType": 0, "progress": 0.0}})


func _show_debug_launcher() -> void:
	_unload_module()
	if _debug_launcher != null and is_instance_valid(_debug_launcher):
		_debug_launcher.visible = true
		return
	_debug_launcher = DEBUG_LAUNCHER.new() as Control
	_debug_launcher.name = "DebugModuleLauncher"
	add_child(_debug_launcher)
	call_deferred("_fit_control_to_viewport", _debug_launcher)
	if _debug_launcher.has_signal("module_selected"):
		_debug_launcher.module_selected.connect(_on_debug_module_selected)


func _hide_debug_launcher() -> void:
	if _debug_launcher != null and is_instance_valid(_debug_launcher):
		_debug_launcher.visible = false


func _on_debug_module_selected(module_id: int, simulation_type: int) -> void:
	_hide_debug_launcher()
	_prepare_module({
		"data": {
			"moduleId": module_id,
			"simulationType": simulation_type,
			"progress": 0.0
		}
	})


func _unload_module() -> void:
	if loaded_module != null and is_instance_valid(loaded_module):
		loaded_module.queue_free()
		loaded_module = null
	_active_module_id = -1
	_active_sim_type = -1


func _apply_session_from_prepare(data: Dictionary) -> void:
	if SupabaseService == null or not SupabaseService.has_method("apply_host_session"):
		return
	var token: String = str(data.get("accessToken", data.get("access_token", "")))
	if token == "":
		return
	SupabaseService.apply_host_session(
		token,
		str(data.get("userId", data.get("user_id", ""))),
		str(data.get("userEmail", data.get("user_email", ""))),
		str(data.get("refreshToken", data.get("refresh_token", "")))
	)
	_print_func_message("_apply_session_from_prepare", "Host session applied for %s" % SupabaseService.user_email)


func _on_message_from_compose(message: String) -> void:
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
			_prepare_module(mess)
		_:
			print("Unknown action: ", action)


func _prepare_module(mess: Dictionary) -> void:
	var data = mess.get("data", {})

	if data.is_empty():
		print("Data key is empty.")
		return

	_apply_session_from_prepare(data)

	var module_id: int = int(data.get("moduleId", -1))
	var simulation_type: int = int(data.get("simulationType", -1))
	var progress: float = float(data.get("progress", 0.0))

	print("Preparing Module: ", module_id)
	print("Simulation Type: ", simulation_type)
	print("Progress: ", progress)

	_hide_debug_launcher()

	match module_id:
		0:
			_load_module_scene(0, "res://modules/module_0/Main.tscn", simulation_type, progress)
		1:
			_load_module_scene(1, "res://modules/module_1/Main.tscn", simulation_type, progress)
		2:
			_load_module_scene(2, "res://modules/module_2/Main.tscn", simulation_type, progress)
		3:
			_load_module_scene(3, "res://modules/module_3/Main.tscn", simulation_type, progress)
		4:
			_load_module_scene(4, "res://modules/module_4/Main.tscn", simulation_type, progress)
		_:
			print("Unknown module id: ", module_id)


func _load_module_scene(module_id: int, scene_path: String, simulation_type: int = 0, progress: float = 0.0) -> void:
	if _load_in_progress:
		_print_func_message("_load_module_scene", "Ignoring duplicate prepare while a load is in progress.")
		return
	if (
		loaded_module != null
		and is_instance_valid(loaded_module)
		and _active_module_id == module_id
		and _active_sim_type == simulation_type
	):
		if loaded_module.has_method("configure"):
			loaded_module.configure(module_id, simulation_type, progress)
		_print_func_message("_load_module_scene", "Module %d already loaded — skipping reload." % module_id)
		_emit_event_safe("ready", module_id)
		return

	_load_in_progress = true
	_print_func_message("_load_module_scene", "Loading Module %d from %s." % [module_id, scene_path])
	_emit_event_safe("loading", module_id)

	var module_instance: Node = _instantiate_module(scene_path)
	if module_instance == null:
		_load_in_progress = false
		_emit_event_safe("error", module_id)
		return

	if module_instance.has_method("configure"):
		module_instance.configure(module_id, simulation_type, progress)

	add_child(module_instance)
	loaded_module = module_instance
	_active_module_id = module_id
	_active_sim_type = simulation_type

	if module_instance is Control:
		_fit_control_to_viewport(module_instance as Control)

	_load_in_progress = false
	_print_func_message("_load_module_scene", "Module %d is ready." % module_id)
	# Defer ready so Compose can subscribe between loading and ready on fast loads.
	call_deferred("_emit_event_safe", "ready", module_id)


func _fit_control_to_viewport(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vp_size := get_viewport().get_visible_rect().size
	if vp_size.x > 1.0 and vp_size.y > 1.0:
		control.size = vp_size


func _emit_event_safe(event: String, module_id: int = -1) -> void:
	if app_plugin:
		send_event(event, module_id)
	else:
		_print_func_message("_emit_event_safe", "Standalone mode event: %s module=%d" % [event, module_id])


func _instantiate_module(scene_path: String) -> Node:
	_unload_module()

	var module_scene: PackedScene = _packed_scene(scene_path)
	if module_scene == null:
		_print_func_message("_instantiate_module", "Failed to load scene at %s." % scene_path)
		return null

	var module_instance = module_scene.instantiate()
	if module_instance == null:
		_print_func_message("_instantiate_module", "module_instance is null")
		return null

	return module_instance


func _packed_scene(scene_path: String) -> PackedScene:
	if _scene_cache.has(scene_path):
		return _scene_cache[scene_path] as PackedScene
	var module_scene: PackedScene = load(scene_path) as PackedScene
	if module_scene != null:
		_scene_cache[scene_path] = module_scene
	return module_scene


func send_event(event: String, moduleId: int = -1, percent: float = -1.0) -> void:
	_print_func_message("send_event", "Preparing event.")

	var response = {
		"type": "event",
		"event": event,
		"moduleId": moduleId
	}
	if percent >= 0.0:
		response["percent"] = percent

	if app_plugin == null:
		_print_func_message("send_event", "Standalone mode: %s" % JSON.stringify(response))
		_handle_standalone_event(event, moduleId, percent)
		return

	app_plugin.sendMessageToCompose(JSON.stringify(response))
	_print_func_message("send_event", "Event sent.")


func _handle_standalone_event(event: String, _module_id: int, _percent: float = -1.0) -> void:
	match event:
		"destroy", "assessment_completed", "guided_completed":
			_unload_module()
			if _allow_debug_fallback() and _env_bool("DEBUG_SHOW_MODULE_PICKER", true):
				_show_debug_launcher()
		_:
			pass


func _print_func_message(func_name: String, message: String) -> void:
	print("func ", func_name, "(): ", message)


func _on_button_pressed() -> void:
	if app_plugin:
		label.text = "Exiting..."
		var data = {
			"type": "event",
			"event": "exit"
		}
		app_plugin.sendMessageToCompose(JSON.stringify(data))
	else:
		label.text = "Standalone preview"
