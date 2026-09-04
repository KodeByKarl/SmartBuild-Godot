class_name Module1PartFactory
extends RefCounted

## Builds clean, origin-centered teaching meshes for Module 1 parts.
## Strong signature colors so each part is identifiable at a glance.


static func build_into(root: Node3D, part_id: String) -> void:
	match part_id:
		"motherboard":
			_build_motherboard(root)
		"cpu":
			_build_cpu(root)
		"ram":
			_build_ram(root)
		"chips":
			_build_chips(root)
		"ssd":
			_build_ssd(root)
		"hdd":
			_build_hdd(root)
		"flash":
			_build_flash(root)
		"psu":
			_build_psu(root)
		"gpu":
			_build_gpu(root)
		"atx":
			_build_atx(root)
		"case":
			_build_case(root)
		"fan":
			_build_fan(root)
		"antistatic":
			_build_antistatic(root)
		"screwdriver":
			_build_screwdriver(root)
		"monitor":
			_build_monitor(root)
		"keyboard":
			_build_keyboard(root)
		"mouse":
			_build_mouse(root)
		"laptop":
			_build_laptop(root)
		"router":
			_build_router(root)
		"modem":
			_build_modem(root)
		"switch":
			_build_switch(root)
		"access_point":
			_build_access_point(root)
		"ethernet_cable":
			_build_ethernet_cable(root)
		"server":
			_build_server(root)
		"nas":
			_build_nas(root)
		_:
			_box(root, "Unknown", Vector3.ZERO, Vector3(1.2, 0.4, 0.8), _mat(Color(0.9, 0.2, 0.7)))


static func _mat(color: Color, metallic: float = 0.08, roughness: float = 0.55) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	# Soft glow so saturated colors read clearly in the dark lab.
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


static func _build_motherboard(root: Node3D) -> void:
	# Flat ATX teaching board — green PCB + sockets (no Sketchfab weight).
	var board := _mat(Color(0.06, 0.48, 0.22))
	var socket := _mat(Color(0.12, 0.12, 0.14), 0.15, 0.55)
	var gold := _mat(Color(0.9, 0.72, 0.18), 0.65, 0.32)
	var dimm := _mat(Color(0.15, 0.55, 0.95))
	_box(root, "PCB", Vector3.ZERO, Vector3(3.2, 0.08, 2.6), board)
	_box(root, "CPUSocket", Vector3(-0.35, 0.12, 0.15), Vector3(0.9, 0.16, 0.9), socket)
	_box(root, "Triangle", Vector3(-0.72, 0.18, 0.5), Vector3(0.12, 0.05, 0.12), gold)
	for i in 4:
		_box(root, "DIMM%d" % i, Vector3(1.0, 0.2, -0.7 + i * 0.35), Vector3(0.12, 0.35, 0.95), dimm)
	_box(root, "PCIe", Vector3(0.1, 0.1, -0.95), Vector3(2.0, 0.1, 0.18), gold)
	_box(root, "IOShield", Vector3(-1.55, 0.25, 0), Vector3(0.12, 0.55, 2.2), _mat(Color(0.55, 0.58, 0.62), 0.4, 0.4))


static func _build_cpu(root: Node3D) -> void:
	var ceramic := _mat(Color(0.18, 0.2, 0.24), 0.05, 0.7)
	var metal := _mat(Color(0.75, 0.78, 0.82), 0.55, 0.3)
	var gold := _mat(Color(0.92, 0.74, 0.2), 0.7, 0.28)
	_box(root, "IHS", Vector3(0, 0.08, 0), Vector3(1.35, 0.12, 1.35), metal)
	_box(root, "Substrate", Vector3.ZERO, Vector3(1.55, 0.08, 1.55), ceramic)
	_box(root, "Pin1", Vector3(-0.65, 0.16, 0.65), Vector3(0.12, 0.04, 0.12), gold)
	for x in 3:
		for z in 3:
			_box(
				root,
				"Pad_%d_%d" % [x, z],
				Vector3(-0.35 + x * 0.35, -0.08, -0.35 + z * 0.35),
				Vector3(0.12, 0.05, 0.12),
				gold
			)


