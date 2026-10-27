## The shared look for every box, label and menu, so the game feels consistent.
## Change colors here and the whole UI follows.
extends RefCounted

const FONT_SIZE := 10
const TEXT := Color(1, 1, 1)
const DIM := Color(0.5, 0.5, 0.62)
const HILITE := Color(1.0, 0.88, 0.35)
const SELECT_BG := Color(1, 1, 1, 0.14)
const BOX_BG := Color(0.06, 0.06, 0.13, 0.94)
const BOX_BORDER := Color(0.95, 0.95, 1.0)


static func box_style(bg: Color = BOX_BG) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = BOX_BORDER
	s.set_border_width_all(2)
	s.set_corner_radius_all(4)
	return s


## A Mother-style window: dark fill, white rounded border.
static func make_box(parent: Node, rect: Rect2) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", box_style())
	parent.add_child(p)
	p.position = rect.position
	p.size = rect.size
	return p


## Pass an area to get a fixed-size label that word-wraps.
static func make_label(parent: Node, text: String, pos: Vector2, area := Vector2.ZERO) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", FONT_SIZE)
	l.add_theme_color_override("font_color", TEXT)
	l.add_theme_constant_override("line_spacing", -1)
	parent.add_child(l)
	l.position = pos
	if area != Vector2.ZERO:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size = area
	return l
