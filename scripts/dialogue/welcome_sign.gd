## The welcome sign at the top of Sunfield Village (map key "1").
extends RefCounted


static func talk(world, _npc) -> void:
	await world.dialogue.say([
		"• \"Welcome to Sunfield Village.\"",
		"• \"Z: talk / check     C: menu     Hold Shift: run\""])
