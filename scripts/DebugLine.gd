extends MeshInstance3D

func draw_line(from: Vector3, to: Vector3, color: Color = Color.RED, duration: float = 1.0) -> void :
	var immediate_mesh: = ImmediateMesh.new()
	var material: = StandardMaterial3D.new()


	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.no_depth_test = true


	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()

	self.mesh = immediate_mesh


	var tween: = create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, duration)
	tween.tween_callback(queue_free)
