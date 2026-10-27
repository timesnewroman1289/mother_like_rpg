## A small reusable menu: a row (horizontal) or column of options with a cursor.
## Every menu in the game is one of these.
##
##   list.set_items(["Bash", "PSI", "Goods"])
##   var picked: int = await list.choose()   # the index, or -1 if cancelled
##
## "await" pauses the calling function until the player picks something, which
## lets menu code read top to bottom instead of being split across callbacks.
extends Control

signal done(index: int)
signal moved(index: int)

const UIKit = preload("res://scripts/ui/ui_kit.gd")

var horizontal := false
var cell := Vector2(80, 14)
var allow_cancel := true
var index := 0

var _items: Array = []
var _enabled: Array = []
var _details: Array = []
var _active := false
var _opened_frame := -1


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


## enabled: optional bools (disabled options are greyed out and can't be picked).
## details: optional right-aligned text per option, e.g. a PP cost.
func set_items(items: Array, enabled: Array = [], details: Array = []) -> void:
	_items = items.duplicate()
	_enabled = enabled.duplicate()
	_details = details.duplicate()
	while _enabled.size() < _items.size():
		_enabled.append(true)
	while _details.size() < _items.size():
		_details.append("")
	index = clampi(index, 0, maxi(_items.size() - 1, 0))
	var n := maxi(_items.size(), 1)
	size = Vector2(cell.x * n, cell.y) if horizontal else Vector2(cell.x, cell.y * n)
	queue_redraw()


func choose(start_index := -1) -> int:
	if start_index >= 0:
		index = clampi(start_index, 0, maxi(_items.size() - 1, 0))
	_active = true
	# Ignore the rest of this frame's input, so the key press that opened this
	# menu doesn't also pick something in it.
	_opened_frame = Engine.get_process_frames()
	queue_redraw()
	moved.emit(index)
	var result: int = await done
	return result


## Closes the menu without emitting a result (used when a battle ends suddenly).
func cancel_choice() -> void:
	_active = false
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or Engine.get_process_frames() == _opened_frame:
		return
	var next_action := "move_right" if horizontal else "move_down"
	var prev_action := "move_left" if horizontal else "move_up"
	if event.is_action_pressed(next_action, true):
		get_viewport().set_input_as_handled()
		_move(1)
	elif event.is_action_pressed(prev_action, true):
		get_viewport().set_input_as_handled()
		_move(-1)
	elif event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		if _items.is_empty():
			return
		if _enabled[index]:
			Sfx.play("confirm")
			_finish(index)
		else:
			Sfx.play("buzz")
	elif event.is_action_pressed("cancel") and allow_cancel:
		get_viewport().set_input_as_handled()
		Sfx.play("cancel")
		_finish(-1)


func _move(step: int) -> void:
	if _items.size() < 2:
		return
	index = posmod(index + step, _items.size())
	Sfx.play("move")
	queue_redraw()
	moved.emit(index)


func _finish(result: int) -> void:
	_active = false
	queue_redraw()
	done.emit(result)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var fs := UIKit.FONT_SIZE
	var baseline := (cell.y + font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	for i in _items.size():
		var origin := Vector2(cell.x * i, 0.0) if horizontal else Vector2(0.0, cell.y * i)
		var color: Color = UIKit.TEXT if _enabled[i] else UIKit.DIM
		if i == index and _active:
			draw_rect(Rect2(origin, cell), UIKit.SELECT_BG)
			if _enabled[i]:
				color = UIKit.HILITE
			var tip := origin + Vector2(7.0, cell.y * 0.5)
			draw_colored_polygon(PackedVector2Array([
				tip + Vector2(-4, -3.5), tip, tip + Vector2(-4, 3.5)]), UIKit.HILITE)
		draw_string(font, origin + Vector2(10, baseline), str(_items[i]),
			HORIZONTAL_ALIGNMENT_LEFT, cell.x - 12.0, fs, color)
		if str(_details[i]) != "":
			draw_string(font, origin + Vector2(0, baseline), str(_details[i]),
				HORIZONTAL_ALIGNMENT_RIGHT, cell.x - 4.0, fs, color)
