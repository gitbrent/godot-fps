## DESIGN NOTES
## - weapons exist on mask 1 *and* 20
## - that way we can easily show here wihtout having to set/unset masks!
extends Node3D
class_name WeaponGallery

signal btn_clicked_close_weapon_gallery

#region vars
@onready var weapon_container: Node3D = $WeaponContainer
@onready var main_camera: Camera3D = $Camera3D
@onready var stat_row_1: StatRow = $WeaponContainer/CanvasLayer/MainUIMarginContainer/HBoxStats/StatsTableCont/StatRow1
@onready var stat_row_2: StatRow = $WeaponContainer/CanvasLayer/MainUIMarginContainer/HBoxStats/StatsTableCont/StatRow2
@onready var stat_row_3: StatRow = $WeaponContainer/CanvasLayer/MainUIMarginContainer/HBoxStats/StatsTableCont/StatRow3
@onready var stat_row_4: StatRow = $WeaponContainer/CanvasLayer/MainUIMarginContainer/HBoxStats/StatsTableCont/StatRow4
#
var loaded_weapon_model: Node3D = null
var rotation_speed: float = 0.5
var joystick_rotation_speed: float = 100.0 # (degrees per second)
var min_zoom_z: float = 0.5 # Closest Z camera can get to origin (weapon)
var max_zoom_z: float = 2.0 # Farthest Z camera can get from origin
var zoom_speed: float = 1.0 # how fast it zooms
# Example weapon data (TODO: need to load this from a JSON, CSV, or custom resource)
var current_weapon_stats: Dictionary = {
	"FIREPOWER": 75,
	"ACCURACY": 60,
	"DAMAGE": 85,
	"HANDLING": 70
}
#endregion

func _ready():
	# Ensure the camera only renders the "WeaponExamine" layer (20)
	main_camera.cull_mask = (1 << 19)

func _process(delta: float):
	# Joystick Input for Rotation
	if loaded_weapon_model:
		var joystick_x_input = Input.get_axis("move_left", "move_right")
		if abs(joystick_x_input) > 0.1: # Add a small deadzone
			# Rotate around the Y-axis based on joystick X input
			loaded_weapon_model.rotate_object_local(Vector3(0, 1, 0), deg_to_rad(joystick_x_input * joystick_rotation_speed * delta))

	# Joystick Input for Zoom (Left Stick Up/Down)
	var joystick_y_input = Input.get_axis("ui_up", "ui_down")

	if abs(joystick_y_input) > 0.1: # Small deadzone
		# Calculate the change in Z based on input and speed
		# If joystick_y_input is positive (forward stick), we want Z to DECREASE (move closer)
		# If joystick_y_input is negative (backward stick), we want Z to INCREASE (move farther)
		var zoom_delta_z = joystick_y_input * zoom_speed * delta
		# Apply the change to the camera's Z position
		var new_camera_z = main_camera.position.z - zoom_delta_z # Subtract to zoom in for positive input
		# Clamp the new Z position
		new_camera_z = clamp(new_camera_z, min_zoom_z, max_zoom_z)
		# Apply the clamped Z position back to the camera
		# Crucially, we only change the Z component; X and Y remain fixed.
		main_camera.position.z = new_camera_z

func _input(event):
	# Mouse drag rotation (Y-axis for left/right spin)
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if loaded_weapon_model:
			# Rotate around the Y-axis (for left/right horizontal spin)
			loaded_weapon_model.rotate_object_local(Vector3(0, 1, 0), deg_to_rad(event.relative.x * rotation_speed))

	# Handle "Back" input (e.g., Esc key or O joypad)
	if Input.is_action_just_pressed("ui_cancel"):
		emit_signal("btn_clicked_close_weapon_gallery")

# PUBLIC METHODS -----------------------------------------------

func load_weapon(weapon_scene_path: String) -> void:
	if loaded_weapon_model:
		loaded_weapon_model.queue_free() # Remove previous weapon if any
		loaded_weapon_model = null

	var weapon_scene = load(weapon_scene_path)
	if weapon_scene:
		loaded_weapon_model = weapon_scene.instantiate()
		weapon_container.add_child(loaded_weapon_model)
		loaded_weapon_model.position = Vector3.ZERO
		loaded_weapon_model.rotation_degrees = Vector3(0, -45, 0)
	else:
		print("ERROR: Failed to load weapon scene: ", weapon_scene_path)

	# we'll get the stats *from* the loaded weapon model or a data source
	# for now, let's use the example data:
	display_weapon_stats(current_weapon_stats)

## since this is just a prototype game, we're hard-coding the 4 stats (as opposed to instantiating StatRows for each)
func display_weapon_stats(stats: Dictionary) -> void:
	var stat_rows = [
		stat_row_1,
		stat_row_2,
		stat_row_3,
		stat_row_4,
	]
	var i := 0
	for stat_name in stats.keys():
		if i >= stat_rows.size():
			break  # Prevent out-of-bounds if stats > 4
		var stat_value = stats[stat_name]
		stat_rows[i].set_stat(stat_name, stat_value)
		i += 1
