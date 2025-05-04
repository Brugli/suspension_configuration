extends Camera3D

@onready var rigid_body_3d: RigidBody3D = $"../RigidBody3D"
	
func _process(delta):
	position = lerp(position, rigid_body_3d.position + Vector3(0, 15, 14), 0.25)
