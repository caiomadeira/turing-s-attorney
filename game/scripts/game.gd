extends Control

const START_SCENE := "res://game/scenes/locations/office/office.tscn"
const TRIBUNAL_SCENE := "res://game/scenes/locations/tribunal/tribunal.tscn"
const FIM_SCENE := "res://game/scenes/locations/fim_de_jogo/fim_de_jogo.tscn"
const VEREDITO_SCENE := "res://game/scenes/locations/veredito/veredito.tscn"

const _NO_COURT_SCENES: Array[String] = [
	TRIBUNAL_SCENE,
	VEREDITO_SCENE,
	FIM_SCENE,
]

@onready var _hud: CanvasLayer = $HUD
@onready var _credibility_layer: CanvasLayer = $CredibilityLayer
@onready var _note_layer: CanvasLayer = $NoteLayer
@onready var _toast_layer: CanvasLayer = $ToastLayer
@onready var _record_button: Button = %RecordButton
@onready var _court_button: Button = %CourtButton
@onready var _court_confirm: ConfirmationDialog = %CourtConfirm
@onready var _inventory_panel: InventoryPanel = %InventoryPanel
@onready var _note_viewer: NoteViewer = %NoteViewer
@onready var _item_toast: ItemToast = $ToastLayer/ItemToast


func _ready() -> void:
	_record_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	_court_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	SceneRouter.register_host(%LocationHost)
	SceneRouter.go_to(START_SCENE)
	_record_button.pressed.connect(_inventory_panel.toggle)
	_court_button.pressed.connect(_on_court_pressed)
	_court_confirm.confirmed.connect(_on_court_confirmed)
	SceneRouter.location_changed.connect(_on_location_changed)
	GameState.flag_changed.connect(_on_flag_changed)
	DialogueDirector.dialogue_started.connect(_on_dialogue_started)
	DialogueDirector.dialogue_finished.connect(_on_dialogue_finished)
	_note_viewer.opened.connect(_on_note_opened)
	_note_viewer.closed.connect(_on_note_closed)
	_refresh_court_button()


func _on_dialogue_started() -> void:
	_inventory_panel.hide()
	_court_confirm.visible = false
	_record_button.disabled = true
	_refresh_court_button()


func _on_dialogue_finished() -> void:
	_record_button.disabled = _note_viewer.visible
	_refresh_court_button()


func _on_note_opened() -> void:
	_inventory_panel.hide()
	_court_confirm.visible = false
	_record_button.disabled = true
	_refresh_court_button()


func _on_note_closed() -> void:
	_record_button.disabled = DialogueDirector.is_running
	_refresh_court_button()


func _on_court_pressed() -> void:
	_court_confirm.popup_centered(Vector2i(560, 180))


func _on_court_confirmed() -> void:
	SceneRouter.go_to(TRIBUNAL_SCENE)


func _on_flag_changed(_flag: String, _value: bool) -> void:
	_refresh_court_button()


func _on_location_changed(scene_path: String) -> void:
	_refresh_court_button(scene_path)
	_apply_end_screen(scene_path)


## No fim de jogo e no veredito somem inventário, losangos, nota e aviso de item.
## CanvasLayer.visible não altera o visible de cada filho.
func _apply_end_screen(scene_path: String) -> void:
	var on_end := scene_path == FIM_SCENE or scene_path == VEREDITO_SCENE
	_hud.visible = not on_end
	_credibility_layer.visible = not on_end
	_note_layer.visible = not on_end
	_toast_layer.visible = not on_end
	if not on_end:
		return
	_inventory_panel.hide()
	_court_confirm.visible = false
	_item_toast.hide()
	if _note_viewer.visible:
		_note_viewer.close()
	_hide_dialog_layout()


func _hide_dialog_layout() -> void:
	var tree := get_tree()
	if not tree.has_meta("dialogic_layout_node"):
		return
	var layout: Variant = tree.get_meta("dialogic_layout_node")
	if is_instance_valid(layout) and layout is CanvasItem:
		(layout as CanvasItem).hide()


func _refresh_court_button(_scene_path: String = "") -> void:
	var hidden := SceneRouter.current_scene_path in _NO_COURT_SCENES or not GameState.has_flag("leu_dossie")
	_court_button.visible = not hidden
	_court_button.disabled = hidden or DialogueDirector.is_running or _note_viewer.visible
