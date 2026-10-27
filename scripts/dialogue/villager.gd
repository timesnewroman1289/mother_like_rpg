## The villager in the south (map key "4"). Explains the rolling HP meter.
extends RefCounted


static func talk(world, _npc) -> void:
	await world.dialogue.say([
		"• Did you know your HP rolls down slowly, like an odometer?",
		"• Even if you take mortal damage, you can still heal before it hits zero!",
		"• Winning the fight stops the meter, too."])
