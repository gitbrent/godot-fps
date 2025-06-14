extends Node3D

@onready var camera_pivot: Node3D = $CameraPivot
var rotation_speed: float = 0.5

func _process(delta: float) -> void:
	camera_pivot.rotation.y += delta * rotation_speed
