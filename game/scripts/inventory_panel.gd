class_name InventoryPanel
extends Control

func _ready() -> void:
	hide()
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	%CloseButton.mouse_default_cursor_shape = Control.CURSOR_ARROW
	%ItemList.mouse_default_cursor_shape = Control.CURSOR_ARROW
	%Dimmer.mouse_default_cursor_shape = Control.CURSOR_ARROW
	var tabs := %Tabs as TabBar
	tabs.mouse_default_cursor_shape = Control.CURSOR_ARROW
	tabs.clear_tabs()
	tabs.add_tab("Itens")
	tabs.add_tab("Argumentos")
	tabs.tab_changed.connect(_on_tab_changed)
	%CloseButton.pressed.connect(hide)
	%Dimmer.gui_input.connect(_on_dimmer_input)
	%ItemList.item_selected.connect(_on_item_selected)
	(%ItemList as ItemList).fixed_icon_size = Vector2(48, 48)
	Inventory.changed.connect(_refresh)
	_refresh()


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _on_tab_changed(_tab: int) -> void:
	_refresh()


func _selected_kind() -> ItemData.Kind:
	return ItemData.Kind.ARGUMENT if (%Tabs as TabBar).current_tab == 1 else ItemData.Kind.ITEM


func _refresh() -> void:
	if not is_node_ready():
		return
	var kind := _selected_kind()
	var items: Array[ItemData] = []
	for item in Inventory.get_items():
		if item.kind == kind:
			items.append(item)
	var item_list := %ItemList as ItemList
	item_list.clear()
	for item in items:
		var index: int = item_list.add_item(item.display_name, item.icon)
		item_list.set_item_metadata(index, item.id)
	if items.is_empty():
		%ItemIcon.texture = null
		%ItemIcon.hide()
		%NameLabel.text = "Argumentos" if kind == ItemData.Kind.ARGUMENT else "Itens"
		%DescriptionLabel.text = "Nenhum argumento anotado." if kind == ItemData.Kind.ARGUMENT else "Nada aqui ainda."
		return
	%ItemList.select(0)
	_show_item(items[0])


func _on_item_selected(index: int) -> void:
	var item_id := str(%ItemList.get_item_metadata(index))
	_show_item(Inventory.get_item(item_id))


func _show_item(item: ItemData) -> void:
	if item == null:
		return
	%ItemIcon.texture = item.icon
	%ItemIcon.visible = item.icon != null
	%NameLabel.text = item.display_name
	%DescriptionLabel.text = item.description


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide()
