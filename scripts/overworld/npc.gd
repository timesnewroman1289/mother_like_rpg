## Anything you can talk to or check on the overworld: people, signs, the save
## frog and present boxes. What talking does lives in their conversation script
## in scripts/dialogue/; "kind" picks how they're drawn.
extends StaticBody2D

const Art = preload("res://scripts/shared/art.gd")

var kind := "person"  # person, healer, sign, frog, gift
var npc_key := ""
var conversation: Script  # from the "talk" entry in NPCS
var colors := {}
var item := ""
var opened := false
var facing := Vector2.DOWN

var _t := 0.0
## Your art, if the PNGs exist. People use a walking sheet named after their
## "sprite" entry in NPCS; things use art/objects/<kind>.png (and gift_open.png).
var _sheet: Texture2D
var _image: Texture2D
var _open_image: Texture2D


func setup(def: Dictionary) -> void:
	kind = def.get("kind", "person")
	conversation = def.get("talk")
	colors = def.get("colors", {})
	item = def.get("item", "")
	if kind == "person" or kind == "healer":
		if def.has("sprite"):
			_sheet = Art.find_texture(Art.CHARACTERS + def["sprite"] + ".png")
	else:
		_image = Art.find_texture(Art.OBJECTS + kind + ".png")
		_open_image = Art.find_texture(Art.OBJECTS + kind + "_open.png")


func _ready() -> void:
	add_to_group("interactable")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 8)
	shape.shape = rect
	shape.position = Vector2(0, -4)
	add_child(shape)


## People turn to look at you when you talk to them.
func face(pos: Vector2) -> void:
	if kind == "person" or kind == "healer":
		facing = (pos - global_position).normalized()
		queue_redraw()


func _process(delta: float) -> void:
	if kind == "frog":
		_t += delta
		queue_redraw()


func _draw() -> void:
	if _sheet:
		Art.draw_sheet_character(self, _sheet, facing, 0.0, false)
		return
	if _image:
		var img := _open_image if opened and _open_image else _image
		var hop := -roundf(absf(sin(_t * 2.5)) * 2.0) if kind == "frog" else 0.0
		Art.draw_texture_at_feet(self, img, 1.0, Vector2(0, hop))
		return
	match kind:
		"frog":
			var hop := absf(sin(_t * 2.5)) * 2.0
			var green := Color(0.3, 0.75, 0.3)
			Art.draw_shadow(self, Vector2.ZERO, 6.0)
			draw_colored_polygon(Art.ellipse(Vector2(0, -5 - hop), 7, 5), green)
			for i in 2:
				var eye := Vector2(-3.5 if i == 0 else 3.5, -10 - hop)
				draw_circle(eye, 2.6, green)
				draw_circle(eye, 1.6, Color.WHITE)
				draw_circle(eye + Vector2(0, 0.4), 0.9, Color.BLACK)
			draw_line(Vector2(-3, -4 - hop), Vector2(3, -4 - hop), Color(0.1, 0.3, 0.1), 1.0)
		"sign":
			draw_rect(Rect2(-1.5, -7, 3, 7), Color(0.4, 0.26, 0.12))
			draw_rect(Rect2(-8, -17, 16, 11), Color(0.75, 0.55, 0.3))
			draw_line(Vector2(-5, -14), Vector2(5, -14), Color(0.4, 0.26, 0.12), 1.0)
			draw_line(Vector2(-5, -10), Vector2(3, -10), Color(0.4, 0.26, 0.12), 1.0)
		"gift":
			Art.draw_shadow(self, Vector2.ZERO, 7.0)
			var red := Color(0.85, 0.2, 0.3)
			var gold := Color(1.0, 0.85, 0.3)
			draw_rect(Rect2(-7, -11, 14, 11), red)
			draw_rect(Rect2(-1, -11, 2, 11), gold)
			if opened:
				draw_rect(Rect2(-6, -10, 12, 3), Color(0.25, 0.05, 0.1))  # empty inside
				draw_rect(Rect2(6, -4, 7, 3), red)  # lid on the ground
			else:
				draw_rect(Rect2(-8, -13, 16, 3), red.lightened(0.15))
				draw_circle(Vector2(-2.5, -14), 2.0, gold)
				draw_circle(Vector2(2.5, -14), 2.0, gold)
		_:
			Art.draw_character(self, colors, facing, 0.0, false)
