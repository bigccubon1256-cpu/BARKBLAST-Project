shader_type canvas_item;

uniform sampler2D progress_texture : hint_default_black;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(0.0, 0.9, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 0.8;
uniform float blur_radius : hint_range(0.0, 50.0) = 2.5; // รัศมีเล็กลงเพื่อให้ดูคมและหรูหราขึ้น
uniform float button_scale : hint_range(0.1, 1.0) = 0.4; // อัตราส่วนขนาดปุ่มจริงต่อโหนดออร่า

void fragment() {
	// แปลง UV ของ ColorRect (ที่มีขนาดใหญ่กว่า เช่น 200x200) ให้เป็น UV ของ TextureButton ตรงกลาง (80x80)
	vec2 tex_uv = (UV - 0.5) / button_scale + 0.5;
	
	vec2 tex_size = vec2(textureSize(progress_texture, 0));
	vec2 pixel_size = 1.0 / tex_size;
	
	float alpha_sum = 0.0;
	float weight_sum = 0.0;
	
	// ใช้ RINGS = 6 และ DIRECTIONS = 16 พร้อมการลดหลั่นน้ำหนักแบบ Gaussian เพื่อให้เนียนเรียบเป็นเนื้อเดียวกัน (Smooth gradient)
	const int DIRECTIONS = 16;
	const int RINGS = 6;
	const float SIGMA = 2.5;
	
	// รวมพิกเซลกลางด้วย
	if (tex_uv.x >= 0.0 && tex_uv.x <= 1.0 && tex_uv.y >= 0.0 && tex_uv.y <= 1.0) {
		float diag = (tex_uv.x + tex_uv.y) / 2.0;
		if (1.0 - diag <= progress) {
			alpha_sum += texture(progress_texture, tex_uv).a;
		}
	}
	weight_sum += 1.0;
	
	for (int i = 0; i < DIRECTIONS; i++) {
		float angle = float(i) * 6.283185307 / float(DIRECTIONS);
		vec2 dir = vec2(cos(angle), sin(angle));
		for (int r = 1; r <= RINGS; r++) {
			float d = float(r);
			vec2 offset_uv = tex_uv + dir * d * blur_radius * pixel_size;
			
			// คำนวณน้ำหนัก Gaussian: exp(-d^2 / (2 * sigma^2))
			float weight = exp(-float(r * r) / (2.0 * SIGMA * SIGMA));
			
			if (offset_uv.x >= 0.0 && offset_uv.x <= 1.0 && offset_uv.y >= 0.0 && offset_uv.y <= 1.0) {
				float diag = (offset_uv.x + offset_uv.y) / 2.0;
				if (1.0 - diag <= progress) {
					vec4 sample_col = texture(progress_texture, offset_uv);
					alpha_sum += sample_col.a * weight;
				}
			}
			weight_sum += weight;
		}
	}
	
	float glow_alpha = 0.0;
	if (weight_sum > 0.0) {
		glow_alpha = alpha_sum / weight_sum;
	}
	
	// Pulse animation เบาๆ ไม่ดึงความเข้มแสงขึ้นจ้าเกินไป
	float pulse = 1.0;
	if (progress >= 1.0) {
		pulse = sin(TIME * 3.5) * 0.15 + 1.1;
	} else {
		pulse = sin(TIME * 1.5) * 0.03 + 0.97;
	}
	
	vec3 final_color = glow_color.rgb * intensity * pulse;
	COLOR = vec4(final_color, glow_alpha * glow_color.a);
}
