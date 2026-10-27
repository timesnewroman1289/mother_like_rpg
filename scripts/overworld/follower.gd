## A party member walking behind the leader, Mother style.
## It simply stands where the leader was a few steps ago.
extends Node2D

const Art = preload("res://scripts/shared/art.gd")
const DELAY := 8  # how many trail points behind the leader

var leader  # the player
var colors := {
	"hair": Color(0.95, 0.45, 0.7), "shirt": Color(0.2, 0.65, 0.6),
	"stripe": Color(0.9, 0.95, 1.0), "pants": Color(0.35, 0.25, 0.4),
}
var facing := Vector2.DOWN

var _step := 0.0
var _moving := false
var _sheet := Art.find_texture(Art.CHARACTERS + "wren.png")  # null until you add the PNG


func _physics_process(delta: float) -> void:
	if leader == null:
		return
	var trail: Array[Vector2] = leader.trail
	if trail.size() > DELAY:
		var target := trail[trail.size() - 1 - DELAY]
		if target.distance_to(position) > 0.1:
			facing = (target - position).normalized()
		position = target
	_moving = leader.moving
	if _moving:
		_step += delta * 10.0
	modulate = leader.modulate
	queue_redraw()


func _draw() -> void:
	if _sheet:
		Art.draw_sheet_character(self, _sheet, facing, _step, _moving)
	else:
		Art.draw_character(self, colors, facing, _step, _moving)
