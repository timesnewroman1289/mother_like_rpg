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

## Colours the player can pick for the text box (field menu -> Options).
## Light boxes get dark text, border and highlight so they stay readable.
const DARK_INK := Color(0.1, 0.1, 0.16)
const TEXT_BOX_COLORS := {
	"White": {"bg": Color(0.97, 0.97, 0.97, 1.0), "border": DARK_INK, "text": DARK_INK, "hilite": Color(0.8, 0.15, 0.3)},
	"Mint green": {"bg": Color(0.62, 0.93, 0.78, 1.0), "border": Color(0.1, 0.36, 0.26), "text": Color(0.05, 0.22, 0.15), "hilite": Color(0.75, 0.15, 0.4)},
	"Black": {"bg": BOX_BG, "border": BOX_BORDER, "text": TEXT, "hilite": HILITE},
	"Orange": {"bg": Color(0.97, 0.58, 0.18, 1.0), "border": Color(0.36, 0.15, 0.02), "text": Color(0.2, 0.08, 0.0), "hilite": Color(1.0, 1.0, 0.85)},
	"Cyan": {"bg": Color(0.4, 0.87, 0.95, 1.0), "border": Color(0.04, 0.3, 0.4), "text": Color(0.02, 0.16, 0.22), "hilite": Color(0.8, 0.15, 0.3)},
	"Blue": {"bg": Color(0.14, 0.25, 0.72, 1.0), "border": BOX_BORDER, "text": TEXT, "hilite": HILITE},
}


static func box_style(bg: Color = BOX_BG, border: Color = BOX_BORDER) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
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
