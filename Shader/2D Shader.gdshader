shader_type canvas_item;

// 🌟 [แก้ตรงนี้!] เอาเครื่องหมายคอมเมนต์ // ออก เพื่อให้มันรู้จักตัวแปร outline_color
uniform sampler2D viewport_texture : hint_default_white, filter_linear;
uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); 
uniform float outline_thickness : hint_range(0.0, 10.0) = 2.0; 

void fragment() {
	vec2 uv = UV;
	vec2 tex_pixel_size = 1.0 / vec2(textureSize(viewport_texture, 0));
	float outline_intensity = 0.0;

	// 🌟 Sobel Edge Detection Filter
	float a[9];
	int index = 0;
	for(int y = -1; y <= 1; y++) {
		for(int x = -1; x <= 1; x++) {
			vec2 offset = vec2(float(x), float(y)) * outline_thickness * tex_pixel_size;
			a[index] = texture(viewport_texture, uv + offset).a;
			index++;
		}
	}

	float sobel_x = a[2] + (2.0 * a[5]) + a[8] - (a[0] + (2.0 * a[3]) + a[6]);
	float sobel_y = a[6] + (2.0 * a[7]) + a[8] - (a[0] + (2.0 * a[1]) + a[2]);
	
	outline_intensity = sqrt((sobel_x * sobel_x) + (sobel_y * sobel_y));
	
	vec4 final_color = outline_color;
	final_color.a *= outline_intensity;
	
	COLOR = final_color;
}