## Mother-style dialogue box. Text types out letter by letter; Z or X advances.
##
##   await dialogue.say(["• Hello!", "• Nice weather today."])
##   var answer: int = await dialogue.say(["• Save?"], ["Yes", "No"])  # 0 = Yes
extends Control

signal finished(choice: int)

const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ChoiceList = preload("res://scripts/ui/choice_list.gd")
const CHARS_PER_SECOND := 40.0
## Test: makes the boxes ripple. Tweak the look in shaders/wobble.gdshader.
const WOBBLE := true
const WobbleShader = preload("res://shaders/wobble.gdshader")

var _box: Panel
var _label: Label
var _arrow: Control
var _choice_box: Panel
var _choices: ChoiceList
var _text_color := UIKit.TEXT

var _lines: Array = []
var _choice_labels: Array = []
var _line := 0
var _shown := 0.0
var _blink := 0.0
var _typing := false
var _active := false
var _asking := false
var _opened_frame := -1


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false
	_box = UIKit.make_box(self, Rect2(8, 166, 304, 66))
	_label = UIKit.make_label(_box, "", Vector2(10, 5), Vector2(284, 56))

	# The little "more text" arrow, drawn as a triangle.
	_arrow = Control.new()
	_arrow.position = Vector2(286, 54)
	_arrow.size = Vector2(8, 6)
	_arrow.draw.connect(func() -> void:
		_arrow.draw_colored_polygon(PackedVector2Array([
			Vector2(0, 0), Vector2(8, 0), Vector2(4, 5)]), _text_color))
	_box.add_child(_arrow)

	_choice_box = UIKit.make_box(self, Rect2(208, 136, 104, 26))
	_choices = ChoiceList.new()
	_choices.horizontal = true
	_choices.cell = Vector2(48, 16)
	_choices.position = Vector2(4, 5)
	_choice_box.add_child(_choices)
	_choice_box.visible = false

	if WOBBLE:
		_add_wobble(_box)
		_add_wobble(_choice_box)
	_apply_colors()


## Paints both boxes in the colour picked in the field menu (Game.text_box_color).
func _apply_colors() -> void:
	var c: Dictionary = UIKit.TEXT_BOX_COLORS[Game.text_box_color]
	for box in [_box, _choice_box]:
		box.add_theme_stylebox_override("panel", UIKit.box_style(c["bg"], c["border"]))
	_text_color = c["text"]
	_label.add_theme_color_override("font_color", _text_color)
	_arrow.queue_redraw()
	_choices.text_color = _text_color
	_choices.hilite_color = c["hilite"]
	_choices.select_bg = Color(_text_color, 0.14)


## Lays a wobble-shader rectangle over the box, a little bigger so the border
## has room to sway. It goes in as the box's first child: the panel itself is
## drawn before it (so it wobbles) and the text after it (so it stays still).
func _add_wobble(box: Control) -> void:
	# Grab a fresh copy of the screen so the shader sees this box, not just
	# what was there before the previous box drew.
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	box.add_child(copy)
	var margin := 3.0
	var overlay := ColorRect.new()
	overlay.mouse_filter = MOUSE_FILTER_IGNORE
	overlay.position = Vector2(-margin, -margin)
	overlay.size = box.size + Vector2(margin, margin) * 2.0
	overlay.material = ShaderMaterial.new()
	overlay.material.shader = WobbleShader
	box.add_child(overlay)
	box.move_child(copy, 0)
	box.move_child(overlay, 1)


func say(lines: Array, choices: Array = []) -> int:
	_lines = lines
	_choice_labels = choices
	_line = 0
	_apply_colors()
	_active = true
	_opened_frame = Engine.get_process_frames()
	visible = true
	_show_line()
	var choice: int = await finished
	return choice


func _show_line() -> void:
	_label.text = str(_lines[_line])
	_label.visible_characters = 0
	_shown = 0.0
	_typing = true
	_arrow.visible = false


func _process(delta: float) -> void:
	if not _active:
		return
	if _typing:
		var before := int(_shown)
		_shown += CHARS_PER_SECOND * delta
		_label.visible_characters = int(_shown)
		if int(_shown) != before and int(_shown) % 2 == 0:
			Sfx.play("text")
		if _shown >= _label.get_total_character_count():
			_end_typing()
	elif not _asking:
		_blink += delta
		_arrow.visible = fmod(_blink, 0.6) < 0.4


func _end_typing() -> void:
	_typing = false
	_label.visible_characters = -1
	_blink = 0.0
	if _line == _lines.size() - 1 and not _choice_labels.is_empty():
		_ask()


func _ask() -> void:
	_asking = true
	_arrow.visible = false
	_choice_box.visible = true
	_choices.set_items(_choice_labels)
	var picked: int = await _choices.choose(0)
	if picked < 0:
		picked = _choice_labels.size() - 1  # cancelling means the last option ("No")
	_asking = false
	_close(picked)


func _unhandled_input(event: InputEvent) -> void:
	if not _active or _asking or Engine.get_process_frames() == _opened_frame:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if _typing:
			_end_typing()  # first press shows the whole line
		else:
			_line += 1
			if _line >= _lines.size():
				_close(-1)
			else:
				_show_line()


func _close(choice: int) -> void:
	_active = false
	visible = false
	_choice_box.visible = false
	finished.emit(choice)
