## The field menu (press C): Goods, PSI and Status, like Mother 3's pause screen.
## A row of commands at the top and the party's cards along the bottom.
extends Control

signal _ack

const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ChoiceList = preload("res://scripts/ui/choice_list.gd")
const DB = preload("res://scripts/data/db.gd")

var dialogue  # the overworld's dialogue box, for messages

var _top: ChoiceList
var _list_box: Panel
var _list: ChoiceList
var _info_box: Panel
var _info: Label
var _who_box: Panel
var _who_label: Label
var _who: ChoiceList
var _status_box: Panel
var _status_left: Label
var _status_right: Label
var _cards: Array = []
var _waiting_ack := false
var _ack_frame := -1


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	size = Vector2(320, 240)

	var top_box := UIKit.make_box(self, Rect2(8, 8, 304, 26))
	_top = ChoiceList.new()
	_top.horizontal = true
	_top.cell = Vector2(74, 16)
	_top.position = Vector2(4, 5)
	top_box.add_child(_top)
	_top.set_items(["Goods", "PSI", "Status", "Close"])

	_list_box = UIKit.make_box(self, Rect2(8, 38, 160, 118))
	_list = ChoiceList.new()
	_list.cell = Vector2(150, 14)
	_list.position = Vector2(4, 3)
	_list_box.add_child(_list)

	_info_box = UIKit.make_box(self, Rect2(172, 38, 140, 60))
	_info = UIKit.make_label(_info_box, "", Vector2(6, 4), Vector2(128, 52))

	_status_box = UIKit.make_box(self, Rect2(8, 38, 304, 118))
	_status_left = UIKit.make_label(_status_box, "", Vector2(10, 6), Vector2(140, 106))
	_status_right = UIKit.make_label(_status_box, "", Vector2(156, 6), Vector2(140, 106))

	_who_box = UIKit.make_box(self, Rect2(8, 160, 304, 24))
	_who_label = UIKit.make_label(_who_box, "", Vector2(8, 4))
	_who = ChoiceList.new()
	_who.horizontal = true
	_who.cell = Vector2(80, 16)
	_who.position = Vector2(110, 4)
	_who_box.add_child(_who)

	for i in Game.party.size():
		var card := UIKit.make_box(self, Rect2(8 + i * 102, 188, 98, 46))
		_cards.append(UIKit.make_label(card, "", Vector2(7, 3)))
	_hide_panels()


## Opens the menu and returns when the player closes it.
func run() -> void:
	visible = true
	_hide_panels()
	_refresh()
	while true:
		var pick: int = await _top.choose()
		if pick == 0:
			await _goods()
		elif pick == 1:
			await _psi()
		elif pick == 2:
			await _status()
		else:
			break
		_hide_panels()
		_refresh()
	visible = false


func _hide_panels() -> void:
	_list_box.visible = false
	_info_box.visible = false
	_who_box.visible = false
	_status_box.visible = false


func _refresh() -> void:
	for i in _cards.size():
		var m: Dictionary = Game.party[i]
		var text := "%s   Lv %d\nHP  %d / %d" % [m["name"], m["level"], m["hp"], m["max_hp"]]
		if int(m["max_pp"]) > 0:
			text += "\nPP  %d / %d" % [m["pp"], m["max_pp"]]
		_cards[i].text = text


func _goods() -> void:
	if Game.inventory.is_empty():
		await dialogue.say(["• You don't have any Goods."])
		return
	var names := []
	for id in Game.inventory:
		names.append(DB.ITEMS[id]["name"])
	_list.set_items(names)
	var slot: int = await _pick_from_list(func(i: int) -> void:
		_info.text = DB.ITEMS[Game.inventory[i]]["desc"])
	if slot < 0:
		return
	var who: int = await _pick_member("Use it on who?")
	if who < 0:
		return
	var id: String = Game.inventory[slot]
	Game.inventory.remove_at(slot)
	var m: Dictionary = Game.party[who]
	var lines: Array = Game.use_item(id, m, m)
	Sfx.play("heal")
	_refresh()
	await dialogue.say(lines)


func _psi() -> void:
	var who: int = await _pick_member("Whose PSI?")
	if who < 0:
		return
	var caster: Dictionary = Game.party[who]
	var ids: Array = caster["psi"]
	if ids.is_empty():
		await dialogue.say(["• %s can't use PSI." % caster["name"]])
		return
	var names := []
	var enabled := []
	var costs := []
	for id in ids:
		var p: Dictionary = DB.PSI[id]
		names.append(p["name"])
		costs.append(str(p["pp"]))
		# Only healing PSI works outside of battle.
		enabled.append(p["kind"] == "heal" and int(caster["pp"]) >= int(p["pp"]))
	_list.set_items(names, enabled, costs)
	var pick: int = await _pick_from_list(func(i: int) -> void:
		var p: Dictionary = DB.PSI[ids[i]]
		_info.text = "%s\nPP cost: %d" % [p["desc"], p["pp"]]
		if p["kind"] != "heal":
			_info.text += "\n(Battle only)")
	if pick < 0:
		return
	var psi: Dictionary = DB.PSI[ids[pick]]
	var target: int = await _pick_member("On who?")
	if target < 0:
		return
	caster["pp"] = int(caster["pp"]) - int(psi["pp"])
	var lines := ["• %s tried %s!" % [caster["name"], psi["name"]]]
	lines.append_array(Game.heal(Game.party[target], psi["power"], 0))
	Sfx.play("psi")
	_refresh()
	await dialogue.say(lines)


func _status() -> void:
	var who: int = await _pick_member("Whose status?")
	if who < 0:
		return
	var m: Dictionary = Game.party[who]
	var psi_names := []
	for id in m["psi"]:
		psi_names.append(DB.PSI[id]["name"])
	var to_next := Game.exp_for_level(int(m["level"]) + 1) - int(m["exp"])
	_status_left.text = "%s\nLevel %d\n\nHP  %d / %d\nPP  %d / %d\n\nEXP  %d\nNext level  %d" % [
		m["name"], m["level"], m["hp"], m["max_hp"], m["pp"], m["max_pp"], m["exp"], to_next]
	_status_right.text = "Offense  %d\nDefense  %d\nSpeed  %d\n\nPSI:\n%s" % [
		m["offense"], m["defense"], m["speed"],
		"\n".join(psi_names) if not psi_names.is_empty() else "(none)"]
	_status_box.visible = true
	await _wait_for_button()
	_status_box.visible = false


func _pick_from_list(describe: Callable) -> int:
	_list_box.visible = true
	_info_box.visible = true
	_list.moved.connect(describe)
	var picked: int = await _list.choose(0)
	_list.moved.disconnect(describe)
	return picked


func _pick_member(prompt: String) -> int:
	_who_box.visible = true
	_who_label.text = prompt
	var names := []
	for m in Game.party:
		names.append(m["name"])
	_who.set_items(names)
	var picked: int = await _who.choose(0)
	_who_box.visible = false
	return picked


func _wait_for_button() -> void:
	_waiting_ack = true
	_ack_frame = Engine.get_process_frames()
	await _ack


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting_ack or Engine.get_process_frames() == _ack_frame:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_waiting_ack = false
		_ack.emit()
