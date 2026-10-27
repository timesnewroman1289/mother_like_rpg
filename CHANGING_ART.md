# Changing the Sprites and Character Art

You can change the art at two levels: quick tweaks to the colors and shapes drawn in code,
or replacing them with your own PNG images.

---

## 1. Quick tweaks: change the colors and shapes

All the placeholder art is drawn in code with shapes:

- **Character colors** are short lists in each file:
  - Kit: `COLORS` in `scripts/overworld/player.gd`
  - Wren: `colors` in `scripts/overworld/follower.gd`
  - NPCs: the `"colors"` entry in each NPC in `NPCS` in `scripts/overworld/overworld.gd`
  - The keys are `skin`, `hair`, `shirt`, `stripe` and `pants`.
- **Enemy colors and size** are set by `"color"` and `"scale"` in `scripts/data/db.gd`.
- **The shapes themselves** are drawn in `scripts/shared/art.gd`. `draw_character()` draws
  the kids, and `_mole()`, `_crow()` and the other `_` functions draw the enemies.
  Change the rectangles and circles there.

---

## 2. Real art: use your own PNG files

**This is already set up.** Save PNGs with the right names in the `art/` folder and the
game uses them; anything without a PNG keeps its drawn placeholder. The file names,
sizes and sprite sheet layout are listed in `art/README.md`. The helpers are
`find_texture()`, `draw_sheet_character()` and `draw_texture_at_feet()` in
`scripts/shared/art.gd`.

The rest of this section explains how that works, in case you want to change it or do
the same thing in your own game.

Every character draws itself in a `_draw()` function. To use real art, replace the
shape-drawing call in that function with a call that draws your image. The movement,
talking and battle code doesn't need to change.

### Step 1. Make a sprite sheet

For each character, make one PNG with:

- 4 rows: facing down, left, right, up (in that order)
- 4 walk frames in each row
- each frame about 16×24 pixels (that size matches the 320×240 screen)

Save it inside the project folder, for example `art/kit.png`. Godot picks it up
automatically. The project is already set to keep pixel art sharp instead of blurry.

### Step 2. Draw it

In `scripts/overworld/player.gd`, replace `_draw()` with:

```gdscript
const SHEET := preload("res://art/kit.png")
const FRAME := Vector2(16, 24)  # size of one frame on the sheet

func _draw() -> void:
	Art.draw_shadow(self, Vector2.ZERO, 6.0)
	var row := 0                           # 0 down, 1 left, 2 right, 3 up
	if facing.y < -0.5: row = 3
	elif facing.x < -0.5: row = 1
	elif facing.x > 0.5: row = 2
	var col := int(_step / (PI / 2.0)) % 4 if moving else 0
	var src := Rect2(Vector2(col, row) * FRAME, FRAME)
	# The node's position is the character's feet, so draw the frame upward from there.
	draw_texture_rect_region(SHEET, Rect2(Vector2(-FRAME.x / 2, -FRAME.y), FRAME), src)
```

`follower.gd` and `npc.gd` take the same change. They have the same `facing` and step
variables, so the same code works.

### Step 3. Enemies

1. Add a `"texture"` entry to each enemy in `scripts/data/db.gd`, for example
   `"texture": "res://art/enemies/mole.png"`.
2. In the `_draw()` of `scripts/battle/enemy_sprite.gd` (battle) and
   `scripts/overworld/field_enemy.gd` (overworld), draw that image in place of the
   `Art.draw_enemy(...)` call when the entry exists:

   ```gdscript
   var tex: Texture2D = load(def["texture"])
   draw_texture(tex, Vector2(-tex.get_width() / 2.0, -tex.get_height()))
   ```

3. `enemy_sprite.gd` doesn't keep the enemy's entry the way `field_enemy.gd` keeps `_def`.
   Give it a `texture` variable next to `shape` and `color`, and have `battle.gd` set it
   when it creates each enemy.

**One catch:** the flash when an enemy is hit currently works by switching the enemy's
color to white. That doesn't work on an image, so for images make the enemy blink
instead: skip drawing it on alternate flash frames.

---

## 3. The usual Godot way: AnimatedSprite2D

Once you're comfortable with the above, this is how most Godot projects do it:

1. Make a `Player.tscn` scene in the editor and give it an **AnimatedSprite2D** child.
2. In the **SpriteFrames** panel, create animations such as `walk_down` and `idle_left`
   from your sprite sheet. You can see the frames as you set them up.
3. In code, play them with `$AnimatedSprite2D.play("walk_" + dir_name)`.
4. For the map, use a **TileMapLayer** node and paint tiles from a tileset image. That
   replaces the text `MAP` and the tile drawing in `overworld.gd`'s `_draw()`.
