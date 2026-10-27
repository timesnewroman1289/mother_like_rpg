## Everyone you can talk to or check on the overworld, keyed by their MAP
## character in overworld.gd. "kind" picks how they're drawn (see npc.gd).
##
## Each NPC's "talk" entry is its conversation script in scripts/dialogue/.
const NPCS := {
	"1": {"kind": "sign", "talk": preload("res://scripts/dialogue/welcome_sign.gd")},
	"2": {"kind": "healer", "sprite": "healer", "colors": {"hair": Color(0.55, 0.3, 0.15), "shirt": Color(0.9, 0.55, 0.65), "pants": Color(0.6, 0.35, 0.45)},
		"talk": preload("res://scripts/dialogue/healer.gd")},
	"3": {"kind": "person", "sprite": "elder", "colors": {"hair": Color(0.85, 0.85, 0.85), "shirt": Color(0.45, 0.4, 0.3), "pants": Color(0.3, 0.3, 0.3)},
		"talk": preload("res://scripts/dialogue/elder.gd")},
	"4": {"kind": "person", "sprite": "villager", "colors": {"hair": Color(0.2, 0.15, 0.1), "shirt": Color(0.95, 0.8, 0.2), "pants": Color(0.2, 0.4, 0.7)},
		"talk": preload("res://scripts/dialogue/villager.gd")},
	"F": {"kind": "frog", "talk": preload("res://scripts/dialogue/save_frog.gd")},
	"G": {"kind": "gift", "item": "bread_roll", "talk": preload("res://scripts/dialogue/present_box.gd")},
}
