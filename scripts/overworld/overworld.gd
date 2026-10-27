## The overworld: a small village and field built from the MAP text below.
##
## Each character in MAP is one 16x16 tile. Edit it to reshape the world!
##   #  tree (solid)     ~  water (solid)      ,  dirt path     f  flowers
##   r  roof (solid)     H  house wall (solid) d  door (solid)  .  grass
##   P  player start     1-4, F, G  people/things to talk to (see data/npcs.gd)
##   m e c s X  field enemies (see ENEMY_TILES)
extends Node2D

const UIKit = preload("res://scripts/ui/ui_kit.gd")
const Player = preload("res://scripts/overworld/player.gd")
const Follower = preload("res://scripts/overworld/follower.gd")
const Npc = preload("res://scripts/overworld/npc.gd")
const NpcData = preload("res://scripts/data/npcs.gd")
const FieldEnemy = preload("res://scripts/overworld/field_enemy.gd")
const DialogueBox = preload("res://scripts/ui/dialogue_box.gd")
const FieldMenu = preload("res://scripts/ui/field_menu.gd")

const TILE := 16
const SOLID_TILES := "#~rHd"
const MAP := [
	"########################################",
	"#####..........................#########",
	"##rrrr....rrrr.........ffff.....########",
	"##HHdH....HdHH....1....ffff......#######",
	"##..,......,..................e....#####",
	"##..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,..####",
	"##.......,..........,.............,..###",
	"##..2....,...F......,...~~~~~.....,...##",
	"##.......,..........,..~~~~~~~....,...##",
	"###......,..........,..~~~~~~~..c.,...##",
	"####.....,....P.....,...~~~~~.....,...##",
	"####.....,,,,,,,,,,,,.............,...##",
	"###..................,............,..###",
	"##..........3........,......e.....,..###",
	"##...................,............,...##",
	"##.###...............,,,,,,,,,,,,,,...##",
	"##.###.......f.f.....,...........,....##",
	"##...........fff.....,...s.......,....##",
	"##..........G........,...........,....##",
	"##...................,.......#...,....##",
	"###..#####...........,......###..,..e.##",
	"###..#####.....m.....,.......#...,....##",
	"##...................,...........,....##",
	"##......4............,,,,,,,,,,,,,....##",
	"##..................................s.##",
	"##........s...........#####......X....##",
	"###..................#######..........##",
	"####..................#####..........###",
	"######..............................####",
	"########################################",
]

const ENEMY_TILES := {"m": "mole", "e": "moles", "c": "crow", "s": "shrub", "X": "boss"}

const GRASS := Color(0.47, 0.74, 0.36)
const GRASS_DARK := Color(0.38, 0.62, 0.3)
const TREE := Color(0.18, 0.5, 0.24)
const TREE_DARK := Color(0.1, 0.33, 0.16)
const PATH := Color(0.83, 0.72, 0.5)
const WATER := Color(0.3, 0.55, 0.9)
const ROOF := Color(0.75, 0.3, 0.25)
const WALL := Color(0.95, 0.9, 0.78)

var player
var dialogue
var field_menu
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	_build_walls()

	# Y-sorting makes things lower on screen draw in front.
	var actors := Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)

	player = Player.new()
	actors.add_child(player)
	var start := Vector2.ZERO
	for y in MAP.size():
		var row: String = MAP[y]
		for x in row.length():
			var ch := row[x]
			var pos := Vector2(x * TILE + TILE * 0.5, y * TILE + TILE - 3)
			if ch == "P":
				start = pos
			elif NpcData.NPCS.has(ch):
				_spawn_npc(actors, ch, pos)
			elif ENEMY_TILES.has(ch):
				_spawn_enemy(actors, ch, Vector2i(x, y), pos)

	player.position = Game.return_position if Game.has_return_position else start
	player.facing = Game.return_facing
	player.reset_trail()
	player.interacted.connect(_on_interact)
	player.menu_requested.connect(_on_menu)

	var follower := Follower.new()
	follower.leader = player
	follower.position = player.trail[0]
	actors.add_child(follower)

	var cam := Camera2D.new()
	cam.position = Vector2(0, -8)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = MAP[0].length() * TILE
	cam.limit_bottom = MAP.size() * TILE
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player.add_child(cam)
	cam.make_current()

	# The UI lives on a CanvasLayer so it stays put while the camera moves.
	var ui := CanvasLayer.new()
	add_child(ui)
	field_menu = FieldMenu.new()
	ui.add_child(field_menu)
	dialogue = DialogueBox.new()
	ui.add_child(dialogue)
	field_menu.dialogue = dialogue
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.size = Vector2(320, 240)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.35)


func _process(delta: float) -> void:
	Game.grace_time = maxf(0.0, Game.grace_time - delta)


# --- Building the world ------------------------------------------------------

## One StaticBody2D for all solid tiles. Runs of solid tiles in a row are
## merged into one rectangle to keep the number of shapes down.
func _build_walls() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	for y in MAP.size():
		var row: String = MAP[y]
		var x := 0
		while x < row.length():
			if not SOLID_TILES.contains(row[x]):
				x += 1
				continue
			var run_start := x
			while x < row.length() and SOLID_TILES.contains(row[x]):
				x += 1
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2((x - run_start) * TILE, TILE)
			shape.shape = rect
			shape.position = Vector2((run_start + x) * 0.5 * TILE, y * TILE + TILE * 0.5)
			body.add_child(shape)


func _spawn_npc(parent: Node, key: String, pos: Vector2) -> void:
	var npc := Npc.new()
	npc.setup(NpcData.NPCS[key])
	npc.npc_key = key
	npc.position = pos
	npc.opened = Game.flags.has("gift_" + key)
	parent.add_child(npc)


