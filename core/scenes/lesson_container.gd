extends VBoxContainer

@export var lesson: LessonData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if lesson:
		#print(lesson.title)
		load_lesson()
	#pass # Replace with function body.

func load_lesson():
	$TitleContainer/Title.text = lesson.title

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
