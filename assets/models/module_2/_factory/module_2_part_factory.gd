class_name Module2PartFactory
extends RefCounted

## Procedural teaching meshes for Module 2 network parts.
## One folder under assets/models/module_2/<part_id>/ = one item.


static func build_into(root: Node3D, part_id: String) -> void:
	match part_id:
		"modem":
			Module1PartFactory.build_into(root, "modem")
		"router":
			Module1PartFactory.build_into(root, "router")
		"switch":
			Module1PartFactory.build_into(root, "switch")
		"access_point":
			Module1PartFactory.build_into(root, "access_point")
		"ethernet_cable":
			Module1PartFactory.build_into(root, "ethernet_cable")
		"workstation", "laptop":
			Module1PartFactory.build_into(root, "laptop")
		"monitor":
			Module1PartFactory.build_into(root, "monitor")
		"keyboard":
			Module1PartFactory.build_into(root, "keyboard")
		"hub":
			_build_hub(root)
		"nic":
			_build_nic(root)
		"repeater":
			_build_repeater(root)
		"firewall":
			_build_firewall(root)
		"fiber_cable":
			_build_fiber_cable(root)
		"patch_panel":
			_build_patch_panel(root)
		"rj45":
			_build_rj45(root)
		"crimper":
			_build_crimper(root)
		"cable_tester":
			_build_cable_tester(root)
		_:
			Module1PartFactory.build_into(root, part_id)


static func _mat(color: Color, metallic: float = 0.08, roughness: float = 0.55) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.22
	return mat


