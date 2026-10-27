# Mother-Like RPG (Godot 4 learning project)

A small, complete, Mother 3 style RPG skeleton to learn from and build on.

**New to Godot? Start with [GUIDE.md](GUIDE.md)**: step-by-step how-tos for dialogue, enemies,
items, PSI, music, sounds, saving, and fixing errors.
There are no image or sound files: all art is drawn in code and all sounds are synthesized,
so every piece can be read and changed in the scripts.

## Running it

1. Install Godot 4.3 or newer (tested on 4.7.2). On Fedora:
   `flatpak install flathub org.godotengine.Godot`
2. Open Godot → **Import** → choose this folder's `project.godot`.
3. Press **F5** to play. To test a scene on its own, open it and press **F6**
   (for example `scenes/battle.tscn` starts a fight against a Grumble Mole).

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | Arrows / WASD | D-pad |
| Talk, check, confirm | Z / Enter / Space | A |
| Back, cancel | X / Esc | B |
| Field menu | C / Tab | Y / Start |
| Run | hold Shift | X |

## What's in it (and where to look)

| Mother 3 feature | Where |
|---|---|
| Overworld built from a text map, Y-sorted characters, camera follow | `scripts/overworld/overworld.gd` |
| Party member following you in a line | `scripts/overworld/follower.gd` (walks the player's `trail`) |
| Visible enemies that chase you, no random encounters | `scripts/overworld/field_enemy.gd` |
| First strike from behind / getting ambushed | `_on_enemy_touched()` in `overworld.gd` |
| "• Bullet" dialogue box with typewriter text and Yes/No questions | `scripts/ui/dialogue_box.gd` |
| "Check" anything ("• No problem here.") | `_on_interact()` in `overworld.gd` |
| NPC conversations: save frog, present boxes, healer, villagers | one script each in `scripts/dialogue/` |
| Field menu: Goods / PSI / Status | `scripts/ui/field_menu.gd` |
| Battle command bar (Bash, PSI, Goods, Guard, Run) at the top | `scripts/battle/battle.gd` |
| **Rolling HP odometer**: heal before it hits 0 and you survive | `scripts/battle/party_card.gd` |
| **Rhythm combos**: press Z on the beat after a Bash, up to 16 hits | `_rhythm_combo()` in `battle.gd` and `beat_clock.gd` |
| Swirly psychedelic battle background | `shaders/battle_bg.gdshader` |
| SMAAAASH!!, mortal damage, level ups, item drops | `battle.gd` and `Game.gain_exp()` |
| Game over → continue from last save | `scripts/game_over.gd` and `Game.load_save()` |
| All items, PSI, enemies and encounters | `scripts/data/db.gd` |

### How the pieces talk to each other

- **Autoloads** (Project Settings → Autoload) are global nodes that survive scene changes:
  - `Game` (`scripts/autoload/game.gd`) holds the party, Goods, flags, defeated enemies and the save.
  - `Sfx` (`scripts/autoload/sfx.gd`) plays sounds: `Sfx.play("confirm")`.
- **Overworld → battle:** touching an enemy calls `Game.start_battle(...)` (this records the encounter
  and where you were standing) and then switches to `battle.tscn`. The battle reads
  `Game.pending_encounter`, and when it ends it switches back. The overworld puts you at
  `Game.return_position` and skips any enemy whose id is in `Game.defeated`.
- **Menus use `await`.** `ChoiceList` (`scripts/ui/choice_list.gd`) is the one reusable menu.
  `var i: int = await list.choose()` waits until the player picks something (or returns -1 on cancel).
  That's why the whole battle reads top to bottom in `_run_battle()` instead of being spread across callbacks.
- **Scenes are built in code.** Each `.tscn` file is just a root node with a script, and the script
  creates its children in `_ready()`. That keeps everything readable in one place. As you
  get comfortable, try moving pieces into real scenes in the editor (e.g. make a
  `Player.tscn` with a `Sprite2D` and a `CollisionShape2D`).

## Things to try next

1. **Add an enemy:** add an entry to `ENEMIES` and `ENCOUNTERS` in `db.gd`, then add a letter
   for it to `ENEMY_TILES` in `overworld.gd` and place that letter on the map.
2. **Add an NPC:** write its conversation in a new script in `scripts/dialogue/`, put a new character
   (say `5`) on the map and add `"5": {...}` to `NPCS` with `"talk"` pointing at the script.
3. **Edit the map:** change the `MAP` strings. Every row must be the same width.
4. **Real art:** drop PNGs into `art/` (names and layout in `art/README.md`, more in
   `CHANGING_ART.md`). Later, try `AnimatedSprite2D` nodes and a `TileMapLayer` map painted in the editor.
5. **Real music:** play an `.ogg` with an `AudioStreamPlayer` and set the `BeatClock`'s `bpm` to match,
   so combos follow the song (that's exactly how Mother 3 works).
6. **Save to disk:** in `Game.save_game()`, write `_save` with
   `FileAccess.open("user://save.dat", FileAccess.WRITE).store_var(_save)` and read it back with `get_var()`.
7. **More Mother 3:** status effects (sleep makes enemies' heartbeats show the rhythm), the dash
   charge, learning new PSI at certain levels, multiple-member enemy targeting.
