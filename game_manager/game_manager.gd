## game_manager.gd
## - global autoload script
## 1. set just the gd script to autoload,
## 2. set game_manager.tscn as default
## 3. do NOT set MainRoot's script to the autoloaded gd
extends Node
#class_name GameManager # NOTE: not needed: Autoload instead

#region SIGNALS
signal player_died()
signal game_started()
signal game_restarted()
signal game_paused_state_changed(is_paused: bool)
signal level_loaded()
#endregion

#region VARIABLES
# EXPORTS/PRELOADS
@export var hud_game_menu: PackedScene = preload("res://ui/main_menu_scene.tscn")
@export var hud_pause_menu: PackedScene = preload("res://ui/pause_menu.tscn")
@export var weapon_gallery_scene: PackedScene = preload("res://weapon_gallery/weapon_gallery.tscn")
@export var shooting_range_scene: PackedScene = preload("res://levels/shooting_range/shooting_range.tscn")
@export var enemy_gallery_scene: PackedScene = preload("res://enemy_gallery/enemy_gallery.tscn")
# LOCALS
var game_over_ui_prefab = null # TODO: FIXME:
var ui_root_node: CanvasLayer = null
var level_root_node: Node = null
var _current_level_instance: Node = null
var spawned_main_menu: Control = null
var spawned_pause_menu: CanvasLayer = null
var spawned_weapon_gallery: WeaponGallery = null
var spawned_player: PlayerController = null
#endregion

func _ready():
	# STEP 1: Wait for the main_root to be added and ready, then get UIRoot and LevelContainer.
	await self.ready
	ui_root_node = get_tree().current_scene.get_node("UIRoot")
	level_root_node = get_tree().current_scene.get_node("LevelRoot")
	if not ui_root_node:
		printerr("Error: 'UIRoot' CanvasLayer not found in 'game_manager.tscn'. Please ensure it's a child of the root.")
		return
	if not level_root_node:
		printerr("Error: 'LevelRoot' Node not found in 'game_manager.tscn'. Please ensure it's a child of the root.")
		return
	# STEP 2: Initial pause state
	set_game_pause_state(false)
	# STEP 3: Connect to global player_died signal
	GameManager.player_died.connect(_on_player_died)
	# STEP 4: Load the initial game state (e.g., Main Menu)
	call_deferred("load_main_menu")

# --- LISTENERS -----------------------------------------------

func _on_player_died() -> void:
	print("Player died! Game Over!")
	# For a shooting range, you might just restart, or go to a game over screen
	# Clear the current level and go to game over screen
	_clear_current_level()
	load_game_over_screen() # Or load_level("res://scenes/main_menu_scene.tscn

# --- UI FUNCS ------------------------------------------------

func start_btn_pressed():
	# Example: Toggle pause menu if game is paused in a level, otherwise go to main menu
	if get_tree().paused:
		if spawned_pause_menu and is_instance_valid(spawned_pause_menu):
			close_pause_menu()
		elif _current_level_instance and is_instance_valid(_current_level_instance):
			open_pause_menu()
	elif not spawned_main_menu and not spawned_weapon_gallery:
		open_pause_menu()

func _clear_ui() -> void:
	# Removes all UI children from _ui_root_node
	if ui_root_node and is_instance_valid(ui_root_node):
		for child in ui_root_node.get_children():
			child.queue_free()
	spawned_main_menu = null
	spawned_weapon_gallery = null

# --- UI MGMT FUNCTIONS  ---------------------------

func open_pause_menu() -> void:
	if spawned_pause_menu and is_instance_valid(spawned_pause_menu):
		return # Already open

	_clear_ui() # Clear any other UI (like HUD, but *not* the game world)
	set_game_pause_state(true) # Pause the game

	if not hud_pause_menu:
		printerr("Pause Menu UI prefab not assigned in GameManager!")
		return

	spawned_pause_menu = hud_pause_menu.instantiate() as CanvasLayer
	ui_root_node.add_child(spawned_pause_menu)

