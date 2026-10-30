extends Node

## Inicia timelines do Dialogic e aplica os sinais delas ao jogo.
##
## Textos de sinal nas timelines:
##   give_item:attorneys_badge
##   remove_item:attorneys_badge
##   set_flag:met_witness
##   change_scene:res://game/scenes/locations/lobby.tscn
##   lose_credibility:1
##   set_credibility:5
##
## change_scene espera a timeline terminar para o local não ser liberado no meio da fala.

signal dialogue_started
signal dialogue_finished

var is_running := false

var _pending_scene := ""


func _ready() -> void:
	DialogicResourceUtil.update()
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.signal_event.connect(_on_signal_event)


func start(timeline: String) -> bool:
	if is_running or timeline.is_empty():
		return false
	var path := _resolve_timeline(timeline)
	if path.is_empty():
		push_error("DialogueDirector: timeline not found: %s" % timeline)
		return false
	is_running = true
	_pending_scene = ""
	dialogue_started.emit()
	Dialogic.start(path)
	return true


func _resolve_timeline(timeline: String) -> String:
	if timeline.begins_with("uid://"):
		return _path_for_uid(timeline)
	if timeline.begins_with("res://"):
		return timeline if FileAccess.file_exists(timeline) else ""
	var registered := DialogicResourceUtil.get_resource_path_from_identifier(timeline, "dtl")
	if registered.begins_with("uid://"):
		return _path_for_uid(registered)
	if registered.is_empty() or not FileAccess.file_exists(registered):
		return ""
	return registered


func _path_for_uid(uid_text: String) -> String:
	var id := ResourceUID.text_to_id(uid_text)
	if id != -1 and ResourceUID.has_id(id):
		var cached := ResourceUID.get_id_path(id)
		if FileAccess.file_exists(cached):
			return cached
	var folder := "res://game/dialogic/timelines"
	var dir := DirAccess.open(folder)
	if dir == null:
		return ""
	for file_name in dir.get_files():
		if not file_name.ends_with(".dtl.uid"):
			continue
		var sidecar_path := folder.path_join(file_name)
		var sidecar := FileAccess.get_file_as_string(sidecar_path).strip_edges()
		if sidecar != uid_text:
			continue
		var timeline_path := sidecar_path.trim_suffix(".uid")
		if FileAccess.file_exists(timeline_path):
			return timeline_path
	return ""


func _on_timeline_ended() -> void:
	if not is_running:
		return
	is_running = false
	dialogue_finished.emit()
	if _pending_scene.is_empty():
		return
	var scene_path := _pending_scene
	_pending_scene = ""
	SceneRouter.go_to(scene_path)


func _on_signal_event(argument: Variant) -> void:
	if typeof(argument) != TYPE_STRING:
		push_warning("DialogueDirector: expected a string signal, got %s" % typeof(argument))
		return
	var parts: PackedStringArray = (argument as String).split(":", true, 1)
	if parts.size() != 2 or parts[0].is_empty() or parts[1].is_empty():
		push_warning("DialogueDirector: bad signal '%s'" % argument)
		return
	match parts[0]:
		"give_item":
			Inventory.add(parts[1])
		"remove_item":
			Inventory.remove(parts[1])
		"set_flag":
			GameState.set_flag(parts[1])
		"change_scene":
			_pending_scene = parts[1]
		"lose_credibility":
			GameState.lose_credibility(parts[1].to_int())
		"set_credibility":
			GameState.set_credibility(parts[1].to_int())
		_:
			push_warning("DialogueDirector: unknown action '%s'" % parts[0])
