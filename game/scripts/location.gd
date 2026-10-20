class_name Location
extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	DialogueDirector.dialogue_started.connect(_refresh_input)
	DialogueDirector.dialogue_finished.connect(_refresh_input)
	var viewer := get_tree().get_first_node_in_group(&"note_viewer") as NoteViewer
	if viewer != null:
		viewer.opened.connect(_refresh_input)
		viewer.closed.connect(_refresh_input)
	_refresh_input()


func _refresh_input() -> void:
	var locked := is_input_locked(get_tree())
	for node in find_children("*", "BaseButton", true, false):
		if node.has_method("refresh_state"):
			node.refresh_state()
		else:
			node.disabled = DialogueDirector.is_running
		if locked:
			node.disabled = true
			if node.has_method("_update_cursor"):
				node._update_cursor()


static func is_input_locked(tree: SceneTree) -> bool:
	if DialogueDirector.is_running:
		return true
	if tree == null:
		return false
	var viewer := tree.get_first_node_in_group(&"note_viewer")
	return viewer != null and viewer.visible
