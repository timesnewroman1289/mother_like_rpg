// A tilted checkerboard that slides across the inside of a text box. The two
// colours come from the text box colour preset (see dialogue_box.gd).
// Play with the numbers!
shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(0.06, 0.06, 0.13, 1.0);
uniform vec4 color_b : source_color = vec4(0.12, 0.12, 0.22, 1.0);
uniform vec2 box_size = vec2(300.0, 62.0); // set by the script, in game pixels
uniform float square = 8.0;                // size of one square, in game pixels
uniform float angle = 15.0;                // tilt, in degrees
uniform vec2 velocity = vec2(10.0, 4.0);   // game pixels per second
uniform float corner = 2.0;                // rounds off the corners to match the border

void fragment() {
	// Snap to whole game pixels so the edges look like pixel art.
	vec2 p = floor(UV * box_size) + 0.5;

	vec2 q = abs(p - box_size * 0.5) - (box_size * 0.5 - corner);
	if (length(max(q, 0.0)) > corner) {
		discard;
	}

	float a = radians(angle);
	vec2 r = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * p - TIME * velocity;
	vec2 cell = floor(r / square);
	COLOR = mod(cell.x + cell.y, 2.0) < 1.0 ? color_a : color_b;
}
