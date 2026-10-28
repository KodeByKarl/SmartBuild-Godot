class_name Module1Content
extends RefCounted

## Module 1 — Installing and Configuring Computer Systems.
## Lesson copy and art follow the SMARTBUILD Figma "Module 1" column; the
## simulations reuse the TESDA CSS NC II Unit 1 step data in ModuleContentRegistry.

const D := preload("res://core/components/lesson/lesson_data.gd")
const A := "res://modules/module_1/assets/figma/"


static func build() -> Dictionary:
	return {
		"id": 1,
		"title": "Installing and Configuring Computer Systems",
		"header": "Module 1 | Installing and Configuring Computer Systems",
		"pages": pages(),
	}


static func pages() -> Array:
	return [
		D.hero(
			"Ready to Assemble and\nDisassemble a Computer?",
			"But before you begin, make sure you have all the necessary tools and equipment for computer assembly and disassembly. On the next page, check the list and make sure you have everything needed to proceed with the activity.",
			A + "m1_p01_assembly_blueprint.png",
			{"bold": ["On the next page, check the list and make sure you have everything needed to proceed with the activity."], "art_ratio": 0.46}
		),
		D.checklist(
			"Tools and Equipment Needed for Computer Assembly and Disassembly",
			"Tick each item to confirm you have it ready before you continue.",
			[
				D.card("Screwdrivers", "Used to tighten and remove screws when installing or removing computer components.", A + "m1_p02_screwdrivers.png"),
				D.card("Anti-Static Wrist Strap", "Must be worn when handling computer components to prevent electrostatic discharge (ESD) that can damage them.", A + "m1_p02_anti_static_wrist_strap.png"),
				D.card("Clean Workspace", "Used to provide a clean and safe area for handling and assembling computer components, helping prevent damage and loss of parts.", A + "m1_p04_organize_workspace.png"),
			],
			true
		),
		D.cards("ESD-Safe Preparation Steps", "Protect the hardware before disassembly and assembly.", [
			D.card("Wear Anti-Static Wrist Strap", "Prevents static electricity from damaging components.", A + "m1_p03_wear_wrist_strap.png"),
			D.card("Lay Out the Anti-Static Mat", "Provides an ESD-safe surface for the components.", A + "m1_p03_anti_static_mat.png"),
			D.card("Stage screwdriver and fasteners", "Prepare the tools and screws needed for the task.", A + "m1_p03_screwdriver_fasteners.png"),
		], {"body_align": "fill", "card_body_size": 11}),
		D.cards("ESD-Safe Preparation Steps", "Protect the hardware before disassembly and assembly.", [
			D.card("Inspect delivered components", "Check components for damage or missing parts.", A + "m1_p04_inspect_components.png"),
			D.card("Confirm compatibility", "Make sure the components are compatible with the computer.", A + "m1_p04_confirm_compatibility.png"),
			D.card("Organize the workspace", "Keep the tools and components arranged and the work area clear.", A + "m1_p04_organize_workspace.png"),
		], {"body_align": "fill", "card_body_size": 11}),
		D.checklist(
			"Before You Start, Follow These Safety Precautions!",
			"Check each item to confirm the necessary safety preparations are complete before starting. Note that these precautions apply to real-life assembly only and are not required or tracked in the simulation.",
			[
				"Unplug your system unit and make sure it is completely disconnected from the power source before disassembling it.",
				"Wear an anti-static wrist strap and make sure it is properly secured before handling any computer components.",
				"Place the anti-static mat on a clean, flat work surface and make sure it is properly positioned before starting the disassembly.",
				"Make sure the work table is large, spacious, and stable enough to safely accommodate the system unit, tools, and computer components during the activity.",
			],
			true
		),
		D.cards("Input and Output Device Setup", "Connect and test input and output devices to ensure proper communication between the user and the computer.", [
			D.card("Identify input devices", "Identify the keyboard, mouse, and other devices used to provide commands or data to the computer."),
			D.card("Connect input devices", "Connect the keyboard and mouse to the appropriate ports on the computer."),
			D.card("Identify output devices", "Identify the monitor, speakers, printer, and other devices used to receive information from the computer."),
			D.card("Connect output devices", "Connect the monitor and other output devices to their appropriate ports."),
		]),
		D.cards("Input and Output Device Setup", "Connect and test input and output devices to ensure proper communication between the user and the computer.", [
			D.card("Power on the devices", "Turn on the computer, monitor, and other connected devices."),
			D.card("Check device detection", "Verify that the connected input and output devices are recognized and functioning properly."),
			D.card("Test input devices", "Test the keyboard and mouse to confirm that commands can be entered correctly."),
			D.card("Test output devices", "Check the monitor, speakers, or other output devices to confirm that information is displayed or produced correctly."),
		]),
		D.cards("Basic Input/Output System (BIOS) Configuration Steps", "Power on with display and input attached. Confirm Central Processing Unit (CPU), Random Access Memory (RAM), and storage detection, then set boot priority for the installer.", [
			D.card("Connect display and input", "Connect the monitor and keyboard to allow you to view and navigate the BIOS/UEFI settings."),
			D.card("Power on the system", "Turn on the computer and wait for the system to begin its boot process."),
			D.card("Enter BIOS/UEFI setup", "Press the designated key during startup to open the Basic Input/Output System (BIOS) or Unified Extensible Firmware Interface (UEFI) configuration menu."),
			D.card("Verify processor detection", "Check the BIOS/UEFI to confirm that the installed Central Processing Unit (CPU) is properly detected."),
		]),
		D.cards("Basic Input/Output System (BIOS) Configuration Steps", "Power on with display and input attached. Confirm Central Processing Unit (CPU), Random Access Memory (RAM), and storage detection, then set boot priority for the installer.", [
			D.card("Verify memory detection", "Check the displayed memory information to confirm that the installed Random Access Memory (RAM) is detected correctly."),
			D.card("Verify storage detection", "Check the storage information to confirm that the installed Hard Disk Drive (HDD) or Solid-State Drive (SSD) is properly recognized."),
			D.card("Set boot priority", "Configure the boot order and select the appropriate device for starting the operating system."),
			D.card("Save and Exit", "Save the configured settings and exit the BIOS/UEFI to restart the computer."),
		]),
		D.cards("Operating System Install Steps", "Boot from installer media, prepare the target volume, and finish first-run account setup.", [
			D.card("Insert bootable USB drive", "Connect the Universal Serial Bus (USB) drive containing the operating system installer to the computer."),
			D.card("Boot from the USB drive", "Start or restart the computer and select the bootable Universal Serial Bus (USB) drive as the startup device."),
			D.card("Choose install options", "Select the appropriate language, region, keyboard layout, and other installation preferences."),
			D.card("Prepare partitions", "Select an existing partition or create a new partition where the operating system will be installed."),
		]),
		D.cards("Operating System Install Steps", "Boot from installer media, prepare the target volume, and finish first-run account setup.", [
			D.card("Format the target volume", "Format the selected partition to prepare it for a clean operating system installation."),
			D.card("Run the operating system installation", "Begin the installation process and allow the operating system files to be copied to the selected drive."),
			D.card("Create user account", "Set up the primary user account and provide the required account information."),
			D.card("Finish first-run setup", "Complete the initial system settings and configuration before using the newly installed operating system."),
		]),
		D.cards("Drivers and System Testing Steps", "Install board device drivers, then prove display, network, and storage work before handover.", [
			D.card("Install motherboard drivers", "Install the drivers needed for the motherboard and its components."),
			D.card("Install graphics drivers", "Install the driver needed for proper display and graphics performance."),
			D.card("Install network drivers", "Install the drivers needed for network connectivity."),
			D.card("Install baseline applications", "Install the basic software needed on the computer."),
		]),
		D.cards("Drivers and System Testing Steps", "Install board device drivers, then prove display, network, and storage work before handover.", [
			D.card("Test the display", "Check the monitor and graphics output to make sure the display is working correctly."),
			D.card("Test internet access", "Verify that the computer can connect to the network and access the internet properly."),
			D.card("Test storage access", "Check if the storage drive is detected and files can be accessed correctly."),
			D.card("Document the build", "Record the installed hardware, drivers, applications, and completed configuration for future reference."),
		]),
		D.external_lab(
			"Guided Simulation",
			"Disassemble the workstation in the official order, then build it again on the bench. Select each part, then place it on the correct slot. Yellow guides show every next step.",
			A + "m1_p01_assembly_blueprint.png",
			"Start Guided Simulation",
			"advance_page"
		),
		D.simulation(ModuleContentRegistry.module_1_disassembly_sim()),
		D.simulation(ModuleContentRegistry.module_1_assembly_sim()),
		D.be_ready(A + "m1_p15_be_ready_checklist.png"),
		D.assessment(ModuleContentRegistry.module_1_assessment_sim()),
		D.completion("You finished Installing and Configuring Computer Systems!", [
			"Tools and ESD Safety",
			"Safe Disassembly",
			"Hardware Assembly",
			"BIOS and OS Setup",
			"Drivers and System Testing",
		]),
	]
