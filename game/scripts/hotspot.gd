@tool
class_name Hotspot
extends Interaction

## Imagem deste ponto. O retângulo do controle é o quadro: arraste as bordas para escalar.
@export var texture: Texture2D:
	set(value):
		texture = value
		_adopt_texture_size()
		apply_resizable_icon()
		if texture != null:
			flat = true
		queue_redraw()

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

var _used := false


func _enter_tree() -> void:
	apply_resizable_icon()
	if texture != null:
		flat = true
	_adopt_texture_size()


func _ready() -> void:
	apply_resizable_icon()
	if texture != null:
		flat = true
	# No editor o script só prepara a imagem. Autoloads do jogo não rodam aqui.
	if Engine.is_editor_hint():
		return
	super()
	pressed.connect(_on_pressed)
	GameState.flag_changed.connect(_on_flag_changed)
	refresh_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW and texture != null:
		# Estica a imagem até o retângulo atual. O tamanho da textura não trava o botão.
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false, Color.WHITE)


func _adopt_texture_size() -> void:
	if texture == null or not is_inside_tree():
		return
	if size.x >= 1.0 and size.y >= 1.0:
		return
	var image_size := texture.get_size()
	if image_size.x < 1.0 or image_size.y < 1.0:
		return
	size = image_size


func refresh_state() -> void:
	var locked := not required_flag.is_empty() and not GameState.has_flag(required_flag)
	visible = not locked
	disabled = locked or (_used and one_shot) or DialogueDirector.is_running
	_update_cursor()


func _on_flag_changed(_flag: String, _value: bool) -> void:
	refresh_state()


func _on_pressed() -> void:
	if DialogueDirector.is_running:
		return
	var next := timeline
	if not timeline_if_flag.is_empty() and not flag.is_empty() and GameState.has_flag(flag):
		next = timeline_if_flag
	if not DialogueDirector.start(next):
		return
	if one_shot:
		_used = true
		refresh_state()
