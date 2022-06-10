shader_type spatial;
render_mode unshaded;

uniform vec4 tint: hint_color = vec4(1.0);

float expnin(float a, float power) {
	float value = 2.0;
	float m = pow(value, -power);
	float scale = 1.0 / (1.0 - m);
	
	return (pow(value, power * (a - 1.0)) - m) * scale;
}

void fragment() {
	float light = (dot(NORMAL, VIEW) + 1.0) / 2.0;
	vec3 color = vec3(expnin(light, 3.0));
	
	ALBEDO = tint.rgb * color;
}