static func _build_ram(root: Node3D) -> void:
	var pcb := _mat(Color(0.08, 0.35, 0.75))
	var chip := _mat(Color(0.08, 0.08, 0.1), 0.05, 0.7)
	var gold := _mat(Color(0.92, 0.74, 0.18), 0.7, 0.28)
	_box(root, "Module", Vector3.ZERO, Vector3(2.4, 0.9, 0.12), pcb)
	_box(root, "Edge", Vector3(0, -0.52, 0), Vector3(2.2, 0.18, 0.06), gold)
	for i in 4:
		_box(root, "IC%d" % i, Vector3(-0.75 + i * 0.5, 0.1, 0.08), Vector3(0.35, 0.45, 0.06), chip)


static func _build_chips(root: Node3D) -> void:
	# Signature: PCB green board + black ICs
	var board := _mat(Color(0.08, 0.62, 0.28))
	var black := _mat(Color(0.08, 0.08, 0.1), 0.05, 0.75)
	var silver := _mat(Color(0.78, 0.8, 0.85), 0.55, 0.3)
	_box(root, "Carrier", Vector3(0, -0.08, 0), Vector3(2.4, 0.08, 1.6), board)
	_box(root, "Chipset", Vector3(-0.45, 0.08, 0.1), Vector3(0.9, 0.16, 0.9), black)
	_box(root, "BiosChip", Vector3(0.7, 0.06, -0.35), Vector3(0.45, 0.12, 0.55), black)
	_box(root, "Controller", Vector3(0.55, 0.05, 0.4), Vector3(0.55, 0.1, 0.35), black)
	for i in 6:
		_box(root, "Cap%d" % i, Vector3(-0.9 + i * 0.28, 0.05, -0.55), Vector3(0.12, 0.1, 0.12), silver)


static func _build_ssd(root: Node3D) -> void:
	# Signature: blue enclosure
	var body := _mat(Color(0.12, 0.42, 0.92), 0.2, 0.4)
	var label := _mat(Color(0.98, 0.98, 1.0), 0.02, 0.7)
	var gold := _mat(Color(0.95, 0.75, 0.15), 0.7, 0.28)
	_box(root, "Enclosure", Vector3.ZERO, Vector3(2.4, 0.22, 1.55), body)
	_box(root, "Label", Vector3(0, 0.12, 0.05), Vector3(1.6, 0.02, 0.9), label)
	_box(root, "SataData", Vector3(1.05, 0, -0.55), Vector3(0.25, 0.12, 0.35), gold)
	_box(root, "SataPower", Vector3(1.05, 0, 0.35), Vector3(0.25, 0.12, 0.55), gold)


static func _build_hdd(root: Node3D) -> void:
	# Signature: silver metal + amber label
	var body := _mat(Color(0.72, 0.74, 0.78), 0.6, 0.32)
	var dark := _mat(Color(0.18, 0.18, 0.2), 0.25, 0.5)
	var label := _mat(Color(1.0, 0.72, 0.12))
	_box(root, "Chassis", Vector3.ZERO, Vector3(2.6, 0.55, 1.8), body)
	_box(root, "TopPlate", Vector3(0, 0.29, 0), Vector3(2.45, 0.04, 1.65), dark)
	_box(root, "Label", Vector3(0.2, 0.32, 0.15), Vector3(1.4, 0.02, 0.8), label)
	_cyl(root, "PlatterHint", Vector3(-0.35, 0.05, 0), 0.55, 0.08, _mat(Color(0.85, 0.86, 0.9), 0.85, 0.18))
	_box(root, "Connector", Vector3(1.2, -0.05, 0), Vector3(0.2, 0.25, 0.9), dark)


static func _build_flash(root: Node3D) -> void:
	# Signature: bright cyan stick
	var body := _mat(Color(0.05, 0.78, 0.88))
	var tip := _mat(Color(0.82, 0.84, 0.88), 0.55, 0.3)
	var cap := _mat(Color(0.02, 0.55, 0.65))
	_box(root, "Body", Vector3(0, 0, 0.15), Vector3(0.7, 0.28, 1.5), body)
	_box(root, "UsbMetal", Vector3(0, 0, -0.95), Vector3(0.5, 0.16, 0.55), tip)
	_box(root, "Cap", Vector3(0, 0, 1.05), Vector3(0.74, 0.32, 0.35), cap)


