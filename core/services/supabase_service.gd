extends Node

## Supabase REST client for optional progress sync + host session apply.
## Auth (login / sign-up / recover) lives in the native Compose app — not here.

signal progress_synced(ok: bool)

const SESSION_PATH := "user://supabase_session.cfg"
const PROGRESS_TABLE := "module_progress"

## Populated only from EnvConfig / OS env / configure() -- never hardcoded.
var supabase_url: String = ""
var supabase_anon_key: String = ""
var enabled: bool = true

var access_token: String = ""
var refresh_token: String = ""
var user_id: String = ""
var user_email: String = ""

var _http: HTTPRequest
var _last_json: Variant = null
var _last_response_code: int = 0
var _last_http_result: int = -1
var _busy: bool = false


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.name = "SupabaseHTTP"
	add_child(_http)
	_load_config()
	_load_session()


func is_configured() -> bool:
	return enabled and supabase_url != "" and supabase_anon_key != ""


func is_signed_in() -> bool:
	return access_token != "" and user_email != ""


func configure(url: String, anon_key: String, _unused_preview: bool = false) -> void:
	supabase_url = url.strip_edges()
	supabase_anon_key = anon_key.strip_edges()


## Called when Android hands off an already-authenticated session via prepare().
func apply_host_session(
	token: String,
	uid: String = "",
	email: String = "",
	refresh: String = ""
) -> void:
	access_token = token.strip_edges()
	refresh_token = refresh.strip_edges()
	user_id = uid.strip_edges()
	user_email = email.strip_edges()
	if access_token != "":
		_save_session()
	else:
		_clear_session()


## Editor / desktop only — never call from production hosted path.
func apply_debug_mock_session() -> void:
	access_token = "debug_mock_token"
	refresh_token = "debug_mock_refresh"
	user_id = "00000000-0000-4000-8000-000000000001"
	user_email = "debug@smartbuild.local"
	_save_session()


func clear_session() -> void:
	access_token = ""
	refresh_token = ""
	user_id = ""
	user_email = ""
	_clear_session()


func sync_module_progress(module_id: int, percent: float, guided_done: bool, assessment_done: bool) -> void:
	if not is_signed_in() or not is_configured():
		progress_synced.emit(false)
		return
	var row: Dictionary = {
		"user_id": user_id,
		"module_id": module_id,
		"percent": percent,
		"guided_done": guided_done,
		"assessment_done": assessment_done,
		"updated_at": Time.get_datetime_string_from_system(true)
	}
	var err: int = await _request(
		"%s/rest/v1/%s?on_conflict=user_id,module_id" % [supabase_url, PROGRESS_TABLE],
		HTTPClient.METHOD_POST,
		JSON.stringify(row),
		true,
		{"Prefer": "resolution=merge-duplicates"}
	)
	progress_synced.emit(err == OK)


func fetch_module_progress() -> Array:
	if not is_signed_in() or not is_configured():
		return []
	var err: int = await _request(
		"%s/rest/v1/%s?user_id=eq.%s&select=*" % [supabase_url, PROGRESS_TABLE, user_id],
		HTTPClient.METHOD_GET,
		"",
		true
	)
	if err != OK:
		return []
	if typeof(_last_json) == TYPE_ARRAY:
		return _last_json as Array
	return []


func _auth_headers(include_bearer: bool, extra: Dictionary = {}) -> PackedStringArray:
	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"apikey: %s" % supabase_anon_key
	]
	if include_bearer and access_token != "":
		headers.append("Authorization: Bearer %s" % access_token)
	else:
		headers.append("Authorization: Bearer %s" % supabase_anon_key)
	for key in extra.keys():
		headers.append("%s: %s" % [str(key), str(extra[key])])
	return headers


func _request(url: String, method: int, body: String, bearer: bool, extra: Dictionary = {}) -> int:
	var wait_frames := 0
	while _busy and wait_frames < 120:
		await get_tree().process_frame
		wait_frames += 1
	if _busy:
		return ERR_BUSY
	_busy = true
	_last_json = null
	_last_response_code = 0
	_last_http_result = -1
	var err: int = _http.request(url, _auth_headers(bearer, extra), method, body)
	if err != OK:
		_busy = false
		_last_json = {"msg": "Could not start HTTP request (%d)." % err}
		return err
	var result: Array = await _http.request_completed
	_busy = false
	_last_http_result = int(result[0])
	_last_response_code = int(result[1])
	var response_body: PackedByteArray = result[3] as PackedByteArray
	var text: String = response_body.get_string_from_utf8()
	if text != "":
		_last_json = JSON.parse_string(text)
	if _last_http_result != HTTPRequest.RESULT_SUCCESS:
		if typeof(_last_json) != TYPE_DICTIONARY:
			_last_json = {"msg": "Connection failed (result %d)." % _last_http_result}
		return FAILED
	if _last_response_code >= 200 and _last_response_code < 300:
		return OK
	return FAILED


func _env_node() -> Node:
	return get_node_or_null("/root/EnvConfig")


func _load_config() -> void:
	var env: Node = _env_node()
	if env != null:
		if env.has_method("reload"):
			env.call("reload")
		if env.has_method("get_value"):
			supabase_url = str(env.call("get_value", "SUPABASE_URL", ""))
			supabase_anon_key = str(env.call("get_value", "SUPABASE_ANON_KEY", ""))
		if env.has_method("get_bool"):
			enabled = bool(env.call("get_bool", "SUPABASE_ENABLED", true))
	if not is_configured():
		push_warning(
			"SupabaseService: not configured. Copy config/env.example to config/env.local "
			+ "or set SUPABASE_URL / SUPABASE_ANON_KEY environment variables."
		)


func _load_session() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SESSION_PATH) != OK:
		return
	access_token = str(cfg.get_value("session", "access_token", ""))
	refresh_token = str(cfg.get_value("session", "refresh_token", ""))
	user_id = str(cfg.get_value("session", "user_id", ""))
	user_email = str(cfg.get_value("session", "user_email", ""))


func _save_session() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("session", "access_token", access_token)
	cfg.set_value("session", "refresh_token", refresh_token)
	cfg.set_value("session", "user_id", user_id)
	cfg.set_value("session", "user_email", user_email)
	cfg.save(SESSION_PATH)


func _clear_session() -> void:
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(SESSION_PATH)
