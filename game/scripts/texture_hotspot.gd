class_name TextureHotspot
extends TextureRect

## Timeline reproduzida quando [member flag] não está definida.
@export_file("*.dtl") var timeline: String = ""
## Timeline reproduzida quando [member flag] já está definida. Deixe vazio para usar sempre [member timeline].
@export_file("*.dtl") var timeline_if_flag: String = ""
## Flag do GameState que troca para [member timeline_if_flag].
@export var flag: String = ""
## Esconde este ponto de interação até o GameState ter esta flag.
@export var required_flag: String = ""
## Desativa depois da primeira conversa bem-sucedida.
@export var one_shot: bool = false
## Desenho do cursor enquanto o ponteiro está sobre este controle.
@export var icon_texture: Texture2D
## Largura e altura do cursor, em pixels.
@export var proportions: Vector2 = Vector2(64, 64)
## Ponto de clique, em pixels de [member icon_texture]. Escala junto com [member proportions].
@export var hotspot: Vector2 = Vector2.ZERO

var _hovered := false
var _used := false
var _active := true
var _pressed_inside := false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	GameState.flag_changed.connect(_on_flag_changed)
	refresh_state()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse.pressed:
		_pressed_inside = _active
		accept_event()
		return
	var fire := _pressed_inside and _active and _hovered
	_pressed_inside = false
	accept_event()
	if fire:
		_on_pressed()


func refresh_state() -> void:
	var hidden := not required_flag.is_empty() and not GameState.has_flag(required_flag)
	# Some durante a fala e volta quando DialogueDirector emite dialogue_finished.
	visible = not hidden and not DialogueDirector.is_running
	_active = visible and not (_used and one_shot) and not Location.is_input_locked(get_tree())
	if not visible:
		_hovered = false
	if not _active:
		_pressed_inside = false
	_update_cursor()


func _on_flag_changed(_flag: String, _value: bool) -> void:
	refresh_state()


func _on_pressed() -> void:
	if not _active or DialogueDirector.is_running:
		return
	var next := timeline
	if not timeline_if_flag.is_empty() and not flag.is_empty() and GameState.has_flag(flag):
		next = timeline_if_flag
	if not DialogueDirector.start(next):
		return
	if one_shot:
		_used = true
		refresh_state()


func _set_hovered(value: bool) -> void:
	_hovered = value
	if not value:
		_pressed_inside = false
	_update_cursor()


func _update_cursor() -> void:
	if _hovered and _active and icon_texture != null:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		Input.set_custom_mouse_cursor(_scaled_cursor(), Input.CURSOR_POINTING_HAND, _scaled_hotspot())
		return
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func _scaled_cursor() -> Texture2D:
	var image := icon_texture.get_image()
	var target := Vector2i(maxi(roundi(proportions.x), 1), maxi(roundi(proportions.y), 1))
	if image.get_size() == target:
		return icon_texture
	image.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


func _scaled_hotspot() -> Vector2:
	var source := icon_texture.get_size()
	if source.x <= 0.0 or source.y <= 0.0:
		return hotspot
	return Vector2(
		hotspot.x * proportions.x / source.x,
		hotspot.y * proportions.y / source.y
	)
