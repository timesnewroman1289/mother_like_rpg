// A cyberpunk take on the psychedelic battle background Mother is famous for:
// glowing cross-wires with data pulses racing along them, bent by EarthBound-style
// scanline warping. Each enemy picks two colors (see "bg" in db.gd):
// color_a is the dark backdrop, color_b is the wire glow. Play with the numbers!
shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(0.25, 0.05, 0.35, 1.0);
uniform vec4 color_b : source_color = vec4(0.05, 0.4, 0.45, 1.0);
uniform float speed = 1.0;
uniform float wobble = 0.035;
uniform float bands = 6.0;      // how many wires fit across the screen
uniform float interlace = 0.35; // how hard odd and even lines slide apart
uniform float pulse = 0.0;      // bumped by the script on every beat

const vec2 RES = vec2(160.0, 120.0);

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

// Distance from c to the nearest whole number: 0 right on a wire, 0.5 halfway between.
float wire_dist(float c) {
	return abs(fract(c + 0.5) - 0.5);
}

// A sharp wire core plus a soft halo around it.
float glow(float d, float width) {
	return smoothstep(width, 0.0, d) + 0.25 * exp(-d * 30.0);
}

void fragment() {
	// Chunky pixels for a retro look.
	vec2 uv = floor(UV * RES) / RES;
	float row = floor(UV.y * RES.y);
	float t = TIME * speed;

	// EarthBound-style warping, worked out per scanline:
	// every line slides sideways by a sine wave of its height...
	uv.x += sin(row * 0.12 + t * 2.0) * wobble;
	// ...odd and even lines slide in opposite directions (the "interlaced" effect)...
	uv.x += (mod(row, 2.0) * 2.0 - 1.0) * sin(row * 0.04 - t * 1.5) * wobble * interlace;
	// ...and lines bunch up and spread apart vertically.
	uv.y += sin(uv.y * 8.0 + t * 1.3) * wobble * 0.8;

	// Square cells on the 4:3 screen, so the diagonals sit at 45 degrees.
	vec2 p = uv * vec2(4.0 / 3.0, 1.0) * bands;

	// Layer 1: big diagonal wires crossing each other, drifting slowly.
	vec2 q = p + vec2(t * 0.15, t * 0.1);
	float u = (q.x + q.y) * 0.5;  // wires running one way
	float v = (q.x - q.y) * 0.5;  // and the other way
	float du = wire_dist(u);
	float dv = wire_dist(v);
	float wires = max(glow(du, 0.035), glow(dv, 0.035));

	// Data pulses: a bright head with a fading tail, racing along each wire.
	// Every wire gets its own random head start so they don't move in lockstep.
	float spark_u = pow(fract(v * 0.5 - t * 0.8 + hash(floor(u + 0.5))), 14.0);
	float spark_v = pow(fract(u * 0.5 + t * 0.6 + hash(floor(v + 0.5) + 31.0)), 14.0);
	float sparks = spark_u * smoothstep(0.06, 0.0, du) + spark_v * smoothstep(0.06, 0.0, dv);

	// Square pads where wires cross, some of them blinking on and off.
	vec2 cell = floor(vec2(u, v) + 0.5);
	float lit = step(0.55, hash(cell.x * 17.0 + cell.y * 59.0 + floor(t * 2.0)));
	float nodes = smoothstep(0.1, 0.07, max(du, dv)) * (0.35 + 0.65 * lit);

	// Layer 2: a fine circuit grid further back, scrolling the other way and
	// warped by its own wave, like EarthBound stacking two moving layers.
	vec2 r = p * 2.0 - vec2(t * 0.4, t * 0.05);
	r.x += sin(row * 0.2 - t * 2.5) * wobble * bands * 2.0;
	float grid = max(glow(wire_dist(r.x), 0.03), glow(wire_dist(r.y), 0.03));

	// Put it all together.
	vec3 hot = mix(color_b.rgb, vec3(1.0), 0.6);
	vec3 col = color_a.rgb * 0.5;
	col += color_b.rgb * grid * 0.12;
	col += color_b.rgb * wires * (0.8 + pulse);
	col += hot * (sparks + nodes);
	col += color_b.rgb * pulse * 0.08;

	// Faint CRT scanlines, then a limited palette for that 16-bit banding.
	col *= 1.0 - 0.12 * mod(row, 2.0);
	col = floor(col * 10.0) / 10.0;
	COLOR = vec4(col, 1.0);
}
