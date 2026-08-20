extends Node3D

@onready var model_pivot: Node3D = $ModelPivot
@onready var model_container: Node3D = $ModelPivot/ModelContainer
@onready var camera: Camera3D = $Camera3D

var rotation_x := 0.0
var rotation_y := 0.0

var rotation_speed := 0.001
var zoom_speed := 0.2
var pan_speed := 0.2

var touches: Dictionary = {}
var previous_finger_1 := Vector2.ZERO
var previous_finger_2 := Vector2.ZERO
var previous_center := Vector2.ZERO

var is_rotating := false
var is_panning := false

var last_mouse_position := Vector2.ZERO

func setup(rs: float, zs: float, ps: float) -> void:
	rotation_speed = rs
	zoom_speed = zs
	pan_speed = ps

func _ready() -> void:
	#pass
	setting_model()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_rotating = event.pressed
			last_mouse_position = event.position

		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
			last_mouse_position = event.position

		# Mouse wheel
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.z -= zoom_speed

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.z += zoom_speed
			
	elif event is InputEventMouseMotion:
		var delta = event.position - last_mouse_position
		last_mouse_position = event.position

		if is_rotating:
			model_pivot.rotate_y(-delta.x * rotation_speed)
			model_pivot.rotate_x(-delta.y * rotation_speed)

		elif is_panning:
			camera.position.x -= delta.x * pan_speed
			camera.position.y += delta.y * pan_speed
	
	### TOUCH SCREEN ###
	
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
			
			if touches.size() == 2:
				previous_finger_1 = touches.values()[0]
				previous_finger_2 = touches.values()[1]
				previous_center = (previous_finger_1 + previous_finger_2) / 2.0
		else:
			touches.erase(event.index)
			if touches.size() < 2:
				previous_finger_1 = Vector2.ZERO
				previous_finger_2 = Vector2.ZERO
				previous_center = Vector2.ZERO
		
	elif event is InputEventScreenDrag:
		touches[event.index] = event.position
		
		if touches.size() == 1:
			model_pivot.rotation.x -= -event.screen_relative.y * rotation_speed
			model_pivot.rotation.y -= -event.screen_relative.x * rotation_speed
		elif touches.size() == 2:
			var positions = touches.values()
			
			var finger_1: Vector2 = positions[0]
			var finger_2: Vector2 = positions[1]
			
			var curr_distance := finger_1.distance_to(finger_2)
			
			var previous_distance := previous_finger_1.distance_to(previous_finger_2)
			
			print("Finger 1: ", finger_1)
			print("Finger 2: ", finger_2)
			print("Current Distance: ", curr_distance)
			
			var distance_change := curr_distance - previous_distance
			camera.position.z -= distance_change * zoom_speed
			
			print("Distance Change: ", distance_change)
			print("Camera Position: ", camera.position.z)
			print("Position: ", camera.position.z - (distance_change * 0.01))
			
			var curr_center := (finger_1 + finger_2) / 2.0
			print("Current Center: ", curr_center)
			
			var curr_movement := curr_center - previous_center
			print("Current Movement: ", curr_movement)
			
			model_pivot.position.x += curr_movement.x * pan_speed
			model_pivot.position.y -= curr_movement.y * pan_speed
			
			previous_finger_1 = finger_1
			previous_finger_2 = finger_2
			previous_center = curr_center

#func reset() -> void:
	#model_container.global_position = Vector3(0,0,0)
	#model_pivot.global_position = Vector3(0,0,0)

func reset() -> void:
	model_pivot.position = Vector3.ZERO
	model_pivot.rotation = Vector3.ZERO

#func setting_model() -> void:
	#var meshes := model_container.find_children(
		#"*",
		#"MeshInstance3D",
		#true,
		#false
	#)
	#
	#if meshes.is_empty():
		#print("No MeshInstance3D found.")
		#return
	#
	#var combined_aabb: AABB
	#var first_mesh := true
	#
	#for mesh in meshes:
		#var mesh_instance: MeshInstance3D = mesh
		#var mesh_aabb := mesh_instance.get_aabb()
		#
		#var transform := (
			#model_container.global_transform.affine_inverse()
			#* mesh_instance.global_transform
		#)
		#mesh_aabb = transform * mesh_aabb
		#
		#if first_mesh:
			#combined_aabb = mesh_aabb
			#first_mesh = false
		#else:
			#combined_aabb = combined_aabb.merge(mesh_aabb)
	#
	#var center := combined_aabb.get_center()
	#print("Model Center: ", center)
	#model_container.global_position = center


func setting_model() -> void:
	var meshes := model_container.find_children(
		"*",
		"MeshInstance3D",
		true,
		false
	)

	if meshes.is_empty():
		print("No MeshInstance3D found.")
		return

	var combined_aabb := AABB()
	var first_mesh := true

	# Calculate the combined bounding box in ModelContainer's local space
	for mesh in meshes:
		var mesh_instance: MeshInstance3D = mesh
		var mesh_aabb := mesh_instance.get_aabb()

		var transform := (
			model_container.global_transform.affine_inverse()
			* mesh_instance.global_transform
		)

		mesh_aabb = transform * mesh_aabb

		if first_mesh:
			combined_aabb = mesh_aabb
			first_mesh = false
		else:
			combined_aabb = combined_aabb.merge(mesh_aabb)

	var center := combined_aabb.get_center()

	print("Model Center: ", center)

	# Move the model itself so its visual center is at the origin.
	for child in model_container.get_children():
		if child is Node3D:
			child.position -= center

	# Keep the pivot centered at the world origin.
	model_pivot.position = Vector3.ZERO
	model_pivot.rotation = Vector3.ZERO
