# Mother-Like RPG Guide: Learning Godot by Building Your Game

A hands-on reference for this project. Every section shows where things live in the
real code and how to change them. Sections marked **Project** are bigger changes that
add a new feature step by step. They're good practice once you're comfortable.

Other docs in this folder:

- `README.md`: controls and a map of which file does what
- `BATTLE_BACKGROUNDS.md`: how the battle background shader works
- `CHANGING_ART.md` and `art/README.md`: using your own art

## Contents

1. [Running, testing and finding mistakes](#1-running-testing-and-finding-mistakes)
2. [GDScript basics, using this project](#2-gdscript-basics-using-this-project)
3. [Editing the map](#3-editing-the-map)
4. [NPCs and dialogue](#4-npcs-and-dialogue)
5. [Story flags: making the world remember](#5-story-flags-making-the-world-remember)
6. [Adding enemies](#6-adding-enemies)
7. [Items (Goods)](#7-items-goods)
8. [PSI](#8-psi)
9. [The party, stats and leveling up](#9-the-party-stats-and-leveling-up)
10. [Tuning battles](#10-tuning-battles)
11. [The battle background](#11-the-battle-background)
12. [Sound effects](#12-sound-effects)
13. [Music](#13-music)
14. [Your own art](#14-your-own-art)
15. [Saving to disk](#15-saving-to-disk)
16. [Ideas for bigger projects](#16-ideas-for-bigger-projects)
17. [When something goes wrong](#17-when-something-goes-wrong)
18. [Where to learn more](#18-where-to-learn-more)

---

## 1. Running, testing and finding mistakes

Start Godot:

```bash
~/Documents/Godot_v4.7.2-stable_linux.x86_64
```

Open **mother_like_rpg** from the project list.

| Key | What it does |
|---|---|
| **F5** | Runs the whole game, starting on the overworld |
| **F6** | Runs only the scene you have open. Open `scenes/battle.tscn` and press F6 to jump straight into a fight |
| **F8** | Stops the game |
| **Ctrl+S** | Saves the script you're editing |

At the bottom of the editor:

- **Output** shows messages, including anything you `print()`.
- **Debugger → Errors** lists problems, with the file and line. Click one to jump
  there.

While the game runs, the **Remote** tab at the top of the Scene panel shows every
node that exists right now. Click one to see its values live in the Inspector.

### `print()` is your best friend

Put this anywhere in a script to see what's going on:

```gdscript
print("HP is now ", m["hp"])
```

It shows in the Output panel. When something doesn't behave the way you expect,
print the values involved.

### Breakpoints

Click in the gutter to the left of a line number (or press **F9** on the line) to add
a red dot. When the game reaches that line it pauses. You can then look at every
variable in the Debugger panel and step through line by line with **F10**.

---

## 2. GDScript basics, using this project

### Nodes and scenes

Everything in Godot is a **node**: a player, a label, a sound player, a camera.
Nodes are arranged in a tree, where children belong to their parent and move with
it.

In most Godot projects you build the tree in the editor. This project builds it **in
code** instead, so you can read everything in one place. Each `.tscn` file is just
one node with a script, and that script creates the rest in `_ready()`.

From `overworld.gd`:

```gdscript
var cam := Camera2D.new()      # make a node
cam.position = Vector2(0, -8)  # set its properties
player.add_child(cam)          # put it in the tree, as a child of the player
```

### Special functions Godot calls for you

| Function | When Godot calls it | Used here for |
|---|---|---|
| `_ready()` | Once, when the node enters the tree | Building the map, the UI, the battle |
| `_process(delta)` | Every frame. `delta` is the seconds since the last frame | Rolling HP, animations, timers |
| `_physics_process(delta)` | At a fixed rate, for movement and collisions | Player and enemy movement |
| `_draw()` | When the node needs drawing (ask with `queue_redraw()`) | All the placeholder art |
| `_unhandled_input(event)` | When a key or button is pressed | Battle rhythm presses |

### Variables and types

```gdscript
var hp := 60               # := means "work out the type for me" (here, int)
var name: String = "Kit"   # or name the type yourself
const TILE := 16           # const never changes
```

### Dictionaries and Arrays

Most game data here is stored in **Dictionaries**, lists of `"key": value` pairs, and
**Arrays**, ordered lists:

```gdscript
var kit := {"name": "Kit", "hp": 60}
print(kit["hp"])           # 60
kit["hp"] -= 10            # change a value

var goods := ["nut_cookie", "pop_jelly"]
goods.append("bread_roll") # add to the end
print(goods.size())        # 3
```

`db.gd` is one big set of Dictionaries: every item, PSI, enemy and encounter.

### Signals

A **signal** is a node announcing "this happened." Other code **connects** to it to
react. From `overworld.gd`:

```gdscript
player.interacted.connect(_on_interact)  # when the player presses Z, run _on_interact
```

`player.gd` declares `signal interacted(target)` and fires it with
`interacted.emit(...)`.

### `await`

`await` pauses a function until something finishes, then carries on from the same
spot. That's how menus and dialogue work here:

```gdscript
await dialogue.say(["• Hello!"])                    # waits until the player finishes reading
var answer: int = await dialogue.say(["• Save?"], ["Yes", "No"])
```

The whole battle (`_run_battle()` in `battle.gd`) is written this way, so it reads
top to bottom like a script of what happens.

### Autoloads: data that survives scene changes

When the game switches scene (overworld → battle), the old scene is thrown away. Data
that must survive lives in **autoloads**. These are scripts Godot loads once and keeps
forever, listed in **Project → Project Settings → Globals → Autoload**:

- **`Game`** (`scripts/autoload/game.gd`) holds the party, Goods, flags, defeated
  enemies and the save. Use it from any script: `Game.party`, `Game.flags`,
  `Game.add_item("nut_cookie")`.
- **`Sfx`** (`scripts/autoload/sfx.gd`) plays sounds: `Sfx.play("confirm")`.

### Indentation uses tabs

GDScript uses indentation to know what belongs to what, like Python. This project
uses **tabs**. If you paste code indented with spaces, Godot complains about mixed
indentation. In the script editor, **Edit → Indentation → Convert Indent to Tabs**
fixes it.

---

## 3. Editing the map

The overworld is the `MAP` text at the top of `scripts/overworld/overworld.gd`. Each
character is one 16×16 tile:

| Character | Tile | Solid? |
|---|---|---|
| `#` | Tree | yes |
| `~` | Water | yes |
| `r` | Roof | yes |
| `H` | House wall | yes |
| `d` | Door | yes |
| `.` | Grass | |
| `,` | Dirt path | |
| `f` | Flowers | |
| `P` | Where the player starts | |
| `1` `2` `3` `4` `F` `G` | NPCs and objects (see `NPCS` and `scripts/dialogue/`) | |
| `m` `e` `c` `s` `X` | Field enemies (see `ENEMY_TILES`) | |

Rules:

- **Every row must be the same length.**
- Keep a border of trees (`#`) around the edge so the player can't walk off the map.
- The map can be any size, and the camera adjusts its limits to fit.

### **Project:** a new tile type

For example, a stone floor `:` that you can walk on:

1. In `_draw_tile()` in `overworld.gd`, add a case to the `match`:

   ```gdscript
   ":":
   	draw_rect(r, Color(0.6, 0.6, 0.65))
   	draw_rect(Rect2(r.position, Vector2(TILE, 1)), Color(0.45, 0.45, 0.5))
   ```

2. Put `:` on the map.
3. To make it solid instead, add it to `SOLID_TILES`: `const SOLID_TILES := "#~rHd:"`.
4. To give it a "check" message, add a case to the `match` in `_on_interact()`:

   ```gdscript
   ":":
   	await dialogue.say(["• The stones are cold."])
   ```

---

## 4. NPCs and dialogue

NPCs live in the `NPCS` table in `scripts/overworld/overworld.gd`, around line 53. Each
key (`"1"`, `"2"`...) is the character that places them on the map, and `"talk"` points
to that NPC's conversation script:

```gdscript
"3": {"kind": "person", "sprite": "elder", "colors": {...},
	"talk": preload("res://scripts/dialogue/elder.gd")},
```

Every conversation has its own file in `scripts/dialogue/`:

| Map key | Who | Script |
|---|---|---|
| `"1"` | Welcome sign | `welcome_sign.gd` |
| `"2"` | Healer (heals the party) | `healer.gd` |
| `"3"` | Elder | `elder.gd` |
| `"4"` | Villager | `villager.gd` |
| `"F"` | Save frog | `save_frog.gd` |
| `"G"` | Present box (shared by every box) | `present_box.gd` |

### Changing what they say

Open the NPC's script. It's one `talk()` function:

```gdscript
static func talk(world, _npc) -> void:
	await world.dialogue.say([
		"• Those critters out in the field have gotten awfully rowdy.",
		"• Here's a secret: after you Bash, press Z in time with the battle music.",
		"• Hit the beat and you'll keep swinging. Up to 16 hits, if you've got the groove!"])
```

Each string in the list is one page of the dialogue box.

- Edit the text inside the quotes.
- Add or remove pages. **Every page except the last needs a comma after it.**
- For quotation marks inside a line, write `\"` (the sign does this).
- The `•` bullet is the Mother style. Keep it or drop it.
- The box fits about three short lines, so split long speeches across pages.

`talk()` gets two things: `world` is the overworld (use `world.dialogue` for the box and
`world.player` for the player), and `npc` is the person or thing you're talking to
(`npc.npc_key`, `npc.item`, `npc.opened`...). Name it `_npc` when you don't use it.

### Adding an NPC

**1.** Copy a script in `scripts/dialogue/`, say `elder.gd` to `farmer.gd`, and change
its lines.

**2.** Copy an entry in `NPCS`, give it a new key that isn't used on the map yet, point
`"talk"` at the new script, and place that character on the map:

```gdscript
"5": {"kind": "person", "sprite": "farmer",
	"colors": {"hair": Color(0.9, 0.8, 0.3), "shirt": Color(0.3, 0.6, 0.3), "pants": Color(0.4, 0.3, 0.2)},
	"talk": preload("res://scripts/dialogue/farmer.gd")},
```

| Field | Meaning |
|---|---|
| `"kind"` | How they're drawn: `"person"`, `"healer"`, `"sign"`, `"frog"`, `"gift"` |
| `"talk"` | Their conversation script in `scripts/dialogue/` |
| `"colors"` | Placeholder art colors: `skin`, `hair`, `shirt`, `stripe`, `pants` |
| `"sprite"` | Name of their art sheet, `art/characters/<sprite>.png` (optional) |
| `"item"` | For gifts: the item id inside |

Two NPCs can share one script. Every present box uses `present_box.gd`, and a second
healer could use `healer.gd`.

### Dialogue that isn't an NPC

**Checking doors, water and trees** is in the `match _tile_at(ahead):` in
`_on_interact()` in `overworld.gd`.

### Asking a question

`dialogue.say()` takes an optional list of answers and returns the number of the one
picked, starting from 0 (`save_frog.gd` does this):

```gdscript
var answer: int = await world.dialogue.say(["• Want a cookie?"], ["Yes", "No"])
if answer == 0:
	await world.dialogue.say(["• Here you go!"])
else:
	await world.dialogue.say(["• Suit yourself."])
```

Pressing X (cancel) picks the last answer, so put "No" last.

### **Project:** an NPC with special behavior

Since each NPC has its own script, special behavior just goes in their `talk()`. This
baker (`scripts/dialogue/baker.gd`) gives you bread once:

```gdscript
## The baker (map key "5"). Gives you a Bread Roll once.
extends RefCounted


static func talk(world, _npc) -> void:
	if Game.flags.has("got_bread"):
		await world.dialogue.say(["• Fresh bread tomorrow, come back!"])
		return
	await world.dialogue.say(["• You look hungry. Take this!"])
	if Game.add_item("bread_roll"):
		Game.flags["got_bread"] = true
		Sfx.play("save")
		await world.dialogue.say(["• %s got a Bread Roll!" % Game.party[0]["name"]])
	else:
		await world.dialogue.say(["• Oh, your bag is full."])
```

`Game.add_item()` returns `false` when Goods are full (8 items), so this checks
before setting the flag. Flags are explained in the next section.

---

## 5. Story flags: making the world remember

`Game.flags` is a Dictionary for remembering that something happened. It's saved by
the save frog and survives scene changes.

```gdscript
Game.flags["met_elder"] = true          # remember something
if Game.flags.has("met_elder"):         # check it
	...
Game.flags["cookies_given"] = 3         # flags can hold numbers too
var n: int = Game.flags.get("cookies_given", 0)   # 0 if it was never set
```

Present boxes already use this: opening box `G` sets `Game.flags["gift_G"]`, and the
overworld checks it so the box stays open.

### **Project:** villagers react to beating the boss

**1.** Set a flag when the boss battle is won. In `_win()` in
`scripts/battle/battle.gd`, next to the line that marks the enemy defeated:

```gdscript
Game.defeated[Game.pending_enemy_id] = true
if Game.pending_encounter == "boss":
	Game.flags["boss_beaten"] = true
```

**2.** Check it when talking. In `scripts/dialogue/elder.gd`:

```gdscript
static func talk(world, _npc) -> void:
	if Game.flags.has("boss_beaten"):
		await world.dialogue.say(["• You beat that Clank Beetle? The field is safe again!"])
		return
	await world.dialogue.say([
		"• Those critters out in the field have gotten awfully rowdy.",
		...])
```

The same idea works for anything: open a path, unlock a shop, or change a whole
village's lines after a story event.

---

## 6. Adding enemies

Three tables work together:

1. **`ENEMIES`** in `scripts/data/db.gd`: a single enemy's stats.
2. **`ENCOUNTERS`** in `db.gd`: which enemies appear together in one fight.
3. **`ENEMY_TILES`** in `overworld.gd`: which map character spawns which encounter.

### Step 1: the enemy

Copy an entry in `ENEMIES` and change it. Keep every field, because the battle reads
all of them.

```gdscript
"slime": {
	"name": "Sour Slime", "shape": "slime", "color": Color(0.6, 0.9, 0.3), "scale": 1.0,
	"hp": 45, "offense": 10, "defense": 4, "speed": 5, "exp": 12,
	"drop": "pop_jelly", "drop_rate": 0.35,
	"attacks": ["%s splashed acid!", "%s wobbled into you!"],
	"idle": ["%s is jiggling."],
	"bpm": 112, "bg": [Color(0.1, 0.05, 0.2), Color(0.5, 1.0, 0.4)],
},
```

| Field | Meaning |
|---|---|
| `"name"` | Shown in battle messages |
| `"shape"` | Which drawn shape to use (`mole`, `crow`, `shrub`, `beetle`). An unknown shape draws a plain circle, which is fine if you'll use a PNG |
| `"color"`, `"scale"` | Color and size of the drawn shape |
| `"hp"`, `"offense"`, `"defense"`, `"speed"` | Stats. Higher speed acts earlier in a turn |
| `"exp"` | EXP each party member gets |
| `"drop"`, `"drop_rate"` | Item id it may leave behind, and the chance (0.0–1.0) |
| `"attacks"`, `"idle"` | Battle messages. `%s` is replaced with the enemy's name |
| `"bpm"` | Tempo of the battle beat, which is the rhythm for combos |
| `"bg"` | Battle background colors: backdrop, then wire glow |
| `"no_run": true` | Optional: you can't run from this fight (the boss uses it) |

### Step 2: the encounter

In `ENCOUNTERS`:

```gdscript
"slime": ["slime"],
"slimes": ["slime", "slime", "slime"],
```

The **first** enemy in the list decides the music tempo, the background and how the
enemy looks walking around on the field.

### Step 3: put it on the map

In `ENEMY_TILES` in `overworld.gd`, pick an unused character and point it at an
**encounter** (not an enemy):

```gdscript
const ENEMY_TILES := {"m": "mole", "e": "moles", "c": "crow", "s": "shrub", "X": "boss", "j": "slimes"}
```

Then put `j` on the map. Don't reuse a character that's already a tile, NPC or enemy.

### Its look

Save a PNG as `art/enemies/slime.png`, named after the key in `ENEMIES`, and it's used
automatically. Optionally add a smaller `art/enemies/slime_field.png` for the
overworld. See `art/README.md`.

Each field enemy is defeated for good once beaten. Its position is stored in
`Game.defeated`. Starting a new game brings them all back.

---

## 7. Items (Goods)

Items are in `ITEMS` in `scripts/data/db.gd`:

```gdscript
"mango": {
	"name": "Mango", "verb": "ate",
	"desc": "Sweet and juicy.\nRecovers 40 HP and 5 PP.", "hp": 40, "pp": 5,
},
```

- `"verb"` makes the message: "Kit **ate** the Mango." Use `"drank"` for drinks.
- `"desc"` shows in menus. `\n` starts a new line.
- `"hp"` and `"pp"` are how much it restores.

Ways to give the player an item:

| Where | How |
|---|---|
| At the start | Add the id to `inventory` in `new_game()` in `game.gd` |
| From an enemy | Set `"drop"` and `"drop_rate"` in the enemy |
| In a present box | Add an NPC entry like `"B": {"kind": "gift", "item": "mango"}` and place `B` on the map. Each box needs its own key so it remembers being opened |
| From code | `Game.add_item("mango")` (returns `false` if Goods are full) |

The Goods limit is `MAX_GOODS` in `game.gd` (8).

---

## 8. PSI

PSI moves are in `PSI` in `db.gd`:

```gdscript
"thunder_a": {
	"name": "PK Thunder α", "pp": 5, "kind": "attack", "target": "enemy",
	"power": 32, "desc": "Zaps one enemy.", "color": Color(1.0, 1.0, 0.4, 0.55),
},
```

| Field | Meaning |
|---|---|
| `"pp"` | PP cost |
| `"kind"` | `"attack"` or `"heal"` |
| `"target"` | `"enemy"`, `"all_enemies"` or `"ally"` |
| `"power"` | Damage or healing amount (with a little randomness) |
| `"color"` | Color of the screen flash. The last number is transparency |

To give it to someone, add its id to their `"psi"` list in `new_game()` in `game.gd`:

```gdscript
"psi": ["fire_a", "freeze_a", "lifeup_a", "thunder_a"],
```

### **Project:** learn PSI by leveling up

In `gain_exp()` in `game.gd`, inside the `while` loop after the stat gains, add:

```gdscript
if m["name"] == "Wren" and m["level"] == 3 and not m["psi"].has("thunder_a"):
	m["psi"].append("thunder_a")
	lines.append("• Wren learned PK Thunder α!")
```

---

## 9. The party, stats and leveling up

The party is set up in `new_game()` in `scripts/autoload/game.gd`. Each member is a
Dictionary:

```gdscript
{
	"name": "Kit", "level": 1, "exp": 0,
	"hp": 60, "max_hp": 60, "pp": 0, "max_pp": 0,
	"offense": 12, "defense": 6, "speed": 6, "psi": [],
},
```

To rename the characters, change `"name"`. Kit has `max_pp` 0, which means no PSI.

**EXP needed per level** is `exp_for_level()`: `10 * (level - 1) * level`, which gives
20, 60, 120, 200... Change the formula to make leveling faster or slower.

**Stat gains** are the `gains` Dictionary in `gain_exp()`, for example
`"max_hp": randi_range(6, 10)` for a random 6 to 10. Change the ranges to change how
strong characters grow.

---

## 10. Tuning battles

Most battle numbers are near the top of `scripts/battle/battle.gd` or in short
functions:

| What | Where | Now |
|---|---|---|
| Damage formula | `_damage()` | `(offense × 2 − defense) × random 0.8–1.2` |
| Rhythm timing window | `COMBO_WINDOW` | 0.14 seconds either side of the beat |
| Max combo hits | `MAX_COMBO` | 16 |
| SMAAAASH chance | `_do_bash()` and `_do_enemy()` | about 6% and 5% |
| Running away | `_try_run()` | 55%, +35% if you struck first, +10% per turn |
| HP roll speed | `ROLL_SPEED` in `party_card.gd` | 12 HP per second. Lower is more forgiving |
| Text speed | `CHARS_PER_SECOND` in `dialogue_box.gd` | 40 |

Change one number at a time, then test with F6 on `battle.tscn`. That way you know
which change did what.

---

## 11. The battle background

The background is a shader: a small program that colors every pixel, every frame.
Right now it's glowing cyberpunk wires with EarthBound-style scanline warping.

- Each enemy's `"bg"` colors (backdrop, then wire glow) are in `db.gd`, and its
  `"bpm"` sets how fast it moves.
- The shader is `shaders/battle_bg.gdshader`.
- **`BATTLE_BACKGROUNDS.md` explains it line by line**, with things to try.

You can edit the shader while the game runs: open `battle.tscn`, press F6, then
change numbers in the shader file and watch them update.

---

## 12. Sound effects

All sounds are made from math at startup in `scripts/autoload/sfx.gd`, with no audio
files. Play one from anywhere:

```gdscript
Sfx.play("confirm")
Sfx.play("note", 1.5)   # the second number changes pitch
```

Available: `move`, `confirm`, `cancel`, `buzz`, `text`, `hit`, `smash`, `hurt`,
`miss`, `note`, `psi`, `defeat`, `run`, `kick`, `hat`, `bass`, `heal`, `level`, `win`,
`save`, `encounter`, `gameover`.

### Make a new synthesized sound

Add a line in `_ready()` in `sfx.gd`:

```gdscript
_sounds["door"] = _make([200, 150], 0.1, 0.25, 0.0, "square")
```

The arguments to `_make()`:

1. **A list of notes**, as frequencies in Hz, played one after another (440 is the
   A above middle C).
2. **Each note's length** in seconds.
3. **Volume**, from 0.0 to 1.0.
4. **Slide:** bends the pitch up (positive) or down (negative) in Hz per second.
5. **Wave shape:** `"square"` (buzzy, classic chiptune), `"triangle"` (softer),
   `"sine"` (pure) or `"noise"` (hiss, for hits).

Try changing the existing sounds' numbers to hear what each argument does.

### Use a real sound file

Make a `sounds/` folder in the project and drop in a `.wav` or `.ogg`. Godot imports
it automatically. Then in `sfx.gd`:

```gdscript
_sounds["door"] = load("res://sounds/door.wav")
```

Replace an existing entry the same way, for example `_sounds["confirm"] = load(...)`,
to change a sound everywhere it's used.

Free sounds: OpenGameArt.org, freesound.org (check each license), or make your own
with **jsfxr** (sfxr.me).

---

## 13. Music

There's no music file yet. The battle "music" is a drum and bass loop played by
`scripts/battle/beat_clock.gd`, which also keeps track of the beat for rhythm combos.

### **Project:** overworld music

At the end of `_ready()` in `overworld.gd`:

```gdscript
var music := AudioStreamPlayer.new()
var song = load("res://music/town.ogg")  # works for .ogg and .mp3
song.loop = true
music.stream = song
music.volume_db = -6.0   # a bit quieter. Every -6 roughly halves the volume
add_child(music)
music.play()
```

The music stops automatically when the scene changes to a battle, because the player
node is thrown away with the scene.

### **Project:** real battle music that combos follow

In Mother 3, each enemy's song **is** the rhythm, and you can do the same.

**1.** Let the beat clock stay silent. In `beat_clock.gd`, add a variable and wrap the
two `Sfx.play` lines:

```gdscript
var synth := true  # false when a real song is playing
```

```gdscript
if synth:
	Sfx.play("kick" if b % 2 == 0 else "hat")
	Sfx.play("bass", BASS_LINE[b % BASS_LINE.size()])
```

**2.** Give an enemy a song. Add a field in `db.gd`, and set `"bpm"` to **the song's
real tempo**:

```gdscript
"music": "res://music/mole_battle.ogg", "bpm": 120,
```

**3.** Play it. In `_ready()` in `battle.gd`, after `add_child(_clock)`:

```gdscript
if lead.has("music"):
	var player := AudioStreamPlayer.new()
	var song = load(lead["music"])
	song.loop = true
	player.stream = song
	add_child(player)
	player.play()
	_clock.synth = false
```

The beat clock starts at the same moment as the song, so the beats line up when the
song starts right on a beat with no silent intro. Trim any silence at the start of
the file with Audacity.

Free music: OpenGameArt.org and itch.io have lots of chiptune. Check each license.

---

## 14. Your own art

Save PNGs with the right names in the `art/` folder and the game uses them. Anything
you haven't drawn yet keeps its placeholder, so you can add art one piece at a time.

| What | File | Size |
|---|---|---|
| Kit, Wren, villagers | `art/characters/<name>.png` | 4×4 sheet of walking frames, e.g. 16×24 each = 64×96 |
| Battle enemies | `art/enemies/<enemy id>.png` | About 64–100 tall |
| Field enemies (optional) | `art/enemies/<enemy id>_field.png` | Small, about 16–24 tall |
| Save frog, sign, present box | `art/objects/frog.png`, `sign.png`, `gift.png`, `gift_open.png` | About 16×16 |

- **Sheet rows:** facing down, left, right, up. Columns are walk frames, and the
  first column is the standing pose.
- Images are placed with their **bottom-center at the character's feet**.
- Use transparent backgrounds. The game keeps pixel art sharp.

`art/README.md` has the full list, and `CHANGING_ART.md` explains how the code draws
your images.

**Map tiles** (grass, trees, water...) are still drawn in code, in `_draw_tile()`.
Using PNGs for them, or switching to Godot's **TileMapLayer** so you can paint maps in
the editor, makes a good next project.

---

## 15. Saving to disk

Right now the save frog saves **in memory only**: it lasts until you close the game.
`Game.save_game()` stores a snapshot in `_save`, and `Game.load_save()` restores it.

### **Project:** keep saves after quitting

**1.** Write the save to a file. At the end of `save_game()` in `game.gd`:

```gdscript
var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
file.store_var(_save)
```

**2.** Add the path near the top of `game.gd`:

```gdscript
const SAVE_PATH := "user://save.dat"
```

**3.** Load it when the game starts. In `_ready()` in `game.gd`, after `new_game()`:

```gdscript
if FileAccess.file_exists(SAVE_PATH):
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	_save = file.get_var()
	load_save()
```

`user://` is a private folder Godot gives your game. On Linux it's
`~/.local/share/godot/app_userdata/Mother-Like RPG/`. To start fresh while testing,
delete `save.dat` there.

---

## 16. Ideas for bigger projects

In rough order of difficulty:

1. **A shop:** an NPC kind `"shop"`. Add `"price"` to items, keep money in
   `Game.flags["money"]`, and show a `ChoiceList` of items to buy.
2. **Learning PSI at levels** for every character (see section 8).
3. **A status effect:** e.g. sleep. Store `"asleep": true` on an enemy and skip its
   turn in `_do_enemy()` until it wakes.
4. **A third party member:** add them to `Game.party`. Battle cards are made for every
   member automatically. On the overworld, a second follower must walk further back
   along the player's `trail`.
5. **More maps (inside houses, a second town):** move `MAP` and `NPCS` into a
   Dictionary of maps, keep `Game.current_map`, and make door tiles switch the map
   and reload the scene.
6. **Moving scenes into the editor:** make a `Player.tscn` with `Sprite2D` and
   `CollisionShape2D` nodes, or paint the map with a `TileMapLayer`. This is how most
   Godot games are built, and it's worth learning.

---

## 17. When something goes wrong

When there's an error, the game pauses, the editor jumps to the line, and the
**Debugger** panel explains it. Common ones:

| Error says | Usually means |
|---|---|
| `Invalid access to property or key 'xxx' on a base object of type 'Dictionary'` | A typo in a key name (`"hp"` vs `"HP"`), or a new enemy/item is missing a field the code reads. Compare with an entry that works |
| `Identifier "xxx" not declared in the current scope` | A typo in a variable or function name, or a variable used outside the function it was made in |
| `Mixed use of tabs and spaces for indentation` | Pasted code uses spaces. Use **Edit → Indentation → Convert Indent to Tabs** |
| `Expected closing "}" after dictionary elements` / `Expected closing "]" after array elements` | A missing comma or bracket in a table in `db.gd` or `NPCS`. Check the line before the one shown |
| `Invalid call. Nonexistent function 'xxx'` | Calling a function that doesn't exist on that object (often a typo) |
| `Cannot call method 'xxx' on a null ...` | Using a node that was never created or was already removed |

Other problems:

- **A row of the map looks shifted or broken:** that row has a different length from
  the others.
- **An NPC doesn't appear:** its key isn't on the map, or the map character doesn't
  match the key exactly (they're case-sensitive).
- **An enemy doesn't appear:** its letter isn't in `ENEMY_TILES`, the encounter name
  is misspelled, or you already beat it this game.
- **A sound or music file won't load:** check the path starts with `res://` and
  matches the file name exactly, including capitals.

When stuck, add `print()` lines around the problem and watch the Output panel.

---

## 18. Where to learn more

- **Godot docs, "Getting Started" → "Your first 2D game":** the official tutorial,
  which teaches the editor-based way of building scenes.
- **Godot docs, "GDScript reference":** every keyword and type explained.
- **In the editor:** hold Ctrl and click any built-in name (like `Camera2D` or
  `create_tween`) to open its documentation, or press **F1** to search.
- **GDQuest** (gdquest.com) and **KidsCanCode**: friendly Godot tutorials.
- **The Book of Shaders** (thebookofshaders.com): for the battle backgrounds.
