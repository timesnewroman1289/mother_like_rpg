## Present boxes (map key "G"). Shared by every box: the item inside comes from
## the "item" entry in NPCS, and opening one sets Game.flags["gift_<key>"].
extends RefCounted

const DB = preload("res://scripts/data/db.gd")


static func talk(world, npc) -> void:
	if npc.opened:
		await world.dialogue.say(["• The present box is empty."])
	elif not Game.add_item(npc.item):
		await world.dialogue.say(["• Your Goods are full. You can't carry any more."])
	else:
		npc.opened = true
		npc.queue_redraw()
		Game.flags["gift_" + npc.npc_key] = true
		Sfx.play("save")
		await world.dialogue.say([
			"• %s opened the present box." % Game.party[0]["name"],
			"• Inside was a %s!" % DB.ITEMS[npc.item]["name"]])
