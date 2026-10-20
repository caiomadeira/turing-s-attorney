class_name SceneExit
extends Interaction

## Cena do local a abrir.
@export_file("*.tscn") var target_scene: String = ""
## Esconde esta saída até o GameState ter esta flag.
@export var required_flag: String = ""
## Condição para atravessar. Vazia, a passagem está livre.
@export var lock: PassageLock
## Timeline reproduzida quando a trava está fechada. Vazia, o clique não faz nada.
@export_file("*.dtl") var locked_timeline: String = ""


func _ready() -> void:
	super()
	pressed.connect(_on_pressed)
	GameState.flag_changed.connect(_on_flag_changed)
	Inventory.changed.connect(refresh_state)
	refresh_state()


func is_passage_open() -> bool:
	return lock == null or lock.is_open()


func refresh_state() -> void:
	var hidden := not required_flag.is_empty() and not GameState.has_flag(required_flag)
	visible = not hidden
	disabled = hidden or Location.is_input_locked(get_tree())
	_update_cursor()


func _on_flag_changed(_flag: String, _value: bool) -> void:
	refresh_state()


func _on_pressed() -> void:
	if Location.is_input_locked(get_tree()):
		return
	if not is_passage_open():
		_on_locked()
		return
	SceneRouter.go_to(target_scene)


## Gancho para a porta reagir com a trava fechada. A timeline de recusa parte daqui.
func _on_locked() -> void:
	if locked_timeline.is_empty():
		return
	DialogueDirector.start(locked_timeline)
