class_name Interaction
extends Button

## Desenho do cursor enquanto o ponteiro está sobre este controle.
@export var icon_texture: Texture2D
## Largura e altura do cursor, em pixels.
@export var proportions: Vector2 = Vector2(64, 64)
## Ponto de clique, em pixels de [member icon_texture]. Escala junto com [member proportions].
@export var hotspot: Vector2 = Vector2.ZERO

var _hovered := false


func _ready() -> void:
	# Sem foco de teclado: Enter e Espaço avançam as falas do Dialogic e,
	# com foco, apertariam de novo o último ponto clicado quando a fala acaba.
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))


## O ícone do Button, com expand_icon, encolhe junto com o controle.
## Sem isso, o tamanho mínimo fica preso ao tamanho da textura.
func apply_resizable_icon() -> void:
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	for color_name in [
		&"icon_normal_color",
		&"icon_hover_color",
		&"icon_pressed_color",
		&"icon_hover_pressed_color",
		&"icon_disabled_color",
		&"icon_focus_color",
	]:
		add_theme_color_override(color_name, Color.WHITE)
	if icon != null:
		flat = true


func _set_hovered(value: bool) -> void:
	_hovered = value
	_update_cursor()


func _update_cursor() -> void:
	if _hovered and not disabled and icon_texture != null:
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
