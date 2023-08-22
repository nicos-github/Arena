shader_type canvas_item;

uniform int pixel_size : hint_range(1, 100) = 10;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    float x = float(int(FRAGCOORD.x) % pixel_size);
	float y = float(int(FRAGCOORD.y) % pixel_size);
	
	x = FRAGCOORD.x + floor(float(pixel_size) / 2.0) - x;
	y = FRAGCOORD.y + floor(float(pixel_size) / 2.0) - y;
	
	COLOR = texture(screen_texture, vec2(x, y) * SCREEN_PIXEL_SIZE);
}