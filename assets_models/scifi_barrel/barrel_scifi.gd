extends RigidBody3D

@export var vfx_explosion: PackedScene
@export var explosion_strength: float = 30.0
@export var health: int = 10
#
@onready var explosion_area_3d: Area3D = $ExplosionArea3D

func do_explosion_radius() -> void:
	for body in explosion_area_3d.get_overlapping_bodies():
		#if body.is_in_group("barrels"):
		# CRASH: Infinite recurrsion!!!
		#if body.name.begins_with("BarrelScifi"):
		#	body.explode()
		
		# WORKS!!
		if body is RigidBody3D:
			var direction = (body.global_transform.origin - global_transform.origin).normalized()
			body.apply_central_impulse(direction * explosion_strength)

func explode() -> void:
	# ----------------
	# 1: stop collisions (prevent "air" from stopping player movement)
	# ----------------
	collision_layer = 0
	# ----------------
	# 2: explosion VFX
	# ----------------
	var vfx = vfx_explosion.instantiate()
	get_tree().root.add_child(vfx)
	vfx.global_position = global_position
	# Two explosions actually looks even better!
	var vfx2 = vfx_explosion.instantiate()
	get_tree().root.add_child(vfx2)
	vfx2.global_position = Vector3(global_position.x, global_position.y+0.8, global_position.z)

	# 0: NEW!
	do_explosion_radius()

	# ----------------
	# 3: audio, scale, and fade away
	# ----------------
	$AnimationPlayer.play("explode")
	await $AnimationPlayer.animation_finished
	queue_free()

func take_damage(amount: int, direction_of_impact: Vector3) -> void:
	health -= amount
	#print("Ouch! Barrel took ", amount, " damage. Health now: ", health)
	if health <= 0:
		explode()
