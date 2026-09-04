extends Node

## Detects device capability and applies low-end-friendly 3D/UI settings.

enum Quality { HIGH, MEDIUM, LOW }

signal quality_changed(quality: Quality)

var quality: Quality = Quality.MEDIUM
var max_fps: int = 60
var viewport_scale: float = 1.0
var auto_rotate_speed: float = 0.85
var enable_page_motion: bool = true
var enable_model_intro: bool = true
var subviewport_update_when_visible_only: bool = false


func _ready() -> void:
	_detect_and_apply()
	get_tree().root.size_changed.connect(_on_window_resized)


func _detect_and_apply() -> void:
	var screen := DisplayServer.screen_get_size()
	var pixels := screen.x * screen.y
	var dpi := DisplayServer.screen_get_dpi()
	var low_end := false

	# Heuristics: small screens, low DPI, or very narrow phones.
	if pixels > 0 and pixels < 1_200_000:
		low_end = true
	if dpi > 0 and dpi < 160:
		low_end = true
	if screen.x > 0 and screen.x < 720:
		low_end = true
	if OS.get_name() == "Android" and pixels > 0 and pixels < 2_100_000:
		# Mid/low Android phones benefit from medium by default.
		if pixels < 1_600_000:
			low_end = true

	if low_end:
		set_quality(Quality.LOW)
	elif pixels >= 2_500_000:
		set_quality(Quality.HIGH)
	else:
		set_quality(Quality.MEDIUM)


func set_quality(new_quality: Quality) -> void:
	quality = new_quality
	match quality:
		Quality.HIGH:
			max_fps = 60
			viewport_scale = 1.0
			auto_rotate_speed = 0.85
			enable_page_motion = true
			enable_model_intro = true
			subviewport_update_when_visible_only = false
		Quality.MEDIUM:
			max_fps = 45
			viewport_scale = 0.85
			auto_rotate_speed = 0.7
			enable_page_motion = true
			enable_model_intro = true
			subviewport_update_when_visible_only = false
		Quality.LOW:
			max_fps = 30
			viewport_scale = 0.55
			auto_rotate_speed = 0.45
			enable_page_motion = true
			enable_model_intro = false
			subviewport_update_when_visible_only = true

	Engine.max_fps = max_fps
	quality_changed.emit(quality)


func scaled_viewport_size(base: Vector2i) -> Vector2i:
	var w := maxi(int(float(base.x) * viewport_scale), 160)
	var h := maxi(int(float(base.y) * viewport_scale), 120)
	# Keep even dimensions for nicer GPU alignment.
	if w % 2 != 0:
		w += 1
	if h % 2 != 0:
		h += 1
	return Vector2i(w, h)


func apply_to_subviewport(sv: SubViewport, container: Control = null) -> void:
	if sv == null:
		return
	var target := Vector2i(640, 360)
	if container != null and container.size.x > 8.0 and container.size.y > 8.0:
		target = Vector2i(int(container.size.x), int(container.size.y))
	elif sv.size.x > 0 and sv.size.y > 0:
		target = sv.size
	sv.size = scaled_viewport_size(target)
	if subviewport_update_when_visible_only:
		sv.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	else:
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _on_window_resized() -> void:
	# Re-check on orientation / foldable changes.
	_detect_and_apply()
