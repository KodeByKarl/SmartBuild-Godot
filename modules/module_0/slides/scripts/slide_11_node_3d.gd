extends Node3D

@onready var worker_animation: AnimationPlayer = $Sketchfab_Scene/AnimationPlayer
@onready var camera_animation: AnimationPlayer = $AnimationPlayer

func _ready():
	worker_animation.play("Armature|mixamo_com|Layer0")
	camera_animation.play("CameraLoop")
