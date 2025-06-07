extends StaticBody3D

@export var broken_model: PackedScene = preload("res://shooting_range/exp_target_new/ExpTarget_Pieces.tscn")

func do_explode():
	var broken_model_inst:Node3D = broken_model.instantiate();
	get_parent().add_child(broken_model_inst);
	broken_model_inst.transform = self.transform;
	self.queue_free();

func _on_area_3d_body_entered(body: Node3D) -> void:
	print("[exp_t] body_entered: ", body)
	do_explode()
