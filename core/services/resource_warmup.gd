extends Node

## Session-wide PackedScene cache + threaded prefetch.
## Never call ResourceLoader.load() on a path that already has a threaded request.

const MODULE_SCENES: PackedStringArray = [
	"res://modules/module_0/Main.tscn",
	"res://modules/module_1/Main.tscn",
	"res://modules/module_2/Main.tscn",
	"res://modules/module_3/Main.tscn",
	"res://modules/module_4/Main.tscn",
]

const LAB_SCENES: PackedStringArray = [
	"res://core/scenes/ModuleShell.tscn",
	"res://core/scenes/InteractiveHardwareLab.tscn",
	"res://core/simulation/PcBuildBench.tscn",
	"res://core/simulation/NetworkLab.tscn",
	"res://core/simulation/ServerLab.tscn",
	"res://core/simulation/MaintenanceBench.tscn",
	"res://core/simulation/CrimpLab.tscn",
]

const MODULE_0_SLIDES: PackedStringArray = [
	"res://modules/module_0/slides/slide_1.tscn",
	"res://modules/module_0/slides/slide_2.tscn",
	"res://modules/module_0/slides/slide_3.tscn",
	"res://modules/module_0/slides/slide_4.tscn",
	"res://modules/module_0/slides/slide_5.tscn",
	"res://modules/module_0/slides/slide_6.tscn",
	"res://modules/module_0/slides/slide_7.tscn",
	"res://modules/module_0/slides/slide_8.tscn",
	"res://modules/module_0/slides/slide_9.tscn",
	"res://modules/module_0/slides/slide_10.tscn",
	"res://modules/module_0/slides/slide_11.tscn",
	"res://modules/module_0/slides/slide_12.tscn",
	"res://modules/module_0/slides/slide_13.tscn",
	"res://modules/module_0/slides/slide_14.tscn",
	"res://modules/module_0/slides/slide_15.tscn",
	"res://modules/module_0/slides/slide_16.tscn",
	"res://modules/module_0/slides/slide_17.tscn",
	"res://modules/module_0/slides/slide_18.tscn",
	"res://modules/module_0/slides/slide_19.tscn",
	"res://modules/module_0/slides/slide_20.tscn",
	"res://modules/module_0/slides/slide_21_completion.tscn",
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
	"res://assets/models/module_2/router/model.tscn",
	"res://assets/models/module_2/modem/model.tscn",
	"res://assets/models/module_2/switch/model.tscn",
	"res://assets/models/module_2/access_point/model.tscn",
	"res://assets/models/module_2/ethernet_cable/model.tscn",
	"res://assets/models/module_2/hub/model.tscn",
	"res://assets/models/module_2/nic/model.tscn",
	"res://assets/models/module_2/repeater/model.tscn",
	"res://assets/models/module_2/firewall/model.tscn",
	"res://assets/models/module_2/fiber_cable/model.tscn",
	"res://assets/models/module_2/patch_panel/model.tscn",
	"res://assets/models/module_2/rj45/model.tscn",
	"res://assets/models/module_2/crimper/model.tscn",
	"res://assets/models/module_2/cable_tester/model.tscn",
	"res://assets/models/module_2/monitor/model.tscn",
	"res://assets/models/module_2/keyboard/model.tscn",
	"res://assets/models/module_4/toolkit/model.tscn",
	"res://assets/models/module_4/diagnostic_pc/model.tscn",
]

var _cache: Dictionary = {}
var _warming := false


func warmup_engine() -> void:
	if _warming:
		return
	_warming = true
	# Cheap shells first so Home → module open is instant.
	prefetch_many(MODULE_SCENES)
	await get_tree().process_frame
	prefetch_many(LAB_SCENES)
	await get_tree().process_frame
	prefetch_many(_slice_paths(MODULE_0_SLIDES, 0, 8))
	await get_tree().process_frame
	prefetch_many(LIGHT_PROPS)
	await get_tree().process_frame
	prefetch_many(_slice_paths(MODULE_0_SLIDES, 8, MODULE_0_SLIDES.size()))
	await get_tree().process_frame
	prefetch_many(MODULE_0_PROPS)
	for module_id in [1, 2, 3, 4]:
		prefetch_module_pages(module_id)
		await get_tree().process_frame


func prefetch_module(module_id: int) -> void:
	if module_id >= 0 and module_id < MODULE_SCENES.size():
		prefetch(MODULE_SCENES[module_id])
	if module_id == 0:
		prefetch_many(MODULE_0_SLIDES)
		prefetch_many(MODULE_0_PROPS)
		prefetch_many(LAB_SCENES)
	else:
		prefetch_many(LAB_SCENES)
		prefetch_module_pages(module_id)


