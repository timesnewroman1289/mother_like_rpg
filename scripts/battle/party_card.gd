## A party member's battle card with Mother 3's rolling HP/PP meters.
##
## member["hp"] is the *target* value. The number on the card rolls toward it
## at ROLL_SPEED, and you only collapse when the rolling number hits 0. So
## after "mortal damage" you still have a few seconds to heal, or win the fight.
extends Control

signal collapsed

const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ROLL_SPEED := 12.0  # HP per second
const CARD_SIZE := Vector2(76, 50)

var member: Dictionary
var raised := false    # the member whose turn it is pops up
var targeted := false  # shows an arrow when picking an ally
var hp_shown := 0.0
var pp_shown := 0.0

var _frozen := false
var _ko := false
var _shake := 0.0
var _lift := 0.0
var _t := 0.0
var _home := Vector2.ZERO
var _hp_meter: Odometer
var _pp_meter: Odometer
var _styles := {}


func _ready() -> void:
	size = CARD_SIZE
	mouse_filter = MOUSE_FILTER_IGNORE
	_home = position
	hp_shown = float(member["hp"])
	pp_shown = float(member["pp"])
	_styles = {
		"normal": UIKit.box_style(),
		"raised": UIKit.box_style(Color(0.16, 0.16, 0.36, 0.97)),
		"ko": UIKit.box_style(Color(0.45, 0.06, 0.08, 0.95)),
	}
	_hp_meter = Odometer.new()
	_hp_meter.position = Vector2(28, 19)
	add_child(_hp_meter)
	_pp_meter = Odometer.new()
	_pp_meter.position = Vector2(28, 34)
	_pp_meter.visible = int(member["max_pp"]) > 0
	add_child(_pp_meter)


func _process(delta: float) -> void:
	_t += delta
	if not _frozen:
		hp_shown = move_toward(hp_shown, float(member["hp"]), ROLL_SPEED * delta)
		pp_shown = move_toward(pp_shown, float(member["pp"]), ROLL_SPEED * 2.0 * delta)
		if not _ko and hp_shown <= 0.0 and int(member["hp"]) <= 0:
			_ko = true
			collapsed.emit()
	_lift = move_toward(_lift, 6.0 if raised else 0.0, 60.0 * delta)
	_shake = maxf(0.0, _shake - delta)
	position = _home + Vector2(sin(_shake * 90.0) * 3.0 * signf(_shake), -_lift)

	# Flash the HP red while it's rolling toward zero: heal fast!
	var dying := int(member["hp"]) <= 0 and not _ko
	_hp_meter.color = Color(1, 0.35, 0.35) if dying and fmod(_t, 0.4) < 0.2 else Color.WHITE
	_hp_meter.value = hp_shown
	_pp_meter.value = pp_shown
	_hp_meter.queue_redraw()
	_pp_meter.queue_redraw()
	queue_redraw()


## Stop the meters (when the battle is won or you escape). If HP was still
## rolling down, you keep whatever is showing; that's the Mother 3 trick.
func freeze() -> void:
	_frozen = true
	if hp_shown > float(member["hp"]):
		member["hp"] = ceili(hp_shown)
	hp_shown = float(member["hp"])
	pp_shown = float(member["pp"])


func shake() -> void:
	_shake = 0.35


func _draw() -> void:
	var style: StyleBox = _styles["ko"] if _ko else (_styles["raised"] if raised else _styles["normal"])
	draw_style_box(style, Rect2(Vector2.ZERO, size))
	var font := ThemeDB.fallback_font
	var fs := UIKit.FONT_SIZE
	draw_string(font, Vector2(7, 14), str(member["name"]), HORIZONTAL_ALIGNMENT_LEFT, size.x - 10.0, fs, UIKit.TEXT)
	draw_string(font, Vector2(7, 29), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UIKit.HILITE)
	if int(member["max_pp"]) > 0:
		draw_string(font, Vector2(7, 44), "PP", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UIKit.HILITE)
	if targeted and fmod(_t, 0.4) < 0.28:
		var tip := Vector2(size.x * 0.5, -3)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-5, -6), tip + Vector2(5, -6)]), UIKit.HILITE)


## Odometer-style digits. Each digit is drawn twice (current and next), shifted
## by how far the value is between whole numbers, so they scroll like wheels.
## clip_contents hides the parts that scroll outside the window.
class Odometer extends Control:
	const DIGITS := 3
	const DIGIT_W := 7.0
	const DIGIT_H := 12.0

	var value := 0.0
	var color := Color.WHITE

	func _init() -> void:
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(DIGITS * DIGIT_W + 4.0, DIGIT_H)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
		var font := ThemeDB.fallback_font
		var v := maxf(value, 0.0)
		var whole := floori(v)
		var frac := v - whole
		for k in DIGITS:
			var place := int(pow(10.0, k))
			var digit := floori(v / place) % 10
			# A digit only turns while every digit to its right shows 9.
			var rolling := whole % place == place - 1
			var shift := frac * DIGIT_H if rolling else 0.0
			var x := size.x - 2.0 - (k + 1) * DIGIT_W
			var baseline := DIGIT_H - 2.5 + shift
			draw_string(font, Vector2(x, baseline), str(digit), HORIZONTAL_ALIGNMENT_CENTER, DIGIT_W, 10, color)
			draw_string(font, Vector2(x, baseline - DIGIT_H), str((digit + 1) % 10), HORIZONTAL_ALIGNMENT_CENTER, DIGIT_W, 10, color)