static func _build_psu(root: Node3D) -> void:
	# Signature: black box + yellow warning stripe
	var body := _mat(Color(0.1, 0.1, 0.12), 0.2, 0.45)
	var grill := _mat(Color(0.35, 0.36, 0.4), 0.35, 0.4)
	var warn := _mat(Color(1.0, 0.85, 0.05))
	var accent := _mat(Color(0.95, 0.2, 0.15))
	_box(root, "Chassis", Vector3.ZERO, Vector3(2.8, 1.5, 2.4), body)
	_cyl(root, "FanGrill", Vector3(0, 0.2, 1.15), 0.85, 0.08, grill, Vector3(deg_to_rad(90), 0, 0))
	_box(root, "IEC", Vector3(1.1, -0.35, 1.15), Vector3(0.45, 0.35, 0.15), grill)
	_box(root, "Switch", Vector3(0.55, -0.35, 1.15), Vector3(0.25, 0.25, 0.12), accent)
	_box(root, "WarnStripe", Vector3(0, 0.76, 0), Vector3(2.2, 0.04, 0.35), warn)
	for i in 4:
		_box(root, "Cable%d" % i, Vector3(-1.2, -0.35 + i * 0.2, -1.15), Vector3(0.35, 0.08, 0.2), _mat(Color(0.05, 0.05, 0.06)))


static func _build_gpu(root: Node3D) -> void:
	# Signature: dual-fan shroud + rear I/O bracket + gold PCIe edge
	var shroud := _mat(Color(0.12, 0.55, 0.28), 0.15, 0.45)
	var metal := _mat(Color(0.55, 0.58, 0.62), 0.45, 0.35)
	var edge := _mat(Color(0.95, 0.75, 0.15), 0.7, 0.3)
	var fan := _mat(Color(0.18, 0.2, 0.22), 0.2, 0.5)
	_box(root, "Shroud", Vector3.ZERO, Vector3(2.6, 0.7, 1.2), shroud)
	_box(root, "Bracket", Vector3(1.35, 0.05, 0), Vector3(0.12, 1.1, 1.35), metal)
	_box(root, "PCIeEdge", Vector3(0, -0.4, 0), Vector3(2.0, 0.08, 0.22), edge)
	_cyl(root, "FanL", Vector3(-0.55, 0.38, 0), 0.42, 0.06, fan, Vector3(deg_to_rad(90), 0, 0))
	_cyl(root, "FanR", Vector3(0.55, 0.38, 0), 0.42, 0.06, fan, Vector3(deg_to_rad(90), 0, 0))
	_box(root, "Power8", Vector3(-1.15, 0.15, -0.55), Vector3(0.35, 0.22, 0.25), metal)


static func _build_atx(root: Node3D) -> void:
	# Signature: white housing + gold pins + red latch
	var shell := _mat(Color(0.96, 0.96, 0.98), 0.02, 0.65)
	var pin := _mat(Color(0.95, 0.72, 0.1), 0.75, 0.28)
	var latch := _mat(Color(0.9, 0.15, 0.12))
	_box(root, "Housing", Vector3.ZERO, Vector3(2.2, 0.55, 0.85), shell)
	_box(root, "Latch", Vector3(0, 0.35, 0), Vector3(0.7, 0.15, 0.35), latch)
	for row in 2:
		for col in 12:
			_box(
				root,
				"Pin_%d_%d" % [row, col],
				Vector3(-1.0 + col * 0.17, -0.05, -0.18 + row * 0.35),
				Vector3(0.08, 0.22, 0.08),
				pin
			)


static func _build_case(root: Node3D) -> void:
	# Signature: charcoal tower + teal window accent
	var metal := _mat(Color(0.22, 0.24, 0.3), 0.4, 0.4)
	var glass := _mat(Color(0.15, 0.75, 0.85, 0.45), 0.05, 0.15)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var accent := _mat(Color(0.1, 0.95, 0.75))
	_box(root, "Body", Vector3.ZERO, Vector3(2.2, 3.4, 3.0), metal)
	_box(root, "SideWindow", Vector3(1.12, 0.1, 0), Vector3(0.06, 2.6, 2.4), glass)
	_box(root, "Front", Vector3(0, 0, 1.52), Vector3(2.0, 3.2, 0.08), metal)
	_box(root, "PowerLed", Vector3(-0.7, 1.3, 1.56), Vector3(0.2, 0.1, 0.05), accent)
	_box(root, "FeetL", Vector3(-0.7, -1.75, 0.9), Vector3(0.35, 0.1, 0.35), metal)
	_box(root, "FeetR", Vector3(0.7, -1.75, 0.9), Vector3(0.35, 0.1, 0.35), metal)