func close_pause_menu() -> void:
	if spawned_pause_menu and is_instance_valid(spawned_pause_menu):
		spawned_pause_menu.queue_free()
		spawned_pause_menu = null

	set_game_pause_state(false) # Unpause the game

	# Re-show game HUD if applicable (if you hid it when opening pause menu)
	# This part depends on how your HUD is managed.
	# If player HUD is a child of player (and not a separate scene itself)
	#if _spawned_player_instance and _spawned_player_instance.has_node("HUD_CanvasLayer"):
		#_spawned_player_instance.get_node("HUD_CanvasLayer").show()


# --- SCENE MGMT FUNCS ----------------------------------------

func _clear_current_level() -> void:
	# Removes the current level instance from the LevelContainer
	if _current_level_instance and is_instance_valid(_current_level_instance):
		_current_level_instance.queue_free()
		_current_level_instance = null
		print("Current level cleared.")

func load_main_menu() -> void:
	# 1:
	_clear_ui()
	_clear_current_level()
	# 2:
	set_game_pause_state(true)
	# 3:
	# NOTE: below wont work with auto-loaders (`get_tree().current_scene is always null)
	#get_tree().change_scene_to_file("res://ui/main_menu_scene.tscn")
	spawned_main_menu = hud_game_menu.instantiate()
	ui_root_node.add_child(spawned_main_menu)

func load_weapon_gallery() -> void:
	# 1:
	_clear_ui()
	# 2:
	set_game_pause_state(true)
	# 3:
	spawned_weapon_gallery = weapon_gallery_scene.instantiate()
	ui_root_node.add_child(spawned_weapon_gallery)
	spawned_weapon_gallery.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	spawned_weapon_gallery.load_weapon("res://enemy/enemy_rifle/enemy_rifle.tscn")

func load_level(level_path: String):
	#print("[load_level] start: ", level_path)
	_clear_ui()
	_clear_current_level()

	if not level_root_node:
		printerr("Error: LevelRoot node not found! Cannot load level.")
		return

	# Load the PackedScene from the string path
	var level_prefab = load(level_path)
	if not level_prefab is PackedScene:
		printerr("Error: Path '", level_path, "' does not point to a PackedScene for a level.")
		return

	_current_level_instance = level_prefab.instantiate()
	level_root_node.add_child(_current_level_instance)

	# Get player instance (logic remains the same)
	#if _current_level_instance.has_method("get_player_instance"):
		#_spawned_player_instance = _current_level_instance.get_player_instance()
	#elif _current_level_instance.has_node("Player"):
		#_spawned_player_instance = _current_level_instance.get_node("Player") as PlayerController
	#else:
		#printerr("Warning: Player instance not found in loaded level.")

	set_game_pause_state(false)
	level_loaded.emit()
	#print("[load_level] end: ", level_path)

func load_game_over_screen():
	_clear_ui() # Clear current UI (e.g., player HUD)
	_clear_current_level() # Clear the level
	set_game_pause_state(true) # Game over screen usually static and paused

	if not game_over_ui_prefab:
		printerr("Game Over UI prefab not assigned in GameManager!")
		# Fallback: go to main menu if no game over screen
		load_main_menu()
		return

	var game_over_instance = game_over_ui_prefab.instantiate()
	ui_root_node.add_child(game_over_instance)

	# You might want to connect signals from the game over screen (e.g., "Restart", "Return to Main Menu")
	#if game_over_instance.has_method("get_restart_button"):
		#game_over_instance.get_restart_button().pressed.connect(func(): load_level_game(shooting_range_level_scene))
	#if game_over_instance.has_method("get_main_menu_button"):
		#game_over_instance.get_main_menu_button().pressed.connect(load_main_menu)

func load_game_over_screen_OLD():
	#get_tree().change_scene_to_file("res://scenes/game_over_scene.tscn")
	#get_tree().change_scene_to_file("res://ui/main_menu_scene.tscn")
	set_game_pause_state(false) # Unpause if game was paused

# --- Pause/Resume Game ---
func set_game_pause_state(pause: bool):
	#print("[set_game_pause_state] paused = ", pause)
	get_tree().paused = pause
	game_paused_state_changed.emit(pause)

# --- Other global functions ---
# (e.g., save/load game, manage settings, global audio, score tracking)
# func save_game(): pass
# func load_settings(): pass
