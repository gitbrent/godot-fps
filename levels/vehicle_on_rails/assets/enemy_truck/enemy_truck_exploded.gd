extends Node3D

signal enemy_truck_exploded

#region vars
@export_group("Props: Explosion")
@export var vfx_explosion: PackedScene = preload("res://levels/vehicle_on_rails/assets/enemy_truck/vfx_explosion/vfx_explosion.tscn")
@export var broken_model: PackedScene = preload("res://levels/vehicle_on_rails/assets/enemy_truck/enemy_truck_exploded.tscn")
@export var explosion_strength: float = 30.0
# ONREADY
@onready var sound_explosion: AudioStreamPlayer = $Explosion
@onready var explosion_area_3d: Area3D = $ExplosionArea3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
#endregion

func do_explode() -> void:
	# 1: explosion VFX
	_handle_explode()
	# 2: explosion physics
	_do_explosion_radius()
	# 3:
	emit_signal("enemy_truck_exploded")

func _handle_explode() -> void:
	# ----------------
	# 2: explosion VFX
	# ----------------
	var vfx1 = vfx_explosion.instantiate()
	get_tree().root.add_child(vfx1)
	vfx1.global_position = global_position
	# (two explosions actually looks better than one!)
	var vfx2 = vfx_explosion.instantiate()
	get_tree().root.add_child(vfx2)
	vfx2.global_position = Vector3(global_position.x, global_position.y+0.8, global_position.z)
	# 3:
	_do_explode_into_pieces()
	# ----------------
	# 3: audio, scale, and fade away
	# ----------------
	animation_player.play("explode")
	await animation_player.animation_finished
	# ----------------
	# LAST: free node
	# ----------------
	queue_free()


func _do_explode_into_pieces():
	# --- 2. Apply forces to each piece ---
	var base_intensity = 7.5
	var torque_intensity = 10.0

	# The center of the explosion is this truck's position
	var explosion_center = self.global_position
	
	for piece in self.get_children():
		# Ensure we are only affecting RigidBody3D nodes
		if piece is RigidBody3D:
			# Calculate a unique intensity for this piece
			var final_intensity = base_intensity + randf_range(-5.0, 5.0)
			# Calculate the outward direction vector
			var direction = (piece.global_position - explosion_center).normalized()
			var final_direction = (direction + Vector3.UP * 0.5).normalized() # Mix in upward force
			# Apply the push outwards
			piece.apply_central_impulse(final_direction * final_intensity)
			# Apply a random tumble/spin
			var random_torque = Vector3(randf(), randf(), randf()).normalized() * torque_intensity
			piece.apply_torque_impulse(random_torque)

## Impact other nearby physics objects
func _do_explosion_radius() -> void:
	for body in explosion_area_3d.get_overlapping_bodies():
		if body is RigidBody3D:
			var direction = (body.global_transform.origin - global_transform.origin).normalized()
			body.apply_central_impulse(direction * explosion_strength)
