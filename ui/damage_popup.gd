# Update your damage popup script to extend Node3D
extends Node3D

@onready var label_3d: Label3D = $Label3D
#
@export var horizontal_jitter: float = 0.5
@export var float_speed: float = 2.0 # Speed at which the popup floats up
@export var fade_speed: float = 2.0 # Speed at which the popup fades out
#
var damage_amount_data: int
var world_position_data: Vector3

# Use a setter function to receive the data
func set_popup_data(amount: int, world_position: Vector3) -> void:
	damage_amount_data = amount
	world_position_data = world_position
	# We set the initial global position in _ready()

# The _ready function is called when the node and its children are ready
func _ready() -> void:
	# --- Set Initial Position in 3D ---
	global_position = world_position_data
	global_position.x += randf_range(-horizontal_jitter, horizontal_jitter)
	global_position.z += randf_range(-horizontal_jitter, horizontal_jitter)

	# --- Set Label3D Text ---
	if label_3d:
		label_3d.text = str(damage_amount_data)
		label_3d.modulate.a = 1.0 # Ensure it starts fully visible
	else:
		print("Error: Label3D node not found in damage popup scene!")
		queue_free() # Cannot display text without Label3D
		return

	# --- Animate Float Up and Fade Out ---
	var tween = create_tween()

	# Animate the Y position to float upwards
	# We tween the 'position:y' property of *this* Node3D (the root)
	tween.tween_property(self, "position:y", position.y + 1.5, float_speed).set_trans(Tween.TRANS_CUBIC) # Float up by 1.5 units over 'float_speed' seconds
	
	# Tween the 'modulate:a' property directly on the label_3d node
	tween.parallel().tween_property(label_3d, "modulate:a", 0.0, fade_speed).set_trans(Tween.TRANS_LINEAR)
	
	# Queue free the node after the tween finishes
	tween.tween_callback(func(): queue_free())


func _process(delta: float) -> void:
	# --- Make Label3D Face Camera ---
	# This makes the text always readable by rotating it towards the camera
	var camera = get_viewport().get_camera_3d()
	if camera and label_3d:
		label_3d.look_at(camera.global_transform.origin, Vector3.UP)
		# Adjust rotation if needed (Label3D might be initially oriented differently)
		label_3d.rotation_degrees.y += 180 # Example: if text is facing away
	
