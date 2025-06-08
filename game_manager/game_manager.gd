# game_manager.gd
extends Node
#class_name GameManager # NOTE: not needed: Autoload instead

#region global-signals
signal player_died()
signal game_started()
signal game_restarted()
signal game_paused_state_changed(is_paused: bool)
signal level_loaded()
#endregion
#region VARIABLES
# READY
@onready var ui_root = get_tree().current_scene.get_node("UIRoot")
# EXPS
@export var hud_game_menu: PackedScene = preload("res://ui/main_menu_scene.tscn")
@export var weapon_gallery_scene: PackedScene = preload("res://weapon_gallery/weapon_gallery.tscn")
@export var shooting_range_scene: PackedScene = preload("res://levels/shooting_range/shooting_range.tscn")
# VARS
var spawned_main_menu: Control = null
var spawned_weapon_gallery: WeaponGallery = null
var spawned_player: PlayerController = null
#endregion

func _ready():
	# STEP 1:
	set_game_pause_state(false)
	# STEP 2:
	call_deferred("load_main_menu")
	# STEP 3: Connect to global player_died signal from anywhere if you emit it from the player
	GameManager.player_died.connect(_on_player_died)

func _input(event):
	if Input.is_action_just_pressed("joypad_start"):
		load_main_menu()

# --- LISTENERS -----------------------------------------------

func _on_player_died() -> void:
	print("Player died! Game Over!")
	# For a shooting range, you might just restart, or go to a game over screen
	load_game_over_screen() # Or load_level("res://scenes/main_menu_scene.tscn

# --- UI FUNCS ------------------------------------------------

func _clear_ui() -> void:
	for child in ui_root.get_children():
		child.queue_free()
	spawned_main_menu      = null
	spawned_weapon_gallery = null

# --- SCENE MGMT FUNCS ----------------------------------------

func load_main_menu() -> void:
	# 1:
	_clear_ui()
	# 2:
	set_game_pause_state(true)
	# 3:
	# NOTE: below wont work with auto-loaders (`get_tree().current_scene is always null)
	#get_tree().change_scene_to_file("res://ui/main_menu_scene.tscn")
	spawned_main_menu = hud_game_menu.instantiate()
	ui_root.add_child(spawned_main_menu)

func load_weapon_gallery() -> void:
	# 1:
	_clear_ui()
	# 2:
	set_game_pause_state(true)
	# 3:
	spawned_weapon_gallery = weapon_gallery_scene.instantiate()
	ui_root.add_child(spawned_weapon_gallery)
	spawned_weapon_gallery.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	spawned_weapon_gallery.load_weapon("res://enemy/enemy_rifle/enemy_rifle.tscn")

func load_level(level_path: String):
	print("[load_level] ", level_path)
	get_tree().change_scene_to_file(level_path)
	set_game_pause_state(false)
	level_loaded.emit()

func load_game_over_screen():
	#get_tree().change_scene_to_file("res://scenes/game_over_scene.tscn")
	get_tree().change_scene_to_file("res://ui/main_menu_scene.tscn")
	set_game_pause_state(false) # Unpause if game was paused

# --- Pause/Resume Game ---
func set_game_pause_state(pause: bool):
	get_tree().paused = pause
	game_paused_state_changed.emit(pause)
	#print("Game paused: ", pause)

# --- Other global functions ---
# (e.g., save/load game, manage settings, global audio, score tracking)
# func save_game(): pass
# func load_settings(): pass
