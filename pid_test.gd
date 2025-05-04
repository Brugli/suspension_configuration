extends RigidBody3D

var last_rotation
var input_y
var proportional
var integral

@export var target : float = 0.0

func _init() -> void:
	last_rotation = rotation_degrees.y
	integral = 0.0
	
func _process(delta: float) -> void:
	if Input.is_action_pressed("turn_right") or Input.is_action_pressed("turn_left"):
		input_y = Input.get_axis("turn_right", "turn_left") * 50
	else:
		input_y = update_angle(rotation_degrees.y, target, delta)
	apply_torque(Vector3(0, input_y, 0))

func update_angle(current_angle: float, target_angle: float, delta: float) -> float:
	if delta <= 0:
		push_error("delta must be greater than 0")
		return 0.0

	var error = target_angle - current_angle
	
	if error > 180.0:
		proportional = error - 360
	else:
		proportional = error
		
	var derivative = current_angle - last_rotation
	last_rotation = current_angle
	
	integral = integral + current_angle * -0.1
	
	var P : float = proportional * 50
	var I : float = clamp(integral, -10, 10)
	var D : float = derivative * -1000
	var result = P + I + D
	return clamp(result, -25, 25)
