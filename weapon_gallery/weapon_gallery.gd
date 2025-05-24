## DESIGN NOTES
## - weapons exist on 1 *and* 20
## - that way we can easily show here wihtout having to set/unset masks!
extends Node3D
class_name WeaponGallery

signal btn_clicked_close_weapon_gallery

#region vars
@onready var weapon_container: Node3D = $WeaponContainer
@onready var main_camera: Camera3D = $Camera3D
#
var loaded_weapon_model: Node3D = null
var rotation_speed: float = 0.5
#endregion

func _ready():
	# Ensure the camera only renders the "WeaponExamine" layer or specific layer for this view
	main_camera.cull_mask = (1 << 19) # Example: Assuming layer 20 is "UI_3D"
	# Initially hide the weapon container if you load it later
	# weapon_container.visible = false

func _process(delta: float):
	# Handle mouse input for rotation
	if Input.is_action_pressed("ui_left"):
		var mouse_delta = Input.get_last_mouse_velocity()
		# Rotate around the Z-axis based on horizontal mouse movement
		# The Z-axis rotation for the weapon itself depends on your weapon's model orientation.
		# Often, you rotate around the Y-axis for horizontal spin, or X-axis for vertical.
		# The request was Z-axis, so let's use that.
		if loaded_weapon_model:
			# You might need to adjust the axis depending on your model's orientation.
			# For typical "examine" screens, it's often rotation around the Y-axis for horizontal spin.
			# If the user wants Z-axis for vertical spin, this is correct.
			loaded_weapon_model.rotate_object_local(Vector3(0, 0, 1), deg_to_rad(mouse_delta.x * rotation_speed))
			# If you meant horizontal spin (like rotating it left/right on a stand), use Y-axis:
			# loaded_weapon_model.rotate_object_local(Vector3(0, 1, 0), deg_to_rad(mouse_delta.x * rotation_speed))

# Method to load a specific weapon model
func load_weapon(weapon_scene_path: String):
	if loaded_weapon_model:
		loaded_weapon_model.queue_free() # Remove previous weapon if any
		loaded_weapon_model = null

	var weapon_scene = load(weapon_scene_path)
	if weapon_scene:
		loaded_weapon_model = weapon_scene.instantiate()
		weapon_container.add_child(loaded_weapon_model)
		# You might need to adjust the loaded_weapon_model's local_position and rotation
		# to center it correctly in the view.
		loaded_weapon_model.position = Vector3.ZERO # Ensure it's at the container's center
		loaded_weapon_model.rotation_degrees = Vector3.ZERO # Reset rotation if needed
		print("WEAPON LOADED!")
		# Ensure it's on the correct rendering layer for this camera
		# loaded_weapon_model.set_layer(20) # Assuming layer 20 is "UI_3D"
	else:
		print("Failed to load weapon scene: ", weapon_scene_path)

func _input(event):
	# Alternatively, if you want drag rotation without holding a button
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var mouse_delta = event.relative
		if loaded_weapon_model:
			# Rotate around the Z-axis (vertical rotation) based on horizontal mouse movement
			loaded_weapon_model.rotate_object_local(Vector3(0, 0, 1), deg_to_rad(mouse_delta.x * rotation_speed))
			# If you meant horizontal rotation (like spinning it on a table), use Y-axis:
			# loaded_weapon_model.rotate_object_local(Vector3(0, 1, 0), deg_to_rad(mouse_delta.x * rotation_speed))

	# Handle a "Back" button input
	if Input.is_action_just_pressed("ui_cancel"): # Default Godot action for Esc key
		# Emit a signal or call a function in GameController to close this scene
		get_parent().close_weapon_examine_screen() # Assuming GameController is the parent

func _on_button_back_pressed() -> void:
	emit_signal("btn_clicked_close_weapon_gallery")
