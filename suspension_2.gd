extends RayCast3D

@onready var chassis: RigidBody3D = get_parent().get_parent()

@export var is_front_wheel: bool
@onready var tire_circumference: float = PI * chassis.rear_wheel_radius * 2.0
var last_pos:Vector3

var previous_spring_length: float = 0.0
var front_angle = 0
var rear_angle = 0
var suspension_rest_distance
var wheel_radius
var lateral_force: float = 0.0

@onready var parent_node: Node3D = get_parent()

@onready var tires_035: MeshInstance3D = $Tires_035
@onready var dust: GPUParticles3D = $Node3D


func _ready() -> void:
	add_exception(chassis)

func _physics_process(delta: float) -> void:
	if chassis.rear_suspension_rest_distance > chassis.front_suspension_rest_distance:
		front_angle = -asin(abs(abs(chassis.rear_suspension_rest_distance)-abs(chassis.front_suspension_rest_distance)) / chassis.lenght_of_vehicle)
		rear_angle = -asin(abs(abs(chassis.front_suspension_rest_distance)-abs(chassis.rear_suspension_rest_distance)) / chassis.lenght_of_vehicle)
	else:
		front_angle = asin(abs(abs(chassis.front_suspension_rest_distance)-abs(chassis.rear_suspension_rest_distance)) / chassis.lenght_of_vehicle)
		rear_angle = asin(abs(abs(chassis.rear_suspension_rest_distance)-abs(chassis.front_suspension_rest_distance)) / chassis.lenght_of_vehicle)
		
	if is_front_wheel:
		#parent_node.rotation.x = lerp(parent_node.rotation.x, front_angle, 0.1)
		#suspension_rest_distance = chassis.front_suspension_rest_distance
		wheel_radius = chassis.front_wheel_radius
	
		if chassis.steering_rotation !=0:
			var angle = clamp(rotation.y + chassis.steering_rotation, -chassis.steering_angle, chassis.steering_angle)
			var new_rotation = angle * delta
			rotation.y = lerp(rotation.y, new_rotation, 0.2)
		else:
			rotation.y = lerp(rotation.y, 0.0, 0.3)
	else:
		#parent_node.rotation.x = lerp(parent_node.rotation.x, rear_angle, 0.1)
		#suspension_rest_distance = chassis.rear_suspension_rest_distance
		wheel_radius = chassis.rear_wheel_radius
		
	suspension_rest_distance = chassis.actual_suspension_rest_distance
	spin_wheel_mesh()
	if is_colliding() && chassis.linear_velocity.length() > 5:
		dust.emitting = true
	else:
		dust.set_emitting(false)

	if is_colliding():
		var collision_point = get_collision_point()
		apply_lateral_force(collision_point, delta)
		apply_friction(collision_point)
		acceleration(collision_point)
		suspension(delta, collision_point)
		set_dust_position(to_local(get_collision_point()).y)
		if to_local(get_collision_point()).y <= -1:
			set_wheel_position(-suspension_rest_distance)
		else:
			set_wheel_position(to_local(get_collision_point()).y + wheel_radius)
	else:
		set_wheel_position(-suspension_rest_distance)
		
func spin_wheel_mesh() -> void:
	var move_dir: float = 1 if chassis.linear_velocity.dot(chassis.basis.z) > 0 else -1
	#var move_dir: float = sign(chassis.linear_velocity.dot(chassis.basis.z))

	var pos_diff: float = global_position.distance_to(last_pos)
	var spin
	if !is_front_wheel and !chassis.acceleration_input == 0:
		spin = ((pos_diff * move_dir) / tire_circumference) * 1440
	else:
		spin = ((pos_diff * move_dir) / tire_circumference) * 360

	tires_035.rotate_x(deg_to_rad(spin))
	dust.rotate_x(deg_to_rad(spin))
	last_pos = global_position
	
func set_wheel_position(new_y_position: float):
	#if get_name() == "FL":
	tires_035.position.y = lerp(tires_035.position.y, new_y_position, 0.75)

func set_dust_position(new_y_position: float):
	dust.position.y = lerp(tires_035.position.y, new_y_position, 0.75)
	#dust.position.z = -0.25
func apply_lateral_force(collision_point, delta):
	var direction: Vector3 = global_basis.x
	var state: = PhysicsServer3D.body_get_direct_state(chassis.get_rid())
	var tire_world_velocity: = state.get_velocity_at_local_position(global_position - chassis.global_position )
	var lateral_velocity: float = direction.dot(tire_world_velocity)
	
	var grip = chassis.rear_tire_grip
	
	if is_front_wheel:
		grip = chassis.front_tire_grip
		
	var desired_velocity_change: float = -lateral_velocity * grip
	lateral_force = desired_velocity_change / delta
	
	chassis.apply_force(direction * lateral_force, collision_point - chassis.global_position)
	
	if chassis.debug:
		DebugDraw3D.draw_arrow(global_position, global_position + (direction * lateral_force / 100), Color.RED, 0.1, true)

func get_point_velocity(point: Vector3) -> Vector3:
	return chassis.linear_velocity + chassis.angular_velocity.cross(point - chassis.global_position)

func apply_friction(collision_point):
	var direction: Vector3 = global_basis.z
	var tire_velocity: Vector3 = get_point_velocity(global_position)
	var friction = direction.dot(tire_velocity) * chassis.mass / 5
	
	chassis.apply_force(-direction * friction, collision_point - chassis.global_position)
	
	var point = Vector3(collision_point.x, collision_point.y + chassis.rear_wheel_radius, collision_point.z)
	
	if chassis.debug:
		DebugDraw3D.draw_arrow(point, point + (-direction * friction * 2) / 100, Color.BLUE_VIOLET, 0.1, true)

func acceleration(collision_point):
	if is_front_wheel:
		return
		
	var acceleration_direction = global_basis.z
	
	var torque = chassis.acceleration_input * chassis.engine_power
	
	var point = Vector3(collision_point.x, collision_point.y, collision_point.z)
	
	chassis.apply_central_force(acceleration_direction * torque)
	#chassis.apply_force(acceleration_direction * torque, (point - chassis.global_position))
	
	if chassis.debug:
		DebugDraw3D.draw_arrow(point, point + (acceleration_direction * torque) / 100, Color.BLUE, 0.1, true)
	
func suspension(delta, collision_point):
	var spring_length
	var spring_force
	var suspension_direction = global_basis.y
	
	var raycast_origin = global_position
	var raycast_destination = collision_point
	var distance = raycast_destination.distance_to(raycast_origin)
	
	spring_length = clamp(distance - wheel_radius, 0, chassis.actual_suspension_rest_distance)
	spring_force = chassis.spring_strength * (chassis.actual_suspension_rest_distance - spring_length)

	var spring_velocity = (previous_spring_length - spring_length) / delta
	var damper_force = chassis.spring_damper * spring_velocity
	var suspension_force = basis.y * (spring_force + damper_force)
	
	previous_spring_length = spring_length
	
	var point = Vector3(collision_point.x, collision_point.y + wheel_radius, collision_point.z)
	
	chassis.apply_force(suspension_direction * suspension_force, point - chassis.global_position)
	
	if chassis.debug:
		#DebugDraw3D.draw_sphere(point, 0.1)
		DebugDraw3D.draw_arrow(global_position, to_global(position + Vector3(-position.x, (suspension_force.y / 100), -position.z)), Color.GREEN, 0.1, true)
	