static func _build_fan(root: Node3D) -> void:
	# Signature: black frame + orange blades
	var frame := _mat(Color(0.12, 0.12, 0.14), 0.25, 0.45)
	var blade := _mat(Color(1.0, 0.45, 0.08))
	var hub := _mat(Color(0.35, 0.35, 0.38), 0.3, 0.4)
	_box(root, "Frame", Vector3.ZERO, Vector3(2.2, 2.2, 0.35), frame)
	_cyl(root, "Hub", Vector3.ZERO, 0.35, 0.4, hub, Vector3(deg_to_rad(90), 0, 0))
	var blades := Node3D.new()
	blades.name = "Blades"
	root.add_child(blades)
	for i in 7:
		var angle := float(i) / 7.0 * TAU
		var b := BoxMesh.new()
		b.size = Vector3(0.28, 0.9, 0.06)
		var mi := MeshInstance3D.new()
		mi.name = "Blade%d" % i
		mi.mesh = b
		mi.material_override = blade
		mi.position = Vector3(cos(angle) * 0.55, sin(angle) * 0.55, 0)
		mi.rotation = Vector3(0, 0, angle)
		blades.add_child(mi)


static func _build_antistatic(root: Node3D) -> void:
	# Highly detailed ESD workstation kit: quilted mat, wrist strap, coiled cord, clip.
	var blue := _mat(Color(0.08, 0.32, 0.92))
	var blue_dark := _mat(Color(0.05, 0.22, 0.7))
	var blue_light := _mat(Color(0.25, 0.55, 0.98))
	var black := _mat(Color(0.06, 0.06, 0.08), 0.1, 0.65)
	var yellow := _mat(Color(1.0, 0.82, 0.05))
	var yellow_dark := _mat(Color(0.85, 0.65, 0.0))
	var metal := _mat(Color(0.78, 0.8, 0.85), 0.7, 0.28)
	var metal_dark := _mat(Color(0.45, 0.47, 0.5), 0.65, 0.35)
	var rubber := _mat(Color(0.12, 0.12, 0.14), 0.05, 0.8)
	var white := _mat(Color(0.95, 0.95, 0.97), 0.02, 0.7)

	# --- Mat body (layered) ---
	_box(root, "MatCore", Vector3(0, -0.12, 0), Vector3(3.6, 0.06, 2.4), blue)
	_box(root, "MatUnderside", Vector3(0, -0.17, 0), Vector3(3.55, 0.04, 2.35), black)
	_box(root, "MatBorderOuter", Vector3(0, -0.08, 0), Vector3(3.7, 0.05, 2.5), blue_dark)
	_box(root, "MatBorderInner", Vector3(0, -0.06, 0), Vector3(3.4, 0.03, 2.2), blue_light)

	# Quilted / dissipative pad grid
	for gx in 10:
		for gz in 6:
			var px := -1.5 + gx * 0.33
			var pz := -0.9 + gz * 0.32
			var pad_mat := blue if ((gx + gz) % 2 == 0) else blue_dark
			_box(root, "Quilt_%d_%d" % [gx, gz], Vector3(px, -0.055, pz), Vector3(0.28, 0.035, 0.26), pad_mat)

	# Yellow ESD caution stripe + label plate
	_box(root, "WarnStripe", Vector3(0, -0.04, 1.05), Vector3(3.2, 0.025, 0.22), yellow)
	_box(root, "WarnStripeEdge", Vector3(0, -0.03, 1.05), Vector3(3.15, 0.01, 0.08), yellow_dark)
	_box(root, "LabelPlate", Vector3(1.1, -0.03, -0.95), Vector3(1.0, 0.02, 0.35), yellow)
	_box(root, "LabelTextBar1", Vector3(1.1, -0.015, -0.9), Vector3(0.75, 0.01, 0.06), black)
	_box(root, "LabelTextBar2", Vector3(1.1, -0.015, -1.0), Vector3(0.55, 0.01, 0.05), black)
	# ESD triangle mark
	_box(root, "EsdMark", Vector3(-1.25, -0.03, -0.95), Vector3(0.35, 0.02, 0.35), yellow)
	_box(root, "EsdMarkInner", Vector3(-1.25, -0.015, -0.95), Vector3(0.18, 0.01, 0.18), black)

	# Common-point ground snap on corner
	_cyl(root, "CpgBase", Vector3(-1.55, -0.02, 0.95), 0.12, 0.06, metal_dark)
	_cyl(root, "CpgSnap", Vector3(-1.55, 0.02, 0.95), 0.08, 0.05, metal)
	_cyl(root, "CpgStud", Vector3(-1.55, 0.06, 0.95), 0.04, 0.04, metal)

	# Corner rivets
	for i in 4:
		var sx := -1.0 if i < 2 else 1.0
		var sz := -1.0 if i % 2 == 0 else 1.0
		_cyl(root, "Rivet%d" % i, Vector3(sx * 1.7, -0.04, sz * 1.1), 0.05, 0.04, metal_dark)

	# --- Wrist strap assembly ---
	var strap := Node3D.new()
	strap.name = "WristStrap"
	strap.position = Vector3(-1.05, 0.22, 0.35)
	root.add_child(strap)

	# Soft band segments (elastic look)
	for i in 16:
		var a := float(i) / 16.0 * TAU
		var r := 0.38
		_box(
			strap,
			"BandSeg%d" % i,
			Vector3(cos(a) * r, 0.0, sin(a) * r * 0.55),
			Vector3(0.14, 0.08, 0.1),
			blue if i % 2 == 0 else blue_dark
		)
	# Inner conductive plate
	_box(strap, "ContactPlate", Vector3(0.38, -0.02, 0), Vector3(0.08, 0.05, 0.28), metal)
	_box(strap, "ContactPad", Vector3(0.42, -0.04, 0), Vector3(0.04, 0.03, 0.22), metal_dark)
	# Adjustable buckle
	_box(strap, "BuckleBody", Vector3(-0.4, 0.02, 0), Vector3(0.22, 0.1, 0.18), metal)
	_box(strap, "BuckleSlot", Vector3(-0.4, 0.06, 0), Vector3(0.14, 0.03, 0.1), black)
	_box(strap, "BucklePin", Vector3(-0.4, 0.08, 0), Vector3(0.03, 0.06, 0.12), metal_dark)
	# Snap connector on strap
	_cyl(strap, "StrapSnap", Vector3(0.15, 0.08, 0.28), 0.07, 0.05, metal, Vector3(deg_to_rad(90), 0, 0))
	_cyl(strap, "StrapSnapStud", Vector3(0.15, 0.12, 0.28), 0.035, 0.04, metal_dark)

	# --- Coiled ESD cord (helix of rings) ---
	var cord := Node3D.new()
	cord.name = "CoiledCord"
	cord.position = Vector3(-0.15, 0.18, 0.55)
	root.add_child(cord)
	for i in 18:
		var t := float(i) / 17.0
		var ang := t * TAU * 4.5
		var cx := t * 1.55
		var cy := sin(ang) * 0.12
		var cz := cos(ang) * 0.12
		_cyl(cord, "Coil%d" % i, Vector3(cx, cy, cz), 0.055, 0.09, black, Vector3(0, ang, deg_to_rad(90)))
	# Cord ends / boots
	_cyl(cord, "BootStrap", Vector3(-0.05, 0, 0), 0.07, 0.12, rubber, Vector3(0, 0, deg_to_rad(90)))
	_cyl(cord, "BootClip", Vector3(1.6, 0, 0), 0.07, 0.12, rubber, Vector3(0, 0, deg_to_rad(90)))
	_box(cord, "LeadIn", Vector3(-0.25, 0, -0.15), Vector3(0.35, 0.05, 0.05), black)
	_box(cord, "LeadOut", Vector3(1.85, 0, 0.05), Vector3(0.4, 0.05, 0.05), black)

	# --- Alligator clip (detailed jaws) ---
	var clip := Node3D.new()
	clip.name = "AlligatorClip"
	clip.position = Vector3(1.55, 0.2, 0.55)
	clip.rotation = Vector3(0, deg_to_rad(-25), deg_to_rad(12))
	root.add_child(clip)
	_box(clip, "HandleTop", Vector3(-0.12, 0.06, 0), Vector3(0.35, 0.08, 0.16), metal)
	_box(clip, "HandleBot", Vector3(-0.12, -0.06, 0), Vector3(0.35, 0.08, 0.16), metal_dark)
	_box(clip, "GripTop", Vector3(-0.22, 0.07, 0), Vector3(0.12, 0.06, 0.14), rubber)
	_box(clip, "GripBot", Vector3(-0.22, -0.07, 0), Vector3(0.12, 0.06, 0.14), rubber)
	_box(clip, "JawTop", Vector3(0.22, 0.04, 0), Vector3(0.32, 0.05, 0.14), metal)
	_box(clip, "JawBot", Vector3(0.22, -0.04, 0), Vector3(0.32, 0.05, 0.14), metal_dark)
	# Serrated teeth
	for i in 5:
		_box(clip, "ToothT%d" % i, Vector3(0.12 + i * 0.06, 0.01, 0), Vector3(0.04, 0.04, 0.12), metal)
		_box(clip, "ToothB%d" % i, Vector3(0.12 + i * 0.06, -0.01, 0), Vector3(0.04, 0.04, 0.12), metal_dark)
	_cyl(clip, "Pivot", Vector3(0.02, 0, 0), 0.04, 0.18, metal_dark, Vector3(deg_to_rad(90), 0, 0))
	_cyl(clip, "Spring", Vector3(-0.02, 0.02, 0), 0.03, 0.1, yellow, Vector3(deg_to_rad(90), 0, 0))

	# --- Banana / grounding plug resting on mat ---
	var plug := Node3D.new()
	plug.name = "GroundPlug"
	plug.position = Vector3(1.35, 0.05, -0.35)
	root.add_child(plug)
	_cyl(plug, "PlugBody", Vector3.ZERO, 0.07, 0.28, black, Vector3(deg_to_rad(90), 0, 0))
	_cyl(plug, "PlugTip", Vector3(0, 0, -0.22), 0.045, 0.16, metal, Vector3(deg_to_rad(90), 0, 0))
	_box(plug, "PlugFlange", Vector3(0, 0, 0.1), Vector3(0.16, 0.16, 0.04), black)

	# Small spare snap / ring hardware
	_cyl(root, "SpareRing", Vector3(0.85, -0.02, -0.35), 0.1, 0.03, metal)
	_cyl(root, "SpareRingHole", Vector3(0.85, 0.0, -0.35), 0.05, 0.04, blue)
	_box(root, "InstructionCard", Vector3(0.2, -0.03, -0.95), Vector3(0.7, 0.015, 0.4), white)
	_box(root, "CardStripe", Vector3(0.2, -0.015, -0.8), Vector3(0.65, 0.008, 0.06), yellow)


