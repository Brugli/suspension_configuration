extends RigidBody3D

@export var debug : bool

@export var front_suspension_rest_distance: float = 0.5
@export var rear_suspension_rest_distance: float = 0.5
@export var spring_strength: float = 500
@export var spring_damper: float = 30
@export var front_wheel_radius: float = 0.25
@export var rear_wheel_radius: float = 0.25
@export var engine_power: float
@export var steering_angle: float = 20
@export var front_tire_grip: float = 1
@export var rear_tire_grip: float = 1

var acceleration_input: float
var steering_input: float
var steering_rotation: float

func _process(delta: float) -> void:
	acceleration_input = Input.get_axis("reverse", "forward")
	steering_input = Input.get_axis("turn_right", "turn_left")
	steering_rotation = steering_input * steering_angle
	
	if debug:
		DebugDraw3D.draw_sphere(center_of_mass, 0.1, Color.YELLOW, delta)
	#if linear_velocity.z <= 0.1 && linear_velocity.z >= -0.1:
	#	front_tire_grip = 1
	#	rear_tire_grip = 1
	if Input.is_action_pressed("handbrake"):
		front_tire_grip = 0.35
		rear_tire_grip = 0.2
	elif steering_input > 0:
		front_tire_grip = 0.6
		rear_tire_grip = 0.5
	else:
		front_tire_grip = 1
		rear_tire_grip = 1
