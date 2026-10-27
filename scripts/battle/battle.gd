## The battle scene: Mother 3 style turn-based combat.
##
## Each turn: pick a command for every party member, then everyone (party and
## enemies) acts in speed order. Repeat until one side is out.
##
## The Mother 3 ideas shown here:
##   * Rolling HP meters (party_card.gd). Damage drains slowly, so you can heal
##     or win before a mortal blow finishes rolling down.
##   * Rhythm combos. After a Bash lands, press Z on the beat for up to 16 hits.
##   * Each enemy has its own tempo and neon wire background (battle_bg.gdshader).
##   * Command menu along the top, party cards along the bottom.
##
## The battle flow is written as one long coroutine (_run_battle) using
## "await", so it reads like a script of what happens, in order.
extends Node2D

const DB = preload("res://scripts/data/db.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ChoiceList = preload("res://scripts/ui/choice_list.gd")
const PartyCard = preload("res://scripts/battle/party_card.gd")
const EnemySprite = preload("res://scripts/battle/enemy_sprite.gd")
const BeatClock = preload("res://scripts/battle/beat_clock.gd")
const BG_SHADER = preload("res://shaders/battle_bg.gdshader")

const SCREEN := Vector2(320, 240)
const COMMANDS := ["Bash", "PSI", "Goods", "Guard", "Run"]
const COMBO_WINDOW := 0.14  # seconds either side of the beat that count as "on time"
const MAX_COMBO := 16
const COMBO_PITCHES := [1.0, 1.122, 1.26, 1.498, 1.682, 2.0, 2.245, 2.52, 2.997, 3.364, 4.0, 3.364, 2.997, 2.52, 2.245, 2.0]

## Party side: {"data": member dict from Game.party, "card": PartyCard, "guarding": bool, "ko": bool}
var fighters: Array = []
## Enemy side: {"def": dict from DB.ENEMIES, "name": String, "hp": int, "alive": bool, "sprite": EnemySprite}
var enemies: Array = []

var _clock: BeatClock
var _bg: ColorRect
var _bg_pulse := 0.0
var _cmd_box: Panel
var _cmd_list: ChoiceList
var _msg_box: Panel
var _line_a: Label
var _line_b: Label
var _sub_box: Panel
var _sub_list: ChoiceList
var _info_box: Panel
var _info: Label
var _target_box: Panel
var _target_list: ChoiceList
var _fx_layer: Node2D
var _flash: ColorRect
var _fade: ColorRect
var _beat_icon: Control
var _beat_glow := 0.0

var _waiting_msg := false
var _skip_msg := false
var _combo_wait := false
var _combo_beat := 0
var _combo_result := 0
var _choosing := false
var _ended := false
var _turn := 0
var _exp_pool := 0
var _drops: Array = []
var _ko_queue: Array = []


func _ready() -> void:
	var ids: Array = DB.ENCOUNTERS.get(Game.pending_encounter, ["mole"])
	var lead: Dictionary = DB.ENEMIES[ids[0]]
	_build_background(lead)
	_spawn_enemies(ids)
	_spawn_party()
	_build_ui()
	_clock = BeatClock.new()
	_clock.bpm = lead["bpm"]
	_clock.beat.connect(_on_beat)
	add_child(_clock)
	_run_battle()


# --- The main battle loop ----------------------------------------------------

func _run_battle() -> void:
	create_tween().tween_property(_fade, "color:a", 0.0, 0.35)
	await say(_intro_text(), 0.9)
	if Game.advantage == "player_first":
		await say("• You caught them off guard!")
	elif Game.advantage == "enemy_first":
		await say("• You were attacked from behind!")

	while true:
		for f in fighters:
			f["guarding"] = false
		var actions: Array = []
		var party_acts := not (_turn == 0 and Game.advantage == "enemy_first")
		var enemies_act := not (_turn == 0 and Game.advantage == "player_first")

		if party_acts:
			var picked: Dictionary = await _collect_commands()
			if _ended:
				return
			if picked["run"]:
				if await _try_run():
					return
			else:
				actions = picked["actions"]
		if enemies_act:
			for e in _alive_enemies():
				actions.append({"type": "enemy", "enemy": e, "speed": float(e["def"]["speed"]) + randf() * 4.0})

		# Fastest goes first (with a little randomness).
		actions.sort_custom(func(a, b): return a["speed"] > b["speed"])
		for a in actions:
			if not _can_act(a):
				_undo(a)
				continue
			await _perform(a)
			await _flush_ko()
			if _alive_enemies().is_empty():
				await _win()
				return
			if _all_ko():
				await _lose()
				return
		await _flush_ko()
		if _all_ko():
			await _lose()
			return
		_turn += 1


func _intro_text() -> String:
	var lead: String = enemies[0]["def"]["name"]
	if enemies.size() == 1:
		return "• You encountered %s!" % lead
	return "• %s and its cohorts attacked!" % lead


func _process(delta: float) -> void:
	_beat_glow = maxf(0.0, _beat_glow - delta * 4.0)
	_bg_pulse = maxf(0.0, _bg_pulse - delta * 3.0)
	(_bg.material as ShaderMaterial).set_shader_parameter("pulse", _bg_pulse)
	_beat_icon.queue_redraw()
	# HP keeps rolling while you're picking commands. If everyone drops while
	# you dawdle in the menu, that's game over.
	if _choosing and not _ended and _all_ko():
		_choosing = false
		_lose()


func _on_beat(_index: int) -> void:
	_beat_glow = 1.0
	_bg_pulse = 0.6
	for e in _alive_enemies():
		e["sprite"].pulse()


func _on_collapsed(i: int) -> void:
	var f: Dictionary = fighters[i]
	f["ko"] = true
	f["guarding"] = false
	Sfx.play("defeat")
	_ko_queue.append("• %s got hurt and collapsed..." % f["data"]["name"])


func _flush_ko() -> void:
	while not _ko_queue.is_empty():
		await say(_ko_queue.pop_front())


# --- Choosing commands -------------------------------------------------------

## Returns {"run": bool, "actions": Array}.
func _collect_commands() -> Dictionary:
	_choosing = true
	var chosen := {}  # fighter index -> action
	var k := 0
	while k < fighters.size():
		var f: Dictionary = fighters[k]
		if f["ko"]:
			k += 1
			continue
		var d: Dictionary = f["data"]
		_set_active_card(k)
		_clear_msgs()
		_msg_box.visible = false
		_cmd_box.visible = true
		var can_psi := not (d["psi"] as Array).is_empty()
		_cmd_list.set_items(COMMANDS, [true, can_psi, not Game.inventory.is_empty(), true, true])
		var cmd: int = await _cmd_list.choose(0)
		var act := {}

		if cmd == -1:
			# Cancel steps back to the previous member's choice.
			var prev := _previous_fighter(k)
			if prev >= 0:
				_undo(chosen.get(prev, {}))
				chosen.erase(prev)
				k = prev
			continue
		elif cmd == 0:
			var target: int = await _pick_enemy()
			if target >= 0:
				act = {"type": "bash", "target": target}
		elif cmd == 1:
			act = await _pick_psi(d)
		elif cmd == 2:
			act = await _pick_goods()
		elif cmd == 3:
			act = {"type": "guard"}
			f["guarding"] = true  # guarding works from the start of the turn
		elif cmd == 4:
			_end_choosing()
			return {"run": true, "actions": []}

		if act.is_empty():
			continue  # backed out of a sub-menu: choose again
		act["fighter"] = f
		act["speed"] = 999.0 if act["type"] == "guard" else float(d["speed"]) + randf() * 4.0
		chosen[k] = act
		k += 1
	_end_choosing()
	return {"run": false, "actions": chosen.values()}


func _end_choosing() -> void:
	_set_active_card(-1)
	_cmd_box.visible = false
	_choosing = false


func _previous_fighter(k: int) -> int:
	for j in range(k - 1, -1, -1):
		if not fighters[j]["ko"]:
			return j
	return -1


## Gives back whatever a cancelled (or skipped) action had set aside.
func _undo(act: Dictionary) -> void:
	if act.get("type") == "item":
		Game.inventory.append(act["item"])
	elif act.get("type") == "guard":
		act["fighter"]["guarding"] = false


func _pick_enemy() -> int:
	var alive: Array = []
	for i in enemies.size():
		if enemies[i]["hp"] > 0:
			alive.append(i)
	if alive.size() == 1:
		return alive[0]
	var names: Array = alive.map(func(i): return enemies[i]["name"])
	var r: int = await _pick_target(names, func(j: int) -> void:
		for i in enemies.size():
			enemies[i]["sprite"].targeted = (i == alive[j]))
	for e in enemies:
		e["sprite"].targeted = false
	return -1 if r < 0 else alive[r]


func _pick_ally() -> int:
	var names: Array = fighters.map(func(f): return f["data"]["name"])
	var r: int = await _pick_target(names, func(j: int) -> void:
		for i in fighters.size():
			fighters[i]["card"].targeted = (i == j))
	for f in fighters:
		f["card"].targeted = false
	return r


func _pick_target(names: Array, on_move: Callable) -> int:
	_target_box.visible = true
	_target_list.set_items(names)
	_target_list.moved.connect(on_move)
	var r: int = await _target_list.choose(0)
	_target_list.moved.disconnect(on_move)
	_target_box.visible = false
	return r


func _pick_from_sub_list(names: Array, enabled: Array, details: Array, describe: Callable) -> int:
	_sub_box.visible = true
	_info_box.visible = true
	_sub_list.set_items(names, enabled, details)
	_sub_list.moved.connect(describe)
	var r: int = await _sub_list.choose(0)
	_sub_list.moved.disconnect(describe)
	_sub_box.visible = false
	_info_box.visible = false
	return r


func _pick_psi(d: Dictionary) -> Dictionary:
	var ids: Array = d["psi"]
	var names := []
	var enabled := []
	var costs := []
	for id in ids:
		var p: Dictionary = DB.PSI[id]
		names.append(p["name"])
		costs.append(str(p["pp"]))
		enabled.append(int(d["pp"]) >= int(p["pp"]))
	var i: int = await _pick_from_sub_list(names, enabled, costs, func(j: int) -> void:
		_info.text = "%s\nPP cost: %d" % [DB.PSI[ids[j]]["desc"], DB.PSI[ids[j]]["pp"]])
	if i < 0:
		return {}
	var psi: Dictionary = DB.PSI[ids[i]]
	var target := 0
	if psi["target"] == "enemy":
		target = await _pick_enemy()
	elif psi["target"] == "ally":
		target = await _pick_ally()
	if target < 0:
		return {}
	return {"type": "psi", "psi": ids[i], "target": target}


func _pick_goods() -> Dictionary:
	var names: Array = Game.inventory.map(func(id): return DB.ITEMS[id]["name"])
	var slot: int = await _pick_from_sub_list(names, [], [], func(j: int) -> void:
		_info.text = DB.ITEMS[Game.inventory[j]]["desc"])
	if slot < 0:
		return {}
	var target: int = await _pick_ally()
	if target < 0:
		return {}
	var id: String = Game.inventory[slot]
	Game.inventory.remove_at(slot)  # set aside now, so two people can't use the same cookie
	return {"type": "item", "item": id, "target": target}


# --- Doing things ------------------------------------------------------------

func _can_act(a: Dictionary) -> bool:
	if a["type"] == "enemy":
		return a["enemy"]["hp"] > 0
	return not a["fighter"]["ko"]


func _perform(a: Dictionary) -> void:
	_clear_msgs()
	if a["type"] == "enemy":
		await _do_enemy(a["enemy"])
		return
	_set_active_card(fighters.find(a["fighter"]))
	match a["type"]:
		"bash":
			await _do_bash(a["fighter"], a["target"])
		"psi":
			await _do_psi(a["fighter"], a["psi"], a["target"])
		"item":
			await _do_item(a["fighter"], a["item"], a["target"])
		"guard":
			await say("• %s is on guard." % a["fighter"]["data"]["name"])
	_set_active_card(-1)


func _do_bash(f: Dictionary, target_index: int) -> void:
	var d: Dictionary = f["data"]
	var e := _retarget(target_index)
	if e.is_empty():
		return
	await say("• %s attacks!" % d["name"], 0.35)
	if randf() < 0.06:
		Sfx.play("miss")
		await say("• Just missed!")
		return
	var base := _damage(int(d["offense"]), int(e["def"]["defense"]))
	var dmg := base
	if randf() < 0.06:
		dmg = int(int(d["offense"]) * 4 * randf_range(0.9, 1.1))
		Sfx.play("smash")
		_flash_screen(Color(1, 1, 1, 0.8))
		await say("• SMAAAASH!!", 0.3)
	else:
		Sfx.play("hit")
	_hit_enemy(e, dmg)

	var combo: Dictionary = await _rhythm_combo(e, base)
	var hits: int = combo["hits"]
	if hits > 1:
		_popup("%d HITS!" % hits, e["sprite"].position + Vector2(0, -78), UIKit.HILITE)
	await say("• %d HP of damage to %s!" % [dmg + int(combo["total"]), e["name"]])
	if e["hp"] <= 0:
		await _enemy_defeated(e)


## After the first hit, each press of Z close enough to the next beat lands
## another (weaker) hit. Pressing off-beat, or not at all, ends the combo.
func _rhythm_combo(e: Dictionary, base: int) -> Dictionary:
	var hits := 1
	var total := 0
	# Aim for the first beat that's at least a quarter second away.
	var beat_index := _clock.nearest_beat() + 1
	while _clock.offset_to(beat_index) > -0.25:
		beat_index += 1
	while hits < MAX_COMBO and int(e["hp"]) > 0:
		_combo_beat = beat_index
		_combo_result = 0
		_combo_wait = true
		while _combo_result == 0:
			if _clock.offset_to(beat_index) > COMBO_WINDOW:
				_combo_result = -1  # the beat went by without a press
			else:
				await get_tree().process_frame
		_combo_wait = false
		if _combo_result < 0:
			break
		var dmg := maxi(1, int(base * randf_range(0.3, 0.45)))
		Sfx.play("note", COMBO_PITCHES[(hits - 1) % COMBO_PITCHES.size()])
		hits += 1
		total += dmg
		_hit_enemy(e, dmg)
		beat_index += 1
	return {"hits": hits, "total": total}


func _do_psi(f: Dictionary, psi_id: String, target: int) -> void:
	var d: Dictionary = f["data"]
	var psi: Dictionary = DB.PSI[psi_id]
	if int(d["pp"]) < int(psi["pp"]):
		await say("• %s doesn't have enough PP!" % d["name"])
		return
	d["pp"] = int(d["pp"]) - int(psi["pp"])
	await say("• %s tried %s!" % [d["name"], psi["name"]], 0.4)
	Sfx.play("psi")
	_flash_screen(psi["color"])

	if psi["kind"] == "attack":
		var targets: Array = []
		if psi["target"] == "all_enemies":
			targets = _alive_enemies()
		else:
			var one := _retarget(target)
			if not one.is_empty():
				targets.append(one)
		for e in targets:
			var dmg := int(int(psi["power"]) * randf_range(0.85, 1.15))
			_hit_enemy(e, dmg)
			await say("• %d HP of damage to %s!" % [dmg, e["name"]], 0.5)
		for e in targets:
			if e["hp"] <= 0:
				await _enemy_defeated(e)
	else:
		var ally: Dictionary = fighters[target]
		if ally["ko"]:
			await say("• But it had no effect...")
			return
		Sfx.play("heal")
		for line in Game.heal(ally["data"], psi["power"], 0):
			await say(line)


func _do_item(f: Dictionary, item_id: String, target: int) -> void:
	var ally: Dictionary = fighters[target]
	if ally["ko"]:
		Game.inventory.append(item_id)
		await say("• %s is in no shape to eat anything..." % ally["data"]["name"])
		return
	Sfx.play("heal")
	for line in Game.use_item(item_id, f["data"], ally["data"]):
		await say(line)


func _do_enemy(e: Dictionary) -> void:
	var def: Dictionary = e["def"]
	if randf() < 0.12:
		var idle: String = (def["idle"] as Array).pick_random()
		await say("• " + idle % e["name"])
		return
	var targets: Array = fighters.filter(func(f): return not f["ko"])
	if targets.is_empty():
		return
	var f: Dictionary = targets.pick_random()
	var d: Dictionary = f["data"]
	var attack: String = (def["attacks"] as Array).pick_random()
	e["sprite"].lunge()
	await say("• " + attack % e["name"], 0.35)
	if randf() < 0.07:
		Sfx.play("miss")
		await say("• %s dodged quickly!" % d["name"])
		return

	var dmg := _damage(int(def["offense"]), int(d["defense"]))
	if randf() < 0.05:
		dmg *= 2
		Sfx.play("smash")
		await say("• SMAAAASH!!", 0.3)
	if f["guarding"]:
		dmg = maxi(1, int(dmg * 0.5))
	d["hp"] = maxi(0, int(d["hp"]) - dmg)
	f["card"].shake()
	Sfx.play("hurt")
	_flash_screen(Color(1, 0, 0, 0.3))
	await say("• %s took %d HP of damage!" % [d["name"], dmg])
	if int(d["hp"]) == 0:
		await say("• %s took mortal damage!" % d["name"])


func _damage(offense: int, defense: int) -> int:
	return maxi(1, int((offense * 2 - defense) * randf_range(0.8, 1.2)))


## The chosen enemy, or the first one still standing if it already fell.
func _retarget(index: int) -> Dictionary:
	if index >= 0 and index < enemies.size() and enemies[index]["hp"] > 0:
		return enemies[index]
	var alive := _alive_enemies()
	return alive[0] if not alive.is_empty() else {}


func _hit_enemy(e: Dictionary, dmg: int) -> void:
	e["hp"] = maxi(0, int(e["hp"]) - dmg)
	e["sprite"].hurt()
	_popup(str(dmg), e["sprite"].position + Vector2(randf_range(-12, 12), -50), Color.WHITE)


func _enemy_defeated(e: Dictionary) -> void:
	if not e["alive"]:
		return
	e["alive"] = false
	e["sprite"].die()
	Sfx.play("defeat")
	var def: Dictionary = e["def"]
	_exp_pool += int(def["exp"])
	if randf() < float(def["drop_rate"]):
		_drops.append({"from": e["name"], "item": def["drop"]})
	await say("• %s was defeated!" % e["name"])


func _alive_enemies() -> Array:
	return enemies.filter(func(e): return e["hp"] > 0)


func _all_ko() -> bool:
	for f in fighters:
		if not f["ko"]:
			return false
	return true


# --- Ending the battle -------------------------------------------------------

func _win() -> void:
	_ended = true
	_freeze_party()
	_clock.playing = false
	Sfx.play("win")
	await say("• YOU WON!", 1.2)
	var awake: Array = fighters.filter(func(f): return not f["ko"])
	await say("• Everyone gained %d EXP." % _exp_pool, 0.6)
	for f in awake:
		for line in Game.gain_exp(f["data"], _exp_pool):
			Sfx.play("level")
			await say(line, 0.6)
	for drop in _drops:
		if Game.add_item(drop["item"]):
			await say("• %s left behind a %s." % [drop["from"], DB.ITEMS[drop["item"]]["name"]])
	Game.defeated[Game.pending_enemy_id] = true
	await _wake_ko()
	await _leave("res://scenes/overworld.tscn")


func _try_run() -> bool:
	_clear_msgs()
	for e in _alive_enemies():
		if e["def"].get("no_run", false):
			await say("• You can't run away from this fight!")
			return false
	await say("• You tried to run away...", 0.4)
	var chance := 0.55 + (0.35 if Game.advantage == "player_first" else 0.0) + 0.1 * _turn
	if randf() >= chance:
		await say("• ...but couldn't get away!")
		return false
	_ended = true
	_freeze_party()
	Sfx.play("run")
	await say("• ...and got away safely!")
	Game.grace_time = 2.5
	await _wake_ko()
	await _leave("res://scenes/overworld.tscn")
	return true


func _lose() -> void:
	if _ended:
		return
	_ended = true
	for list in [_cmd_list, _sub_list, _target_list]:
		list.cancel_choice()
	for box in [_cmd_box, _sub_box, _info_box, _target_box]:
		box.visible = false
	_clock.playing = false
	await _flush_ko()
	Sfx.play("gameover")
	await say("• The party was wiped out...", 1.5)
	await _leave("res://scenes/game_over.tscn")


func _freeze_party() -> void:
	for f in fighters:
		f["card"].freeze()


## In this sample, collapsed members get back up with 1 HP after a battle.
func _wake_ko() -> void:
	for f in fighters:
		if f["ko"]:
			f["data"]["hp"] = 1
			await say("• %s came to, barely." % f["data"]["name"])


func _leave(scene_path: String) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.4)
	await t.finished
	get_tree().change_scene_to_file(scene_path)


