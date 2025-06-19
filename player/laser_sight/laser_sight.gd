# laser_sight.gd
extends MeshInstance3D

var draw_mesh: ImmediateMesh
var laser_material: StandardMaterial3D # Export or create a material

func _ready():
	draw_mesh = ImmediateMesh.new()
	mesh = draw_mesh # Assign the ImmediateMesh to the MeshInstance3D's mesh property

	# Example: Create a simple red material if not exported
	if laser_material == null:
		laser_material = StandardMaterial3D.new()
		laser_material.albedo_color = Color(1, 0, 0, 1) # Red
		laser_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED # For a bright, flat color
		laser_material.grow = 0.01 # Make it slightly larger to avoid Z-fighting sometimes
		# Consider using a ShaderMaterial for more advanced laser effects (glow, animated texture)

func draw_laser_line(p_start: Vector3, p_end: Vector3):
	if not is_instance_valid(draw_mesh): return

	draw_mesh.clear_surfaces() # Clear previous lines

	draw_mesh.surface_begin(Mesh.PRIMITIVE_LINES, laser_material)
	draw_mesh.surface_add_vertex(p_start)
	draw_mesh.surface_add_vertex(p_end)
	draw_mesh.surface_end()
