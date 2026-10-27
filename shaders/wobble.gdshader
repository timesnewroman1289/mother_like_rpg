// Makes whatever is drawn underneath ripple like it's underwater. The dialogue
// box lays a rectangle with this shader over itself (see dialogue_box.gd).
// Play with the numbers!
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float amplitude = 1.5;  // how far it sways, in game pixels
uniform float frequency = 0.25; // how tight the waves are (higher = more ripples)
uniform float speed = 4.0;

const vec2 RES = vec2(320.0, 240.0);

void fragment() {
	vec2 px = SCREEN_UV * RES;  // where we are, in game pixels
	vec2 offset = vec2(
		sin(px.y * frequency + TIME * speed),
		0.5 * sin(px.x * frequency * 0.5 + TIME * speed * 0.7)) * amplitude;
	COLOR = texture(screen_texture, SCREEN_UV + offset / RES);
}
