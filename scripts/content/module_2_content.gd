class_name Module2Content
extends RefCounted

## Module 2 — Setting Up Computer Networks.
## Lessons follow the SMARTBUILD Figma "Module 2" column. The Guided and
## Assessment simulations are the Android cable-crimp + network-topology labs,
## reached through the external_lab hand-off pages.

const D := preload("res://core/components/lesson/lesson_data.gd")
const A := "res://modules/module_2/assets/figma/"


static func build() -> Dictionary:
	return {
		"id": 2,
		"title": "Setting Up Computer Networks",
		"header": "Module 2 | Setting Up Computer Networks",
		"pages": pages(),
	}


static func pages() -> Array:
	return [
		D.hero(
			"Ready to Set Up and\nConnect a Computer\nNetwork?",
			"But before you begin, make sure you have all the necessary tools and equipment for network setup and cable crimping. On the next page, check the list and make sure you have everything needed to proceed with the activity.",
			A + "m2_p01_network_setup.png",
			{"bold": ["On the next page, check the list and make sure you have everything needed to proceed with the activity."], "art_ratio": 0.46}
		),
		D.checklist(
			"Tools and Equipment Needed for Network Setup and RJ45 Cable Crimping",
			"Tick each item to confirm you have it ready before you continue.",
			[
				D.card("Ethernet Cable (UTP)", "Used to create network cables for connecting computers and other network devices for data transmission.", A + "m2_p02_ethernet_cable.png"),
				D.card("RJ45 Connectors", "Used to terminate the ends of Ethernet cables and provide a secure connection to network ports.", A + "m2_p02_rj45_connectors.png"),
				D.card("RJ45 Crimping Tool", "Used to attach and secure the RJ45 connector onto the Ethernet cable, ensuring proper contact.", A + "m2_p02_crimping_tool.png"),
				D.card("Cable Tester", "Used to test the Ethernet cable after crimping and check if the wires are properly connected.", A + "m2_p02_cable_tester.png"),
			],
			true
		),
		D.cards("Ethernet Cables", "", [
			D.card("Straight through", "An Ethernet cable with the same wiring order on both ends (T568B to T568B). It connects different devices, like a computer to a switch or a switch to a router.", A + "m2_p03_straight_through.png", {"no_divider": true}),
			D.card("Cross-over", "A cable with T568A on one end and T568B on the other. It connects similar devices, like a computer to a computer or a switch to a switch.", A + "m2_p03_crossover.png", {"no_divider": true}),
		], {"title_size": 27, "card_title_size": 18, "card_body_size": 16}),
		D.hero(
			"What is Computer\nNetworking?",
			"Computer networking is the process of connecting computers and network devices so they can communicate and share resources.",
			A + "m2_p06_computer_networking.png",
			{"art_ratio": 0.46}
		),
		D.cards("Networking Devices", "Hardware used to connect computers and other devices, allowing them to communicate and share data over a network.", [
			D.card("Router", "Connects different networks and directs data between them.", A + "m2_p07_router.png"),
			D.card("Switch", "Connects multiple devices within the same network.", A + "m2_p07_switch.png"),
			D.card("Hub", "Connects multiple devices and sends data to all connected devices.", A + "m2_p07_hub.png"),
		], {"card_title_size": 18, "card_body_size": 18}),
		D.cards("Networking Devices", "Hardware used to connect computers and other devices, allowing them to communicate and share data over a network.", [
			D.card("Repeater", "Extends a network signal over a longer distance.", A + "m2_p08_repeater.png"),
			D.card("Bridge", "Connects two network segments together.", A + "m2_p08_bridge.png"),
		], {"card_title_size": 18, "card_body_size": 18}),
		D.cards("Network Categories", "Networks are grouped by the area they cover. The four types are PAN, LAN, MAN, and WAN, from the smallest to the largest.", [
			D.card("Personal Area Network (PAN)", "A network that connects a person's own devices when they are near each other. It usually covers up to about 10 meters."),
			D.card("Local Area Network (LAN)", "A group of computers connected within a small area, such as a building, office, floor, or department."),
			D.card("Metropolitan Area Network (MAN)", "A network bigger than a LAN that can cover up to 50 miles. It is used to connect a small area like a town or city."),
			D.card("Wide Area Network (WAN)", "A network that covers a large area, like a city or country, using telephone lines, cables, and radio waves. The Internet is the biggest WAN."),
		], {"card_title_size": 18, "card_body_size": 18}),
		D.cards("Network Topologies", "A topology is the way devices in a network are arranged and connected to each other. The layout affects how data moves, how easy the network is to set up, and how well it keeps working when something fails.", [
			D.card("Bus Topology", "All devices share one main cable. Data travels along it, and each device picks up what is meant for it.", A + "m2_p10_bus_topology.png"),
			D.card("Ring Topology", "Devices are connected in a circle. Data travels around the ring in one direction until it reaches its destination.", A + "m2_p10_ring_topology.png"),
			D.card("Star Topology", "All devices connect to a central device, like a switch or hub. If one cable fails, the other devices keep working.", A + "m2_p10_star_topology.png"),
		], {"card_title_size": 18, "card_body_size": 17}),
		D.cards("Network Topologies", "A topology is the way devices in a network are arranged and connected to each other. The layout affects how data moves, how easy the network is to set up, and how well it keeps working when something fails.", [
			D.card("Mesh Topology", "Each device connects to many or all other devices. Data has more than one path, so the network stays reliable.", A + "m2_p11_mesh_topology.png"),
			D.card("Tree Topology", "Star networks linked to a main cable, forming a branching layout. It is good for larger networks.", A + "m2_p11_tree_topology.png"),
			D.card("Hybrid Topology", "A mix of two or more topologies, combined to fit the needs of the network.", A + "m2_p11_hybrid_topology.png"),
		], {"card_title_size": 18, "card_body_size": 17}),
		D.cards("Wireless Network Security Protocols", "Wireless networks are protected by encryption. The three main types are WPA/WPA2, WEP, and 802.1X.", [
			D.card("Wi-Fi Protected Access (WPA and WPA2)", "Encrypts the information and makes sure the security key is not changed. WPA2 is the more secure version, but it does not work with older adapters."),
			D.card("Wired Equivalent Privacy (WEP)", "An older method that uses a security key to encrypt data. It is easy to crack, so it is no longer recommended."),
			D.card("802.1X Authentication", "Uses a server to check users before giving them network access. It improves security for wireless and wired networks and is common in workplaces."),
		], {"card_title_size": 14, "card_body_size": 15}),
		D.external_lab(
			"Guided Simulation",
			"Pick your tools and crimp a straight-through cable, then a crossover cable. Next build the network on the workstation: place the switches and PCs, connect them with the right cable, set the IP addresses, and test the link with ping. Yellow guides show every next step.",
			A + "m2_p02_crimping_tool.png",
			"Start Guided Simulation",
			"start_guided_lab"
		),
		D.be_ready(A + "m2_p14_be_ready_checklist.png"),
		D.external_lab(
			"Assessment Simulation",
			"Make both cables and rebuild the network again — this time with no hints or guides. Read the scenario brief, then complete every step on your own, including the ping test.",
			A + "m2_p14_be_ready_checklist.png",
			"Start Assessment",
			"start_assessment_lab"
		),
		D.completion("You finished Setting Up Computer Networks!", [
			"Identify Networking Components",
			"Create Ethernet Cables",
			"Connect Network Devices",
			"Assign IP Addresses",
			"Test Network Connection",
		]),
	]
