extends Camera3D
@onready var parent: RigidBody3D = $"../RigidBody3D"
@onready var tracking_node: Node3D = $Node3D5

func _process(delta: float) -> void:
	position = lerp(position, parent.position + Vector3(parent.basis.y * 3) + Vector3(parent.basis.z * -5), 0.25)
	tracking_node.position = parent.position + Vector3(parent.basis.z * 5)
	#transform.basis = parent.transform.basis
	look_at(tracking_node.position)
