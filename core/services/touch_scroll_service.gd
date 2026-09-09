extends Node

## Gives every ScrollContainer in the app a TouchDragScroll helper.
##
## Scroll areas are created all over the place — page shells, part galleries,
## simulation docks, overlays — and several are built in code at runtime. Hooking
## node_added means new ones are covered without each site remembering to opt in.


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_attach_recursive(get_tree().root)


func _on_node_added(node: Node) -> void:
	if node is ScrollContainer:
		TouchDragScroll.attach(node as ScrollContainer)


func _attach_recursive(node: Node) -> void:
	if node is ScrollContainer:
		TouchDragScroll.attach(node as ScrollContainer)
	for child in node.get_children():
		_attach_recursive(child)
