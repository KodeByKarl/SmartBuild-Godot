extends Node3D

## Intro slides should not run live 3D — simulations own 3D elsewhere.
const FREEZE_3D := true

@onready var worker_animation: AnimationPlayer = $Sketchfab_Scene/AnimationPlayer
@onready var camera_animation: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if FREEZE_3D:
		_freeze_preview()
		return
	if worker_animation != null:
		worker_animation.play("Armature|mixamo_com|Layer0")
	if camera_animation != null:
		camera_animation.play("CameraLoop")


func _freeze_preview() -> void:
	if worker_animation != null:
		worker_animation.stop()
	if camera_animation != null:
		camera_animation.stop()
	var viewport := get_parent() as SubViewport
	if viewport != null:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var container := viewport.get_parent() if viewport != null else null
	if container is CanvasItem:
		(container as CanvasItem).modulate = Color(0.75, 0.82, 0.88, 1.0)
	# Keep a still frame visible; live orbit/animation stays off.
	visible = true
