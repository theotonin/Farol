shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.82, 0.95, 0.88, 1.0);
uniform float pulse_speed = 2.4;
uniform float pulse_amount = 0.18;

void fragment() {
	vec4 center = texture(TEXTURE, UV);
	vec2 pixel = TEXTURE_PIXEL_SIZE;
	float nearby = 0.0;
	nearby = max(nearby, texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a);
	nearby = max(nearby, texture(TEXTURE, UV - vec2(pixel.x, 0.0)).a);
	nearby = max(nearby, texture(TEXTURE, UV + vec2(0.0, pixel.y)).a);
	nearby = max(nearby, texture(TEXTURE, UV - vec2(0.0, pixel.y)).a);
	nearby = max(nearby, texture(TEXTURE, UV + pixel).a);
	nearby = max(nearby, texture(TEXTURE, UV - pixel).a);
	nearby = max(nearby, texture(TEXTURE, UV + vec2(pixel.x, -pixel.y)).a);
	nearby = max(nearby, texture(TEXTURE, UV + vec2(-pixel.x, pixel.y)).a);
	float outline = nearby * (1.0 - center.a);
	float pulse = 1.0 - pulse_amount + (sin(TIME * pulse_speed) * 0.5 + 0.5) * pulse_amount;
	COLOR = vec4(outline_color.rgb, outline_color.a * outline * pulse);
}