static func _build_screwdriver(root: Node3D) -> void:
	# Signature: red/yellow handle
	var handle := _mat(Color(0.95, 0.18, 0.12))
	var grip := _mat(Color(1.0, 0.85, 0.05))
	var shaft := _mat(Color(0.78, 0.8, 0.85), 0.75, 0.22)
	_cyl(root, "Handle", Vector3(0, 0, 0.7), 0.28, 1.2, handle, Vector3(deg_to_rad(90), 0, 0))
	_cyl(root, "Grip", Vector3(0, 0, 0.2), 0.3, 0.35, grip, Vector3(deg_to_rad(90), 0, 0))
	_cyl(root, "Shaft", Vector3(0, 0, -0.85), 0.08, 1.6, shaft, Vector3(deg_to_rad(90), 0, 0))
	_box(root, "Tip", Vector3(0, 0, -1.7), Vector3(0.14, 0.04, 0.2), shaft)


static func _build_monitor(root: Node3D) -> void:
	# Signature: black bezel + glowing blue screen
	var bezel := _mat(Color(0.08, 0.08, 0.1), 0.15, 0.5)
	var screen := _mat(Color(0.15, 0.65, 0.95), 0.02, 0.2)
	screen.emission_energy_multiplier = 0.85
	var stand := _mat(Color(0.3, 0.32, 0.36), 0.3, 0.4)
	_box(root, "Bezel", Vector3(0, 0.55, 0), Vector3(3.2, 2.0, 0.18), bezel)
	_box(root, "Screen", Vector3(0, 0.55, 0.08), Vector3(2.9, 1.7, 0.04), screen)
	_box(root, "Neck", Vector3(0, -0.7, -0.15), Vector3(0.35, 0.9, 0.25), stand)
	_box(root, "Base", Vector3(0, -1.2, 0), Vector3(1.6, 0.12, 1.0), stand)


