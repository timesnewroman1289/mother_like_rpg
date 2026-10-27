## The elder in the middle of the village (map key "3"). Explains rhythm combos.
extends RefCounted


static func talk(world, _npc) -> void:
	await world.dialogue.say([
		"• Those critters out in the field have gotten awfully rowdy.",
		"• Here's a secret: after you Bash, press Z in time with the battle music.",
		"• Hit the beat and you'll keep swinging. Up to 16 hits, if you've got the groove!"])
