# Your art goes here

Drop PNG files into these folders with the names below. The game uses each PNG
as soon as it exists. Anything you haven't made yet keeps its drawn placeholder, so
you can add art one character at a time. If Godot is open, it imports new files
automatically when you switch back to the editor window.

The screen is 320×240, so keep sprites small (Mother 3's characters are about 16×24).
Every image is placed with its **bottom-center at the character's feet**, so leave
no empty rows under the feet.

## characters/ — walking sprite sheets

| File | Who |
|---|---|
| `kit.png` | Kit, the player |
| `wren.png` | Wren, the party member following you |
| `healer.png`, `elder.png`, `villager.png` | the villagers (the `"sprite"` names in `NPCS` in `scripts/overworld/overworld.gd`) |

Each sheet is a **4×4 grid** of equal-sized frames (a 16×24 frame makes a 64×96 PNG).
The frame size is worked out from the image size, so any size works as long as the grid is 4×4.

```
         col 0     col 1    col 2     col 3
row 0  [ stand ] [ step ] [ stand ] [ step ]   facing down
row 1  [  ...  ]                               facing left
row 2  [  ...  ]                               facing right
row 3  [  ...  ]                               facing up
```

Column 0 is also the standing pose. A soft shadow is drawn under the feet for you.

To add a new villager sheet, give their entry in `NPCS` a `"sprite": "name"` and save
`characters/name.png`.

## enemies/ — one image per enemy

| File | Used for |
|---|---|
| `mole.png`, `crow.png`, `shrub.png`, `beetle.png` | the battle screen (named after the keys in `ENEMIES` in `scripts/data/db.gd`) |
| `mole_field.png`, etc. (optional) | the small version walking around the overworld; without it, the battle image is shrunk |

Battle images are drawn at their own size (`"scale"` only affects the drawn shapes).
The enemies stand near the middle of the screen, so about 64–100 pixels tall fits well.
They blink when hit and bob and squash to the beat automatically.

## objects/ — things you can check

| File | What |
|---|---|
| `frog.png` | the save frog (it hops automatically) |
| `sign.png` | signposts |
| `gift.png`, `gift_open.png` | present box, closed and opened |

These have no automatic shadow, so draw one into the image if you want it.
