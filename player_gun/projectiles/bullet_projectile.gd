extends RigidBody3D

@export var impact_scene: PackedScene
@export var speed: float = 100.0
@export var lifetime: float = 3.0

func setup(direction: Vector3) -> void:
	linear_velocity = direction.normalized() * speed  # 🚀 Set movement here
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func spawn_impact(pos: Vector3, normal: Vector3) -> void:
	print("Spawning impact at:", pos, "Normal:", normal)
	
	if not impact_scene:
		print("Impact scene not set!")
		return
	
	var impact = impact_scene.instantiate()
	get_tree().current_scene.add_child(impact)
	
	print("Impact spawned:", impact)
	
	impact.global_transform.origin = global_transform.origin + normal * 0.05  # Slight nudge
	impact.look_at(global_transform.origin + normal, Vector3.UP)

func _on_area_3d_body_entered(body: Node3D) -> void:
	print("bullet-projectile-hit: ", body.name)
	# STEP 1: damage
	if body.is_in_group("damageable") and body.has_method("take_damage"):
		body.take_damage(10)
	# STEP 2: hit
	if body.is_in_group("damageable") and body.has_method("show_hit"):
		body.show_hit(global_position)
	# STEP 3: remove bullet from world
	queue_free()