static func _build_keyboard(root: Node3D) -> void:
	# Signature: charcoal base + teal keys
	var base := _mat(Color(0.14, 0.15, 0.18), 0.1, 0.55)
	var key := _mat(Color(0.2, 0.85, 0.75))
	var accent := _mat(Color(0.95, 0.35, 0.15))
	_box(root, "Base", Vector3.ZERO, Vector3(3.4, 0.22, 1.35), base)
	for row in 4:
		for col in 12:
			var use_accent := row == 0 and col >= 10
			_box(
				root,
				"Key_%d_%d" % [row, col],
				Vector3(-1.45 + col * 0.25, 0.14, -0.45 + row * 0.28),
				Vector3(0.2, 0.08, 0.2),
				accent if use_accent else key
			)


static func _build_mouse(root: Node3D) -> void:
	# Signature: purple body
	var body := _mat(Color(0.55, 0.22, 0.85))
	var btn := _mat(Color(0.4, 0.15, 0.7))
	var wheel := _mat(Color(0.9, 0.9, 0.95), 0.25, 0.4)
	_box(root, "Body", Vector3(0, 0.12, 0), Vector3(1.1, 0.45, 1.7), body)
	_box(root, "LeftBtn", Vector3(-0.28, 0.32, 0.25), Vector3(0.45, 0.08, 0.7), btn)
	_box(root, "RightBtn", Vector3(0.28, 0.32, 0.25), Vector3(0.45, 0.08, 0.7), btn)
	_cyl(root, "Wheel", Vector3(0, 0.38, 0.15), 0.1, 0.22, wheel, Vector3(0, 0, deg_to_rad(90)))


