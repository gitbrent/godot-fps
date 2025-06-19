extends Node3D

signal target_enemy_poster_hit

@onready var label_hits: Label3D = $MeshFiringTarget/LabelHits
var total_hits: int = 0

func _ready() -> void:
	label_hits.text = str(total_hits)

func _on_area_3d_body_entered(body: Node3D) -> void:
	#print("TARGET ENEMY POSTER AREA hit!")
	emit_signal("target_enemy_poster_hit")
	total_hits += 1
	label_hits.text = str(total_hits)
