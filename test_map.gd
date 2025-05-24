extends Node3D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
#
@onready var hud_game_menu: Control = $HudGameMenu
@onready var countdown_label: CanvasLayer = $CountdownLabel
#
var spawned_player: PlayerController
var spawned_enemy: EnemyController
var max_enemies = 3
var can_spawn_enemies = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# STEP 1: assert
	if !player_scene or !enemy_scene:
		print("ASSERT FAILED")
		return
	# STEP 2:
	hud_game_menu.btn_clicked_start_game.connect(_on_btn_clicked_start_game)
	# STEP 3:
	show_start_screen()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if can_spawn_enemies:
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.size() < max_enemies:
			spawn_enemy()

func pause_game(value:bool) -> void:
	get_tree().paused = value

# HUD GUI FUNCS -----------------------------------------------

func show_start_screen() -> void:
	pause_game(true)
	hud_game_menu.show_game_menu(true)

func _on_btn_clicked_start_game() -> void:
	# 1: cleanup
	if spawned_player:
		spawned_player.queue_free()
	
	if get_tree().has_group("enemies"):
		for node in get_tree().get_nodes_in_group("enemies"):
			node.queue_free()
	
	# 2:
	hud_game_menu.show_game_menu(false)
	pause_game(false)
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
	show_start_screen()

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
