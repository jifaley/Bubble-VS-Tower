shader_type canvas_item;

uniform float dash_length : hint_range(0.1, 100.0) = 20.0;
uniform float gap_length : hint_range(0.1, 100.0) = 5.0;
uniform vec4 line_color  = vec4(1.0, 0.0, 0.0, 1.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float total_length = dash_length + gap_length;
    float position = mod(FRAGCOORD.x, total_length);
    if (position < dash_length) {
        COLOR = line_color;
    } else {
        COLOR = vec4(0.0);  // 透明
    }
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
