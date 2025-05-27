## NOTE: we could have also just added this to the `damagable` global group
## and listened for projectiles to hit as well.
extends StaticBody3D
class_name TargetPoster

signal poster_hit

func _on_area_3d_body_entered(body: Node3D) -> void:
	#print("TargetPoster hit by: ", body)
	emit_signal("poster_hit")
