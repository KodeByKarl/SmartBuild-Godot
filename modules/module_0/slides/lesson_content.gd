class_name Module0LessonContent
extends RefCounted

## Slide copy + layout for Module 0 (ids 1..20). Keeps wording; dark chrome via builder.

const IMG := "res://assets/images/"
const CARD := "res://assets/images/cards/"


## Short Help panel copy for the Module 0 header (1-based slide id).
static func help_for(slide_id: int) -> Dictionary:
	match slide_id:
		1:
			return {"title": "Welcome to CSS", "body": "This intro orients you to Computer Systems Servicing — why it matters and how the course path starts."}
		2:
			return {"title": "Why CSS is relevant", "body": "Every industry depends on working computers and networks. Technicians keep that technology running."}
		3:
			return {"title": "Where CSS can take you", "body": "CSS NC II is an entry path into roles like repair, tech support, hardware install, and network support."}
		4:
			return {"title": "What a CSS technician does", "body": "Focus on hardware work, troubleshooting, and clear user support — in shops, offices, or on-site."}
		5:
			return {"title": "Qualification mindset", "body": "Keep learning, solve problems, understand systems, and work well with others."}
		6:
			return {"title": "Knowledge and skills", "body": "Build fundamentals: systems basics, tools, hardware parts, safety, and communication."}
		7:
			return {"title": "Work safely (OHS)", "body": "Identify hazards, assess risk, then control harm. Safety protects people and equipment."}
		8:
			return {"title": "Identify the hazard", "body": "Scan the work area before you start — cords, electricity, unstable stacks, and clutter."}
		9:
			return {"title": "Assess and control", "body": "Judge likelihood and severity, then reduce risk with training, safe lifting, and procedures."}
		10:
			return {"title": "Quality matters", "body": "Assess materials, document work, and keep inventory so servicing stays accountable."}
		11, 12:
			return {"title": "Interactive practice", "body": "Use this slide to explore concepts visually. Search opens the Parts Encyclopedia for related hardware."}
		13:
			return {"title": "How a computer works", "body": "Remember the loop: Input → Process → Output → Storage."}
		14:
			return {"title": "What's inside", "body": "Map devices to roles: CPU (process), keyboard/mouse (input), monitor (output), SSD/HDD (storage)."}
		15:
			return {"title": "The system unit", "body": "The chassis houses PSU, motherboard, CPU, RAM, cooling, expansion cards, and storage."}
		16:
			return {"title": "Core components", "body": "Motherboard, RAM, CPU, and storage are the foundation of every build."}
		17:
			return {"title": "Power, cooling, expansion", "body": "PSU feeds power, cooling protects performance, and expansion cards add capabilities like graphics."}
		18:
			return {"title": "Memory vs storage", "body": "RAM is fast temporary workspace; drives keep data after power-off."}
		19:
			return {"title": "How parts connect", "body": "Ports, sockets, slots, and connectors join devices — know which is which before you assemble."}
		20:
			return {"title": "Know your tools", "body": "Use the right tool safely. Pair this with ESD protection before touching boards."}
		21:
			return {"title": "Intro complete", "body": "Review your achievements, then Proceed to Home. Modules 1–4 practice assembly, networks, servers, and maintenance."}
		_:
			return {"title": "Module 0 help", "body": "Use Search for the Parts Encyclopedia. Use Prev/Next to move through the intro slides."}


