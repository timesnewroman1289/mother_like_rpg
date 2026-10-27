## An enemy in battle. Draws itself and reacts to hits, beats and defeat.
extends Node2D

const Art = preload("res://scripts/shared/art.gd")

var enemy_id := "mole"  # key in DB.ENEMIES; art/enemies/<enemy_id>.png replaces the drawing
var shape := "mole"
var color := Color.WHITE
var art_scale := 1.0
var targeted := false

var _t := 0.0
var _hurt := 0.0
var _pulse := 0.0
var _texture: Texture2D


func _ready() -> void:
	_texture = Art.find_texture(Art.ENEMIES + enemy_id + ".png")


func _process(delta: float) -> void:
	_t += delta
	_hurt = maxf(0.0, _hurt - delta)
	_pulse = maxf(0.0, _pulse - delta * 5.0)
	queue_redraw()


func hurt() -> void:
	_hurt = 0.4


## Squash a little on every beat, so you can see the rhythm too.
func pulse() -> void:
	_pulse = 1.0


func lunge() -> void:
	var t := create_tween()
	t.tween_property(self, "position:y", position.y + 10.0, 0.08)
	t.tween_property(self, "position:y", position.y, 0.12)


func die() -> void:
	targeted = false
	var t := create_tween().set_parallel()
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_property(self, "position:y", position.y + 12.0, 0.5)


func _draw() -> void:
	var flash := _hurt > 0.0 and fmod(_hurt, 0.12) > 0.06
	var width := _texture.get_width() * 0.4 if _texture else 22.0 * art_scale
	Art.draw_shadow(self, Vector2.ZERO, width)
	var squash := 1.0 + _pulse * 0.07
	var jitter := Vector2(randf_range(-2.5, 2.5), 0.0) if _hurt > 0.0 else Vector2.ZERO
	draw_set_transform(jitter, 0.0, Vector2(squash, 2.0 - squash))
	if _texture:
		# A PNG can't turn white like the drawn shapes, so it blinks when hit instead.
		# It's drawn at its own size (scale only applies to the drawn shapes).
		if not flash:
			Art.draw_texture_at_feet(self, _texture, 1.0, Vector2(0, roundf(sin(_t * 3.0) * 1.5)))
	else:
		Art.draw_enemy(self, shape, Color.WHITE if flash else color, art_scale, _t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if targeted and fmod(_t, 0.4) < 0.28:
		var top := _texture.get_height() + 6.0 if _texture else 60.0 * art_scale
		var tip := Vector2(0, -top)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-6, -8), tip + Vector2(6, -8)]), Color(1, 0.88, 0.35))
