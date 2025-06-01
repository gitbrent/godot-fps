extends RigidBody3D
class_name BulletProjectile

@export var impact_scene: PackedScene
@export var bullet_hole_decal: PackedScene
@export var speed: float = 100.0
@export var lifetime: float = 3.0
@export var damage: float = 10.0
var fire_direction: Vector3

func setup(direction: Vector3) -> void:
	fire_direction = direction
	linear_velocity = direction.normalized() * speed
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func spawn_impact(hit_position: Vector3, hit_normal: Vector3) -> void:
	#print("[b_p] spawn_impact: ", hit_position, " / ", hit_normal)
	# 1:
	if not impact_scene:
		print("Impact scene not set!")
		return
	# 2:
	var impact = impact_scene.instantiate()
	get_tree().current_scene.add_child(impact)
	impact.global_transform.origin = hit_position + hit_normal * 0.05
	impact.look_at(hit_position + hit_normal, Vector3.UP)

## WORKS!
func show_hit_decal(hit_position: Vector3, hit_normal: Vector3) -> void:
	# 1) instance the Decal
	var decal = bullet_hole_decal.instantiate() as Decal
	get_tree().current_scene.add_child(decal)

	# 2) offset it slightly to prevent z-fighting
	decal.global_transform.origin = hit_position + hit_normal * 0.005

	# 3) Face the decal OUTWARDS from the surface, aligned with the normal
	# We want the decal's +Z axis to point along the hit_normal.
	# Since Basis.looking_at points -Z at the target, we pass -hit_normal as the target direction.
	var target_direction = -hit_normal
	var up_vector = Vector3.UP

	# Handle the edge case where the normal is almost perfectly vertical (up or down)
	# In this case, Vector3.UP is parallel to the normal, and it can't determine "up".
	# Use a different perpendicular vector as the up_vector in such cases.
	if abs(hit_normal.dot(Vector3.UP)) > 0.999: # Check if normal is almost parallel to global UP
		up_vector = Vector3.FORWARD # Or Vector3.RIGHT, any vector not parallel to UP

	var new_basis = Basis.looking_at(target_direction, up_vector, true) # `true` for `is_global_up`
	decal.global_transform.basis = new_basis

	# 4) random spin around the decal's own normal for variety
	# The decal's local Z-axis is now aligned with the hit_normal.
	# So, rotate around the local Z-axis.
	decal.rotate_object_local(Vector3(0, 0, 1), randf_range(0, TAU))

	# Optional: Add a timer to queue_free the decal after a duration
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(decal.queue_free)

## WORKS! and is cool!
func show_red_dot_hit(hit_position: Vector3, hit_normal: Vector3):
	# 1: RED SPHERE
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED  # or Color(1, 0, 0)
	# 2:
	var red_impact_sphere = MeshInstance3D.new()
	red_impact_sphere.mesh = SphereMesh.new()
	red_impact_sphere.scale = Vector3.ONE * 0.05
	red_impact_sphere.material_override = mat
	get_tree().current_scene.add_child(red_impact_sphere)
	var spawn_position = hit_position + hit_normal * 0.0
	red_impact_sphere.global_transform.origin = spawn_position
	# 2:
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(red_impact_sphere.queue_free)

func _on_area_3d_body_entered(body: Node3D) -> void:
	#print("[bullet-projectile]-hit: ", body.name)
	var hit_position = global_transform.origin # Simple for now, but use actual contact point if available
	var hit_normal = -linear_velocity.normalized() # Simple estimate of surface normal (opposite of bullet direction)
	# STEP 1: damage
	if body.is_in_group("damageable") and body.has_method("take_damage"):
		body.take_damage(damage, fire_direction)
	# STEP 2: hit
	if body.is_in_group("damageable") and body.has_method("show_hit"):
		body.show_hit(global_position)
	# NEW: if hit node doesnt implement its own `show_hit`, then show default effect
	if body.is_in_group("damageable") and not body.has_method("show_hit"):
		#body.show_hit_decal(hit_position, hit_normal)
		spawn_impact(hit_position, hit_normal)
		show_hit_decal(hit_position, hit_normal)
		#show_red_dot_hit(hit_position, hit_normal)
	# STEP 3: remove bullet from world
	queue_free()