# --- Messages ----------------------------------------------------------------

## Shows a line in the message box (keeping the previous line above it),
## types it out, then waits a moment. Z skips ahead.
func say(text: String, hold := 0.7) -> void:
	_cmd_box.visible = false
	_msg_box.visible = true
	_line_a.text = _line_b.text
	_line_b.text = text
	_line_b.visible_characters = 0
	_skip_msg = false
	_waiting_msg = true
	var shown := 0.0
	while shown < text.length() and not _skip_msg:
		await get_tree().process_frame
		shown += get_process_delta_time() * 60.0
		_line_b.visible_characters = int(shown)
	_line_b.visible_characters = -1
	_skip_msg = false
	var waited := 0.0
	while waited < hold and not _skip_msg:
		await get_tree().process_frame
		waited += get_process_delta_time()
	_skip_msg = false
	_waiting_msg = false


func _clear_msgs() -> void:
	_line_a.text = ""
	_line_b.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("confirm"):
		return
	if _combo_wait:
		get_viewport().set_input_as_handled()
		var off := _clock.offset_to(_combo_beat)
		_combo_result = 1 if absf(off) <= COMBO_WINDOW else -1  # too early also breaks the combo
	elif _waiting_msg:
		get_viewport().set_input_as_handled()
		_skip_msg = true


