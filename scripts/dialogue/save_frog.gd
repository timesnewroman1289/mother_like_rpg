## The save frog (map key "F"). Asks whether to save, then saves.
extends RefCounted


static func talk(world, _npc) -> void:
	var answer: int = await world.dialogue.say([
		"• Ribbit! I'm the save frog.",
		"• Shall I write down your adventure so far?"], ["Yes", "No"])
	if answer == 0:
		Game.save_game(world.player.global_position, world.player.facing)
		Sfx.play("save")
		await world.dialogue.say([
			"• Ribbit! Your adventure has been saved.",
			"• If your party is ever wiped out, you'll continue from here."])
	else:
		await world.dialogue.say(["• Ribbit. Come back anytime."])