func prefetch_module_pages(module_id: int) -> void:
	if module_id < 1:
		return
	var data: Dictionary = ModuleContentRegistry.get_module(module_id)
	var pages: Array = data.get("pages", [])
	for page_index in pages.size():
		var page: Dictionary = pages[page_index] as Dictionary
		prefetch_many(paths_for_page(page))
		# Only the next few pages' props — warming every Sketchfab glTF at once
		# can stall low-end phones during the demo.
		if page_index >= 3:
			continue
		for title_variant in page.get("related_models", []):
			var item: Dictionary = _model_item_by_title(data, str(title_variant))
			var scene_path := str(item.get("scene_path", ""))
			if scene_path != "":
				prefetch(scene_path)


func paths_for_page(page: Dictionary) -> PackedStringArray:
	var paths: PackedStringArray = []
	var ptype := str(page.get("type", ""))
	var mode := str(page.get("sim_mode", ""))
	match ptype:
		"model_library":
			paths.append("res://core/scenes/InteractiveHardwareLab.tscn")
		"guided_simulation", "assessment":
			match mode:
				"pc_build":
					paths.append("res://core/simulation/PcBuildBench.tscn")
				"network_lab":
					paths.append("res://core/simulation/NetworkLab.tscn")
				"server_lab":
					paths.append("res://core/simulation/ServerLab.tscn")
				"maintenance_bench":
					paths.append("res://core/simulation/MaintenanceBench.tscn")
				"crimp_lab":
					paths.append("res://core/simulation/CrimpLab.tscn")
				"crossover_task":
					paths.append("res://core/simulation/CrimpLab.tscn")
					paths.append("res://core/simulation/NetworkLab.tscn")
	return paths


func _slice_paths(paths: PackedStringArray, begin: int, end: int) -> PackedStringArray:
	var out: PackedStringArray = []
	var last: int = mini(end, paths.size())
	for index in range(maxi(begin, 0), last):
		out.append(paths[index])
	return out


func prefetch_many(paths: PackedStringArray) -> void:
	for path in paths:
		prefetch(path)


func prefer_light_path(path: String) -> String:
	if path.ends_with(".gltf") or path.ends_with(".glb"):
		var light := path.get_base_dir().path_join("model.tscn")
		if ResourceLoader.exists(light):
			return light
	return path


func prefetch(path: String) -> void:
	path = prefer_light_path(path)
	if path == "" or _cache.has(path):
		return
	if not ResourceLoader.exists(path):
		return
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_take_threaded(path)
		return
	ResourceLoader.load_threaded_request(path)


func has_cached(path: String) -> bool:
	return path != "" and _cache.has(path)


## Non-blocking. Returns cache or a just-finished threaded load. Never sync-loads
## while a thread is running for the same path.
func get_packed(path: String) -> PackedScene:
	path = prefer_light_path(path)
	if path == "":
		return null
	if _cache.has(path):
		return _cache[path] as PackedScene
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		return _take_threaded(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return null
	if not ResourceLoader.exists(path):
		return null
	# Never block the UI thread on Sketchfab glTF — that is what froze Router.
	if path.ends_with(".gltf") or path.ends_with(".glb"):
		prefetch(path)
		return null
	var scene := load(path) as PackedScene
	if scene != null:
		_cache[path] = scene
	return scene


func await_packed(path: String, timeout_ms: int = 12000) -> PackedScene:
	var ready: PackedScene = get_packed(path)
	if ready != null:
		return ready
	prefetch(path)
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		ready = get_packed(path)
		if ready != null:
			return ready
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_FAILED:
			break
		await get_tree().process_frame
	return get_packed(path)


func _take_threaded(path: String) -> PackedScene:
	var status := ResourceLoader.load_threaded_get_status(path)
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		return null
	var res: Resource = ResourceLoader.load_threaded_get(path)
	if res is PackedScene:
		_cache[path] = res
		return res as PackedScene
	return null


func _model_item_by_title(module_data: Dictionary, title: String) -> Dictionary:
	for page_variant in module_data.get("pages", []):
		var page: Dictionary = page_variant as Dictionary
		if str(page.get("type", "")) != "model_library":
			continue
		for item_variant in page.get("items", []):
			var item: Dictionary = item_variant as Dictionary
			if str(item.get("title", "")) == title:
				return item
	return {}