# --- Building the screen -----------------------------------------------------

func _build_background(lead: Dictionary) -> void:
	_bg = ColorRect.new()
	_bg.size = SCREEN
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = BG_SHADER
	var colors: Array = lead["bg"]
	mat.set_shader_parameter("color_a", colors[0])
	mat.set_shader_parameter("color_b", colors[1])
	mat.set_shader_parameter("speed", float(lead["bpm"]) / 110.0)
	_bg.material = mat
	add_child(_bg)


func _spawn_enemies(ids: Array) -> void:
	var layer := Node2D.new()
	add_child(layer)
	var counts := {}
	for id in ids:
		counts[id] = counts.get(id, 0) + 1
	var seen := {}
	var spacing := 100.0
	var start_x := SCREEN.x * 0.5 - spacing * (ids.size() - 1) * 0.5
	for i in ids.size():
		var id: String = ids[i]
		var def: Dictionary = DB.ENEMIES[id]
		var display_name: String = def["name"]
		if counts[id] > 1:  # two of the same? call them "Grumble Mole A" and "B"
			seen[id] = seen.get(id, 0) + 1
			display_name += " " + "ABCD"[seen[id] - 1]
		var sprite := EnemySprite.new()
		sprite.enemy_id = id
		sprite.shape = def["shape"]
		sprite.color = def["color"]
		sprite.art_scale = def["scale"]
		sprite.position = Vector2(start_x + spacing * i, 145)
		layer.add_child(sprite)
		enemies.append({"def": def, "name": display_name, "hp": int(def["hp"]), "alive": true, "sprite": sprite})


