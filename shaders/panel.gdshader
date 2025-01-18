shader_type spatial;

uniform sampler2D albedo_texture: source_color;
uniform sampler2D depth_texture: hint_depth_texture, repeat_disable, filter_nearest;

//void vertex() {
	//// Called for every vertex the material is visible on.
	//VERTEX.x += VIEW.x;
	//VERTEX.y += VIEW.y;
	//VERTEX.z += VIEW.z;
//}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = texture(albedo_texture, UV).rgb;
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
