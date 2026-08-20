extends Node3D

@export var object_id := "ram"

var dragging := false
var drag_plane: Plane


func _input_event(
	_camera: Camera3D,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:
				start_drag(event.position)
			else:
				end_drag(event.position)


func start_drag(screen_position: Vector2) -> void:

	dragging = true

	drag_plane = Plane(
		Vector3.FORWARD,
		global_position.z
	)


func end_drag(screen_position: Vector2) -> void:

	if not dragging:
		return

	dragging = false

	print("RAM DRAG ENDED")
