extends Node3D

@export var shell_scene: PackedScene

func eject_shell() -> void:
	#Engine.time_scale = 0.05 # DEBUG:
	var newBullet: Node3D = shell_scene.instantiate()
	get_tree().root.add_child(newBullet)
	newBullet.global_position = global_position
	# This part works.
	newBullet.global_rotation = Vector3(0,randf_range(0,360),0)

	var eject_dir = self.global_transform.basis.x.normalized()
	var impulse = eject_dir * 0.52 + Vector3.UP * 0.2 + Vector3.LEFT * 0.3
	# works: var impulse = eject_dir * .2 + Vector3.UP * randf_range(0.2, 0.4) + Vector3.LEFT * randf_range(0.2, 0.4)
	newBullet.apply_impulse(impulse)
