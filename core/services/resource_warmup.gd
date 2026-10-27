extends Node

## Session-wide PackedScene cache + threaded prefetch.
## Never call ResourceLoader.load() on a path that already has a threaded request.
## Modules 1–4 share ModuleFlow (lesson pages + simulations); Module 1 also
## needs the 3D build bench. Modules 2–4 simulations run in the Android labs.

const MODULE_SCENES: PackedStringArray = [
	"res://modules/module_0/Main.tscn",
	"res://core/components/lesson/ModuleFlow.tscn",
]

const LAB_SCENES: PackedStringArray = [
	"res://core/simulation/PcBuildBench.tscn",
]

## Module 0 slides are data pages (Module0Content) built by the shared
## LessonDeck; only the deck scene loads.
const MODULE_0_SLIDES: PackedStringArray = [
	"res://core/components/lesson/LessonDeck.tscn",
]

const MODULE_0_PROPS: PackedStringArray = [
	"res://assets/models/shared/super_computer/scene.gltf",
	"res://assets/models/shared/mini_computer/mini_computer.glb",
	"res://assets/models/module_3/mainframe/scene.gltf",
	"res://assets/models/module_1/laptop/scene.gltf",
	"res://assets/models/shared/ipad/scene.gltf",
]

const LIGHT_PROPS: PackedStringArray = [
	"res://assets/models/module_1/_factory/part_model.tscn",
	"res://assets/models/module_1/chips/model.tscn",
	"res://assets/models/module_1/hdd/model.tscn",
	"res://assets/models/module_1/psu/model.tscn",
	"res://assets/models/module_1/atx/model.tscn",
	"res://assets/models/module_1/fan/model.tscn",
	"res://assets/models/module_1/antistatic/model.tscn",
	"res://assets/models/module_1/gpu/model.tscn",
	"res://assets/models/module_1/router/model.tscn",
	# Heavy authored glTFs the Module 1 bench installs on drop — loading them
	# synchronously at attach time froze the frame (CPU fan lag).
	"res://assets/models/module_1/cooler/model.tscn",
	"res://assets/models/module_1/motherboard/model.tscn",
]

const PRIORITY_LABS: PackedStringArray = [
	"res://core/components/lesson/ModuleFlow.tscn",
	"res://core/simulation/PcBuildBench.tscn",
]

var _cache: Dictionary = {}
var _warming := false


func warmup_engine() -> void:
	if _warming:
		return
	_warming = true
	prefetch_many(MODULE_SCENES)
	await get_tree().process_frame
	prefetch_many(LAB_SCENES)
	await get_tree().process_frame
	prefetch_many(_slice_paths(MODULE_0_SLIDES, 0, 8))
	await get_tree().process_frame
	prefetch_many(LIGHT_PROPS)
	await get_tree().process_frame
	prefetch_many(_slice_paths(MODULE_0_SLIDES, 8, MODULE_0_SLIDES.size()))
	# Module 0's heavy glTF props are NOT warmed here: they compete with the
	# Module 1 bench for loader threads. warmup_priority(0) loads them on demand.
	_warming = false


func warmup_priority(module_id: int) -> void:
	match module_id:
		0:
			prefetch_many(MODULE_0_SLIDES)
			prefetch_many(MODULE_0_PROPS)
			await await_packed("res://modules/module_0/Main.tscn", 12000)
		1:
			prefetch_many(PRIORITY_LABS)
			prefetch_many(LIGHT_PROPS)
			await await_packed("res://core/simulation/PcBuildBench.tscn", 15000)
		_:
			pass


func prefetch_module(module_id: int) -> void:
	match module_id:
		0:
			prefetch("res://modules/module_0/Main.tscn")
			prefetch_many(MODULE_0_SLIDES)
			prefetch_many(MODULE_0_PROPS)
		1:
			prefetch_many(PRIORITY_LABS)
			prefetch_many(LIGHT_PROPS)
		2, 3, 4:
			prefetch("res://core/components/lesson/ModuleFlow.tscn")
		_:
			pass


func prefetch(path: String) -> void:
	if path.is_empty() or _cache.has(path):
		return
	if not ResourceLoader.exists(path):
		return
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
		return
	var err := ResourceLoader.load_threaded_request(path)
	if err != OK:
		push_warning("ResourceWarmup.prefetch failed %s (%s)" % [path, error_string(err)])


func prefetch_many(paths: PackedStringArray) -> void:
	for path in paths:
		prefetch(path)


func get_packed(path: String) -> PackedScene:
	if path.is_empty():
		return null
	if _cache.has(path) and _cache[path] is PackedScene:
		return _cache[path] as PackedScene
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res: Resource = ResourceLoader.load_threaded_get(path)
		if res is PackedScene:
			_cache[path] = res
			return res as PackedScene
	if ResourceLoader.has_cached(path):
		var cached: Resource = ResourceLoader.load(path)
		if cached is PackedScene:
			_cache[path] = cached
			return cached as PackedScene
	return null


func await_packed(path: String, timeout_ms: int = 8000) -> PackedScene:
	if path.is_empty():
		return null
	var existing := get_packed(path)
	if existing != null:
		return existing
	prefetch(path)
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		var packed := get_packed(path)
		if packed != null:
			return packed
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_FAILED:
			push_warning("ResourceWarmup.await_packed failed: %s" % path)
			return null
		await get_tree().process_frame
	return get_packed(path)


## Prefer procedural/light model.tscn over heavy glTF when both exist.
func prefer_light_path(scene_path: String) -> String:
	if scene_path.is_empty():
		return scene_path
	if scene_path.ends_with("scene.gltf") or scene_path.ends_with("scene.glb"):
		var light := scene_path.get_base_dir().path_join("model.tscn")
		if ResourceLoader.exists(light):
			return light
	return scene_path


func _slice_paths(paths: PackedStringArray, start: int, end_exclusive: int) -> PackedStringArray:
	var out: PackedStringArray = []
	var i := maxi(start, 0)
	var stop := mini(end_exclusive, paths.size())
	while i < stop:
		out.append(paths[i])
		i += 1
	return out
