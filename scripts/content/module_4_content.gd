class_name Module4Content
extends RefCounted

## Module 4 — Maintaining Computer Systems and Networks.
## Lessons follow the SMARTBUILD Figma "Module 4" column. The Guided and
## Assessment simulations are the Android service-ticket desktop lab.

const D := preload("res://core/components/lesson/lesson_data.gd")
const A := "res://modules/module_4/assets/figma/"


static func build() -> Dictionary:
	return {
		"id": 4,
		"title": "Maintaining Computer Systems and Networks",
		"header": "Module 4 | Maintaining Computer Systems and Networks",
		"pages": pages(),
	}


static func pages() -> Array:
	var faults := "Identifying and Isolating Faults"
	var faults_sub := "These are common methods for diagnosing computer problems. Familiarize yourself with them for effective troubleshooting."
	var network := "Troubleshooting Network Connection Problems"
	var network_sub := "Application may vary as there are various network configurations, operating systems, setup, etc."
	var testing := "Testing Computer Systems & Networks"
	return [
		D.hero(
			"Is Your Computer Ready\nfor the Long Run?",
			"Welcome to the last module, “Maintain Computer Systems and Networks”!\n\nIn this final module, you’ll learn how to keep computer systems and networks working properly through regular maintenance, troubleshooting, data protection, and preventive care.",
			A + "m4_p01_pc_repair_workspace.png",
			{"art_side": "left", "art_ratio": 0.44}
		),
		D.hero(
			"Troubleshooting",
			"Troubleshooting is the process of identifying the cause of problems or faults in a computer system. Troubleshooting experiences may vary because technicians develop their skills through their knowledge and personal experience.\n\nAs a computer technician, you must be knowledgeable about the fundamentals of computer concepts, as solving problems often depends on your understanding and ability to apply what you know.",
			A + "m4_p02_troubleshooting.png",
			{"art_side": "left", "art_ratio": 0.44}
		),
		D.hero(
			"Preventive Maintenance",
			"Preventive maintenance involves the regular and systematic inspection, cleaning, and replacement of worn-out parts, materials, and systems.\n\nIt helps prevent failures by routinely checking and ensuring that all components are working properly.",
			A + "m4_p03_preventive_maintenance.png",
			{"body_size": 18, "art_ratio": 0.44}
		),
		D.hero(
			"Hardware Maintenance",
			"Computer hardware maintenance involves regularly checking cables, components, and peripherals to keep the system in good condition. The following are basic hardware maintenance tasks:",
			A + "m4_p04_hardware_maintenance.png",
			{"art_side": "left", "art_ratio": 0.44, "bold": ["hardware maintenance"], "bullets": [
				"Remove dust from fans.", "Clean dust from the power supply.", "Remove dust from internal components.",
				"Clean the mouse and keyboard.", "Check the cables.",
			]}
		),
		D.hero(
			"Software Maintenance",
			"Software maintenance involves keeping software updates current and following proper policies when installing programs, operating systems, and security updates. Here are some simple tasks for software maintenance:",
			A + "m4_p05_software_maintenance.png",
			{"art_side": "left", "art_ratio": 0.44, "bold": ["Software maintenance"], "bullets": [
				"Check security, software, and driver updates.", "Scan for viruses and malware, and update antivirus files.",
				"Remove unused and unwanted programs.", "Scan and defragment hard drives.",
			]}
		),
		D.hero(
			"Data Protection",
			"Data protection is one of the first steps in troubleshooting. Computer data should be protected before performing any work on a client’s or customer’s computer.\n\nA backup is a copy of data stored on a computer or hard drive and saved to external media such as a DVD, CD, or flash drive. In organizations, backups are regularly performed daily, weekly, or monthly to ensure that important data remains protected and readily available when needed.",
			A + "m4_p06_data_protection.png",
			{"art_ratio": 0.44, "bold": ["Data protection", "backup"]}
		),
		D.hero(
			"Routine Maintenance",
			"A well-maintained computer performs better, whether through improved RAM performance or Internet speed. Here are some tips for maintaining computer systems and networks:",
			A + "m4_p07_routine_maintenance.png",
			{"art_ratio": 0.44, "bullets": [
				"Clean browsers (e.g., CCleaner).", "Scan for and remove spyware and viruses.", "Defragment the hard drive regularly.",
				"Uninstall unused programs.", "Remove unnecessary startup programs.", "Use the computer’s disk management tools.",
			]}
		),
		D.cards("Tips on Maintaining Hardware", "Learn simple ways to properly care for and maintain computer hardware.", [
			D.card("Always use an Uninterruptible Power Supply to protect your computer from power interruptions.", "An electrical device that provides backup power during power failures and helps protect computers from electrical surges. Network and phone lines should also have surge protection to prevent damage during electrical storms.", A + "m4_p08_ups.png", {"art_side": "right"}),
			D.card("Open up your computer.", "Dust can build up inside your computer, so check and clean it every few months. Regular cleaning helps maintain proper airflow and prevent overheating. Always follow proper assembly and disassembly procedures to avoid damaging components.", A + "m4_p08_open_up_computer.png", {"art_side": "right"}),
		], {"card_title_size": 18, "card_body_size": 16, "stack": true, "body_align": "fill"}),
		D.cards("Tips on Maintaining Hardware", "Learn simple ways to properly care for and maintain computer hardware.", [
			D.card("Be careful when plugging peripherals into the computer", "Ports can be easily damaged when mishandled. Avoid forcing cables into ports and connect them gently. Keep ports clean and free from dust or debris. Also, avoid pulling cables roughly to prevent damage. These repairs can be quite costly.", A + "m4_p09_careful_with_ports.png", {"art_side": "right"}),
			D.card("Check Cables and Connections", "Regularly inspect internal cables and connections for looseness, damage, or wear. Secure loose connections and replace damaged cables to prevent hardware problems and unexpected shutdowns.", A + "m4_p09_cable_inspection.png", {"art_side": "right"}),
		], {"card_title_size": 18, "card_body_size": 16, "stack": true, "body_align": "fill"}),
		D.cards(faults, faults_sub, [
			D.card("Power On Self Test (POST)", "Power-On Self-Test (POST) is the computer’s first hardware check when you turn it on. Before the operating system starts, POST checks the main components and alerts you if a hardware problem may prevent the computer from starting or working properly."),
			D.card("Operating System Load Time", "The time it takes for the operating system to load can help identify possible problems. If it takes longer than usual, it may indicate an issue with the hard drive or other system components."),
			D.card("Graphic Problems", "Check the display after the operating system loads. If you notice blurry graphics, screen flickering, distorted images, or other visual errors, check the graphics card and its connections for possible hardware problems."),
		], {"title_size": 27, "card_title_size": 14, "body_align": "center"}),
		D.cards(faults, faults_sub, [
			D.card("Check for Newly Installed Hardware", "If a problem occurs after installing new hardware, check if its driver is causing a conflict. Use Device Manager to look for warning signs, errors, or devices that are not working properly. This can help identify hardware-related issues and determine if the device needs a driver update."),
			D.card("Check for Newly Installed Software", "If a problem occurs after installing new software, check if the program is causing the issue. Close or uninstall the software to see if the problem is resolved. This can help identify software-related issues and determine if the program is conflicting with the system."),
			D.card("Check RAM and CPU Consumption", "If the computer is running slowly or lagging, check the RAM and CPU usage in Task Manager. High usage may indicate that too many programs are running or that a program is using too many system resources. Close unnecessary programs to help reduce the system load."),
		], {"title_size": 27, "card_title_size": 14, "body_align": "center"}),
		D.cards(faults, faults_sub, [
			D.card("Check if the hard drive is making scratching or loud noises", "Listen for unusual scratching, clicking, or loud noises coming from the hard drive. These sounds may indicate a possible drive problem. If you notice unusual noises, back up important files and check the hard drive for errors or signs of damage to prevent data loss."),
			D.card("Run a virus and malware scan", "If the computer is running slowly, showing unusual pop-ups, or behaving unexpectedly, run a virus and malware scan. Use a trusted security program to detect and remove harmful software that may be affecting the system. Regular scans can help prevent future infections and keep the computer running properly."),
			D.card("Check problems while running Safe Mode", "Safe Mode can be activated by repeatedly pressing F8 during startup. It loads only essential drivers and services, making it easier to identify software-related issues. If the problem still occurs in Safe Mode, it may indicate an issue with the operating system."),
		], {"title_size": 27, "card_title_size": 14, "body_align": "center"}),
		D.cards(network, network_sub, [
			D.card("Wired Network", "Check that the network cable is securely connected and inspect the LEDs. A solid green light indicates a connection, while flashing means data activity. No or red/orange lights may indicate a faulty cable, port, or network adapter."),
			D.card("Wireless Network", "If using a wireless device, make sure the Wi-Fi button or switch is turned on. Check that the device is connected to the correct network, and enter the correct password when connecting to a secured Wi-Fi network."),
			D.card("Adapter Functionality", "Verify that the network card can ping itself using the ping command. In Windows, use the Command Prompt; in Unix/Linux, use the shell. Enter ping 127.0.0.1 or ping localhost. Successful replies indicate the adapter is working, while errors may indicate improper installation, incorrect drivers, or a faulty network card."),
		], {"title_size": 27, "card_title_size": 14, "body_align": "center"}),
		D.cards(network, network_sub, [
			D.card("Connect to the router", "Use ipconfig to find the Default Gateway (router address), then ping it using ping 192.168.1.1. If you receive replies, the connection is working. If not, restart the computer, router, and modem, then try again. If the issue persists, try an Ethernet connection or contact the router manufacturer."),
			D.card("Firewall", "If possible, temporarily disable the firewall to check whether it is causing network problems. If the firewall is still enabled, ensure that the necessary ports are open, especially the HTTP port."),
			D.card("Internet is not working", "If you can ping the router but cannot access the Internet, the issue may be with the router or ISP. Restart the computer, router, and modem, then try again. You can also run ping google.com to check connectivity. If the problem persists, check the browser and router settings, or contact your ISP for assistance."),
		], {"title_size": 27, "card_title_size": 14, "body_align": "center"}),
		D.cards("Solving Common Hardware Issues", "The following are the techniques and strategies that you may perform when you are trying to solve hardware issues.", [
			D.card("Trial and Error", "Identify the problem by testing components one at a time. For hardware issues, swap compatible components or try different peripherals to find the faulty part. Make only one change at a time and handle components carefully to avoid damage."),
			D.card("Check Cable Issues", "Many computer problems are caused by loose or improper cable connections. Check that all cables are securely connected and that the power supply provides power to the necessary components. Always refer to the manufacturer’s manual for proper connections."),
			D.card("Document Computer Issues", "Document troubleshooting and repairs to help prevent recurring problems. Keep track of frequently repaired or aging components so you can identify which hardware may need replacement."),
		], {"title_size": 27, "card_title_size": 14, "body_align": "center"}),
		D.hero(
			"Viruses",
			"A virus is a harmful program that infects and replicates across a computer system. It can damage files, slow down the system, cause frequent hangs, and spread through infected media, emails, websites, or downloads.\n\nTwo Methods of Eliminating Viruses:\n1. Removing the Virus – The antivirus detects and removes the virus without damaging the affected file.\n2. Quarantine – If the virus cannot be safely removed, the infected file is isolated and made inactive in the antivirus quarantine.",
			A + "m4_p16_viruses.png",
			{"art_ratio": 0.44, "bold": ["Two Methods of Eliminating Viruses", "Removing the Virus", "Quarantine"]}
		),
		D.cards("Types of Viruses", "", [
			D.card("Boot viruses", "Infect the boot records of floppy disks or hard drives. They activate when the computer starts and the infected disk is accessed.\n\nExamples: Form, Disk Killer, Michelangelo, Stone."),
			D.card("Program viruses", "Infect executable files such as .COM, .EXE, and .SYS. They become active when the infected program runs and can spread to other files.\n\nExamples: Sunday, Cascade."),
			D.card("Multipartite viruses", "Combine the characteristics of boot and program viruses by infecting both program files and boot records.\n\nExamples: Invader, Flip, Tequila."),
		], {"title_size": 32, "card_title_size": 14, "body_align": "center"}),
		D.cards("Types of Viruses", "", [
			D.card("Stealth viruses", "Use techniques to hide their presence and avoid detection, such as disguising file sizes or redirecting disk reads.\n\nExamples: Frodo, Joshi, Whale."),
			D.card("Polymorphic viruses", "Change or encrypt their code with each infection, making them harder for antivirus software to detect.\n\nExamples: Involuntary, Stimulate, Cascade, Phoenix."),
			D.card("Macro viruses", "Infect macros within documents or templates and activate when an infected document is opened.\n\nExamples: DMV, Nuclear, Word Concept."),
		], {"title_size": 32, "card_title_size": 14, "body_align": "center"}),
		D.hero(
			"Testing Computer\nSystems & Networks",
			"Testing computer systems and networks involves checking the hardware, software, and network connections to make sure they are working properly. It helps identify problems, verify system performance, and ensure that devices can communicate and connect properly. Proper testing also helps detect errors, confirm that components are functioning correctly, and maintain reliable computer and network operation.",
			A + "m4_p19_testing_diagnostics.png",
			{"art_ratio": 0.44}
		),
		D.cards(testing, "", [
			D.card("Testing the Hard Drive", "A faulty hard drive may cause data errors, slow performance, boot failures, or random restarts. Tools such as Chkdsk, TestDisk, SeaTools, and HDD Health can help detect drive problems. If a S.M.A.R.T. error appears, back up your data and consider replacing the drive."),
			D.card("Testing the Power Supply Unit", "Software like SpeedFan can monitor voltage and fan activity, but it cannot fully test the PSU’s condition. If the power supply is faulty, it is recommended to replace it. You can also use a PSU Wattage Calculator to determine the computer’s power requirements and ensure efficient power usage."),
			D.card("Testing the Memory", "Faulty RAM can cause boot failures, crashes, BSOD errors, random restarts, or failed installations. Remove recently added RAM before testing. Use Windows Memory Diagnostic, MemTest86, or DocMemory, or swap it with a compatible module. Replace the RAM if defective."),
		], {"title_size": 32, "card_title_size": 14, "body_align": "center"}),
		D.cards(testing, "", [
			D.card("Testing the Motherboard and CPU", "A faulty motherboard or CPU may cause boot failures, beep codes, crashes, or random restarts. Check for bulging capacitors or bent CPU pins, then use tools like Hot CPU Tester, Intel Processor Diagnostic Tool, or PC-Doctor. If either component is faulty, replacement may be needed."),
			D.card("Testing the Optical Drive", "A faulty optical drive may cause reading errors, playback problems, or failed program installations. First, test multiple discs to determine if the problem is with the drive or a specific disc. Clean the drive and use tools like CD Roller, CD Check, or CD/DVD Diagnostic. If the problem continues, replace the optical drive."),
			D.card("Testing the Network", "After setting up the network, check if the connection is working. Check the RJ-45 port lights on each computer, switch, or router to ensure the cables are connected. Use ipconfig /all to verify the IP address and network configuration. Finally, use ping localhost or ping another computer to confirm communication."),
		], {"title_size": 32, "card_title_size": 14, "body_align": "fill"}),
		D.external_lab(
			"Guided Simulation",
			"Work a real service ticket on the Windows desktop: open the ticket, diagnose the problem, run the maintenance and antivirus tools, and close the ticket. Yellow guides show every next step.",
			A + "m4_p02_troubleshooting.png",
			"Start Guided Simulation",
			"start_guided_lab"
		),
		D.be_ready(A + "m4_p23_be_ready_checklist.png"),
		D.external_lab(
			"Assessment",
			"Handle the service visit again — this time with no hints or guides. Read the scenario brief, then complete every step on your own.",
			A + "m4_p23_be_ready_checklist.png",
			"Start Assessment",
			"start_assessment_lab"
		),
		D.completion("You finished Maintaining Computer Systems and Networks!", [
			"Troubleshooting",
			"Hardware Maintenance",
			"Correcting Defects",
			"Inspecting and Testing Computer Systems",
			"Inspecting and Testing Computer Networks",
		]),
	]
