## Procedural placeholder art, drawn with CanvasItem draw_* calls, plus the
## helpers that draw your own PNGs instead when they exist (see art/README.md).
##
## Each drawing has its origin at the character's feet (bottom-center), which
## makes Y-sorting on the overworld work naturally.
extends RefCounted

const CHARACTERS := "res://art/characters/"
const ENEMIES := "res://art/enemies/"
const OBJECTS := "res://art/objects/"


## Loads an image, or returns null if that file doesn't exist yet. Everything
## that draws itself checks for its PNG first and falls back to the shapes below.
static func find_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


## Draws one frame of a walking sprite sheet with the feet at the origin.
## The sheet is a 4x4 grid of equal frames. Rows: facing down, left, right, up.
## Columns: 4 walk frames; column 0 is also used when standing still.
static func draw_sheet_character(ci: CanvasItem, sheet: Texture2D, facing: Vector2, step: float, moving: bool) -> void:
	var frame := sheet.get_size() / 4.0
	var row := 0
	if facing.y < -0.5:
		row = 3
	elif facing.x < -0.5:
		row = 1
	elif facing.x > 0.5:
		row = 2
	var col := int(step / (PI / 2.0)) % 4 if moving else 0
	draw_shadow(ci, Vector2.ZERO, 6.0)
	var src := Rect2(Vector2(col, row) * frame, frame)
	ci.draw_texture_rect_region(sheet, Rect2(Vector2(-floorf(frame.x / 2.0), -frame.y), frame), src)


## Draws a single image with its bottom-center at the origin (plus offset).
static func draw_texture_at_feet(ci: CanvasItem, tex: Texture2D, s := 1.0, offset := Vector2.ZERO) -> void:
	var size := tex.get_size() * s
	ci.draw_texture_rect(tex, Rect2(Vector2(-floorf(size.x / 2.0), -size.y) + offset, size), false)


