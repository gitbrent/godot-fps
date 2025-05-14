extends Node3D

@export_group("Scene Children")
@export var bullet_scene: PackedScene
@export_group("Camera & ADS")
@export var normal_position: Vector3 = Vector3(0.15, 0.5, -0.7)
@export var normal_rotation: Vector3 = Vector3(4, 180, 0)
@export var normal_fov: float = 75.0
@export var ads_position: Vector3 = Vector3(0.0, 0.635, -0.4)
@export var ads_rotation: Vector3 = Vector3(-4, 180, 0)
@export var ads_fov: float = 40.0
@export_group("Full-Auto")
@export var fire_rate: float = 4.0 # Bullets per second
#
@onready var muzzle_flash: MeshInstance3D = $Node3D/MuzzlePoint/MuzzleFlash
@onready var muzzle_point: Node3D = $Node3D/MuzzlePoint
@onready var gun_bullet_ejector: Node3D = $Node3D/GunBulletEjector
@onready var gun = $Node3D
#
# TODO: make these ARGS
const LAYER_WORLD = 1 << 0    # Layer 1
const LAYER_BULLETS = 1 << 1  # Layer 2
const LAYER_ENEMIES = 1 << 2  # Layer 3
#
var fire_cooldown: float = 0.0 # Cooldown starts at 0, ready to fire immediately
var is_ads: bool = false # aim-down-sights
var recoil_offset := Vector3.ZERO
var recoil_rot := Vector3.ZERO

func _ready() -> void:
	# 1: scene defaults
	muzzle_flash.visible = false
	$ScopeOverlay.visible = false
	$Crosshair.visible = true
	gun.transform.origin = normal_position
	gun.rotation_degrees = normal_rotation

# TODO: we needd ot have the CONTROLLER do when to fire!

func _process(delta):
	# -------
	# STEP 1: adjust view
	# ......: gun my lerping back from firing and/or have ADS
	# STEP 1-1: Calculate ADS position and rotation targets
	var base_pos = ads_position if is_ads else normal_position
	var base_rot = ads_rotation if is_ads else normal_rotation
	# STEP 1-2: Apply recoil as an offset from ADS/hipfire base
	var final_pos = base_pos + recoil_offset
	var final_rot = base_rot + recoil_rot
	# STEP 1-3: Lerp toward that final pose
	gun.transform.origin = gun.transform.origin.lerp(final_pos, delta * 10.0)
	gun.rotation_degrees = gun.rotation_degrees.lerp(final_rot, delta * 10.0)
	# STEP 1-4: set FOV
	var camera: Camera3D = get_viewport().get_camera_3d()
	var target_fov = ads_fov if is_ads else normal_fov
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)  # Smooth zoom
	# -------
	# STEP 2: full-auto firing
	# -------
	# Decrease cooldown over time
	fire_cooldown -= delta
	## Check if the fire action is currently pressed AND the cooldown is ready (<= 0.0)
	## This single check handles both the initial press (since _fire_cooldown starts at 0)
	## and subsequent shots in full-auto as the cooldown expires.
	if Input.is_action_pressed("ui_shoot") and fire_cooldown <= 0.0:
		if camera:
			shoot_proj()
		# Reset cooldown for the next shot
		fire_cooldown = 1.0 / fire_rate
	# -------
	# STEP 3: aim-down-sights (ADS)
	# -------
	if Input.is_action_pressed("ui_aim_down_sights"):
		is_ads = true
		#$ScopeOverlay.visible = true
		$Crosshair.visible = false
	else:
		is_ads = false
		#$ScopeOverlay.visible = false
		$Crosshair.visible = true

func shoot_proj() -> void:
	# 1: FX
	shoot_fx()
	# 2: projectile
	shoot_bullet_proj()

func shoot_fx():
	# 4: muzzle-flash
	$Node3D/MuzzlePoint/MuzzleParticles.restart()
	# 1: audio
	$AudioGunshot.play()
	# 2: eject spent shell casing
	gun_bullet_ejector.eject_shell()
	# 3: recoil animation
	# IMPORTANT: apply tranform to the underlying model so we can use 0,0.2,04 etc. - otherwise, position will require tyaking ARG values and updating those!
	if is_ads:
		$AnimationPlayer.play("fire_ads")
	else:
		$AnimationPlayer.play("fire_normal")

func shoot_bullet_proj():
	#Engine.time_scale = 0.1
	#print("CAMERA POSITION: ", get_viewport().get_camera_3d().global_transform.origin)
	#print("MUZZLE POSITION: ", muzzle_point.global_transform.origin)
	var camera = get_viewport().get_camera_3d()
	# Get the camera's forward direction directly
	var shoot_direction = -camera.global_transform.basis.z
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	# Spawn the bullet slightly in front of the muzzle point along the shooting direction
	# Adjust the 0.1 value as needed based on your gun model and bullet size
	var spawn_offset = 0.1 # Small offset to spawn bullet slightly ahead of muzzle
	if is_ads:
		# IMPORTANT: in ADS mode, we have to add this or the bullet hits player istantly!
		spawn_offset += 0.4
	bullet.global_transform.origin = muzzle_point.global_transform.origin + shoot_direction * spawn_offset
	bullet.setup(shoot_direction) # Pass the camera's forward direction
	#print("SHOOT DIRECTION: ", shoot_direction)
