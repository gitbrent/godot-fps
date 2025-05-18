extends Node3D

#region vars
@export_group("Scene Children")
@export var bullet_scene: PackedScene
@export_group("Props")
@export var fire_rate: float = 2.0 # Bullets per second
#
@onready var muzzle_point: Node3D = $MuzzlePoint
@onready var muzzle_flash: MeshInstance3D = $MuzzlePoint/MuzzleFlash
#
var fire_cooldown: float = 0.0 # Cooldown starts at 0, ready to fire immediately
#endregion

func _ready() -> void:
	# 1: scene defaults
	muzzle_flash.visible = false

func _process(delta):
	# Decrease cooldown over time
	if fire_cooldown > 0.0:
		fire_cooldown -= delta
		if fire_cooldown < 0.0:
			fire_cooldown = 0.0 # Ensure it doesn't go below zero

func shoot_proj(target_position:Vector3) -> void:
	#print("[enemy_rifle] shoot_proj: ", target_position)
	#print("Muzzle Global Position: ", muzzle_point.global_transform.origin)

	# 1: FX (Call your FX function if you have one)
	# shoot_fx() # Call your effects function
	# TODO: Add flash, etc.

	# 2: projectile
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	# 3: Calculate the correct shooting direction
	# Direction from muzzle point to the target position
	var shoot_direction = (target_position - muzzle_point.global_transform.origin).normalized()	
	
	# 4: Correctly set the bullet's initial spawn position
	# Spawn the bullet slightly in front of the muzzle point along the shooting direction
	var spawn_offset = 0.1 # Small offset
	bullet.global_transform.origin = muzzle_point.global_transform.origin + shoot_direction * spawn_offset
	
	# 5: direct bullet to target direction
	if bullet.has_method("setup"):
		bullet.setup(shoot_direction)
	else:
		print("Warning: Bullet scene does not have a 'setup' method taking a direction Vector3.")

# PUBLIC METHODS ==========================================

func request_fire(target_position:Vector3) -> bool:
	# print("[enemy_rifle] request_fire: ",target_position)
	# Check if the gun is ready to fire based on cooldown
	if fire_cooldown <= 0.0:
		shoot_proj(target_position) # Perform the firing mechanics
		fire_cooldown = 1.0 / fire_rate # Reset cooldown
		return true # Indicate that a shot was fired
	return false # Indicate that the gun was not ready to fire
