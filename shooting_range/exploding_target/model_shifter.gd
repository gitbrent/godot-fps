extends StaticBody3D
class_name exp_target

signal exploded

@export var broken_model: PackedScene = preload("res://shooting_range/exploding_target/ExplodingTarget_Pieces_Modified.tscn")

func do_explode():
	var broken_model_inst:Node3D = broken_model.instantiate()
	get_parent().add_child(broken_model_inst)
	broken_model_inst.transform = self.transform
	emit_signal("exploded")
	self.queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	#print("[m_s] body_entered: ", body)
	do_explode()
