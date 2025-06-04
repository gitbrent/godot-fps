extends Node3D

@onready var enemy_1: EnemyController = $Enemy1
@onready var enemy_2: EnemyController = $Enemy2
@onready var enemy_chatter_1: AudioStreamPlayer3D = $MaleSoldierEnemyChatter1
@onready var enemy_chatter_2: AudioStreamPlayer3D = $MaleSoldierEnemyChatter2

func _ready() -> void:
	# 1:
	enemy_1.state_machine.request_state_change('idle')
	enemy_1.can_patrol = false
	# 2:
	enemy_2.state_machine.request_state_change('idle')
	enemy_2.can_patrol = false
	# 3:
	do_chatter_audio()

func do_chatter_audio() -> void:
	# 1: short delay
	await get_tree().create_timer(2).timeout
	# 2: 
	enemy_chatter_1.anim
	enemy_chatter_1.play("YELLING")
	animation_player.play("IDLE_RIFLE")
	enemy_chatter_1.play()
	await enemy_chatter_1.finished
	await get_tree().create_timer(1).timeout
	enemy_chatter_2.play()
	await enemy_chatter_2.finished
