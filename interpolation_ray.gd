extends RayCast3D

@onready var rigid_body_3d: RigidBody3D = $"../RigidBody3D"

var hit
var hit_normal
var hit_normal_z
var hit_normal_x

func _ready() -> void:
	position = rigid_body_3d.global_position

func _process(delta: float) -> void:
	position = rigid_body_3d.global_position
	if is_colliding():
		hit = get_collision_point()
		hit_normal = get_collision_normal()
		hit_normal_z = get_collision_normal().z
		hit_normal_x = get_collision_normal().x
