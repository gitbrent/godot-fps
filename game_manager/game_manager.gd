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
@export var hud_options_menu: PackedScene = preload("res://ui/options_menu/options_menu.tscn")
@export var weapon_gallery_scene: PackedScene = preload("res://weapon_gallery/weapon_gallery.tscn")
@export var enemy_gallery_scene: PackedScene = preload("res://enemy_gallery/enemy_gallery.tscn")
@export var shooting_range_scene: PackedScene = preload("res://levels/shooting_range/shooting_range.tscn")
# LOCALS
var game_over_ui_prefab = null # TODO: FIXME:
var ui_root_node: CanvasLayer = null
var level_root_node: Node = null
var _current_level_instance: Node = null
var spawned_main_menu: Control = null
var spawned_pause_menu: Control = null
var spawned_options_menu: Control = null
var spawned_weapon_gallery: WeaponGallery = null
var spawned_enemy_gallery: EnemyGallery = null
var spawned_player: PlayerController = null
#endregion

func _ready() -> void:
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
	_set_game_pause_state(false)
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
	_load_game_over_screen()

# --- UI FUNCS ------------------------------------------------

func _clear_ui() -> void:
	# Removes all UI children from _ui_root_node
	if ui_root_node and is_instance_valid(ui_root_node):
		for child in ui_root_node.get_children():
			child.queue_free()
	spawned_main_menu = null
	spawned_weapon_gallery = null

# --- UI MGMT FUNCTIONS  --------------------------------------

func _open_pause_menu() -> void:
	if spawned_pause_menu and is_instance_valid(spawned_pause_menu):
		return # Already open
	
	_clear_ui() # Clear any other UI (like HUD, but *not* the game world)
	_set_game_pause_state(true) # Pause the game
	
	if not hud_pause_menu:
		printerr("Pause Menu UI prefab not assigned in GameManager!")
		return
	
	spawned_pause_menu = hud_pause_menu.instantiate() as Control
	ui_root_node.add_child(spawned_pause_menu)
	
	# --- CONNECT SIGNALS FROM THE PAUSE MENU INSTANCE ---
	if spawned_pause_menu.has_signal("show_options"):
		spawned_pause_menu.show_options.connect(_open_options_menu)
	else:
		printerr("PauseMenu scene does not have 'show_options' signal!")
	if spawned_pause_menu.has_signal("resume_game"):
		spawned_pause_menu.resume_game.connect(_close_pause_menu)
	else:
		printerr("PauseMenu scene does not have 'resume_game' signal!")
	if spawned_pause_menu.has_signal("quit_game"):
		spawned_pause_menu.quit_game.connect(load_main_menu)
	else:
		printerr("PauseMenu scene does not have 'quit_game' signal!")

func _close_pause_menu() -> void:
	# 1:
	if spawned_pause_menu and is_instance_valid(spawned_pause_menu):
		spawned_pause_menu.queue_free()
		spawned_pause_menu = null
	# 2:
	_set_game_pause_state(false)

func _open_options_menu() -> void:
	if spawned_options_menu and is_instance_valid(spawned_options_menu):
		return # Already open
	
	_clear_ui() # Clear any other UI (like HUD, but *not* the game world)
	_set_game_pause_state(true) # Pause the game
	
	if not hud_options_menu:
		printerr("Options Menu UI prefab not assigned in GameManager!")
		return
	
	spawned_options_menu = hud_options_menu.instantiate() as Control
	ui_root_node.add_child(spawned_options_menu)

	if spawned_options_menu.has_signal("resume_game"):
		spawned_options_menu.resume_game.connect(_close_options_menu)
	else:
		printerr("OptionsMenu scene does not have 'resume_game' signal!")

func _close_options_menu() -> void:
	# 1:
	if spawned_options_menu and is_instance_valid(spawned_options_menu):
		spawned_options_menu.queue_free()
		spawned_options_menu = null
	# 2:
	_set_game_pause_state(false)

# --- SCENE MGMT FUNCS ----------------------------------------

