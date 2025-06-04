extends Node3D

#region
@export var enemy_scene: PackedScene
@export var exptgt_scene: PackedScene
@export var enemy_chat_scene: PackedScene
#
@onready var spawn1_marker_3d: Marker3D = $Spawn1/Marker3D
@onready var spawn2_marker_3d: Marker3D = $Spawn2/Marker3D
@onready var spawn3_mesh_3d: MeshInstance3D = $Spawn3/MeshInstance3D
@onready var spawn_6: Node3D = $Spawn6
#
const EXP_TARGET_POS: Vector3 = Vector3(7.5, 1.4, -8.2)
var active_enemies: Array[EnemyController] = []
var active_chatters: Node3D
var active_exp_tgt: StaticBody2D
#endregion

func _ready() -> void:
	spawn_exp_target()

func spawn_enemy() -> EnemyController:
	# 1:
	if not enemy_scene:
		print("[s_r] assert failed!")
		return null
	# 2:
	var new_enemy:EnemyController = enemy_scene.instantiate() as EnemyController
	get_tree().current_scene.add_child(new_enemy)
	# 3: Add the new enemy to your tracking array
	active_enemies.append(new_enemy)
	# 4: Connect to a signal from the enemy to know when it dies (or is removed)
	if new_enemy.has_signal("died"):
		new_enemy.died.connect(_on_enemy_died.bind(new_enemy))
	else:
		# Fallback: connect to tree_exited if no specific 'died' signal, though 'died' is better
		new_enemy.tree_exited.connect(Callable(self, "_on_enemy_removed_from_tree").bind(new_enemy))
	# LAST:
	return new_enemy

func spawn_chatters() -> void:
	# 1: check
	if not enemy_chat_scene:
		print("[s_r] assert failed!")
		return
	# 2: instantiate
	active_chatters = enemy_chat_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(active_chatters)
	# 3: position
	active_chatters.global_position = spawn3_mesh_3d.global_position

func spawn_exp_target() -> void:
	# 1:
	if not enemy_scene:
		print("[s_r] assert failed!")
		return
	# 2:
	var active_exp_tgt = exptgt_scene.instantiate() as exp_target
	spawn_6.add_child(active_exp_tgt)
	active_exp_tgt.global_position = EXP_TARGET_POS
	# 3: Add the new enemy to tracking array
	if active_exp_tgt.has_signal("exploded"):
		active_exp_tgt.exploded.connect(_on_target_exploded)

# --------------------------------------------------

func _on_player_controller_player_died() -> void:
	# When player dies, clear all active enemies
	for enemy in active_enemies:
		if is_instance_valid(enemy): # Always check if the instance is still valid before interacting
			enemy.queue_free()
	active_enemies.clear() # Clear the array after freeing them

func _on_target_exploded() -> void:
	#print("target exploded!")
	await get_tree().create_timer(2).timeout
	spawn_exp_target()

func _on_enemy_died(enemy_instance: EnemyController) -> void:
	# This function will be called when an enemy emits its 'died' signal
	if active_enemies.has(enemy_instance):
		active_enemies.erase(enemy_instance)
	# NOTE: can add logic here for scoring, wave progression, etc.
	print("Enemy died! Active enemies remaining: ", active_enemies.size())

func _on_enemy_removed_from_tree(enemy_instance: EnemyController) -> void:
	# Fallback if no 'died' signal. Less explicit but still works.
	if active_enemies.has(enemy_instance):
		active_enemies.erase(enemy_instance)
	print("Enemy removed from tree. Active enemies remaining: ", active_enemies.size())

func _on_target_poster_1_poster_hit() -> void:
	var new_enemy = spawn_enemy()
	new_enemy.global_position = spawn1_marker_3d.global_position
	new_enemy.state_machine.request_state_change('attack')
	new_enemy.can_patrol = true

func _on_target_poster_2_poster_hit() -> void:
	var new_enemy = spawn_enemy()
	new_enemy.global_position = spawn2_marker_3d.global_position
	new_enemy.state_machine.request_state_change('idle')
	new_enemy.can_patrol = false

func _on_target_poster_3_poster_hit() -> void:
	spawn_chatters()
