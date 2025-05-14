extends RigidBody3D

var has_clinked := false

func _ready():
	await get_tree().create_timer(3.0).timeout  # Despawn after 5 seconds
	queue_free()
