# settings_manager.gd
extends Node
#class_name SettingsManager # NOTE: used by autoload singleton

const SETTINGS_FILE_PATH = "user://settings.cfg"

var config = ConfigFile.new()

# Game settings variables
var invert_look: bool = false:
	set(value):
		invert_look = value
		_save_settings()

func _ready():
	_load_settings()

func _load_settings() -> void:
	var error = config.load(SETTINGS_FILE_PATH)
	if error != OK:
		printerr("Could not load settings file from ", SETTINGS_FILE_PATH, ". Error: ", error)
		# If file doesn't exist or is corrupt, load default settings
		_set_default_settings()
		_save_settings() # Save defaults so file is created

	# Retrieve settings (provide default values if they don't exist in the file)
	invert_look = config.get_value("Controls", "invert_look", false)
	# You can add more settings here:
	# master_volume = config.get_value("Audio", "master_volume", 1.0)
	# fullscreen_mode = config.get_value("Display", "fullscreen", true)

	print("Settings loaded: Invert Look = ", invert_look)

func _save_settings() -> void:
	# Clear existing sections to prevent old, unused settings from lingering
	config.clear()

	# Save controls settings
	config.set_value("Controls", "invert_look", invert_look)

	# Save other sections:
	# config.set_value("Audio", "master_volume", master_volume)
	# config.set_value("Display", "fullscreen", fullscreen_mode)

	var error = config.save(SETTINGS_FILE_PATH)
	if error != OK:
		printerr("Could not save settings file to ", SETTINGS_FILE_PATH, ". Error: ", error)
	else:
		print("Settings saved successfully to ", SETTINGS_FILE_PATH)

func _set_default_settings() -> void:
	print("Setting default settings...")
	invert_look = false
	# master_volume = 1.0
	# fullscreen_mode = true

# Public function to toggle invert look, useful for UI buttons
func toggle_invert_look() -> void:
	self.invert_look = not self.invert_look # Use 'self.' to trigger the setter
