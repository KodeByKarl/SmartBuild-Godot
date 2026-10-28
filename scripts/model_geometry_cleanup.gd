class_name ModelGeometryCleanup
extends RefCounted

## Hides baked junk volumes such as the Sketchfab placa-base AM4 socket cube
## (a ~65k-vert white block that sits on the motherboard and blocks the board).


static func strip_placeholder_volumes(root: Node) -> void:
	if root == null:
		return

	var to_remove: Array[Node] = []
	_collect(root, to_remove)

	for node in to_remove:
		if not is_instance_valid(node):
			continue
		_hide_mesh_tree(node)
		if node.is_inside_tree():
			node.free()
		else:
			node.queue_free()


static func _collect(node: Node, out: Array[Node]) -> void:
	if _is_junk_node(node):
		out.append(node)
		return
	for child in node.get_children():
		_collect(child, out)


static func _is_junk_node(node: Node) -> bool:
	var lower_name := String(node.name).to_lower()
	if (
		lower_name.contains("am4")
		or lower_name.contains("socket")
		or lower_name.contains("_removed")
		or lower_name.contains("hidden_am4")
		or lower_name.contains("ground")
		or lower_name.contains("floor")
	):
		return true

	if not (node is MeshInstance3D):
		# Importer nodes: only strip known junk names, never by vertex count.
		return false

	var mesh_instance := node as MeshInstance3D
	var mesh_name := ""
	if mesh_instance.mesh != null:
		mesh_name = String(mesh_instance.mesh.resource_name).to_lower()
	if mesh_name.contains("hidden_am4") or mesh_name.contains("am4"):
		return true

	# Never delete high-poly meshes by vertex count alone — modern Sketchfab
	# cases/keyboards commonly ship 65k+ verts per surface. Name / cube checks only.
	if mesh_instance.is_inside_tree() and _is_oversized_world_cube(mesh_instance):
		return true

	return false


static func _importer_vertex_count(node: Node) -> int:
	if node.get_class() != "ImporterMeshInstance3D":
		return 0
	var importer_mesh = node.get("mesh")
	if importer_mesh == null or not importer_mesh.has_method("get_surface_count"):
		return 0
	var total := 0
	for surface_index in importer_mesh.get_surface_count():
		var arrays: Array = importer_mesh.get_surface_arrays(surface_index)
		if arrays.is_empty() or arrays[0] == null:
			continue
		total += arrays[0].size()
	return total


static func _surface_vertex_count(mesh_instance: MeshInstance3D) -> int:
	var mesh := mesh_instance.mesh
	if mesh == null:
		return 0
	if mesh is ArrayMesh:
		var array_mesh := mesh as ArrayMesh
		var total := 0
		for surface_index in array_mesh.get_surface_count():
			total += array_mesh.surface_get_array_len(surface_index)
		return total
	return 0


static func _is_oversized_world_cube(mesh_instance: MeshInstance3D) -> bool:
	var aabb: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
	var size := aabb.size
	var longest := maxf(size.x, maxf(size.y, size.z))
	var shortest := minf(size.x, minf(size.y, size.z))
	if longest < 1.1:
		return false
	var cube_like := shortest > longest * 0.35
	var volume := size.x * size.y * size.z
	return cube_like and volume > 4.0


static func _hide_mesh_tree(node: Node) -> void:
	if node is CanvasItem or node is Node3D:
		node.visible = false
	if node is MeshInstance3D:
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_hide_mesh_tree(child)