static func _build_laptop(root: Node3D) -> void:
	# Signature: silver shell + green screen
	var shell := _mat(Color(0.7, 0.72, 0.76), 0.45, 0.32)
	var dark := _mat(Color(0.12, 0.12, 0.14), 0.15, 0.5)
	var screen := _mat(Color(0.2, 0.85, 0.45), 0.02, 0.22)
	screen.emission_energy_multiplier = 0.7
	_box(root, "Base", Vector3(0, 0, 0.2), Vector3(3.0, 0.18, 2.0), shell)
	_box(root, "Deck", Vector3(0, 0.1, 0.15), Vector3(2.8, 0.04, 1.7), dark)
	var lid := Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0, 0.1, -0.85)
	lid.rotation = Vector3(deg_to_rad(-65), 0, 0)
	root.add_child(lid)
	_box(lid, "LidShell", Vector3(0, 0.95, 0), Vector3(3.0, 1.9, 0.12), shell)
	_box(lid, "Display", Vector3(0, 0.95, 0.08), Vector3(2.7, 1.6, 0.04), screen)


static func _build_router(root: Node3D) -> void:
	# Signature: black body + green link LEDs + black antennas
	var body := _mat(Color(0.12, 0.12, 0.14), 0.15, 0.5)
	var antenna := _mat(Color(0.08, 0.08, 0.1), 0.1, 0.55)
	var led := _mat(Color(0.15, 0.95, 0.35))
	led.emission_energy_multiplier = 0.9
	_box(root, "Body", Vector3.ZERO, Vector3(2.4, 0.45, 1.5), body)
	_cyl(root, "AntennaL", Vector3(-0.9, 0.9, -0.5), 0.06, 1.5, antenna)
	_cyl(root, "AntennaR", Vector3(0.9, 0.9, -0.5), 0.06, 1.5, antenna)
	for i in 5:
		_box(root, "Led%d" % i, Vector3(-0.8 + i * 0.35, 0.15, 0.72), Vector3(0.12, 0.08, 0.05), led)


static func _build_modem(root: Node3D) -> void:
	# Signature: taller white/grey WAN CPE box + cyan status LED
	var shell := _mat(Color(0.82, 0.86, 0.9), 0.05, 0.65)
	var face := _mat(Color(0.15, 0.2, 0.28), 0.1, 0.5)
	var led := _mat(Color(0.09, 0.65, 0.87))
	led.emission_energy_multiplier = 1.0
	_box(root, "Body", Vector3.ZERO, Vector3(1.6, 1.2, 1.1), shell)
	_box(root, "Face", Vector3(0, 0.1, 0.56), Vector3(1.2, 0.7, 0.04), face)
	_box(root, "Status", Vector3(0, 0.45, 0.58), Vector3(0.2, 0.12, 0.04), led)
	_box(root, "Coax", Vector3(0.5, -0.35, -0.55), Vector3(0.18, 0.18, 0.25), _mat(Color(0.75, 0.55, 0.15), 0.4, 0.35))