func _spawn_enemy(parent: Node, ch: String, tile: Vector2i, pos: Vector2) -> void:
	var id := "enemy_%d_%d" % [tile.x, tile.y]
	if Game.defeated.has(id):
		return
	var enemy := FieldEnemy.new()
	enemy.encounter = ENEMY_TILES[ch]
	enemy.enemy_id = id
	enemy.player = player
	enemy.position = pos
	enemy.touched.connect(_on_enemy_touched)
	parent.add_child(enemy)


func _tile_at(world_pos: Vector2) -> String:
	var tx := floori(world_pos.x / TILE)
	var ty := floori(world_pos.y / TILE)
	if ty < 0 or ty >= MAP.size():
		return "#"
	var row: String = MAP[ty]
	if tx < 0 or tx >= row.length():
		return "#"
	return row[tx]


# --- Talking, checking and the menu -----------------------------------------

func _on_interact(target) -> void:
	if _busy:
		return
	_busy = true
	player.frozen = true
	if target != null:
		await _talk(target)
	else:
		# Mother lets you "check" anything. Look at the tile in front of you.
		var ahead: Vector2 = player.global_position + Vector2(0, -4) + player.facing * 12.0
		match _tile_at(ahead):
			"d":
				await dialogue.say(["• The door is locked."])
			"~":
				await dialogue.say(["• The water is sparkling."])
			"#":
				await dialogue.say(["• It's a big, healthy tree."])
			_:
				await dialogue.say(["• No problem here."])
	player.frozen = false
	_busy = false


## Runs the NPC's conversation script from scripts/dialogue/.
func _talk(npc) -> void:
	npc.face(player.global_position)
	if npc.conversation:
		await npc.conversation.talk(self, npc)


func _on_menu() -> void:
	if _busy:
		return
	_busy = true
	player.frozen = true
	Sfx.play("confirm")
	await field_menu.run()
	player.frozen = false
	_busy = false


# --- Starting a battle -------------------------------------------------------

func _on_enemy_touched(enemy) -> void:
	if _busy:
		return
	_busy = true
	player.frozen = true

	# Like Mother 3: bump into an enemy from behind and you strike first;
	# get caught from behind and the enemies do.
	var to_enemy: Vector2 = (enemy.global_position - player.global_position).normalized()
	var adv := "none"
	if player.facing.dot(to_enemy) > 0.4 and enemy.facing.dot(to_enemy) > 0.2:
		adv = "player_first"
	elif player.facing.dot(to_enemy) < -0.2:
		adv = "enemy_first"
	Game.start_battle(enemy.encounter, enemy.enemy_id, adv, player.global_position, player.facing)

	Sfx.play("encounter")
	var t := create_tween()
	for i in 3:
		t.tween_property(_fade, "color", Color(1, 1, 1, 0.85), 0.07)
		t.tween_property(_fade, "color", Color(1, 1, 1, 0.0), 0.07)
	t.tween_property(_fade, "color", Color(0, 0, 0, 1), 0.3)
	await t.finished
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


# --- Drawing the map ---------------------------------------------------------

func _draw() -> void:
	for y in MAP.size():
		var row: String = MAP[y]
		for x in row.length():
			_draw_tile(row[x], Rect2(x * TILE, y * TILE, TILE, TILE), x, y)


func _draw_tile(ch: String, r: Rect2, x: int, y: int) -> void:
	var c := r.get_center()
	var noise := (x * 7 + y * 13) % 5  # cheap "random" variety per tile
	match ch:
		"#":
			draw_rect(r, GRASS_DARK)
			draw_circle(c + Vector2(0, 1), 8.0, TREE_DARK)
			draw_circle(c + Vector2(-1, -1), 6.5, TREE)
			draw_circle(c + Vector2(-3, -3), 2.5, TREE.lightened(0.25))
		"~":
			draw_rect(r, WATER)
			if (x + y) % 2 == 0:
				draw_line(c + Vector2(-4, 0), c + Vector2(3, 0), WATER.lightened(0.4), 1.0)
		"r":
			draw_rect(r, ROOF)
			draw_line(r.position + Vector2(0, 5), r.position + Vector2(TILE, 5), ROOF.darkened(0.3), 1.0)
			draw_line(r.position + Vector2(0, 11), r.position + Vector2(TILE, 11), ROOF.darkened(0.3), 1.0)
		"H":
			draw_rect(r, WALL)
			draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(8, 6)), Color(0.45, 0.65, 0.9))
		"d":
			draw_rect(r, WALL)
			draw_rect(Rect2(r.position + Vector2(3, 2), Vector2(10, 14)), Color(0.5, 0.3, 0.15))
			draw_circle(r.position + Vector2(10, 9), 1.0, Color(1.0, 0.85, 0.3))
		",":
			draw_rect(r, PATH)
			if noise == 0:
				draw_circle(c + Vector2(3, -2), 1.0, PATH.darkened(0.2))
		"f":
			draw_rect(r, GRASS)
			var petals := [Color(1, 0.5, 0.6), Color(1, 0.95, 0.5), Color(0.75, 0.6, 1)]
			for i in 3:
				var p := c + Vector2(-4 + i * 4, -3 + ((i + noise) % 3) * 3)
				draw_circle(p, 1.6, petals[(i + noise) % 3])
		_:
			draw_rect(r, GRASS)
			if noise == 0:
				draw_line(c + Vector2(-2, 2), c + Vector2(-1, -1), GRASS_DARK, 1.0)
				draw_line(c + Vector2(1, 2), c + Vector2(2, -1), GRASS_DARK, 1.0)