static func build(root: Control, slide_id: int) -> void:
	var content := Module0SlideBuilder.mount(root)
	match slide_id:
		1:
			Module0SlideBuilder.hero_split(
				content,
				IMG + "slide1.png",
				"WELCOME TO\nCOMPUTER SYSTEMS SERVICING",
				"",
				[
					"Computers have become an essential part of everyday life, business, education, communication, and industry. As technology continues to simplify tasks and create new possibilities, the need for people who understand, maintain, and troubleshoot computer systems continues to grow.",
					"Computer Systems Servicing is a fundamental starting point for developing skills in the computer industry."
				],
				true,
				0.9
			)
		2:
			Module0SlideBuilder.title_art_cards(
				content,
				"WHY IS CSS\nRELEVANT?",
				"Technology drives every industry, and skilled technicians keep it running.",
				IMG + "slide2.png",
				[
					{"title": "Technology Is Everywhere", "body": "Businesses, schools, and organizations depend on computers and networks to operate every single day. Every industry relies on functioning technology.", "art": CARD + "card_network.png"},
					{"title": "Key Roles Needed", "body": "• Maintain hardware\n• Troubleshoot problems\n• Install & configure equipment\n• Maintain basic networks\n• Support users & organizations", "art": CARD + "card_tools.png"},
					{"title": "Growing Importance", "body": "As technology becomes more critical to daily operations, the demand for skilled computer servicing technicians continues to grow across all sectors.", "art": CARD + "card_growth.png"},
				],
				1.4
			)
		3:
			Module0SlideBuilder.stacked_art(
				content,
				"WHERE CAN\nCSS TAKE YOU?",
				"CSS NC II: Your Entry Point into the IT Industry",
				"CSS NC II develops competencies in diagnosing, troubleshooting, repairing, and maintaining computer systems. Possible roles: Computer Servicing & Repair, Technical Support, Hardware Installation, Network Support, and IT-related service environments.",
				IMG + "slide3-1.png",
				IMG + "slide3-2.png"
			)
		4:
			Module0SlideBuilder.title_art_cards(
				content,
				"WHAT DOES A\nCSS TECHNICIAN DO?",
				"Technicians may work in offices, service centers, or travel to clients.",
				IMG + "slide4.png",
				[
					{"title": "Hardware", "body": "Assemble & disassemble systems, install or replace components, perform maintenance & repairs on physical equipment.", "art": CARD + "card_motherboard.png"},
					{"title": "Troubleshooting", "body": "Identify problems, diagnose hardware & software issues, restore systems to full working condition.", "art": CARD + "card_troubleshoot.png"},
					{"title": "Support", "body": "Assist users, explain technical information clearly, and collaborate with teams to resolve IT concerns.", "art": CARD + "card_support.png"},
				]
			)
		5:
			Module0SlideBuilder.header_and_cards(
				content,
				"WHAT DOES THE QUALIFICATION REQUIRE?",
				"A good technician keeps learning to adapt to the movement of technology.",
				"",
				[
					{"title": "Keep Up with Technology", "body": "Stay updated with the latest hardware, software, and industry trends to remain effective as a technician.", "art": CARD + "card_learning.png"},
					{"title": "Solve Problems", "body": "Apply logical thinking to diagnose and resolve hardware, software, and network issues efficiently.", "art": CARD + "card_troubleshoot.png"},
					{"title": "Understand Systems", "body": "Develop deep knowledge of how computer components interact and function together as a complete system.", "art": CARD + "card_motherboard.png"},
					{"title": "Work with Others", "body": "Communicate clearly, collaborate with teams, and adapt to different users and work environments.", "art": CARD + "card_team.png"},
				]
			)
		6:
			Module0SlideBuilder.header_and_cards(
				content,
				"WHAT KNOWLEDGE AND SKILLS DO I NEED?",
				"The stronger your fundamentals, the easier computer servicing tasks become.",
				"",
				[
					{"title": "Computer Systems Basics", "body": "Understand how computers work: input, process, output, and storage. Know the roles of key components like CPU, RAM, and storage devices.", "art": CARD + "card_cpu.png"},
					{"title": "Troubleshooting & Tools", "body": "Diagnose hardware and software issues systematically. Use hand tools, ESD protection, and diagnostic equipment safely and correctly.", "art": CARD + "card_tools.png"},
					{"title": "Hardware Components", "body": "Identify and handle internal parts: motherboard, CPU, RAM, storage, power supply, and expansion cards. Know how they connect and function together.", "art": CARD + "card_system_unit.png"},
					{"title": "Safety, Communication & Teamwork", "body": "Apply OHS principles on the job. Communicate technical information clearly to users and collaborate effectively with colleagues and teams.", "art": CARD + "card_safety.png"},
				]
			)
		7:
			Module0SlideBuilder.title_art_cards(
				content,
				"WORK SAFELY: OHS",
				"Occupational Health and Safety for Computer Technicians",
				IMG + "slide7.png",
				[
					{"title": "What is OHS?", "body": "OHS protects the health and safety of workers in the workplace. For technicians, safety is critical due to electrical equipment, sensitive components, and specialized tools.", "art": CARD + "card_safety.png"},
					{"title": "Three-Step Process", "body": "1. IDENTIFY - Spot Hazards\n2. ASSESS - Evaluate Risk\n3. CONTROL - Reduce Harm", "art": CARD + "card_assess.png"},
					{"title": "Key Reminder", "body": "A good technician protects both people and equipment. Safety is not optional - it is part of every task.", "art": CARD + "card_hazard.png"},
				]
			)
		8:
			Module0SlideBuilder.title_art_cards(
				content,
				"STEP 1 - IDENTIFY THE HAZARD",
				"Before fixing problems, look around and identify hazards.",
				IMG + "slide8.png",
				[
					{"title": "What is a Hazard?", "body": "A hazard is anything that can cause harm. Common examples in a computer servicing environment include: tangled electrical cords, unstable stacked objects, excessive noise, electrical hazards, and unsafe work areas.", "art": CARD + "card_hazard.png"},
					{"title": "Best Practice", "body": "Always assess your surroundings before beginning any repair or maintenance task.", "art": CARD + "card_assess.png"},
				],
				1.35
			)
		9:
			Module0SlideBuilder.stacked_art(
				content,
				"STEP 2 & 3 - ASSESS AND CONTROL",
				"Risk Assessment & Risk Control",
				"Don't just notice hazards, take action to reduce risk.",
				IMG + "slide9-1.png",
				IMG + "slide9-2.png"
			)
			Module0SlideBuilder.add_cards_row(content, [
				{"title": "Assess", "body": "Consider the likelihood and severity of harm from each hazard.", "art": CARD + "card_assess.png"},
				{"title": "Control", "body": "Request instruction or training, avoid heavy lifting alone, remove hazards, and follow safety procedures.", "art": CARD + "card_safety.png"},
			])
		10:
			Module0SlideBuilder.title_art_cards(
				content,
				"QUALITY MATTERS",
				"Technicians handle equipment that must meet standards through purchasing, assembly, repair, maintenance, or transfer.",
				IMG + "slide10.png",
				[
					{"title": "ASSESS", "body": "Check equipment and materials before use. Verify condition, completeness, and specifications to ensure everything meets required standards.", "art": CARD + "card_assess.png"},
					{"title": "DOCUMENT", "body": "Record work details, equipment info, and results. Clear documentation supports accountability and future troubleshooting.", "art": CARD + "card_learning.png"},
					{"title": "INVENTORY", "body": "Track components and specs systematically. Good technicians work safely, carefully, and systematically.", "art": CARD + "card_storage.png"},
				]
			)
		13:
			Module0SlideBuilder.header_and_cards(
				content,
				"HOW DOES A COMPUTER SYSTEM WORK?",
				"The Four Fundamental Roles: INPUT → PROCESS → OUTPUT → STORAGE",
				"",
				[
					{"title": "INPUT", "body": "Input devices (e.g., Keyboard, Mouse) capture data and send it to the CPU.", "art": CARD + "card_input.png"},
					{"title": "PROCESS", "body": "The CPU processes instructions and performs calculations to produce a result.", "art": CARD + "card_cpu.png"},
					{"title": "OUTPUT", "body": "Processed results are delivered to output devices such as a Monitor or Printer, making information visible or usable for the user.", "art": CARD + "card_monitor.png"},
					{"title": "STORAGE", "body": "Data and results are saved to storage devices such as an SSD or HDD for permanent retention, allowing retrieval even after the system is powered off.", "art": CARD + "card_storage.png"},
				]
			)
		14:
			Module0SlideBuilder.header_and_cards(
				content,
				"WHAT'S INSIDE A COMPUTER?",
				"Hardware enables processing, storage, input, and output.",
				"",
				[
					{"title": "Processing", "body": "CPU - executes instructions and calculations. The brain of the computer.", "art": CARD + "card_cpu.png"},
					{"title": "Input", "body": "Keyboard - enters text and commands. Mouse - points and selects.", "art": CARD + "card_input.png"},
					{"title": "Storage", "body": "Keeps data even when the computer is off. SSD/HDD hold files and the OS.", "art": CARD + "card_storage.png"},
					{"title": "Output", "body": "Monitor - displays visual information to the user. Speakers/printers deliver other outputs.", "art": CARD + "card_monitor.png"},
				]
			)
		15:
			Module0SlideBuilder.header_body(
				content,
				"THE SYSTEM UNIT",
				"Inside the Heart of a Computer",
				[
					"The system unit is the main enclosure that houses the critical internal components of a computer. It provides the physical structure and electrical connections needed for all parts to work together.",
					"Key internal components: Power Supply Unit (PSU), Motherboard, CPU, RAM, Cooling System (fans & heat sinks), Expansion Cards, and Storage Devices (SSD/HDD)."
				],
				CARD + "card_system_unit.png"
			)
		16:
			Module0SlideBuilder.header_and_cards(
				content,
				"THE CORE COMPONENTS",
				"Understanding What's Inside Your Computer",
				"",
				[
					{"title": "Motherboard", "body": "Main circuit board that connects and enables communication between all components in the computer system.", "art": CARD + "card_motherboard.png"},
					{"title": "Random Access Memory (RAM)", "body": "Temporary storage that holds data and instructions currently in use while the computer is running.", "art": CARD + "card_ram.png"},
					{"title": "Central Processing Unit (CPU)", "body": "Processes instructions and performs calculations. Often called the \"brain\" of the computer.", "art": CARD + "card_cpu.png"},
					{"title": "Storage", "body": "Permanent storage (SSD or HDD) that keeps files, programs, and the operating system even when the computer is off.", "art": CARD + "card_storage.png"},
				]
			)
		17:
			Module0SlideBuilder.header_and_cards(
				content,
				"POWER, COOLING, & EXPANSION",
				"Essential Components Inside the System Unit",
				"",
				[
					{"title": "Power Supply Unit (PSU)", "body": "Converts and distributes electrical power to all internal components. Without it, no part of the system can operate.", "art": CARD + "card_psu.png"},
					{"title": "Cooling System", "body": "Fans, heat sinks, and heat pipes manage heat generated by the CPU and GPU, preventing overheating and ensuring stable performance.", "art": CARD + "card_cooling.png"},
					{"title": "Expansion Cards", "body": "Add or enhance capabilities such as graphics (GPU), sound, or network interfaces by connecting to motherboard slots.", "art": CARD + "card_expansion.png"},
				]
			)
		18:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 24)
			row.size_flags_vertical = Control.SIZE_EXPAND_FILL
			content.add_child(row)
			var arts := VBoxContainer.new()
			arts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			arts.size_flags_stretch_ratio = 0.9
			arts.add_theme_constant_override("separation", 12)
			row.add_child(arts)
			arts.add_child(Module0SlideBuilder.make_art(IMG + "slide9-1.png", 140.0, 1.4))
			arts.add_child(Module0SlideBuilder.make_art(IMG + "slide9-2.png", 140.0, 1.4))
			var text := VBoxContainer.new()
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text.size_flags_stretch_ratio = 1.15
			text.add_theme_constant_override("separation", 12)
			text.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_child(text)
			text.add_child(Module0SlideBuilder.make_label("WHERE DOES THE COMPUTER KEEP ITS DATA?", Module0SlideTheme.title_settings(28)))
			text.add_child(Module0SlideBuilder.make_label("Memory vs. Storage: Two Different Roles", Module0SlideTheme.subtitle_settings(16)))
			Module0SlideBuilder.add_cards_row(content, [
				{"title": "Memory", "body": "Temporary, fast working space used while programs run. Data is lost when the machine is powered off.", "art": CARD + "card_ram.png"},
				{"title": "Storage", "body": "Provides permanent storage for your OS, applications, documents, and photos. Data is retained long-term.", "art": CARD + "card_storage.png"},
			])
		19:
			Module0SlideBuilder.header_and_cards(
				content,
				"HOW DO COMPONENTS CONNECT?",
				"Ports, Slots, Sockets, & Connectors",
				"",
				[
					{"title": "PORT", "body": "External interface for connecting devices and cables. Common examples are USB, HDMI, Ethernet, and Audio ports found on the rear or front panel of the system unit.", "art": CARD + "card_port.png"},
					{"title": "SOCKET", "body": "A dedicated receptacle on the motherboard that holds a specific component securely in place. The CPU socket is the most critical example; it locks the processor into position.", "art": CARD + "card_socket.png"},
					{"title": "SLOT", "body": "A motherboard connection point designed to accept expansion cards or memory modules. Examples include RAM slots and PCIe slots for expansion cards.", "art": CARD + "card_slot.png"},
					{"title": "CONNECTOR", "body": "A plug or interface used to join cables to components internally or externally. Examples include SATA connectors for storage drives and power connectors from the PSU.", "art": CARD + "card_connector.png"},
				]
			)
		20:
			Module0SlideBuilder.header_and_cards(
				content,
				"KNOW YOUR TOOLS",
				"Essential Tools for Computer Technicians",
				"A good technician knows not only the tool, but when and how to use it safely.",
				[
					{"title": "Power Supply Unit (PSU)", "body": "Converts and distributes electrical power to all internal components. Without it, no part of the system can operate.", "art": CARD + "card_psu.png"},
					{"title": "Cooling System", "body": "Fans, heat sinks, and heat pipes manage heat generated by the CPU and GPU, preventing overheating and ensuring stable performance.", "art": CARD + "card_cooling.png"},
					{"title": "Expansion Cards", "body": "Add or enhance such as graphics (GPU), sound, or network interfaces by connecting to motherboard slots.", "art": CARD + "card_expansion.png"},
				]
			)
		_:
			Module0SlideBuilder.header_body(content, "Module 0", "", ["Slide content unavailable."])
