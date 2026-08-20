#extends Control
#
#@export var model: PackedScene
#
#
#@onready var camera: Camera3D = $SubViewportContainer/SubViewport/World/Camera
#
#var model_instance: Node3D
#var is_dragging := false
#var last_mouse_position := Vector2.ZERO
#
#func _ready():
	#if model:
		#var instance = model.instantiate()
		#print("Model Type: ", instance.get_class())
		#print("Is Node3D: ", instance is Node3D)
		#model_instance = model.instantiate()
		#$SubViewportContainer/SubViewport/World.add_child(model_instance)
#
#func get_3d_object_at_mouse(mouse_position: Vector2):
	#var viewport_size = $SubViewportContainer.size
#
	#var viewport_position = mouse_position
#
	#var from = camera.project_ray_origin(viewport_position)
	#var direction = camera.project_ray_normal(viewport_position)
#
	#var to = from + direction * 1000.0
#
	#var space_state = camera.get_world_3d().direct_space_state
#
	#var query = PhysicsRayQueryParameters3D.create(from, to)
#
	#return space_state.intersect_ray(query)
#
#func _gui_input(event):
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#is_dragging = event.pressed
			#last_mouse_position = event.position
			#print("Mouse button: ", event.pressed)
#
	#if event is InputEventMouseMotion:
		#print("Mouse moving: ", event.position)
#
#func _gui_input(event):
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#var hit = get_3d_object_at_mouse(event.position)
#
			#if hit:
				#print("3D HIT: ", hit.collider.name)
			#else:
				#print("3D HIT: nothing")
#
#func _process(_delta):
	#if is_dragging and model_instance is Node3D:
		#var mouse_position = get_global_mouse_position()
		#var delta = mouse_position - last_mouse_position
		#model_instance.rotate_y(delta.x * 0.01)
		#model_instance.rotate_x(delta.y * 0.01)
		#last_mouse_position = mouse_position

extends Control

@export var model: PackedScene
#var model := preload("res://core/components/models/TextComponent.tscn").instantiate()

@onready var camera: Camera3D = $SubViewportContainer/SubViewport/World/Camera

var model_instance: Node3D

var is_dragging := false
var last_mouse_position := Vector2.ZERO

var zoom_speed := 0.5
var min_zoom := 2.0
var max_zoom := 10.0

func _ready():
	if model:
		model_instance = model.instantiate()
		#model_instance = model
		$SubViewportContainer/SubViewport/World.add_child(model_instance)

#func _gui_input(event):
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#is_dragging = event.pressed
			#last_mouse_position = event.position

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			last_mouse_position = event.position

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-zoom_speed)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(zoom_speed)


func zoom_camera(amount: float):
	camera.position.z = clamp(
		camera.position.z + amount,
		min_zoom,
		max_zoom
	)

func _process(_delta):
	if is_dragging and model_instance is Node3D:
		var mouse_position = get_global_mouse_position()
		var delta = mouse_position - last_mouse_position

		model_instance.rotate_y(delta.x * 0.01)
		model_instance.rotate_x(delta.y * 0.01)

		last_mouse_position = mouse_position
