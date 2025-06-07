# game_manager.gd
extends Node
#class_name GameManager # NOTE: not needed: Autoload instead

# --- Signals for global events ---
signal player_died()
signal game_started()
signal game_restarted()
signal game_paused_state_changed(is_paused: bool) # Already using this idea
signal level_loaded()

@export var main_menu_scene:PackedScene

func _ready():
	# Initial setup or scene loading if you want to start directly in main menu
	#print("[GameManager] Autoload is ready!")
	# 1:
	set_game_pause_state(false)
	# STEP 1: Go to main menu on game start
	call_deferred("load_main_menu")
	# STEP 2: Connect to global player_died signal from anywhere if you emit it from the player
	GameManager.player_died.connect(_on_player_died)

# --- Listeners ---

func _on_player_died():
	print("Player died! Game Over!")
	# For a shooting range, you might just restart, or go to a game over screen
	load_game_over_screen() # Or load_level("res://scenes/main_menu_scene.tscn

# --- Scene Management Functions ---

func load_main_menu():
	get_tree().change_scene_to_file("res://ui/main_menu_scene.tscn")
	#get_tree().change_scene_to_file("res://levels/shooting_range/shooting_range.tscn")
	#get_tree().change_scene_to_packed(main_menu_scene)
	# Unpause if game was paused
	#if get_tree().paused:
	#	set_game_pause_state(false)

func load_level(level_path: String):
	get_tree().change_scene_to_file(level_path)
	set_game_pause_state(false) # Ensure game is unpaused
	level_loaded.emit()

func load_game_over_screen():
	#get_tree().change_scene_to_file("res://scenes/game_over_scene.tscn")
	get_tree().change_scene_to_file("res://ui/main_menu_scene.tscn")
	set_game_pause_state(false) # Unpause if game was paused

# --- Pause/Resume Game ---
func set_game_pause_state(pause: bool):
	get_tree().paused = pause
	game_paused_state_changed.emit(pause)
	print("Game paused: ", pause)

# --- Other global functions ---
# (e.g., save/load game, manage settings, global audio, score tracking)
# func save_game(): pass
# func load_settings(): pass
