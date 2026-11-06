extends Button

const START_SCENE := "res://game/scenes/locations/office/office.tscn"


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	GameState.reset()
	Inventory.clear()
	SceneRouter.go_to(START_SCENE)
