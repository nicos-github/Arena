shader_type canvas_item;

uniform vec4 tint : source_color; // tint effect
uniform float wave_speed = 3.0; // wave loop speed
uniform float wave_freq = 10.0; // wave vertical freq
uniform float wave_width = 1; // wave width 
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D freq_noise;

uniform float vignette_intensity = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_rgb : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform sampler2D screen_vec : hint_screen_texture;

float vignette(vec2 uv){
	uv *= 1.0 - uv.xy;
	float vignette = uv.x * uv.y * 15.0;
	return pow(vignette, vignette_intensity * vignette_opacity);
}


void fragment(){
	vec2 wave_uv_offset;
	
	vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = FRAGCOORD.xy / iResolution.xy;
	
	wave_uv_offset.x = cos((TIME*wave_speed)+uv.x+uv.y*wave_freq*2.0*texture(freq_noise, uv).r)*wave_width*0.01;
	
	
	float r = texture(screen_texture, uv + wave_uv_offset.x).r;
    float g = texture(screen_texture, uv + wave_uv_offset.x).g;
    float b = texture(screen_texture, uv + wave_uv_offset.x).b;
	
	
	
	// vignette
	vec4 color = texture(screen_vec, SCREEN_UV);
	vec4 text = texture(TEXTURE, UV);
	
	text.rgba *= (vignette_rgb.rgba);
	text.rgba *= (1.0 - vignette(UV));
	
	vec4 tex= mix(vec4(r, g, b, 1.0), tint, 0.5)/1.5;
	tex += vec4((text.rgb)*color.rgb,text.a);
    COLOR = tex;
	
}