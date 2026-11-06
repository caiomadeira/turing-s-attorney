extends Node

## Itens que o jogador está carregando. As definições ficam em res://game/data/items/.

signal changed
signal item_added(item: ItemData)

const ITEMS_DIR := "res://game/data/items/"

var _catalog: Dictionary = {}
var _owned: Array[String] = []


func _ready() -> void:
	_load_catalog()


func add(item_id: String) -> bool:
	if not _catalog.has(item_id):
		push_warning("Inventory: unknown item '%s'" % item_id)
		return false
	if item_id in _owned:
		return false
	_owned.append(item_id)
	changed.emit()
	item_added.emit(_catalog[item_id])
	return true


func clear() -> void:
	if _owned.is_empty():
		return
	_owned.clear()
	changed.emit()


func remove(item_id: String) -> bool:
	var index := _owned.find(item_id)
	if index == -1:
		return false
	_owned.remove_at(index)
	changed.emit()
	return true


func has(item_id: String) -> bool:
	return item_id in _owned


func get_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for item_id in _owned:
		var item := get_item(item_id)
		if item:
			items.append(item)
	return items


func get_item(item_id: String) -> ItemData:
	return _catalog.get(item_id) as ItemData


func _load_catalog() -> void:
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_error("Inventory: cannot open %s" % ITEMS_DIR)
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".remap"):
			file_name = file_name.trim_suffix(".remap")
		if not file_name.ends_with(".tres"):
			continue
		var item := load(ITEMS_DIR.path_join(file_name)) as ItemData
		if item == null or item.id.is_empty():
			push_warning("Inventory: skipped %s" % file_name)
			continue
		_catalog[item.id] = item
