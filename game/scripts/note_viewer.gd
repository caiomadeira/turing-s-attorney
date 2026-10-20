class_name NoteViewer
extends Control

signal opened
signal closed

const GENERIC_PAPER := preload("res://game/ui/notes/paper_generic.svg")

var _pages: Array[NotePage] = []
var _index := 0


func _ready() -> void:
	add_to_group(&"note_viewer")
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	var dimmer := %Dimmer as Control
	dimmer.mouse_default_cursor_shape = Control.CURSOR_ARROW
	dimmer.gui_input.connect(_on_dimmer_input)
	var prev := %PrevButton as Button
	var next := %NextButton as Button
	var close_button := %CloseButton as Button
	for button in [prev, next, close_button]:
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	prev.pressed.connect(_show_previous)
	next.pressed.connect(_show_next)
	close_button.pressed.connect(close)


func open(pages: Array[NotePage]) -> void:
	if pages.is_empty():
		push_warning("NoteViewer: note has no pages")
		return
	_pages = pages
	_index = 0
	_show_page()
	show()
	get_viewport().gui_release_focus()
	opened.emit()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func _show_previous() -> void:
	if _index <= 0:
		return
	_index -= 1
	_show_page()


func _show_next() -> void:
	if _index >= _pages.size() - 1:
		return
	_index += 1
	_show_page()


func _show_page() -> void:
	var page := _pages[_index]
	var paper := %PaperTexture as TextureRect
	var body := %BodyLabel as Label
	if page == null or page.texture == null:
		paper.texture = GENERIC_PAPER
	else:
		paper.texture = page.texture
	body.text = "" if page == null else page.text
	(%PageLabel as Label).text = "%d / %d" % [_index + 1, _pages.size()]
	(%PrevButton as Button).visible = _index > 0
	(%NextButton as Button).visible = _index < _pages.size() - 1


func _unhandled_input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_show_previous()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_show_next()
		get_viewport().set_input_as_handled()


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()
