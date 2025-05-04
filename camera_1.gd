extends Camera3D

@onready var rigid_body_3d: RigidBody3D = $"../RigidBody3D"
	
func _physics_process(delta: float) -> void:
	position = lerp(position, rigid_body_3d.position + Vector3(0, 15, 14), 0.25)
