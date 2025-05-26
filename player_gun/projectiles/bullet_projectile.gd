extends RigidBody3D
class_name BulletProjectile

@export var impact_scene: PackedScene
@export var bullet_hole_decal: PackedScene
@export var speed: float = 100.0
@export var lifetime: float = 3.0
var fire_direction: Vector3

func setup(direction: Vector3) -> void:
	fire_direction = direction
	linear_velocity = direction.normalized() * speed
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func spawn_impact(hit_position: Vector3, hit_normal: Vector3) -> void:
	print("[b_p] spawn_impact: ", hit_position, " / ", hit_normal)
	# 1:
	if not impact_scene:
		print("Impact scene not set!")
		return
	# 2:
	var impact = impact_scene.instantiate()
	get_tree().current_scene.add_child(impact)
	impact.global_transform.origin = hit_position + hit_normal * 0.05
	impact.look_at(hit_position + hit_normal, Vector3.UP)

func show_hit_decal(hit_position: Vector3, hit_normal: Vector3) -> void:
	# 1) instance the Decal
	var decal = bullet_hole_decal.instantiate() as Decal
	get_tree().current_scene.add_child(decal)

	# 2) offset it slightly to prevent z-fighting
	decal.global_transform.origin = hit_position + hit_normal * 0.05

	# 3) face the decal INTO the surface
	#    look_at() makes the -Z axis point at the target, so we aim it at (pos - normal)
	decal.look_at(hit_position - hit_normal, Vector3.UP)

	# 4) random spin around the decal's own normal for variety
	decal.rotate_object_local(Vector3(0, 0, 1), randf_range(0, TAU))

	# 5) queue it up for cleanup
	#get_tree().create_timer(5.0).timeout.connect(decal.queue_free)

func ZZZZshow_hit_decal(hit_position: Vector3, hit_normal: Vector3) -> void:
	if not bullet_hole_decal:
		print("bullet_hole_decal not set!")
		return

	var decal = bullet_hole_decal.instantiate()
	get_tree().current_scene.add_child(decal)

	# Position just in front of the surface
	decal.global_position = hit_position + hit_normal * 0.05

	# Build a basis that points decal's Z toward the wall, and aligns up to prevent rotation issues
	var forward = -hit_normal.normalized()
	var right = forward.cross(Vector3.UP).normalized()
	var up = right.cross(forward).normalized()
	decal.global_transform = Transform3D(Basis(right, up, forward), decal.global_position)

	# Optional: rotate decal randomly around Z for visual variation
	#decal.rotate_object_local(Vector3(0, 0, 1), randf_range(0, TAU))

func ZZZshow_hit_decal(hit_position: Vector3, hit_normal: Vector3):
	if not bullet_hole_decal:
		push_warning("bullet_hole_decal not set!")
		return

	var bhole = bullet_hole_decal.instantiate()
	get_tree().current_scene.add_child(bhole)

	# Step 1: Move to surface + nudge outward slightly
	var spawn_position = hit_position + hit_normal * 0.01
	bhole.global_transform.origin = spawn_position

	# Step 2: Align Z to face into the surface
	#var up = abs(hit_normal.dot(Vector3.UP)) > 0.99 ? Vector3.FORWARD : Vector3.UP
	var up = Vector3.UP
	if abs(hit_normal.dot(Vector3.UP)) > 0.99:
		up = Vector3.FORWARD
	bhole.look_at(spawn_position - hit_normal, up)

	# Step 3: Optional random rotation around Z for variety
	bhole.rotate_object_local(Vector3(0, 0, 1), randf_range(0, TAU))

	# Step 4: DEBUG SPHERE — remove after testing
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED  # or Color(1, 0, 0)
	var debug = MeshInstance3D.new()
	debug.mesh = SphereMesh.new()
	debug.scale = Vector3.ONE * 0.05
	debug.material_override = mat
	get_tree().current_scene.add_child(debug)
	debug.global_transform.origin = spawn_position
	await get_tree().create_timer(0.4).timeout
	debug.queue_free()

func ZZshow_hit_decal(hit_position: Vector3, hit_normal: Vector3):
	if not bullet_hole_decal:
		print("bullet_hole_decal not set!")
		return

	var bhole = bullet_hole_decal.instantiate()
	get_tree().current_scene.add_child(bhole)

	# Position slightly offset along the normal to avoid z-fighting
	bhole.global_transform.origin = hit_position + hit_normal * 0.01

	# Align to the surface normal (Z axis should point out from the surface)
	var basis = Basis()
	basis.z = -hit_normal.normalized()
	basis.x = basis.z.cross(Vector3.UP).normalized()
	basis.y = basis.z.cross(basis.x).normalized()
	bhole.global_transform.basis = basis

	# Optional: randomize rotation around surface normal for variety
	bhole.rotate_object_local(Vector3(0, 0, 1), randf_range(0, TAU))

func Zshow_hit_decal(hit_position: Vector3, hit_normal: Vector3):
	# 1:
	if not bullet_hole_decal:
		print("bullet_hole_decal not set!")
		return
	# 2:
	var bhole = bullet_hole_decal.instantiate()
	get_tree().current_scene.add_child(bhole)
	# Offset slightly out to avoid Z-fighting
	bhole.global_transform.origin = hit_position + hit_normal * 0.05

	# Align the decal to the surface normal
	#bhole.look_at(hit_position + hit_normal, Vector3.UP) # Look at a point along the normal, with Y-axis up
	bhole.look_at(hit_position, hit_position + hit_normal)
	# You might need to rotate it manually if the QuadMesh's default orientation isn't correct
	#bhole.rotate_object_local(Vector3(0,0,1), deg_to_rad(randf_range(0, 360))) # Random rotation for variety

	# Optionally, fade out or remove after a delay to prevent too many decals
	#var timer = get_tree().create_timer(10.0) # Remove after 10 seconds
	#timer.timeout.connect(bhole.queue_free)

## BRENT: this works and is cool!
func show_red_dot_hit(hit_position: Vector3, hit_normal: Vector3):
	# Step 4: DEBUG SPHERE — remove after testing
	var spawn_position = hit_position + hit_normal * 0.01
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED  # or Color(1, 0, 0)
	var debug = MeshInstance3D.new()
	debug.mesh = SphereMesh.new()
	debug.scale = Vector3.ONE * 0.05
	debug.material_override = mat
	get_tree().current_scene.add_child(debug)
	debug.global_transform.origin = spawn_position
	await get_tree().create_timer(0.4).timeout
	debug.queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	#print("[bullet-projectile]-hit: ", body.name)
	# STEP 1: damage
	if body.is_in_group("damageable") and body.has_method("take_damage"):
		body.take_damage(10, fire_direction)
	# STEP 2: hit
	if body.is_in_group("damageable") and body.has_method("show_hit"):
		body.show_hit(global_position)
	# NEW: if hit node doesnt implement its own `show_hit`, then show default effect
	if body.is_in_group("damageable") and not body.has_method("show_hit"):
		var hit_position = global_transform.origin # Simple for now, but use actual contact point if available
		var hit_normal = -linear_velocity.normalized() # Simple estimate of surface normal (opposite of bullet direction)
		#body.show_hit_decal(hit_position, hit_normal)
		spawn_impact(hit_position, hit_normal)
		show_hit_decal(hit_position, hit_normal)
		show_red_dot_hit(hit_position, hit_normal)
	# STEP 3: remove bullet from world
	queue_free()
