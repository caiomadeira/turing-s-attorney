class_name ItemLock
extends PassageLock

## Id do item em Inventory. Vazio deixa a passagem aberta.
@export var item_id: String = ""


func is_open() -> bool:
	if item_id.is_empty():
		return true
	return Inventory.has(item_id)
