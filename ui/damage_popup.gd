extends Node

@export var horizontal_jitter:int = 20

# Variables to store the data passed from the enemy
var damage_amount_data: int
var world_position_data: Vector3

# Use a setter function to receive the data
func set_popup_data(amount: int, world_position: Vector3) -> void:
	damage_amount_data = amount
	world_position_data = world_position
	# Note: We don't do anything with the data yet, just store it.

# @onready variables are initialized here, after the node is added to the tree
@onready var label: Label = $CanvasLayer/Label

# The _ready function is called when the node and its children are ready
func _ready() -> void:
	# Now that the label is ready, we can use the stored data
	label.text = str(damage_amount_data)
	
	# Convert 3D world position to 2D screen position
	var camera = get_viewport().get_camera_3d()
	# Ensure the camera is valid before using it
	if camera:
		var screen_pos = camera.unproject_position(world_position_data)
		label.position = screen_pos
		label.position.x += randf_range(-horizontal_jitter, horizontal_jitter) # Random X jitter
	else:
		# Handle case where camera is not found (e.g., print an error)
		print("Error: Camera3D not found for damage popup.")
		queue_free() # Or handle this case differently
		return # Exit the function if no camera
	
	# Animate float up and fade out
	var tween = create_tween()
	# Animate the y position relative to its current position
	tween.tween_property(label, "position:y", label.position.y - 30, 0.6).set_trans(Tween.TRANS_CUBIC)
	# Animate the alpha (modulate.a) property
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_LINEAR)
	# Queue free the node after the tween finishes
	tween.tween_callback(func(): queue_free())
