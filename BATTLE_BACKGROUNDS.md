# How the Battle Backgrounds Work

The battle backgrounds come from a **shader**: a small program that runs on the graphics
card and works out the color of every pixel on the screen, every frame. There's no image
behind it; the pattern is built from math. The whole effect is in
`shaders/battle_bg.gdshader`, which is about 85 lines long.

---

## Setup in Godot (`scripts/battle/battle.gd`, in `_build_background`, around line 671)

1. A `ColorRect` covers the whole 320×240 screen.
2. It gets a `ShaderMaterial` that uses the shader.
3. Each enemy's two colors from `"bg"` in `scripts/data/db.gd` are passed in as `color_a`
   and `color_b`. The animation speed comes from the enemy's tempo (`bpm / 110`), so
   faster battle songs warp and pulse faster.
4. On every beat, `battle.gd` sets a `pulse` value to 0.6 and lets it fade back to 0 in
   `_process()`, which makes the background flash in time with the music.

Values passed from a script into a shader are called **uniforms**. You set them with
`set_shader_parameter("name", value)`.

---

## What the shader does

Godot runs the `fragment()` function once for every pixel. `UV` is the pixel's position
from (0,0) in the top-left corner to (1,1) in the bottom-right, and `TIME` counts up in
seconds. The look is cyberpunk: glowing wires crossing over a dark backdrop, with data
pulses running along them. `color_a` is the backdrop and `color_b` is the wire glow.

### 1. Chunky pixels

```glsl
vec2 uv = floor(UV * RES) / RES;
```

This rounds the position down to a 160×120 grid, so groups of nearby pixels get the same
color. That gives it the low-resolution Game Boy Advance look.

### 2. EarthBound-style warping

```glsl
uv.x += sin(row * 0.12 + t * 2.0) * wobble;                                              // lines slide sideways
uv.x += (mod(row, 2.0) * 2.0 - 1.0) * sin(row * 0.04 - t * 1.5) * wobble * interlace;  // odd/even lines split apart
uv.y += sin(uv.y * 8.0 + t * 1.3) * wobble * 0.8;                                       // lines bunch up and spread out
```

`row` is which line of the screen the pixel is on. EarthBound shifted each line of the
screen by a different amount, and these are its three classic tricks: a sideways wave,
the "interlaced" effect where every other line goes the opposite way, and a vertical
squash. Everything drawn afterwards gets bent by them.

### 3. The wires

```glsl
float u = (q.x + q.y) * 0.5;   // wires running one way
float v = (q.x - q.y) * 0.5;   // and the other way
float du = wire_dist(u);        // 0 right on a wire
```

`wire_dist` measures how far a number is from the nearest whole number. Lines where
`x + y` is a whole number run diagonally one way, and lines where `x - y` is whole run the
other way, so together they cross into a diamond mesh. `glow()` turns that distance into
a sharp wire plus a soft halo.

### 4. Pulses, nodes and a second layer

- **Data pulses:** `pow(fract(...), 14.0)` makes a ramp that is dark nearly all the way and
  then spikes, a bright head with a short tail. It slides along each wire over time, and
  `hash()` gives each wire a random head start.
- **Nodes:** where both distances are small, two wires cross, so a square pad is drawn
  there. Some of them blink on and off at random.
- **Back layer:** a finer, dimmer grid scrolls the other way with its own wave. EarthBound
  often stacked two moving layers like this.

### 5. Finishing touches

```glsl
col += color_b.rgb * wires * (0.8 + pulse);   // wires flash on each beat
col *= 1.0 - 0.12 * mod(row, 2.0);            // faint CRT scanlines
col = floor(col * 10.0) / 10.0;               // limited palette, for banding
```

---

## Things to try

You can edit the shader while the game is running and see the change right away:

- Open `scenes/battle.tscn` and press **F6**.
- Then edit the `.gdshader` file in Godot's shader editor.

Some changes to try:

- **Change one number:** set `wobble` to 0.1 for a seasick look, `interlace` to 1.5 for a
  heavily split screen, or `bands` to 3 for fewer, bigger wires.
- **Straight wires:** use `q.x` and `q.y` in place of `q.x + q.y` and `q.x - q.y` to get a
  square grid, like a circuit board.
- **Faster data:** raise the `0.8` and `0.6` in the spark lines, or change the `14.0` to make
  the pulse tails longer or shorter.
- **A third neon color:** add a `color_c` uniform and use it in place of `hot` so the pulses
  are a different color from the wires, for example pink pulses on cyan wires.
- **Change it per enemy:** add more `"bg"` settings in `db.gd` (for example a wobble or
  bands value) and pass them in where `battle.gd` sets the colors.

## Learning more

*The Book of Shaders* (thebookofshaders.com) is a good next step. Its examples use the
same functions as this file: `sin`, `smoothstep`, `mix`, `fract` and `floor`.
