shader_type spatial;

uniform vec4 grass_color : hint_color;
uniform vec4 dirt_color : hint_color;

uniform float transition1 : hint_range(0,1);
uniform float transition2 : hint_range(0,1);

varying float flatness;

void vertex() {
	flatness = dot(NORMAL, vec3(0,1,0));
}

void fragment() {
	if (flatness > transition1) {
		ALBEDO = grass_color.rgb;
	}
	else if (flatness > transition2) {
		ALBEDO = mix(dirt_color.rgb, grass_color.rgb, (flatness - transition2)/(transition1 - transition2));
	}
	else {
		ALBEDO = dirt_color.rgb;		
	}
}