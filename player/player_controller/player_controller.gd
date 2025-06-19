## player_controller.gd
## Brent Prototype Player Controller
class_name PlayerController
extends CharacterBody3D

signal player_died

#region variables
# PROPERTIES
@export_group("Properties")
@export var HEALTH = 500
@export var GUN:PackedScene
@export_group("Speeds")
@export var LOOK_SPEED = 0.002
@export var BASE_SPEED = 5.0
@export var SPRINT_SPEED = 10.0
@export var JUMP_VELOCITY = 4.5
# INPUT VARS
var mouse_captured = false
var look_rotation: Vector2
var move_speed = 0.0
var joy_look = Vector2.ZERO
var joy_look_speed = 1000
# CLASS VARS
var is_dying: bool = false
var is_crouched: bool = false
#var total_kills = 0 # TODO: need gun/bullet feedback (listener?)
var total_shots = 0
# ONREADY VARS
@onready var head: Node3D = $Head # AKA: camera pivot
@onready var collider: CollisionShape3D = $Collider
@onready var camera: Camera3D = $Head/Camera3D
@onready var death_message: Label = $HUD_CanvasLayer/DeathMessage
#@onready var damage_flash: ColorRect = $HUD_CanvasLayer/DamageFlash
@onready var damage_flash: TextureRect = $HUD_CanvasLayer/TextureRect
@onready var gun_instance: Node3D
@onready var health_bar: ProgressBar = $HUD_CanvasLayer/MarginContainer/HBoxContainer/HealthBar
@onready var sound_argh: AudioStreamPlayer = $"Audio/Sound-argh"
@onready var label_2: Label = $HUD_CanvasLayer/MarginContainer/HBoxContainer/VBoxContainer/Label2
#endregion

# ---------------------------------------------------------

func _ready() -> void:
	# SET DEFAULTS
	# 1: canmera
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	# 2: ux
	death_message.visible = false
	damage_flash.visible = false
	# SETUP
	health_bar.max_value = HEALTH
	health_bar.value = HEALTH
	# GUN SETUP
	gun_instance = GUN.instantiate()
	head.add_child(gun_instance)
	gun_instance.name = "Gun"

func _unhandled_input(event: InputEvent) -> void:
	if is_dying:
		return
	
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	elif event is InputEventJoypadMotion:
		if event.axis == 2:
			joy_look.x = event.axis_value
		elif event.axis == 3:
			joy_look.y = -event.axis_value

func _physics_process(delta: float) -> void:
	# FIRST:
	if is_dying:
		return
	
	# 1: die if player fell off the map
	if global_transform.origin.y < 0.0:
		take_damage(HEALTH, Vector3.ZERO)
	
	# 2: apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# 3: handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# 4: modify speed based on sprinting
	if SPRINT_SPEED > 0 and Input.is_action_pressed("ui_sprint"):
		move_speed = SPRINT_SPEED
	else:
		move_speed = BASE_SPEED
	
	# 5: TODO:
	#if Input.is_action_pressed("shooter_crouch"):
		#if is_crouched
			## TODO:
			#pass
	#else:
		## TODO:
		#pass
	
	# 6: get the input direction and handle the movement/deceleration.
	# .: As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	
	# 7: handle look
	if joy_look != Vector2.ZERO:
		# NOTE: Multiply by joy_look_speed and delta to get a smooth rotation
		rotate_look(joy_look * joy_look_speed * delta)
	
	# 8: Handle Shoot Input - Tell the gun to fire
	if Input.is_action_pressed("ui_shoot"):
		if gun_instance: # Ensure the gun reference is valid
			var fire_result = gun_instance.request_fire()
			if fire_result:
				total_shots += 1
				label_2.text = str(total_shots)
	
	# LAST:
	move_and_slide()

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func rotate_look(rot_input: Vector2):
	## NOTE Rotate us to look around.
	## Base of controller rotates around y (left/right). Head rotates around x (up/down).
	## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
	if SettingsManager.invert_look:
		look_rotation.x -= rot_input.y * LOOK_SPEED
	else:
		look_rotation.x += rot_input.y * LOOK_SPEED
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * LOOK_SPEED
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

# ---------------------------------------------------------

func show_hit(_hit_position: Vector3) -> void:
	# blackhole
	pass

func take_damage(amount: int, _direction_of_impact: Vector3) -> void:
	#print("Ouch! Player took ", amount, " damage. Health now: ", health)
	HEALTH = max(HEALTH - amount, 0)
	health_bar.value = HEALTH
	if HEALTH <= 0:
		die()
	else:
		flash_damage_screen()

func flash_damage_screen():
	damage_flash.visible = true
	damage_flash.modulate.a = 0.5  # full flash
	#
	var tween := create_tween()
	tween.tween_property(damage_flash, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): damage_flash.visible = false)

func die():
	# STEP 0:
	if is_dying:
		return
	#print("PLAYER DIED")
	is_dying = true
	
	# STEP 1: uncapture mouse
	release_mouse()

	# 2. Immediate Visual/Audio Feedback
	damage_flash.modulate = Color(1, 0, 0, 0.7)
	damage_flash.visible = true
	sound_argh.play()
	death_message.visible = true
	gun_instance.visible = false

	# 3. Fade Out UI (Damage Popups, HUD, etc.)
	# Assuming damage popups are children of a CanvasLayer or Control node, or you have a list of them
	# You'd need a reference to your HUD root or a function to hide/tween all UI elements
	# Example for damage_flash fade out and other HUD elements:
	var ui_fade_tween := create_tween()
	ui_fade_tween.set_parallel(true) # Run multiple tweens at once
	# Tween out damage_flash alpha
	#ui_fade_tween.tween_property(damage_flash, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	# fade out healthbar
	ui_fade_tween.tween_property(health_bar, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

	# Add death animation, ragdoll, scene reset, etc.
	damage_flash.visible = true
	damage_flash.modulate = Color(1, 0, 0, 0.7)

	# 4: Fade out all damage popups
	for popup in get_tree().get_nodes_in_group("ui_damage_popup"):
		popup.queue_free()

	# 5. Fall over
	var camera_tween := create_tween()
	camera_tween.tween_property(camera, "rotation_degrees:z", -45.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await camera_tween.finished
	await ui_fade_tween.finished

	# LAST:
	emit_signal("player_died")
