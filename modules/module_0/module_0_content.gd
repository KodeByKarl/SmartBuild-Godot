class_name Module0Content
extends RefCounted

## Module 0 — Introduction to Computer Systems Servicing, as lesson data.
## Figma "Prep Lesson" pages 0–19 are the source of truth: pages, text and
## images follow the frames word for word. Rendered by the shared LessonDeck
## (Figma layouts), including the completion page shared with Modules 1–4.
##
## Order follows the Figma page numbers, except page 19 ("You're Almost Ready!")
## sits before page 18 (Congratulations): the completion screen ends the module,
## so nothing after it could be reached.

## Exact images exported from the Figma "Prep Lesson" frames (2x PNG).
const FIGMA := "res://modules/module_0/assets/figma/"


static func _page(phase: String, help_title: String, help_body: String, section: Dictionary) -> Dictionary:
	return {
		"card": "figma",
		"phase": phase,
		"help": {"title": help_title, "body": help_body},
		"sections": [section],
	}


## Figma step/info card. Prep Lesson cards have no divider under the title,
## except the Knowledge and Skills page.
static func _card(title: String, body: String, art: String = "", divider: bool = false) -> Dictionary:
	var c := {"title": title, "body": body, "no_divider": not divider}
	if art != "":
		c["art"] = FIGMA + art
	return c


static func _cards(title: String, title_size: int, card_title_size: int, card_body_size: int, cards: Array) -> Dictionary:
	return {
		"layout": "figma_cards",
		"title": title,
		"title_size": title_size,
		"card_title_size": card_title_size,
		"card_body_size": card_body_size,
		"cards": cards,
	}


static func _hero(title: String, body: String, art: String, art_side: String, art_ratio: float) -> Dictionary:
	return {
		"layout": "figma_hero",
		"title": title,
		"body": body,
		"art": FIGMA + art,
		"art_side": art_side,
		"art_ratio": art_ratio,
		"body_size": 16,
	}


static func pages() -> Array:
	var list := _pages()
	# Doc revisions: card pages 2, 3, 5, 6, 7, 9, 10, 12, 13, 17 get larger, justified body text.
	for idx in [1, 2, 4, 5, 6, 8, 9, 11, 12, 16]:
		var section: Dictionary = (((list[idx] as Dictionary)["sections"] as Array)[0]) as Dictionary
		section["body_align"] = "fill"
		section["card_body_size"] = int(section.get("card_body_size", 14)) + 3
	return list


