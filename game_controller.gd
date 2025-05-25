extends Node3D
class_name GameController

#region vars
@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var weapon_gallery_scene: PackedScene
#
@onready var hud_game_menu: Control = $HudGameMenu
@onready var countdown_label: CanvasLayer = $CountdownLabel
#
var spawned_player: PlayerController = null
var spawned_enemy: EnemyController = null
var spawned_weapon_gallery: WeaponGallery = null
var max_enemies = 3
var can_spawn_enemies = false
#endregion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# STEP 1: assert
	if !player_scene or !enemy_scene:
		print("ASSERT FAILED")
		return
	# STEP 2:
	hud_game_menu.btn_clicked_start_game.connect(_on_btn_clicked_start_game)
	# STEP 3:
	show_start_screen(true)

func _input(event):
	if Input.is_action_just_pressed("joypad_start"):
		show_start_screen(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if can_spawn_enemies:
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.size() < max_enemies:
			spawn_enemy()

func pause_game(value:bool) -> void:
	get_tree().paused = value

# HUD GUI FUNCS -----------------------------------------------

func show_start_screen(value:bool) -> void:
	pause_game(value)
	hud_game_menu.show_game_menu(value)

func _on_btn_clicked_start_game() -> void:
	# 1: cleanup
	if spawned_player:
		spawned_player.queue_free()
	
	if get_tree().has_group("enemies"):
		for node in get_tree().get_nodes_in_group("enemies"):
			node.queue_free()
	
	# 2:
	show_start_screen(false)
	
	# 3:
	spawn_player()
	
	# 3:
	# TODO: WIP: show "321" on the screen
	countdown_label.show_321_countdown()
	await get_tree().create_timer(3).timeout
	can_spawn_enemies = true

# PLAYER FUNCS -----------------------------------------------

func _on_player_died() -> void:
	# 1:
	pause_game(true)
	can_spawn_enemies = false
	# 2:
	await get_tree().create_timer(2).timeout
	# 3:
	spawned_player.queue_free()
	# 3:
	show_start_screen(true)

func spawn_player() -> void:
	spawned_player = player_scene.instantiate()
	get_tree().current_scene.add_child(spawned_player)
	spawned_player.global_position = Vector3(0,0,10)
	spawned_player.player_died.connect(_on_player_died)

# ENEMY FUNCS -----------------------------------------------

func spawn_enemy() -> void:
	if enemy_scene:
		#print("[test_map] spawning enemy...")
		spawned_enemy = enemy_scene.instantiate()
		get_tree().current_scene.add_child(spawned_enemy)
		spawned_enemy.can_patrol = true
		spawned_enemy.global_position = Vector3(0.0, 0.0, -10.0)
		spawned_enemy.state_machine.request_state_change("patrol")

# WEAPON GALLERY --------------------------------------------

func _on_examine_weapon_button_pressed():
	print("Examine Weapon button pressed!")
	if spawned_weapon_gallery:
		spawned_weapon_gallery.queue_free()
	get_tree().paused = true # Pause the game while in examine screen
	# Hide main menu UI
	if hud_game_menu:
		hud_game_menu.visible = false
	# WIP:
	show_start_screen(false)
	pause_game(true)
	# Hide player HUD if it was visible
	if spawned_player:
		var player_hud_canvas_layer = spawned_player.hud_canvas_layer
		if player_hud_canvas_layer:
			player_hud_canvas_layer.visible = false

	if weapon_gallery_scene:
		spawned_weapon_gallery = weapon_gallery_scene.instantiate()
		get_tree().current_scene.add_child(spawned_weapon_gallery)
		# Ensure it processes inputs even if paused
		spawned_weapon_gallery.set_process_mode(Node.PROCESS_MODE_ALWAYS)
		spawned_weapon_gallery.btn_clicked_close_weapon_gallery.connect(close_weapon_examine_screen)

		# --- Load a specific weapon ---
		# Example: Load an enemy's default weapon. You'll need the path to its GLB/OBJ/TSCN file.
		# Ensure your enemy weapon model scene (e.g., "res://models/enemy_rifle.tscn") is correctly imported
		spawned_weapon_gallery.load_weapon("res://enemy_rifle/enemy_rifle.tscn")
	else:
		print("Error: Weapon examine scene prefab not assigned!")

func close_weapon_examine_screen(): # Called from weapon_examine_screen.gd
	print("Closing weapon examine screen.")
	if is_instance_valid(spawned_weapon_gallery):
		spawned_weapon_gallery.queue_free()
		spawned_weapon_gallery = null

	pause_game(false)
	# Show the main menu again (or whatever screen you came from)
	show_start_screen(true) # Or show_game_over_screen() if you want to remember previous state
