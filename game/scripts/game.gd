extends Control

const START_SCENE := "res://game/scenes/locations/office/office.tscn"

@onready var _record_button: Button = %RecordButton
@onready var _inventory_panel: InventoryPanel = %InventoryPanel
@onready var _note_viewer: NoteViewer = %NoteViewer


func _ready() -> void:
	_record_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	SceneRouter.register_host(%LocationHost)
	SceneRouter.go_to(START_SCENE)
	_record_button.pressed.connect(_inventory_panel.toggle)
	DialogueDirector.dialogue_started.connect(_on_dialogue_started)
	DialogueDirector.dialogue_finished.connect(_on_dialogue_finished)
	_note_viewer.opened.connect(_on_note_opened)
	_note_viewer.closed.connect(_on_note_closed)


func _on_dialogue_started() -> void:
	_inventory_panel.hide()
	_record_button.disabled = true


func _on_dialogue_finished() -> void:
	_record_button.disabled = _note_viewer.visible


func _on_note_opened() -> void:
	_inventory_panel.hide()
	_record_button.disabled = true


func _on_note_closed() -> void:
	_record_button.disabled = DialogueDirector.is_running