static func _pages() -> Array:
	var system_unit := _hero(
		"The System Unit",
		"The system unit is the main enclosure that houses the critical internal components of a computer. It provides the physical structure and electrical connections needed for all parts to work together.",
		"m0_p11_system_unit.png", "right", 0.36
	)
	system_unit["body_after"] = "Key internal components: Power Supply Unit (PSU), Motherboard, CPU, RAM, Cooling System (fans & heat sinks), Expansion Cards, and Storage Devices (SSD/HDD)."

	var almost_ready := _cards("You’re Almost Ready!", 27, 16, 14, [
		_card("Guided Simulation", "Get step-by-step guidance as you perform each task. Follow the instructions, observe the proper procedures, and practice the skills needed to complete the simulation correctly."),
		_card("Assessment", "Put your knowledge and skills to the test. Complete the tasks independently and apply what you learned from the Guided Simulation."),
	])
	almost_ready["subtitle"] = "You’re now nearing the end of the Preparatory Module! You’ve gained the foundational knowledge needed to proceed to Modules 1–4. Each module includes a Guided Simulation and Assessment."
	almost_ready["body_align"] = "fill"

	return [
		# Figma page 0 (1:220)
		_page("", "Welcome to CSS",
			"Computers play an important role in creating innovations. Basic knowledge and skills in computer servicing are essential in today's digital world.",
			{
				"layout": "welcome_hero",
				"art": FIGMA + "m0_p01_pc_repair_workspace.png",
				"title": "Welcome To Computer\nSystems Servicing",
				"body": "As technology continues to make everyday tasks easier, computers play an important role in creating innovations and making things possible. In today's digital world, having basic knowledge and skills in computer servicing is essential.",
			}),
		# Figma page 1 (1:298)
		_page("Career path", "What a CSS technician does",
			"A CSS technician works on hardware, troubleshoots problems, and supports users.",
			_cards("What Does a CSS Technician Do?", 27, 20, 14, [
				_card("Hardware", "Assemble & Disassemble systems, install or replace components, perform maintenance & repairs on physical equipment.", "m0_p02_hardware.png"),
				_card("Troubleshooting", "Identify problems, diagnose hardware & software issues, restore systems to full working condition.", "m0_p02_troubleshooting.png"),
				_card("Support", "Assist users, explain technical information clearly, and collaborate with teams to resolve IT concerns.", "m0_p02_support.png"),
			])),
		# Figma page 2 (1:321)
		_page("Career path", "Knowledge and skills",
			"Build your fundamentals: computer system basics, hardware components, troubleshooting and tools, and safety and communication.",
			_cards("What Knowledge and Skills Do I Need?", 27, 14, 12, [
				_card("Computer System Basics", "Understand how computer work: input, process, output, and storage. Know the roles of key components like CPU, RAM, and storage device.", "", true),
				_card("Hardware Components", "Identify and handle internal parts: Motherboard, CPU, RAM, Storage, Power Supply, and expansion cards. Know how they connect and function together.", "", true),
				_card("Troubeshooting & Tools", "Diagnose hardware and software issues systematically. Use hand tools, ESD Protection, and diagnostic equipment safety and correctly.", "", true),
				_card("Safety, Communication & Tools", "Apply OHS principles on the job. Communicate technical information clearly to users and collaborate effectively with colleagues and teams.", "", true),
			])),
		# Figma page 3 (1:834)
		_page("Safety", "Occupational Health and Safety",
			"OHS protects the health and safety of workers. Technicians work with electrical equipment, sensitive components, and specialized tools.",
			_hero("What is Occupational\nHealth and Safety?",
				"OHS protects the health and safety of workers in the workplace. For technicians, safety is critical due to electrical equipment, sensitive components, and specialized tools.",
				"m0_p04_safety_gear.png", "left", 0.46)),
		# Figma page 4 (1:811)
		_page("Safety", "CSS OHS Procedures", "Steps 1–4 of the twelve OHS procedures for computer servicing.",
			_cards("CSS OHS Procedures", 27, 12, 12, [
				_card("STEP 1", "Don't work alone, so someone can help you in an emergency.", "m0_p05_ohs_step1_work_with_someone.png"),
				_card("STEP 2", "Power off and unplug the computer before working on it.", "m0_p05_ohs_step2_unplug.png"),
				_card("STEP 3", "Remove any liquids from your work area to avoid electrocution or damage to parts.", "m0_p05_ohs_step3_no_liquids.png"),
				_card("STEP 4", "Be careful with tools that could cause a short circuit.", "m0_p05_ohs_step4_careful_tools.png"),
			])),
		# Figma page 5 (1:981)
		_page("Safety", "CSS OHS Procedures", "Steps 5–8 of the twelve OHS procedures for computer servicing.",
			_cards("CSS OHS Procedures", 27, 12, 12, [
				_card("STEP 5", "Ground or discharge yourself before touching any computer part.", "m0_p06_ohs_step5_ground_yourself.png"),
				_card("STEP 6", "Don't force parts that don't slip into place easily.", "m0_p06_ohs_step6_dont_force_parts.png"),
				_card("STEP 7", "Clean the work area before and after use to keep it sanitary and prevent accidents.", "m0_p06_ohs_step7_clean_work_area.png"),
				_card("STEP 8", "Hold components by the edges and avoid touching the IC (integrated circuit) parts.", "m0_p06_ohs_step8_hold_by_edges.png"),
			])),
		# Figma page 6 (1:1004)
		_page("Safety", "CSS OHS Procedures", "Steps 9–12 of the twelve OHS procedures for computer servicing.",
			_cards("CSS OHS Procedures", 27, 12, 12, [
				_card("STEP 9", "Always wear Personal Protective Equipment (PPE) according to your organization's OHS procedures.", "m0_p07_ohs_step9_ppe.png"),
				_card("STEP 10", "Makes sure the pins are properly aligned when plugging in a cable connector.", "m0_p07_ohs_step10_aligned_pins.png"),
				_card("STEP 11", "Know the contingency measures for workplace accidents, fire, and other emergencies.", "m0_p07_ohs_step11_emergencies.png"),
				_card("STEP 12", "Clean the computer system with a brush, compressed air, or a blower.", "m0_p07_ohs_step12_clean_with_brush.png"),
			])),
		# Figma page 7 (1:847)
		_page("Computer basics", "What is a computer?",
			"A computer accepts data as input, processes it, stores information, and produces output.",
			_hero("What is a Computer?",
				"A Computer is an electronic device that accepts data as input, processes it according to instructions, stores information, and produces output. It performs these operations to help users complete tasks, solve problems, and access or manage information.",
				"m0_p08_computer.png", "left", 0.44)),
		# Figma page 8 (1:116)
		_page("Computer basics", "Types of computers",
			"Supercomputer, mainframe, minicomputer, and microcomputer differ in size, power, and number of users.",
			_cards("Different Types of Computer", 27, 14, 12, [
				_card("Supercomputer", "Extreme powerful machines used for complex research, weather forecasting, and scientific exploration.", "m0_p09_supercomputer.png"),
				_card("Mainframe", "Large-scale systems that handle massive amounts of data and support many users simultaneously.", "m0_p09_mainframe.png"),
				_card("Minicomputer", "Mid-range systems that support multiple users and environments.", "m0_p09_minicomputer.png"),
				_card("Microcomputer", "The most common type, including desktop, laptops, and smartphones used daily.", "m0_p09_microcomputer.png"),
			])),
		# Figma page 9 (1:143)
		_page("Computer basics", "How a computer system works",
			"Input receives data, process analyzes it, output presents it, and storage saves it for later.",
			_cards("How does a Computer System Works?", 27, 14, 12, [
				_card("Input", "Receives raw data and instructions that need to be processed.", "m0_p10_input.png"),
				_card("Process", "Processes and analyzes the received data based on given instructions.", "m0_p10_process.png"),
				_card("Output", "Provides the processed data as clear and useful information.", "m0_p10_output.png"),
				_card("Storage", "Saves data and information for future access and use.", "m0_p10_storage.png"),
			])),
		# Figma page 10 (1:860)
		_page("Computer basics", "The system unit",
			"The system unit houses the PSU, motherboard, CPU, RAM, cooling system, expansion cards, and storage devices.",
			system_unit),
		# Figma page 11 (1:168)
		_page("Computer basics", "What is inside a computer?",
			"The motherboard connects everything, the CPU processes, RAM holds data in use, and storage keeps files permanently.",
			_cards("What is Inside a Computer?", 27, 14, 12, [
				_card("Mother Board", "The main circuit board that connects all computer components.", "m0_p12_motherboard.png"),
				_card("Central Processing Unit (CPU)", "The brain of the computer that processes instructions and performs calculations.", "m0_p12_cpu.png"),
				_card("Random Access Memory (RAM)", "Temporarily stores data and programs that the computer is currently using.", "m0_p12_ram.png"),
				_card("Storage", "Permanently stores files, programs, photos, and other data.", "m0_p12_storage.png"),
			])),
		# Figma page 12 (1:194)
		_page("Computer basics", "What is inside a computer?",
			"The GPU handles graphics, the PSU powers the components, and the cooling fan and heat sink remove heat.",
			_cards("What is Inside a Computer?", 27, 14, 12, [
				_card("Graphics Processing Unit (GPU)", "Processes and displays images, videos, and graphics.", "m0_p13_gpu.png"),
				_card("Power Supply Unit (PSU)", "Provides electricity to the computer’s components.", "m0_p13_psu.png"),
				_card("Cooling Fan", "A fan that moves air over the heatsink to help remove the heat.", "m0_p13_cooling_fan.png"),
				_card("Heat Sink", "Absorbs and spreads heat away from the CPU.", "m0_p13_heat_sink.png"),
			])),
		# Figma page 13 (1:104)
		_page("Networking", "What is computer networking?",
			"Networking connects computers and devices so they can share data, resources, files, and internet access.",
			_hero("What is Computer\nNetworking?",
				"The process of connecting computers and devices to communicate and share data, resources, files, and internet access with each other. It allows devices to work together through wired or wireless connections.",
				"m0_p14_computer_networking.png", "left", 0.44)),
		# Figma page 14 (1:6)
		_page("Networking", "Networking components",
			"Network cables, RJ45 connectors, and routers connect devices and networks.",
			_cards("Networking Components", 27, 18, 15, [
				_card("Network Cables", "Connects devices to the network.", "m0_p15_network_cables.png"),
				_card("RJ45 Connector", "Connects the network cable to devices.", "m0_p15_rj45_connector.png"),
				_card("Router", "Connects different networks and directs data.", "m0_p15_router.png"),
			])),
		# Figma page 15 (1:1031)
		_page("Networking", "Networking components",
			"A switch connects devices within a network; a repeater extends the network signal.",
			_cards("Networking Components", 27, 18, 16, [
				_card("Switch", "Connects multiple devices within a network.", "m0_p16_switch.png"),
				_card("Repeater", "Extends the network signal.", "m0_p16_repeater.png"),
			])),
		# Figma page 16 (1:28). Figma's captions on pages 16–17 are network
		# placeholders; descriptions come from Figma's Module 1/2 tools pages.
		_page("Technician tools", "Know your tools",
			"An anti-static kit prevents ESD damage, screwdrivers fasten components, and a cable tester checks crimped cables.",
			_cards("Know Your Tools", 27, 18, 15, [
				_card("Anti Static Kit", "Must be worn when handling computer components to prevent electrostatic discharge (ESD) that can damage them.", "m0_p17_anti_static_kit.png"),
				_card("Screwdrivers", "Used to tighten and remove screws when installing or removing computer components.", "m0_p17_screwdrivers.png"),
				_card("Cable Tester", "Used to test the Ethernet cable after crimping and check if the wires are properly connected.", "m0_p17_cable_tester.png"),
			])),
		# Figma page 17 (1:50)
		_page("Technician tools", "Know your tools",
			"A crimping tool attaches RJ45 connectors; a brush removes dust from computer parts.",
			_cards("Know Your Tools", 27, 18, 15, [
				_card("Crimping Tool", "Used to attach and secure the RJ45 connector onto the Ethernet cable, ensuring proper contact.", "m0_p18_crimping_tool.png"),
				_card("Brush", "Used to gently remove dust from fans, vents, and other computer parts.", "m0_p18_brush.png"),
			])),
		# Figma page 19 (32:220) — placed before page 18, see header note.
		_page("Complete", "You're almost ready",
			"Modules 1–4 each include a Guided Simulation and an Assessment.",
			almost_ready),
		# Figma page 18 (1:68) — same shared completion layout as Modules 1–4.
		_page("Complete", "Congratulations!",
			"You finished Introduction to CSS! Proceed to Home saves the module as complete; Retake Module starts it again.",
			{
				"layout": "completion",
				"title": "Congratulations!",
				"subtitle": "You finished Introduction to CSS!",
				"topics": ["Intro to CSS", "OHS Procedures", "Types of Computers", "Networking Components", "Technician Tools"],
			}),
	]