static func _mesh(root: Node, name: String, mesh: Mesh, material: Material, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation = rot
	root.add_child(mi)
	return mi


static func _box(root: Node, name: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(root, name, box, material, pos)


static func _cyl(root: Node, name: String, pos: Vector3, radius: float, height: float, material: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 24
	return _mesh(root, name, cyl, material, pos, rot)


static func _build_hub(root: Node3D) -> void:
	var body := _mat(Color(0.75, 0.78, 0.82), 0.1, 0.55)
	var port := _mat(Color(0.25, 0.28, 0.32), 0.1, 0.5)
	var led := _mat(Color(0.95, 0.55, 0.15))
	led.emission_energy_multiplier = 0.85
	_box(root, "Body", Vector3.ZERO, Vector3(2.6, 0.4, 1.3), body)
	for i in 5:
		var x := -1.0 + i * 0.5
		_box(root, "Port%d" % i, Vector3(x, 0, 0.62), Vector3(0.32, 0.2, 0.12), port)
		_box(root, "Led%d" % i, Vector3(x, 0.14, 0.66), Vector3(0.1, 0.06, 0.04), led)


static func _build_nic(root: Node3D) -> void:
	var pcb := _mat(Color(0.08, 0.45, 0.22))
	var bracket := _mat(Color(0.7, 0.72, 0.76), 0.45, 0.35)
	var port := _mat(Color(0.2, 0.22, 0.26))
	var chip := _mat(Color(0.1, 0.1, 0.12), 0.05, 0.7)
	_box(root, "PCB", Vector3.ZERO, Vector3(2.2, 0.08, 1.2), pcb)
	_box(root, "Chip", Vector3(-0.2, 0.1, 0), Vector3(0.7, 0.12, 0.7), chip)
	_box(root, "Bracket", Vector3(1.15, 0.15, 0), Vector3(0.12, 1.0, 1.3), bracket)
	_box(root, "RJ45", Vector3(1.05, 0.05, 0.15), Vector3(0.35, 0.28, 0.35), port)


static func _build_repeater(root: Node3D) -> void:
	var body := _mat(Color(0.15, 0.16, 0.2), 0.15, 0.5)
	var antenna := _mat(Color(0.08, 0.08, 0.1))
	var led := _mat(Color(0.09, 0.65, 0.87))
	led.emission_energy_multiplier = 0.9
	_box(root, "Body", Vector3.ZERO, Vector3(1.4, 1.6, 0.7), body)
	_cyl(root, "AntL", Vector3(-0.45, 1.3, 0), 0.05, 1.2, antenna)
	_cyl(root, "AntR", Vector3(0.45, 1.3, 0), 0.05, 1.2, antenna)
	_box(root, "Status", Vector3(0, 0.4, 0.36), Vector3(0.25, 0.12, 0.05), led)
	_box(root, "Plug", Vector3(0, -0.95, 0), Vector3(0.35, 0.35, 0.25), _mat(Color(0.85, 0.85, 0.88)))


static func _build_firewall(root: Node3D) -> void:
	var body := _mat(Color(0.12, 0.14, 0.18), 0.2, 0.45)
	var accent := _mat(Color(0.85, 0.25, 0.2))
	accent.emission_energy_multiplier = 0.55
	var port := _mat(Color(0.22, 0.24, 0.28))
	_box(root, "Chassis", Vector3.ZERO, Vector3(3.0, 0.5, 1.6), body)
	_box(root, "Badge", Vector3(-1.1, 0.1, 0.78), Vector3(0.5, 0.2, 0.05), accent)
	for i in 4:
		_box(root, "Port%d" % i, Vector3(-0.3 + i * 0.45, 0, 0.78), Vector3(0.32, 0.22, 0.12), port)


static func _build_fiber_cable(root: Node3D) -> void:
	var jacket := _mat(Color(0.95, 0.85, 0.2), 0.05, 0.5)
	var ferrule := _mat(Color(0.75, 0.78, 0.82), 0.35, 0.35)
	var core := _mat(Color(0.4, 0.85, 1.0))
	core.emission_energy_multiplier = 0.8
	_cyl(root, "Fiber", Vector3.ZERO, 0.06, 2.2, jacket, Vector3(0, 0, deg_to_rad(90)))
	_cyl(root, "FerruleL", Vector3(-1.25, 0, 0), 0.1, 0.35, ferrule, Vector3(0, 0, deg_to_rad(90)))
	_cyl(root, "FerruleR", Vector3(1.25, 0, 0), 0.1, 0.35, ferrule, Vector3(0, 0, deg_to_rad(90)))
	_cyl(root, "CoreL", Vector3(-1.4, 0, 0), 0.03, 0.12, core, Vector3(0, 0, deg_to_rad(90)))
	_cyl(root, "CoreR", Vector3(1.4, 0, 0), 0.03, 0.12, core, Vector3(0, 0, deg_to_rad(90)))


static func _build_patch_panel(root: Node3D) -> void:
	var frame := _mat(Color(0.18, 0.2, 0.24), 0.2, 0.45)
	var port := _mat(Color(0.25, 0.28, 0.32))
	var label := _mat(Color(0.9, 0.9, 0.92))
	_box(root, "Frame", Vector3.ZERO, Vector3(3.4, 0.55, 0.9), frame)
	for row in 2:
		for i in 6:
			var x := -1.4 + i * 0.55
			var y := 0.12 - row * 0.28
			_box(root, "Port_%d_%d" % [row, i], Vector3(x, y, 0.42), Vector3(0.4, 0.18, 0.12), port)
	_box(root, "LabelStrip", Vector3(0, 0.28, 0.4), Vector3(3.0, 0.06, 0.04), label)


static func _build_rj45(root: Node3D) -> void:
	var body := _mat(Color(0.8, 0.88, 0.92), 0.05, 0.35)
	var gold := _mat(Color(0.9, 0.75, 0.25), 0.6, 0.3)
	var latch := _mat(Color(0.7, 0.75, 0.8))
	_box(root, "Plug", Vector3.ZERO, Vector3(0.55, 0.35, 0.45), body)
	_box(root, "Contacts", Vector3(0.28, 0.02, 0), Vector3(0.08, 0.2, 0.35), gold)
	_box(root, "Latch", Vector3(-0.15, 0.22, 0), Vector3(0.25, 0.08, 0.2), latch)


static func _build_crimper(root: Node3D) -> void:
	var handle := _mat(Color(0.12, 0.45, 0.75))
	var steel := _mat(Color(0.7, 0.72, 0.76), 0.55, 0.3)
	_box(root, "HandleL", Vector3(-0.55, -0.5, 0), Vector3(0.25, 1.4, 0.2), handle)
	_box(root, "HandleR", Vector3(0.55, -0.5, 0), Vector3(0.25, 1.4, 0.2), handle)
	_box(root, "Jaw", Vector3(0, 0.45, 0), Vector3(1.3, 0.35, 0.35), steel)
	_box(root, "Die", Vector3(0, 0.55, 0.1), Vector3(0.7, 0.2, 0.25), _mat(Color(0.45, 0.48, 0.52), 0.4, 0.4))


static func _build_cable_tester(root: Node3D) -> void:
	var body := _mat(Color(0.95, 0.55, 0.12))
	var face := _mat(Color(0.12, 0.14, 0.18))
	var led := _mat(Color(0.2, 0.95, 0.4))
	led.emission_energy_multiplier = 0.9
	var port := _mat(Color(0.25, 0.28, 0.32))
	_box(root, "Body", Vector3.ZERO, Vector3(1.6, 0.45, 2.2), body)
	_box(root, "Face", Vector3(0, 0.2, 0.2), Vector3(1.2, 0.08, 1.4), face)
	for i in 8:
		_box(root, "Led%d" % i, Vector3(-0.7 + i * 0.2, 0.26, 0.5), Vector3(0.12, 0.05, 0.12), led)
	_box(root, "RJ45", Vector3(0, 0.05, -0.95), Vector3(0.45, 0.28, 0.35), port)
