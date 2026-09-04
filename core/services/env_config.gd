extends Node

## Loads secrets/config from environment variables and local env files.
## Never commit real values — use env.example / secrets.properties.example.

const ENV_LOCAL_DOTENV := "res://config/env.local"
const ENV_EXAMPLE_DOTENV := "res://config/env.example"
const ENV_LOCAL_CFG := "res://config/env.local.cfg"
const USER_ENV_CFG := "user://env.cfg"

var _values: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	_values.clear()
	_load_dotenv_file(ENV_LOCAL_DOTENV)
	_load_config_file(ENV_LOCAL_CFG)
	_load_config_file(USER_ENV_CFG)
	_overlay_os_environment()


func get_value(key: String, default: String = "") -> String:
	var from_os: String = OS.get_environment(key).strip_edges()
	if from_os != "":
		return from_os
	if _values.has(key):
		return str(_values[key]).strip_edges()
	return default


func get_bool(key: String, default: bool = false) -> bool:
	var raw: String = get_value(key, "").to_lower()
	if raw == "":
		return default
	return raw in ["1", "true", "yes", "on"]


func require_value(key: String) -> String:
	var value: String = get_value(key, "")
	if value == "":
		push_error("EnvConfig: missing required key '%s'. Copy config/env.example to config/env.local" % key)
	return value


func has_supabase() -> bool:
	return get_value("SUPABASE_URL") != "" and get_value("SUPABASE_ANON_KEY") != ""


func _overlay_os_environment() -> void:
	# OS already wins in get_value(); this only documents known keys for tooling.
	var keys: Array[String] = [
		"SUPABASE_URL",
		"SUPABASE_ANON_KEY",
		"SUPABASE_ENABLED",
		"SUPABASE_PREVIEW_FALLBACK",
		"SUPABASE_AUTH_SCHEME",
		"SUPABASE_AUTH_HOST",
		"DEBUG_MOCK_SESSION",
		"DEBUG_SHOW_MODULE_PICKER",
		"DEBUG_STANDALONE_MODULE_ID",
		"DEBUG_STANDALONE_SIMULATION_TYPE",
	]
	for key in keys:
		var env_val: String = OS.get_environment(key).strip_edges()
		if env_val != "":
			_values[key] = env_val


func _load_config_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		push_warning("EnvConfig: failed to load %s" % path)
		return
	if cfg.has_section("env"):
		for key in cfg.get_section_keys("env"):
			_values[str(key)] = str(cfg.get_value("env", key, ""))
	if cfg.has_section("supabase"):
		# Friendly aliases for ConfigFile users.
		if cfg.has_section_key("supabase", "url"):
			_values["SUPABASE_URL"] = str(cfg.get_value("supabase", "url", ""))
		if cfg.has_section_key("supabase", "anon_key"):
			_values["SUPABASE_ANON_KEY"] = str(cfg.get_value("supabase", "anon_key", ""))
		if cfg.has_section_key("supabase", "enabled"):
			_values["SUPABASE_ENABLED"] = str(cfg.get_value("supabase", "enabled", true))
		if cfg.has_section_key("supabase", "preview_fallback"):
			_values["SUPABASE_PREVIEW_FALLBACK"] = str(cfg.get_value("supabase", "preview_fallback", false))


func _load_dotenv_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("EnvConfig: cannot open %s" % path)
		return
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		if line.begins_with("export "):
			line = line.substr(7).strip_edges()
		var eq: int = line.find("=")
		if eq <= 0:
			continue
		var key: String = line.substr(0, eq).strip_edges()
		var value: String = line.substr(eq + 1).strip_edges()
		if (value.begins_with("\"") and value.ends_with("\"")) or (value.begins_with("'") and value.ends_with("'")):
			value = value.substr(1, value.length() - 2)
		_values[key] = value
	file.close()
