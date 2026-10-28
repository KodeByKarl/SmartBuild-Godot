class_name Module3Content
extends RefCounted

## Module 3 — Setting Up Computer Servers.
## Lessons follow the SMARTBUILD Figma "Module 3" column. The Guided and
## Assessment simulations are the Android server-topology + Server Manager labs.

const D := preload("res://core/components/lesson/lesson_data.gd")
const A := "res://modules/module_3/assets/figma/"


static func build() -> Dictionary:
	return {
		"id": 3,
		"title": "Setting Up Computer Servers",
		"header": "Module 3 | Setting Up Computer Servers",
		"pages": pages(),
	}


static func pages() -> Array:
	var list := _pages()
	# Module 3 pages carry the most copy: pack them with minimal gaps.
	for page in list:
		(page as Dictionary)["tight"] = true
	return list


static func _pages() -> Array:
	var how_to := "How to Install Modules/Add-ons?"
	return [
		D.hero(
			"Ready to Set Up a\nComputer Server?",
			"At the end of the module, students should be able to demonstrate a clear understanding of computer server setup, including server and client concepts, boot processes, user network access, network security, modules and add-ons, and network service types.",
			A + "m3_p01_server_setup.png",
			{"art_ratio": 0.46}
		),
		D.cards("Understanding the “Server” and “Client”", "It is a way of organizing communication between computers on a network. In this setup, one computer or system provides a service, while another computer requests and uses that service.", [
			D.card("Server", "A server is a computer or system that provides services, resources, or data to other computers connected to a network.", A + "m3_p02_server.png", {"art_side": "right", "no_divider": true}),
			D.card("Client", "A client is a computer or device that requests and uses services or resources provided by a server.", A + "m3_p02_client.png", {"art_side": "right", "no_divider": true}),
		], {"card_title_size": 22, "card_body_size": 18}),
		D.wide("How Server and Client Work Together?", "", {
			"body": "The client and server communicate through a network. The client sends a request for a service or resource, and the server processes the request and sends a response back.",
			"art": A + "m3_p03_client_server_flow.png",
			"art_height": 220.0,
		}),
		D.cards("Functions of Server/Client", "The server and client perform different functions that work together to provide and use network services.", [
			D.card("Server", "", "", {"bullets": [
				"Checks authorization", "Maintains data integrity", "Processes queries and updates",
				"Handles database requests", "Maintains system information", "Supports concurrent access & recovery",
			]}),
			D.card("Client", "", "", {"bullets": [
				"Manages user interface", "Checks user input", "Processes application logic",
				"Generates database requests", "Receives server responses",
			]}),
		], {"card_title_size": 22, "card_body_size": 18}),
		D.cards("Server/Client Topologies", "A Client/Server topology describes how client computers and servers are arranged and connected within a network.", [
			D.card("Single Client, Single Server", "One client connects directly to a single server to access its services.", A + "m3_p05_single_client_single_server.png", {"no_divider": true}),
			D.card("Multiple Clients, Single Server", "Multiple clients connect to one server, which provides services to all connected clients.", A + "m3_p05_multiple_clients_single_server.png", {"no_divider": true}),
			D.card("Multiple Clients, Multiple Servers", "Multiple clients can connect to multiple servers and access services from the available servers.", A + "m3_p05_multiple_clients_multiple_servers.png", {"no_divider": true}),
		], {"card_title_size": 20, "card_body_size": 17, "body_align": "fill"}),
		D.wide("Understanding the Boot Process", "The boot process is the sequence of steps a computer follows when it is turned on or restarted. It prepares the hardware, loads the operating system, and brings the computer to the log-on screen.", {
			"inner_title": "The 5 Stages of the Boot Process",
			"flow": "Pre-boot → Boot → Load → Initialization → Log-on",
		}),
		D.cards("", "", [
			D.card("Pre - Boot Stage", "The BIOS starts the pre-boot stage by identifying and prioritizing the available boot devices before the operating system is loaded.", "", {
				"subhead": "Common Pre-Boot Errors:",
				"sub_bullets": ["Corrupt MBR", "Improperly Configured Hardware", "No Active Partition", "Corrupt or Missing NTLDR"],
			}),
			D.card("Boot Stage", "During the Boot stage, the Windows Boot Manager reads the Boot Configuration Data (BCD) and determines which operating system should be loaded.", "", {
				"subhead": "Common Boot Errors:",
				"sub_bullets": ["Missing or Corrupt Files", "Improperly Configured Boot.ini", "Hardware Configuration Error"],
			}),
		], {"card_title_size": 24, "card_body_size": 17, "body_align": "fill", "help": "The first two of the five boot stages, and the errors that stop each one."}),
		D.cards("", "", [
			D.card("Load Stage", "During the Load stage, the Windows Server 2008 splash screen appears while the Windows Boot Loader loads the components needed to start the operating system."),
			D.card("Initialization Stage", "During Initialization, the operating system kernel takes control from the Windows Boot Loader and continues preparing the system."),
			D.card("Log-on Stage", "During the Log-on stage, the Windows Server operating system displays its graphical interface and log-on screen."),
		], {"card_title_size": 24, "card_body_size": 17, "body_align": "fill", "help": "The last three of the five boot stages."}),
		D.split("Windows Server and Module", {
			"title": "Module",
			"body": "A package that contains PowerShell commands such as cmdlets, providers, functions, variables, workflows, and aliases. It helps organize and share commands, allowing users to add them to their PowerShell sessions and use them like built-in commands.",
			"no_divider": true,
			"body_size": 16,
		}, {
			"title_size": 30,
			"left_ratio": 0.3,
			"right": {
				"heading": "The following are modules which support different functions and features in the Windows Server OS.",
				"columns": [
					[
						"1.  Active Directory module",
						"2.  Active Directory Rights Management Services module",
						"3.  Active Directory Rights Management Services Administration module",
						"4.  Application ID Policy Management module",
						"5.  Best Practice Analyzer module",
						"6.  Background Intelligent Transfer Service (BITS)",
						"7.  Failover Clusters module",
					],
					[
						"8.  Group Policy module",
						"9.  Network Load Balancing Clusters module",
						"10.  Remote Desktop Services module",
						"11.  Server Manager module",
						"12.  Server Migration module",
						"13.  Internet Information Services (IIS) module",
					],
				],
			},
		}),
		D.split(how_to, {
			"title": "Step 1: Find Module Commands",
			"body": "Run ‘Get-Command –Noun Module’ to view all commands related to modules.",
		}, {"title_size": 27, "right_art": A + "m3_p12_ps_get_command.png", "left_ratio": 0.27}),
		D.split(how_to, {
			"title": "Step 2: List Available Modules",
			"body": "Run ‘Get-Module –ListAvailable’ to display all installed modules.",
		}, {"title_size": 27, "right_art": A + "m3_p13_ps_list_available.png", "left_ratio": 0.27}),
		D.split(how_to, {
			"title": "Step 3: Load ServerManager Module",
			"body": "Run ‘Get-Help Import-Module’ for help, then use ‘Import-Module ServerManager’ to load the module into the current session.",
		}, {"title_size": 27, "right_art": A + "m3_p14_ps_import_module.png", "left_ratio": 0.27}),
		D.cards("Types of Network Services", "", [
			D.card("Remote Access", "Allows authorized users to access and control a computer without being physically present."),
			D.card("Domain Controller", "Used to evaluate system requirements and monitor server performance on each computer."),
			D.card("Web Services", "Enables the hosting of websites and web-based applications, supporting both static and dynamic content."),
			D.card("Database Services", "Provides database services to other computers or applications through a client-server model."),
		], {"title_size": 27, "card_title_size": 18, "card_body_size": 17}),
		D.cards("Types of Network Services", "", [
			D.card("Proxy Server", "Acts as an intermediary between clients and other servers, handling requests for resources on their behalf."),
			D.card("File Services", "Provides essential services for managing files and the way they are made available and replicated on the network."),
			D.card("Print Services", "Provides for high availability of network-attached print devices."),
		], {"title_size": 27, "card_title_size": 18, "card_body_size": 17}),
		D.external_lab(
			"Guided Simulation",
			"Connect the clients and the server on the workstation and set their IP addresses, then set up the PC and configure the server in Server Manager. Yellow guides show every next step.",
			A + "m3_p02_server.png",
			"Start Guided Simulation",
			"start_guided_lab"
		),
		D.be_ready(A + "m3_p17_be_ready_checklist.png"),
		D.external_lab(
			"Assessment Simulation",
			"Set up the server network again — this time with no hints or guides. Read the scenario brief, then complete every step on your own.",
			A + "m3_p17_be_ready_checklist.png",
			"Start Assessment",
			"start_assessment_lab"
		),
		D.completion("You finished Setting Up Computer Servers!", [
			"Understand Server and Client",
			"Boot Processes",
			"Configure User Network Access",
			"Security Check on Network Access",
			"Install Modules/Add-ons",
		]),
	]
