shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float intensity_floor : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float intensity_ceil : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float pulse_speed = 30.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

vec3 hash(vec3 p)
{
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5,183.3,246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
    p = fract(sin(p) * 43758.5453123);
    return p;
}

float pulse(float offset) {
	return clamp((sin(TIME * pulse_speed) + 1.0 + offset) / 2.0, 0.0, 1.0);
}

void fragment() {
	vec3 base_color = texture(screen_texture, UV).rgb;
	vec3 base_noise_color = hash(base_color);
	
	vec3 clamped_color = mix(base_color, base_noise_color, clamp(intensity * pulse(intensity_floor), intensity_floor, intensity_ceil));
	//clamped_color = hash(clamped_color);
	//base_noise_color = mix(base_color, clamped_color, clamp(intensity * pulse(0.0), intensity_floor, intensity_ceil));
	//base_noise_color = hash(base_noise_color);
	
	COLOR.rgb = clamped_color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
