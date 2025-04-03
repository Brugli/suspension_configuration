extends Camera3D

@onready var rigid_body_3d: RigidBody3D = $"../RigidBody3D"


func _process(delta):
	
	var player_position = Vector3(rigid_body_3d.position.x +4, rigid_body_3d.position.y + 1, rigid_body_3d.position.z + 4)
	position = player_position
