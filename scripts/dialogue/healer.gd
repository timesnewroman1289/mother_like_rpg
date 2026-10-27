## The healer by the west house (map key "2"). Restores the whole party.
extends RefCounted


static func talk(world, _npc) -> void:
	await world.dialogue.say([
		"• Oh, you look worn out, sweetie.",
		"• Come here, let me fix you up."])
	Game.heal_all()
	Sfx.play("heal")
	await world.dialogue.say(["• Everyone's HP and PP were fully restored!"])