static func ellipse(center: Vector2, rx: float, ry: float, points := 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in points:
		var a := TAU * i / points
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func draw_shadow(ci: CanvasItem, center: Vector2, width: float) -> void:
	ci.draw_colored_polygon(ellipse(center, width, width * 0.4), Color(0, 0, 0, 0.28))


## A little RPG kid. colors may contain: skin, hair, shirt, stripe, pants.
static func draw_character(ci: CanvasItem, colors: Dictionary, facing: Vector2, step: float, moving: bool) -> void:
	var skin: Color = colors.get("skin", Color(1.0, 0.8, 0.62))
	var hair: Color = colors.get("hair", Color(0.35, 0.2, 0.1))
	var shirt: Color = colors.get("shirt", Color(0.3, 0.5, 0.9))
	var stripe: Color = colors.get("stripe", shirt.lightened(0.35))
	var pants: Color = colors.get("pants", Color(0.3, 0.25, 0.2))

	draw_shadow(ci, Vector2.ZERO, 6.0)
	var swing := sin(step) * 1.5 if moving else 0.0
	var bob := -absf(sin(step)) if moving else 0.0

	# Legs and arms swing opposite each other while walking.
	ci.draw_rect(Rect2(-4, -6 + swing, 3, 6 - swing), pants)
	ci.draw_rect(Rect2(1, -6 - swing, 3, 6 + swing), pants)
	ci.draw_rect(Rect2(-7, -13 + bob - swing, 2, 6), skin)
	ci.draw_rect(Rect2(5, -13 + bob + swing, 2, 6), skin)
	ci.draw_rect(Rect2(-5, -14 + bob, 10, 9), shirt)
	ci.draw_rect(Rect2(-5, -11 + bob, 10, 2), stripe)

	var head := Vector2(0, -19 + bob)
	ci.draw_circle(head, 6.0, hair)
	if facing.y < -0.5:
		return  # facing away: just the back of the head
	var face := head + Vector2(facing.x * 1.2, 1.5)
	ci.draw_circle(face, 4.6, skin)
	var eye_y := face.y - 0.5
	if absf(facing.x) > 0.7 and absf(facing.y) < 0.5:
		ci.draw_rect(Rect2(face.x + facing.x * 2.0 - 0.5, eye_y, 1, 2), Color.BLACK)
	else:
		ci.draw_rect(Rect2(face.x - 2.5 + facing.x, eye_y, 1, 2), Color.BLACK)
		ci.draw_rect(Rect2(face.x + 1.5 + facing.x, eye_y, 1, 2), Color.BLACK)


## Enemies, drawn upward from the feet. s = scale, t = time (for animation).
static func draw_enemy(ci: CanvasItem, shape: String, color: Color, s: float, t: float) -> void:
	match shape:
		"mole":
			_mole(ci, color, s, t)
		"crow":
			_crow(ci, color, s, t)
		"shrub":
			_shrub(ci, color, s, t)
		"beetle":
			_beetle(ci, color, s, t)
		_:
			ci.draw_circle(Vector2(0, -16 * s), 16 * s, color)


static func _eye(ci: CanvasItem, pos: Vector2, r: float, look := Vector2.ZERO) -> void:
	ci.draw_circle(pos, r, Color.WHITE)
	ci.draw_circle(pos + look * r * 0.4, r * 0.55, Color.BLACK)


static func _mole(ci: CanvasItem, c: Color, s: float, t: float) -> void:
	var bob := sin(t * 3.0) * s
	var top := Vector2(0, -18 * s + bob)
	ci.draw_rect(Rect2(-18 * s, top.y, 36 * s, -top.y), c)
	ci.draw_circle(top, 18 * s, c)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var paw := Vector2(side * 19 * s, -6 * s)
		ci.draw_circle(paw, 6 * s, c.darkened(0.3))
		for k in 3:
			var from := paw + Vector2(side * 4 * s, (k - 1) * 3 * s)
			ci.draw_line(from, from + Vector2(side * 4 * s, (k - 1) * 1.5 * s), Color(0.95, 0.9, 0.8), maxf(1.0, s))
	ci.draw_circle(top + Vector2(0, 5 * s), 7 * s, c.lightened(0.25))
	ci.draw_circle(top + Vector2(0, 3 * s), 3.5 * s, Color(1.0, 0.55, 0.65))
	var eye_y := top.y - 6 * s
	if fmod(t, 3.2) > 0.15:
		ci.draw_circle(Vector2(-7 * s, eye_y), 2.2 * s, Color.BLACK)
		ci.draw_circle(Vector2(7 * s, eye_y), 2.2 * s, Color.BLACK)
	else:
		ci.draw_line(Vector2(-9 * s, eye_y), Vector2(-5 * s, eye_y), Color.BLACK, maxf(1.0, s))
		ci.draw_line(Vector2(5 * s, eye_y), Vector2(9 * s, eye_y), Color.BLACK, maxf(1.0, s))
	ci.draw_line(Vector2(-11 * s, eye_y - 5 * s), Vector2(-4 * s, eye_y - 3 * s), Color.BLACK, maxf(1.0, 1.5 * s))
	ci.draw_line(Vector2(11 * s, eye_y - 5 * s), Vector2(4 * s, eye_y - 3 * s), Color.BLACK, maxf(1.0, 1.5 * s))


static func _crow(ci: CanvasItem, c: Color, s: float, t: float) -> void:
	var hover := sin(t * 5.0) * 3.0 * s
	var flap := sin(t * 12.0) * 8.0 * s
	var body := Vector2(0, -28 * s + hover)
	var beak := Color(1.0, 0.75, 0.2)
	ci.draw_line(body + Vector2(-4, 10) * s, body + Vector2(-4, 18) * s, beak, maxf(1.0, 1.5 * s))
	ci.draw_line(body + Vector2(4, 10) * s, body + Vector2(4, 18) * s, beak, maxf(1.0, 1.5 * s))
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		ci.draw_colored_polygon(PackedVector2Array([
			body + Vector2(side * 6 * s, -2 * s),
			body + Vector2(side * 28 * s, -10 * s + flap),
			body + Vector2(side * 22 * s, 6 * s + flap * 0.5)]), c.darkened(0.25))
	ci.draw_circle(body, 13 * s, c)
	ci.draw_circle(body + Vector2(-5, -6) * s, 3.5 * s, c.lightened(0.45))
	ci.draw_colored_polygon(PackedVector2Array([
		body + Vector2(-4, 1) * s, body + Vector2(4, 1) * s, body + Vector2(0, 10) * s]), beak)
	_eye(ci, body + Vector2(-5, -3) * s, 3.2 * s, Vector2(0.3, 0.5))
	_eye(ci, body + Vector2(5, -3) * s, 3.2 * s, Vector2(-0.3, 0.5))


static func _shrub(ci: CanvasItem, c: Color, s: float, t: float) -> void:
	ci.draw_rect(Rect2(-3 * s, -8 * s, 6 * s, 8 * s), Color(0.45, 0.3, 0.15))
	var center := Vector2(0, -22 * s)
	var pts := PackedVector2Array()
	var spikes := 12
	for i in spikes * 2:
		var a := TAU * i / (spikes * 2) + sin(t * 2.0) * 0.06
		var r := (20.0 if i % 2 == 0 else 15.0) * s + sin(t * 6.0 + i) * 0.8 * s
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(pts, c)
	ci.draw_circle(center, 13 * s, c.lightened(0.12))
	_eye(ci, center + Vector2(-6, -3) * s, 3.4 * s, Vector2(0.4, 0.2))
	_eye(ci, center + Vector2(6, -3) * s, 3.4 * s, Vector2(-0.4, 0.2))
	var w := maxf(1.0, 1.5 * s)
	ci.draw_line(center + Vector2(-10, -10) * s, center + Vector2(-3, -7) * s, Color.BLACK, w)
	ci.draw_line(center + Vector2(10, -10) * s, center + Vector2(3, -7) * s, Color.BLACK, w)
	ci.draw_polyline(PackedVector2Array([
		center + Vector2(-6, 6) * s, center + Vector2(-3, 4) * s, center + Vector2(0, 6) * s,
		center + Vector2(3, 4) * s, center + Vector2(6, 6) * s]), Color.BLACK, w)


static func _beetle(ci: CanvasItem, c: Color, s: float, t: float) -> void:
	var bob := sin(t * 2.5) * 1.5 * s
	var body := Vector2(0, -22 * s + bob)
	var leg := Color(0.2, 0.2, 0.25)
	for i in 3:
		var x := (-14.0 + i * 14.0) * s
		var kick := sin(t * 8.0 + i) * 2.0 * s
		ci.draw_line(body + Vector2(x, 8 * s), Vector2(x - 6 * s + kick, 0), leg, maxf(1.0, 2.0 * s))
		ci.draw_line(body + Vector2(x, 8 * s), Vector2(x + 6 * s - kick, 0), leg, maxf(1.0, 2.0 * s))
	ci.draw_colored_polygon(PackedVector2Array([
		body + Vector2(-5, -14) * s, body + Vector2(5, -14) * s,
		body + Vector2(sin(t * 3.0) * 2.0, -36) * s]), c.darkened(0.3))
	ci.draw_colored_polygon(ellipse(body, 26 * s, 18 * s), c)
	ci.draw_line(body + Vector2(0, -17) * s, body + Vector2(0, 17) * s, c.darkened(0.45), maxf(1.0, 1.5 * s))
	ci.draw_colored_polygon(ellipse(body + Vector2(-10, -8) * s, 6 * s, 3 * s), c.lightened(0.5))
	var glow := 0.6 + 0.4 * sin(t * 6.0)
	ci.draw_circle(body + Vector2(-9, -4) * s, 3.5 * s, Color(1, 0.2, 0.2, glow))
	ci.draw_circle(body + Vector2(9, -4) * s, 3.5 * s, Color(1, 0.2, 0.2, glow))
	for i in 3:
		ci.draw_circle(body + Vector2(-14 + i * 14, 8) * s, 1.6 * s, c.darkened(0.5))