func _spawn_party() -> void:
	var w := PartyCard.CARD_SIZE.x + 4.0
	var start_x := SCREEN.x * 0.5 - w * Game.party.size() * 0.5
	for i in Game.party.size():
		var card := PartyCard.new()
		card.member = Game.party[i]
		card.position = Vector2(start_x + w * i + 2.0, 186)
		add_child(card)
		card.collapsed.connect(_on_collapsed.bind(i))
		fighters.append({"data": Game.party[i], "card": card, "guarding": false, "ko": false})


func _build_ui() -> void:
	_cmd_box = UIKit.make_box(self, Rect2(4, 4, 312, 26))
	_cmd_list = ChoiceList.new()
	_cmd_list.horizontal = true
	_cmd_list.cell = Vector2(61, 18)
	_cmd_list.position = Vector2(3, 4)
	_cmd_box.add_child(_cmd_list)
	_cmd_list.set_items(COMMANDS)
	_cmd_box.visible = false

	_msg_box = UIKit.make_box(self, Rect2(4, 4, 312, 36))
	_line_a = UIKit.make_label(_msg_box, "", Vector2(8, 3))
	_line_b = UIKit.make_label(_msg_box, "", Vector2(8, 18))
	for line in [_line_a, _line_b]:
		line.clip_text = true
		line.size = Vector2(296, 14)
	_msg_box.visible = false

	_sub_box = UIKit.make_box(self, Rect2(4, 34, 184, 120))
	_sub_list = ChoiceList.new()
	_sub_list.cell = Vector2(174, 14)
	_sub_list.position = Vector2(4, 4)
	_sub_box.add_child(_sub_list)
	_sub_box.visible = false

	_info_box = UIKit.make_box(self, Rect2(192, 34, 124, 60))
	_info = UIKit.make_label(_info_box, "", Vector2(6, 4), Vector2(112, 52))
	_info_box.visible = false

	_target_box = UIKit.make_box(self, Rect2(4, 34, 312, 26))
	_target_list = ChoiceList.new()
	_target_list.horizontal = true
	_target_list.cell = Vector2(100, 16)
	_target_list.position = Vector2(4, 5)
	_target_box.add_child(_target_list)
	_target_box.visible = false

	# A little note that pulses on the beat, to help you find the rhythm.
	_beat_icon = Control.new()
	_beat_icon.position = Vector2(294, 160)
	_beat_icon.size = Vector2(20, 20)
	_beat_icon.draw.connect(_draw_beat_icon)
	add_child(_beat_icon)

	_fx_layer = Node2D.new()
	add_child(_fx_layer)

	_flash = ColorRect.new()
	_flash.size = SCREEN
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_fade = ColorRect.new()
	_fade.size = SCREEN
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _draw_beat_icon() -> void:
	var c: Color = UIKit.HILITE.lerp(Color.WHITE, _beat_glow)
	c.a = 0.45 + 0.55 * _beat_glow
	var r := 4.0 + 1.5 * _beat_glow
	_beat_icon.draw_circle(Vector2(7, 15), r, c)
	_beat_icon.draw_rect(Rect2(7 + r - 1.5, 3, 1.5, 12), c)
	_beat_icon.draw_rect(Rect2(7 + r - 1.5, 3, 6, 2), c)


func _set_active_card(i: int) -> void:
	for j in fighters.size():
		fighters[j]["card"].raised = (j == i)


func _flash_screen(color: Color) -> void:
	_flash.color = color
	create_tween().tween_property(_flash, "color:a", 0.0, 0.35)


func _popup(text: String, pos: Vector2, color: Color) -> void:
	var l := UIKit.make_label(_fx_layer, text, pos - Vector2(12, 0))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	var t := l.create_tween()
	t.tween_property(l, "position:y", pos.y - 18.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.45)
	t.tween_callback(l.queue_free)