static func _build_switch(root: Node3D) -> void:
	# Signature: flat rackable body + row of RJ45 ports + amber/green LEDs
	var body := _mat(Color(0.1, 0.12, 0.16), 0.2, 0.45)
	var port := _mat(Color(0.2, 0.22, 0.26), 0.1, 0.55)
	var led_g := _mat(Color(0.2, 0.95, 0.4))
	led_g.emission_energy_multiplier = 0.85
	_box(root, "Chassis", Vector3.ZERO, Vector3(3.2, 0.35, 1.4), body)
	for i in 8:
		var x := -1.4 + i * 0.4
		_box(root, "Port%d" % i, Vector3(x, -0.02, 0.68), Vector3(0.28, 0.18, 0.12), port)
		_box(root, "Led%d" % i, Vector3(x, 0.12, 0.7), Vector3(0.1, 0.06, 0.04), led_g)


static func _build_access_point(root: Node3D) -> void:
	# Signature: round ceiling AP dome + cyan ring
	var dome := _mat(Color(0.9, 0.92, 0.95), 0.05, 0.6)
	var ring := _mat(Color(0.09, 0.65, 0.87))
	ring.emission_energy_multiplier = 0.7
	var base := _mat(Color(0.2, 0.22, 0.26), 0.15, 0.5)
	_cyl(root, "Dome", Vector3(0, 0.15, 0), 1.1, 0.35, dome)
	_cyl(root, "Ring", Vector3(0, 0.0, 0), 1.15, 0.08, ring)
	_box(root, "Mount", Vector3(0, -0.2, 0), Vector3(0.5, 0.15, 0.5), base)


static func _build_ethernet_cable(root: Node3D) -> void:
	# Signature: blue Cat cable + clear RJ45 plugs
	var cable := _mat(Color(0.15, 0.45, 0.85), 0.05, 0.55)
	var plug := _mat(Color(0.75, 0.85, 0.9), 0.05, 0.35)
	var gold := _mat(Color(0.9, 0.75, 0.25), 0.6, 0.3)
	_cyl(root, "Cable", Vector3.ZERO, 0.08, 2.4, cable, Vector3(0, 0, deg_to_rad(90)))
	_box(root, "PlugL", Vector3(-1.35, 0, 0), Vector3(0.35, 0.22, 0.28), plug)
	_box(root, "PlugR", Vector3(1.35, 0, 0), Vector3(0.35, 0.22, 0.28), plug)
	_box(root, "ContactsL", Vector3(-1.5, 0.02, 0), Vector3(0.08, 0.14, 0.22), gold)
	_box(root, "ContactsR", Vector3(1.5, 0.02, 0), Vector3(0.08, 0.14, 0.22), gold)


static func _build_server(root: Node3D) -> void:
	# Signature: tall tower + front bay rails + cyan status LEDs
	var chassis := _mat(Color(0.14, 0.16, 0.2), 0.2, 0.45)
	var bay := _mat(Color(0.08, 0.09, 0.12), 0.15, 0.5)
	var led := _mat(Color(0.09, 0.65, 0.87))
	led.emission_energy_multiplier = 0.95
	_box(root, "Chassis", Vector3.ZERO, Vector3(1.6, 3.2, 2.2), chassis)
	for i in 4:
		_box(root, "Bay%d" % i, Vector3(0, 1.1 - i * 0.55, 1.05), Vector3(1.2, 0.35, 0.12), bay)
	for i in 3:
		_box(root, "Led%d" % i, Vector3(-0.5 + i * 0.4, 1.4, 1.12), Vector3(0.14, 0.1, 0.05), led)
	_box(root, "Handle", Vector3(0, -1.4, 1.05), Vector3(0.8, 0.12, 0.15), _mat(Color(0.55, 0.58, 0.62), 0.35, 0.4))


static func _build_nas(root: Node3D) -> void:
	# Signature: wide NAS chassis + dual drive trays + green activity LEDs
	var body := _mat(Color(0.18, 0.2, 0.24), 0.18, 0.48)
	var tray := _mat(Color(0.3, 0.32, 0.36), 0.12, 0.55)
	var led := _mat(Color(0.2, 0.95, 0.4))
	led.emission_energy_multiplier = 0.9
	_box(root, "Body", Vector3.ZERO, Vector3(2.8, 1.0, 1.8), body)
	_box(root, "TrayL", Vector3(-0.7, 0.05, 0.85), Vector3(1.0, 0.55, 0.15), tray)
	_box(root, "TrayR", Vector3(0.7, 0.05, 0.85), Vector3(1.0, 0.55, 0.15), tray)
	_box(root, "ActL", Vector3(-0.7, 0.35, 0.95), Vector3(0.2, 0.08, 0.04), led)
	_box(root, "ActR", Vector3(0.7, 0.35, 0.95), Vector3(0.2, 0.08, 0.04), led)
