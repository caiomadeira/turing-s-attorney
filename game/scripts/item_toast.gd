class_name ItemToast
extends PanelContainer

var _queue: Array[ItemData] = []
var _hide_token := 0
var _showing := false


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Inventory.item_added.connect(_on_item_added)
	DialogueDirector.dialogue_finished.connect(_on_dialogue_finished)


func _on_item_added(item: ItemData) -> void:
	_queue.append(item)
	if DialogueDirector.is_running:
		return
	_show_next()


func _on_dialogue_finished() -> void:
	_show_after_dialogue_closes()


func _show_after_dialogue_closes() -> void:
	await get_tree().process_frame
	var layout := _dialog_layout()
	if layout != null and layout.is_inside_tree():
		if layout.is_queued_for_deletion():
			await layout.tree_exited
		elif layout.visible:
			while is_instance_valid(layout) and layout.visible:
				await get_tree().process_frame
	if DialogueDirector.is_running:
		return
	_show_next()


func _dialog_layout() -> Node:
	var tree := get_tree()
	if not tree.has_meta("dialogic_layout_node"):
		return null
	var layout: Variant = tree.get_meta("dialogic_layout_node")
	if not is_instance_valid(layout):
		return null
	return layout


func _show_next() -> void:
	if _showing or _queue.is_empty() or DialogueDirector.is_running:
		return
	_showing = true
	var item: ItemData = _queue.pop_front()
	%Icon.texture = item.icon
	%Icon.visible = item.icon != null
	if item.kind == ItemData.Kind.ARGUMENT:
		%Message.text = "Argumento anotado: %s" % item.display_name
	else:
		%Message.text = "Item %s adquirido" % item.display_name
	modulate.a = 1.0
	show()
	_hide_token += 1
	_hide_later(_hide_token)


func _hide_later(token: int) -> void:
	await get_tree().create_timer(2.6).timeout
	if token != _hide_token or not is_inside_tree():
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	await tween.finished
	if token != _hide_token:
		return
	hide()
	modulate.a = 1.0
	_showing = false
	_show_next()
