## Global game state, autoloaded as "Game" (see Project Settings -> Autoload).
##
## Scenes are thrown away when you switch between them, so anything that must
## survive a scene change lives here: the party, Goods, story flags, which
## field enemies are gone, and where to put the player after a battle.
extends Node

const DB = preload("res://scripts/data/db.gd")
const MAX_GOODS := 8
const STAT_NAMES := {
	"max_hp": "Max HP", "max_pp": "Max PP", "offense": "Offense",
	"defense": "Defense", "speed": "Speed",
}

var party: Array = []
var inventory: Array = []
var flags := {}
var defeated := {}

# Hand-off from the overworld to the battle scene.
var pending_encounter := ""
var pending_enemy_id := ""
var advantage := "none"  # "none", "player_first" or "enemy_first"

# Where the player appears when the overworld loads.
var has_return_position := false
var return_position := Vector2.ZERO
var return_facing := Vector2.DOWN
var grace_time := 0.0  # seconds of "enemies leave you alone" after fleeing

# Settings. Not part of the save, so they stick through game overs.
var text_box_color := "Black"  # a key of UIKit.TEXT_BOX_COLORS

var _save := {}


func _ready() -> void:
	_setup_input()
	new_game()


func new_game() -> void:
	party = [
		{
			"name": "Kit", "level": 1, "exp": 0,
			"hp": 60, "max_hp": 60, "pp": 0, "max_pp": 0,
			"offense": 12, "defense": 6, "speed": 6, "psi": [],
		},
		{
			"name": "Wren", "level": 1, "exp": 0,
			"hp": 44, "max_hp": 44, "pp": 24, "max_pp": 24,
			"offense": 7, "defense": 5, "speed": 9, "psi": ["fire_a", "freeze_a", "lifeup_a"],
		},
	]
	inventory = ["nut_cookie", "nut_cookie", "pop_jelly"]
	flags = {}
	defeated = {}
	has_return_position = false
	return_facing = Vector2.DOWN
	grace_time = 0.0
	_save = _snapshot()


# --- Saving (in memory; see README for writing it to disk) ------------------

func save_game(pos: Vector2, facing: Vector2) -> void:
	return_position = pos
	return_facing = facing
	has_return_position = true
	_save = _snapshot()


func load_save() -> void:
	party = _save["party"].duplicate(true)
	inventory = _save["inventory"].duplicate()
	flags = _save["flags"].duplicate(true)
	defeated = _save["defeated"].duplicate()
	has_return_position = _save["has_pos"]
	return_position = _save["pos"]
	return_facing = _save["facing"]
	grace_time = 0.0


func _snapshot() -> Dictionary:
	return {
		"party": party.duplicate(true), "inventory": inventory.duplicate(),
		"flags": flags.duplicate(true), "defeated": defeated.duplicate(),
		"has_pos": has_return_position, "pos": return_position, "facing": return_facing,
	}


# --- Battles -----------------------------------------------------------------

func start_battle(encounter: String, enemy_id: String, adv: String, pos: Vector2, facing: Vector2) -> void:
	pending_encounter = encounter
	pending_enemy_id = enemy_id
	advantage = adv
	return_position = pos
	return_facing = facing
	has_return_position = true


# --- Goods, healing and levels ------------------------------------------------

func add_item(id: String) -> bool:
	if inventory.size() >= MAX_GOODS:
		return false
	inventory.append(id)
	return true


## Returns the message lines to show. Does not remove the item from Goods.
func use_item(id: String, user: Dictionary, target: Dictionary) -> Array:
	var item: Dictionary = DB.ITEMS[id]
	var lines := []
	if user["name"] == target["name"]:
		lines.append("• %s %s the %s." % [user["name"], item["verb"], item["name"]])
	else:
		lines.append("• %s gave the %s to %s." % [user["name"], item["name"], target["name"]])
	lines.append_array(heal(target, item["hp"], item["pp"]))
	return lines


func heal(m: Dictionary, hp: int, pp: int) -> Array:
	var lines := []
	if hp > 0:
		var gained := mini(hp, int(m["max_hp"]) - int(m["hp"]))
		m["hp"] = int(m["hp"]) + gained
		if gained > 0:
			lines.append("• %s's HP went up by %d!" % [m["name"], gained])
	if pp > 0 and int(m["max_pp"]) > 0:
		var gained := mini(pp, int(m["max_pp"]) - int(m["pp"]))
		m["pp"] = int(m["pp"]) + gained
		if gained > 0:
			lines.append("• %s's PP went up by %d!" % [m["name"], gained])
	if lines.is_empty():
		lines.append("• But nothing happened...")
	return lines


func heal_all() -> void:
	for m in party:
		m["hp"] = m["max_hp"]
		m["pp"] = m["max_pp"]


## Total EXP needed to reach a level: 20, 60, 120, 200...
func exp_for_level(level: int) -> int:
	return 10 * (level - 1) * level


## Adds EXP and handles level ups. Returns the message lines to show.
func gain_exp(m: Dictionary, amount: int) -> Array:
	var lines := []
	m["exp"] = int(m["exp"]) + amount
	while int(m["exp"]) >= exp_for_level(int(m["level"]) + 1):
		m["level"] = int(m["level"]) + 1
		lines.append("• %s's level went up to %d!" % [m["name"], m["level"]])
		var gains := {
			"max_hp": randi_range(6, 10), "offense": randi_range(1, 3),
			"defense": randi_range(1, 2), "speed": randi_range(1, 2),
		}
		if int(m["max_pp"]) > 0:
			gains["max_pp"] = randi_range(3, 6)
		for stat in gains:
			m[stat] = int(m[stat]) + int(gains[stat])
			lines.append("• %s went up by %d!" % [STAT_NAMES[stat], gains[stat]])
		m["hp"] = mini(int(m["hp"]) + int(gains["max_hp"]), int(m["max_hp"]))
	return lines


# --- Controls ----------------------------------------------------------------
# Defined in code so the whole input map is visible in one place. You can also
# do this in Project Settings -> Input Map.

func _setup_input() -> void:
	_bind("move_up", [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP])
	_bind("move_down", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN])
	_bind("move_left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT])
	_bind("move_right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT])
	_bind("confirm", [KEY_Z, KEY_ENTER, KEY_SPACE], [JOY_BUTTON_A])
	_bind("cancel", [KEY_X, KEY_ESCAPE, KEY_BACKSPACE], [JOY_BUTTON_B])
	_bind("menu", [KEY_C, KEY_TAB], [JOY_BUTTON_Y, JOY_BUTTON_START])
	_bind("run", [KEY_SHIFT], [JOY_BUTTON_X])


func _bind(action: StringName, keys: Array, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	for button in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = button
		InputMap.action_add_event(action, jb)
