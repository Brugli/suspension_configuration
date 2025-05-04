extends Node3D

@onready var camera_1: Camera3D = $Camera_1
@onready var chase_cam: Camera3D = $chase_cam

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("swap_cam"):
		if camera_1.current:
			camera_1.set_current(false)
			chase_cam.set_current(true)
		else:
			camera_1.set_current(true)
			chase_cam.set_current(false)