func _clear_current_level() -> void:
	# Removes the current level instance from the LevelContainer
	if _current_level_instance and is_instance_valid(_current_level_instance):
		level_root_node.remove_child(_current_level_instance)

		# Clear any CanvasLayers
		for child in _current_level_instance.get_children():
			if child is CanvasLayer:
				child.queue_free()
				print("BAM!")

		_current_level_instance.queue_free()
		_current_level_instance = null
		print("Current level cleared.")

func _load_game_over_screen() -> void:
	_clear_ui() # Clear current UI (e.g., player HUD)
	_clear_current_level() # Clear the level
	_set_game_pause_state(true) # Game over screen usually static and paused

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

func _load_game_over_screen_OLD():
	#get_tree().change_scene_to_file("res://scenes/game_over_scene.tscn")
	#get_tree().change_scene_to_file("res://ui/main_menu_scene.tscn")
	_set_game_pause_state(false) # Unpause if game was paused

# --- PAUSE MGMT FUNCS ----------------------------------------

func _set_game_pause_state(pause: bool) -> void:
	# 1:
	get_tree().paused = pause
	# 2:
	game_paused_state_changed.emit(pause)
	# 3: level-specific
	if _current_level_instance and is_instance_valid(_current_level_instance):
		# set HUD visibility
		for node in _current_level_instance.get_children():
			if node is CanvasLayer:
				node.visible = not pause
				print("curr_level Canvas visibility set to: ", not pause)
			#else:
			#	printerr("CanvasLayer not found or is not a CanvasLayer child of _current_level_instance!")
	if _current_level_instance and is_instance_valid(_current_level_instance):
		var hud_canvas_layer = _current_level_instance.find_child("HUD_CanvasLayer", true, false)
		if hud_canvas_layer is CanvasLayer:
			hud_canvas_layer.visible = not pause
			print("`HUD_CanvasLayer` visibility set to: ", not pause)

# --- PUBLIC FUNCS ----------------------------------------

func start_btn_pressed() -> void:
	# Example: Toggle pause menu if game is paused in a level, otherwise go to main menu
	if get_tree().paused:
		if spawned_pause_menu and is_instance_valid(spawned_pause_menu):
			_close_pause_menu()
		elif _current_level_instance and is_instance_valid(_current_level_instance):
			_open_pause_menu()
	elif not spawned_main_menu and not spawned_weapon_gallery:
		_open_pause_menu()

func load_main_menu() -> void:
	# 1:
	_clear_ui()
	_clear_current_level()
	# 2:
	_set_game_pause_state(false)
	# 3:
	# NOTE: below wont work with auto-loaders (`get_tree().current_scene is always null)
	#get_tree().change_scene_to_file("res://ui/main_menu_scene.tscn")
	spawned_main_menu = hud_game_menu.instantiate()
	ui_root_node.add_child(spawned_main_menu)

func load_weapon_gallery() -> void:
	# 1:
	_clear_ui()
	# 2:
	_set_game_pause_state(true)
	# 3:
	spawned_weapon_gallery = weapon_gallery_scene.instantiate()
	ui_root_node.add_child(spawned_weapon_gallery)
	spawned_weapon_gallery.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	spawned_weapon_gallery.load_weapon("res://enemy/enemy_rifle/enemy_rifle.tscn")

func load_enemy_gallery() -> void:
	# 1:
	_clear_ui()
	# 2:
	_set_game_pause_state(true)
	# 3:
	spawned_enemy_gallery = enemy_gallery_scene.instantiate()
	ui_root_node.add_child(spawned_enemy_gallery)
	spawned_enemy_gallery.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	spawned_enemy_gallery.load_enemy("res://enemy/enemy_controller/enemy_controller.tscn")

func load_level(level_path: String):
	#print("[load_level] start: ", level_path)
	_clear_ui()
	_clear_current_level()
	_set_game_pause_state(false) # Ensure game is unpaused for new level to start

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

	_set_game_pause_state(false)
	level_loaded.emit()
	#print("[load_level] end: ", level_path)

# --- TODO: FUTURE: Other global functions ---
# (e.g., save/load game, manage settings, global audio, score tracking)
# func save_game(): pass
# func load_settings(): pass
