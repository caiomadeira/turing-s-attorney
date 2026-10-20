class_name NoteInteraction
extends Interaction

## Páginas desta nota, na ordem em que o leitor as mostra.
@export var pages: Array[NotePage] = []
## Esconde esta nota até o GameState ter esta flag.
@export var required_flag: String = ""


func _ready() -> void:
	super()
	pressed.connect(_on_pressed)
	GameState.flag_changed.connect(_on_flag_changed)
	refresh_state()


func refresh_state() -> void:
	var locked := not required_flag.is_empty() and not GameState.has_flag(required_flag)
	visible = not locked
	disabled = locked or DialogueDirector.is_running
	_update_cursor()


## Páginas exibidas por [method open_note]. Sobrescreva para montar a nota em código.
func get_pages() -> Array[NotePage]:
	return pages


## Abre o leitor com [method get_pages]. Sobrescreva para mudar o que o clique faz.
func open_note() -> void:
	var viewer := _find_viewer()
	if viewer == null:
		push_error("NoteInteraction: note viewer not found")
		return
	viewer.open(get_pages())


func _on_flag_changed(_flag: String, _value: bool) -> void:
	refresh_state()


func _on_pressed() -> void:
	if not _can_read():
		return
	open_note()


func _can_read() -> bool:
	if DialogueDirector.is_running or _is_note_open():
		return false
	if not required_flag.is_empty() and not GameState.has_flag(required_flag):
		return false
	if get_pages().is_empty():
		push_warning("NoteInteraction: no pages on %s" % name)
		return false
	return true


func _is_note_open() -> bool:
	var viewer := _find_viewer()
	return viewer != null and viewer.visible


func _find_viewer() -> NoteViewer:
	var node := get_tree().get_first_node_in_group(&"note_viewer")
	return node as NoteViewer
