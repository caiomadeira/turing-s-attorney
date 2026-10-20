class_name ExitArrow
extends SceneExit

enum Direction { LEFT, RIGHT, UP, DOWN }

const DIRECTION_ICONS: Dictionary[Direction, Texture2D] = {
	Direction.LEFT: preload("res://assets/kenney_cursor-pack/PNG/Outline/Double/arrow_w.png"),
	Direction.RIGHT: preload("res://assets/kenney_cursor-pack/PNG/Outline/Double/arrow_e.png"),
	Direction.UP: preload("res://assets/kenney_cursor-pack/PNG/Outline/Double/arrow_n.png"),
	Direction.DOWN: preload("res://assets/kenney_cursor-pack/PNG/Outline/Double/arrow_s.png"),
}

## Para que lado a seta aponta.
@export var direction: Direction = Direction.RIGHT:
	set(value):
		direction = value
		_update_direction_icon()


func _ready() -> void:
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var empty := StyleBoxEmpty.new()
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(style_name, empty)
	super()


func _update_cursor() -> void:
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	_update_direction_icon()


func _update_direction_icon() -> void:
	icon = DIRECTION_ICONS[direction] if _hovered and not disabled else null
