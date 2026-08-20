extends Control

var curr_slide: int = 0
var current_slide: Control = null

var slides1: Array[PackedScene] = [
	preload("res://modules/module_0/slides/slide_1.tscn"),
	preload("res://modules/module_0/slides/slide_2.tscn"),
	preload("res://modules/module_0/slides/slide_3.tscn"),
	preload("res://modules/module_0/slides/slide_4.tscn"),
	preload("res://modules/module_0/slides/slide_5.tscn"),
	preload("res://modules/module_0/slides/slide_6.tscn"),
	preload("res://modules/module_0/slides/slide_7.tscn"),
	preload("res://modules/module_0/slides/slide_8.tscn"),
	preload("res://modules/module_0/slides/slide_9.tscn"),
	preload("res://modules/module_0/slides/slide_10.tscn"),
	preload("res://modules/module_0/slides/slide_11.tscn"),
	preload("res://modules/module_0/slides/slide_12.tscn"),
	preload("res://modules/module_0/slides/slide_13.tscn"),
	preload("res://modules/module_0/slides/slide_14.tscn"),
	preload("res://modules/module_0/slides/slide_15.tscn"),
	preload("res://modules/module_0/slides/slide_16.tscn"),
	preload("res://modules/module_0/slides/slide_17.tscn"),
	preload("res://modules/module_0/slides/slide_18.tscn"),
	preload("res://modules/module_0/slides/slide_19.tscn"),
	preload("res://modules/module_0/slides/slide_20.tscn"),
]

var slides: Array[Dictionary] = [
	{
		"title": "Welcome to Computer Systems Servicing",
		"body": "Computers are everywhere.
Behind every working computer system are people who install, maintain, troubleshoot, and repair them.",
		"type": "text"
	},
	{
		"title": "Why is CSS Relevant?",
		"body": "Technology is an important part of modern workplaces. Organizations rely on computers, networks, and other technology, creating a need for people who can provide computer servicing and repair.",
		"type": "text"
	},
	{
		"title": "What You Will Learn",
		"body": "This introduction covers the electronics industry, workplace safety, quality standards, computer fundamentals, hardware components, ports and connectors, and common servicing tools.",
		"type": "text"
	}
]

# Presentation.
@onready var content: VBoxContainer = $Wrapper/Presentation/Content
# Navigation.
@onready var prev_btn: Button = $Wrapper/Navigation/Buttons/PreviousButton
@onready var next_btn: Button = $Wrapper/Navigation/Buttons/NextButton
@onready var page_num_lbl: Label = $Wrapper/Navigation/PageNumberLabel
@onready var exit_btn: Button = $Wrapper/Navigation/ExitButton

func _ready():
	prev_btn.pressed.connect(_on_prev_btn_pressed)
	next_btn.pressed.connect(_on_next_btn_pressed)
	
	_disable_btn()
	update_slide()

func update_slide():
	if current_slide != null:
		current_slide.queue_free()
		current_slide = null
	
	current_slide = slides1[curr_slide].instantiate()
	content.add_child(current_slide)
	
	page_num_lbl.text = str((curr_slide + 1), " / ", slides1.size())

func _disable_btn():
	prev_btn.disabled = true if curr_slide == 0 else false
	next_btn.disabled = true if curr_slide == (slides1.size() - 1) else false

func _on_prev_btn_pressed():
	curr_slide -= 1
	_disable_btn()
	update_slide()

func _on_next_btn_pressed():
	curr_slide += 1
	_disable_btn()
	update_slide()
