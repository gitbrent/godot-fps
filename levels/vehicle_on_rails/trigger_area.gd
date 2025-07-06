extends Node3D

signal enemy_truck_triggered

## Triggered when `PlayerController` collides
func _on_area_3d_body_entered(body: Node3D) -> void:
	emit_signal("enemy_truck_triggered")
