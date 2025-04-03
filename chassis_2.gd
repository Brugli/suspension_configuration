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

@export var rotation_force: float  = 100

var acceleration_input: float
var steering_input: float
var steering_rotation: float
var front_angle: float = 0
var rear_angle: float = 0
var body_offset : float

@onready var pitch_controller: PID_Controller = get_node("pid_controller")
@onready var roll_controller: PID_Controller = get_node("pid_controller")
@onready var body_node: Node3D = $body_node
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var physics_node: Node3D = $body_node/physics_node
@onready var bl: RayCast3D = $Node3D3/BL


#func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
#	var z_input = torque_controller.update_angle(transform.basis.get_euler( ).z, 0, get_physics_process_delta_time())
#	var z_torque: float = rotation_force * z_input
#	apply_torque(Vector3(0, 0, z_torque))
#	
#	var x_input = torque_controller.update_angle(transform.basis.get_euler( ).x, 0, get_physics_process_delta_time())
#	var x_torque: float = rotation_force * x_input
#	apply_torque(Vector3(x_torque, 0, 0))

func _process(delta: float) -> void:
	acceleration_input = Input.get_axis("reverse", "forward")
	steering_input = Input.get_axis("turn_right", "turn_left")
	steering_rotation = steering_input * steering_angle
	var z_input: float = roll_controller.update_angle(-rotation.z, 0, delta)
	var z_torque: float = rotation_force * z_input
	var x_input: float = pitch_controller.update_angle(-rotation.x, 0, delta)
	var x_torque: float = rotation_force * x_input
	
	apply_torque(Vector3(0, 0, z_torque))
	apply_torque(Vector3(x_torque, 0, 0))
	
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
		front_tire_grip = 0.35
		rear_tire_grip = 0.2
	elif steering_input > 0:
		front_tire_grip = 0.6
		rear_tire_grip = 0.5
	else:
		front_tire_grip = 0.5
		rear_tire_grip = 0.5
	
	var t = bl.lateral_force / 50 * linear_velocity.length() / 300
	var r = -acceleration_input * (linear_velocity.length()) / 400
	physics_node.rotation_degrees.z = clamp(physics_node.rotation_degrees.z, -15, 15)
	physics_node.rotation.z = lerp(physics_node.rotation.z, t, delta * 3)
	physics_node.rotation_degrees.x = clamp(physics_node.rotation_degrees.x, -5, 15)
	physics_node.rotation.x = lerp(physics_node.rotation.x, r, delta * 4)
	
	
	
