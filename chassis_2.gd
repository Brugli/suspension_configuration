extends RigidBody3D

@export var debug : bool

@export var front_suspension_rest_distance: float = 0.5
@export var rear_suspension_rest_distance: float = 0.5
@export var actual_suspension_rest_distance: float = 0.5
@export var lenght_of_vehicle: float = 3
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
@onready var steering_rotation: float = 0
var front_angle: float = 0
var rear_angle: float = 0
var body_offset : float

@onready var body_node: Node3D = $body_node
@onready var physics_node: Node3D = $body_node/physics_node
@onready var bl: RayCast3D = $Node3D3/BL
@onready var ray_cast_3d: RayCast3D = $RayCast3D

var last_x_rotation
var last_z_rotation
var proportional
var integral
@export var target : float = 0.0

var tilt
var roll

func _init() -> void:
	last_x_rotation = rotation_degrees.x
	last_z_rotation = rotation_degrees.z
	integral = 0.0
	
func _physics_process(delta: float) -> void:
	acceleration_input = Input.get_axis("reverse", "forward")
	acceleration_input = clamp(acceleration_input, -0.75, 1)
	steering_input = Input.get_axis("turn_right", "turn_left")
	steering_rotation = steering_input * steering_angle
	
	if not ray_cast_3d.is_colliding():
		set_angular_damp(1.5)
		var input_x = update_x_angle(rotation_degrees.x, target, delta)
		var input_z = update_z_angle(rotation_degrees.z, target, delta)
		apply_torque(Vector3(basis.x * input_x))
		apply_torque(Vector3(basis.z * input_z))
		tilt = 0.0
		roll = 0.0
	else:
		tilt = bl.lateral_force / 50 * linear_velocity.length() / 300
		roll = -acceleration_input * 2 * (linear_velocity.length()) / 400
		set_angular_damp(0)
	
	if !rear_suspension_rest_distance == front_suspension_rest_distance:
		if rear_suspension_rest_distance > front_suspension_rest_distance:
			front_angle = asin(abs(abs(rear_suspension_rest_distance)-abs(front_suspension_rest_distance)) / lenght_of_vehicle)
			body_offset = ((lenght_of_vehicle*0.5) * sin(front_angle)) + 0.5 + front_suspension_rest_distance
		elif rear_suspension_rest_distance < front_suspension_rest_distance:
			front_angle = -asin(abs(abs(front_suspension_rest_distance)-abs(rear_suspension_rest_distance)) / lenght_of_vehicle)
			body_offset = ((lenght_of_vehicle*0.5) * sin(-front_angle)) + 0.5 + rear_suspension_rest_distance
		body_node.position.y = body_offset
		body_node.rotation.x = front_angle * 0.5
	else:
		body_node.position.y = front_suspension_rest_distance + 0.5
		body_node.rotation.x = 0
		
	if Input.is_action_pressed("handbrake"):
		front_tire_grip = lerp(front_tire_grip, 0.35, 0.1)
		rear_tire_grip = lerp(rear_tire_grip, 0.2, 0.1)
	elif not steering_input == 0:
		front_tire_grip = lerp(front_tire_grip, 0.6, 0.1)
		rear_tire_grip = lerp(rear_tire_grip, 0.5, 0.1)
	else:
		front_tire_grip = lerp(front_tire_grip, 0.5, 0.1)
		rear_tire_grip = lerp(rear_tire_grip, 0.5, 0.1)
	
	physics_node.rotation_degrees.z = clamp(physics_node.rotation_degrees.z, -15, 15)
	physics_node.rotation.z = lerp(physics_node.rotation.z, tilt / 1.5, 0.05)
	physics_node.rotation_degrees.x = clamp(physics_node.rotation_degrees.x, -5, 10)
	physics_node.rotation.x = lerp(physics_node.rotation.x, roll / 1.5 , 0.05)
	
func update_x_angle(current_angle: float, target_angle: float, delta: float) -> float:
	if delta <= 0:
		push_error("delta must be greater than 0")
		return 0.0

	var error = target_angle - current_angle
	
	if error > 180.0:
		proportional = error - 360
	else:
		proportional = error
		
	var derivative = current_angle - last_x_rotation
	last_x_rotation = current_angle
	
	integral = integral + current_angle * -0.1
	
	var P : float = proportional * 25
	var I : float = clamp(integral, -10, 10)
	var D : float = derivative * -250
	var result = P + I + D
	return clamp(result, -5, 5)
	
func update_z_angle(current_angle: float, target_angle: float, delta: float) -> float:
	if delta <= 0:
		push_error("delta must be greater than 0")
		return 0.0

	var error = target_angle - current_angle
	
	if error > 180.0:
		proportional = error - 360
	else:
		proportional = error
		
	var derivative = current_angle - last_z_rotation
	last_z_rotation = current_angle
	
	integral = integral + current_angle * -0.1
	
	var P : float = proportional * 50
	var I : float = clamp(integral, -10, 10)
	var D : float = derivative * -1000
	var result = P + I + D
	return clamp(result, -250, 250)
