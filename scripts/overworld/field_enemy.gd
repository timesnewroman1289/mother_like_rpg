## A visible enemy on the overworld (Mother games have no random encounters).
## It wanders near home and chases the player when close. Touching it starts
## a battle; the overworld works out who gets the first move.
extends CharacterBody2D

signal touched(enemy)

const Art = preload("res://scripts/shared/art.gd")
const DB = preload("res://scripts/data/db.gd")
const CHASE_RANGE := 72.0
const CHASE_SPEED := 50.0
const WANDER_SPEED := 22.0
const WANDER_RADIUS := 48.0

var encounter := "mole"
var enemy_id := ""
var player  # set by the overworld
var facing := Vector2.DOWN

var _def: Dictionary
var _home := Vector2.ZERO
var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0
var _t := 0.0
## Your art, if it exists: art/enemies/<id>_field.png at its own size, or else
## the battle image art/enemies/<id>.png shrunk down.
var _texture: Texture2D
var _texture_scale := 1.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 1  # bump into walls and NPCs, but walk through the player
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	shape.position = Vector2(0, -4)
	add_child(shape)
	_home = position
	var id: String = DB.ENCOUNTERS[encounter][0]
	_def = DB.ENEMIES[id]
	_t = randf() * 10.0
	_texture = Art.find_texture(Art.ENEMIES + id + "_field.png")
	if _texture == null:
		_texture = Art.find_texture(Art.ENEMIES + id + ".png")
		_texture_scale = 0.42


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if player == null or player.frozen:
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()
	if dist < CHASE_RANGE and dist > 0.0:
		if Game.grace_time > 0.0:
			velocity = -to_player / dist * WANDER_SPEED * 1.5  # scared off for a bit
		else:
			velocity = to_player / dist * CHASE_SPEED
	else:
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_wander_timer = randf_range(0.8, 2.0)
			if position.distance_to(_home) > WANDER_RADIUS:
				_wander_dir = (_home - position).normalized()
			elif randf() < 0.35:
				_wander_dir = Vector2.ZERO
			else:
				_wander_dir = Vector2.from_angle(randf() * TAU)
		velocity = _wander_dir * WANDER_SPEED
	if velocity.length() > 1.0:
		facing = velocity.normalized()
	move_and_slide()

	if dist < 13.0 and Game.grace_time <= 0.0:
		touched.emit(self)


func _draw() -> void:
	Art.draw_shadow(self, Vector2.ZERO, 8.0)
	if _texture:
		Art.draw_texture_at_feet(self, _texture, _texture_scale, Vector2(0, roundf(sin(_t * 4.0))))
	else:
		Art.draw_enemy(self, _def["shape"], _def["color"], 0.42 * float(_def["scale"]), _t)
