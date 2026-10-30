class_name CredibilityBar
extends Control

## Losangos de credibilidade do promotor durante o julgamento.
## Um losango cheio para cada ponto em GameState.credibility.

## A barra só aparece quando o GameState tem esta flag.
@export var show_flag: String = "em_julgamento"
## Largura e altura de cada losango, em pixels.
@export var diamond_size: float = 36.0
## Espaço entre dois losangos, em pixels.
@export var spacing: float = 12.0

const FULL_COLOR := Color(1.0, 0.93, 0.72)
const EMPTY_COLOR := Color(0.15, 0.15, 0.15, 0.45)
const OUTLINE_COLOR := Color(0.12, 0.08, 0.03)

var _last_value := GameState.MAX_CREDIBILITY


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.credibility_changed.connect(_on_credibility_changed)
	GameState.flag_changed.connect(_on_flag_changed)
	visible = GameState.has_flag(show_flag)


func _on_flag_changed(flag: String, value: bool) -> void:
	if flag == show_flag:
		visible = value


func _on_credibility_changed(value: int) -> void:
	# Perdeu losango: a barra pisca em vermelho.
	if value < _last_value:
		modulate = Color(1.0, 0.3, 0.3)
		create_tween().tween_property(self, "modulate", Color.WHITE, 0.6)
	_last_value = value
	queue_redraw()


func _draw() -> void:
	var half := diamond_size * 0.5
	for i in GameState.MAX_CREDIBILITY:
		var center := Vector2(half + i * (diamond_size + spacing), half)
		var points := PackedVector2Array([
			center + Vector2(0, -half),
			center + Vector2(half, 0),
			center + Vector2(0, half),
			center + Vector2(-half, 0),
		])
		var fill := FULL_COLOR if i < GameState.credibility else EMPTY_COLOR
		draw_colored_polygon(points, fill)
		points.append(points[0])
		draw_polyline(points, OUTLINE_COLOR, 3.0, true)
