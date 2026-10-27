## The player on the overworld. Eight-direction movement, hold Shift to run,
## Z to talk/check, C for the menu.
extends CharacterBody2D

signal interacted(target)  # target is an NPC, or null if nothing is in front
signal menu_requested

const Art = preload("res://scripts/shared/art.gd")
const WALK_SPEED := 72.0
const RUN_SPEED := 135.0
const TALK_RANGE := 22.0
const COLORS := {
	"hair": Color(0.95, 0.62, 0.2), "shirt": Color(0.85, 0.22, 0.25),
	"stripe": Color(1.0, 0.9, 0.35), "pants": Color(0.25, 0.3, 0.6),
}

var facing := Vector2.DOWN
var frozen := false  # true while talking or in a menu
var moving := false
## Recent positions, oldest first. The party follower walks along this.
var trail: Array[Vector2] = []

var _step := 0.0
var _sheet := Art.find_texture(Art.CHARACTERS + "kit.png")  # null until you add the PNG


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING  # top-down: no gravity, no floors
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 7)  # just the feet, so you can walk "behind" things
	shape.shape = rect
	shape.position = Vector2(0, -3.5)
	add_child(shape)


func reset_trail() -> void:
	trail.clear()
	for i in range(12, 0, -1):
		trail.append(global_position - facing * i * 2.0)
	trail.append(global_position)


func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if not frozen:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running := Input.is_action_pressed("run")
	velocity = dir * (RUN_SPEED if running else WALK_SPEED)
	moving = dir != Vector2.ZERO
	if moving:
		facing = dir.normalized()
		_step += delta * (16.0 if running else 10.0)
	move_and_slide()

	if trail.is_empty() or global_position.distance_to(trail[-1]) >= 2.0:
		trail.append(global_position)
		if trail.size() > 64:
			trail.pop_front()

	# Blink while enemies are leaving you alone after running from a battle.
	modulate.a = (0.35 if int(Game.grace_time * 12.0) % 2 == 0 else 1.0) if Game.grace_time > 0.0 else 1.0
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if frozen:
		return
	if event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		interacted.emit(_find_interactable())
	elif event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		menu_requested.emit()


## The closest NPC that is roughly in front of us.
func _find_interactable() -> Node2D:
	var best: Node2D = null
	var best_dist := TALK_RANGE
	for node in get_tree().get_nodes_in_group("interactable"):
		var n := node as Node2D
		var offset := n.global_position - global_position
		var dist := offset.length()
		if dist < best_dist and (dist < 4.0 or facing.dot(offset / dist) > 0.5):
			best = n
			best_dist = dist
	return best


func _draw() -> void:
	if _sheet:
		Art.draw_sheet_character(self, _sheet, facing, _step, moving)
	else:
		Art.draw_character(self, COLORS, facing, _step, moving)
