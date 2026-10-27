## Game data: Goods (items), PSI, enemies and encounters.
##
## Everything is a plain Dictionary so it's easy to read and tweak here.
## When your game grows, consider turning these into custom Resource classes
## (.tres files) so you can edit them in the Inspector instead.
extends RefCounted

const ITEMS := {
	"nut_cookie": {
		"name": "Nut Cookie", "verb": "ate",
		"desc": "A crunchy cookie.\nRecovers 30 HP.", "hp": 30, "pp": 0,
	},
	"bread_roll": {
		"name": "Bread Roll", "verb": "ate",
		"desc": "Freshly baked.\nRecovers 70 HP.", "hp": 70, "pp": 0,
	},
	"pop_jelly": {
		"name": "Pop Jelly", "verb": "ate",
		"desc": "Fizzy and sweet.\nRecovers 15 PP.", "hp": 0, "pp": 15,
	},
}

## kind: "attack" or "heal".  target: "enemy", "all_enemies" or "ally".
const PSI := {
	"fire_a": {
		"name": "PK Fire α", "pp": 6, "kind": "attack", "target": "all_enemies",
		"power": 24, "desc": "Burns every enemy.", "color": Color(1.0, 0.45, 0.1, 0.55),
	},
	"freeze_a": {
		"name": "PK Freeze α", "pp": 4, "kind": "attack", "target": "enemy",
		"power": 38, "desc": "Freezes one enemy.", "color": Color(0.5, 0.8, 1.0, 0.55),
	},
	"lifeup_a": {
		"name": "Lifeup α", "pp": 5, "kind": "heal", "target": "ally",
		"power": 45, "desc": "Heals one ally.", "color": Color(0.5, 1.0, 0.6, 0.55),
	},
}

## Each enemy picks its own battle tempo (bpm). That's the beat you tap to
## for rhythm combos, just like each Mother 3 enemy has its own battle song.
## "bg" is the pair of colors for the battle background shader: backdrop, then wire glow.
const ENEMIES := {
	"mole": {
		"name": "Grumble Mole", "shape": "mole", "color": Color(0.58, 0.4, 0.26), "scale": 1.0,
		"hp": 38, "offense": 9, "defense": 3, "speed": 4, "exp": 9,
		"drop": "nut_cookie", "drop_rate": 0.4,
		"attacks": ["%s scratched wildly!", "%s tackled!"],
		"idle": ["%s is grumbling quietly.", "%s dug a little hole."],
		"bpm": 104, "bg": [Color(0.35, 0.16, 0.05), Color(0.9, 0.62, 0.22)],
	},
	"crow": {
		"name": "Tin Crow", "shape": "crow", "color": Color(0.32, 0.34, 0.45), "scale": 1.0,
		"hp": 30, "offense": 11, "defense": 2, "speed": 12, "exp": 11,
		"drop": "pop_jelly", "drop_rate": 0.3,
		"attacks": ["%s pecked furiously!", "%s dive-bombed!"],
		"idle": ["%s is polishing its tin feathers."],
		"bpm": 128, "bg": [Color(0.05, 0.1, 0.38), Color(0.35, 0.85, 0.9)],
	},
	"shrub": {
		"name": "Angry Shrub", "shape": "shrub", "color": Color(0.3, 0.68, 0.3), "scale": 1.0,
		"hp": 52, "offense": 8, "defense": 6, "speed": 2, "exp": 14,
		"drop": "bread_roll", "drop_rate": 0.25,
		"attacks": ["%s lashed out with its branches!", "%s threw a pinecone!"],
		"idle": ["%s is rustling menacingly."],
		"bpm": 92, "bg": [Color(0.04, 0.28, 0.1), Color(0.75, 0.92, 0.3)],
	},
	"beetle": {
		"name": "Clank Beetle", "shape": "beetle", "color": Color(0.62, 0.66, 0.78), "scale": 1.35,
		"hp": 170, "offense": 15, "defense": 8, "speed": 6, "exp": 60,
		"drop": "bread_roll", "drop_rate": 1.0,
		"attacks": ["%s rammed with its horn!", "%s fired a rusty bolt!"],
		"idle": ["%s is recalibrating...", "%s's gears ground loudly."],
		"bpm": 120, "bg": [Color(0.3, 0.0, 0.25), Color(0.95, 0.3, 0.45)],
		"no_run": true,
	},
}

## A field enemy starts one of these. The first enemy listed decides the
## music tempo, the background, and what the enemy looks like on the field.
const ENCOUNTERS := {
	"mole": ["mole"],
	"moles": ["mole", "mole"],
	"crow": ["crow", "mole"],
	"shrub": ["shrub"],
	"boss": ["beetle"],
}
