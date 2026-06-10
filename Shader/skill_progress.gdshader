shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.0, 0.9, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 8.0) = 1.8;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// คำนวณพิกัดแนวทแยง: เมื่อปุ่มหมุน 45 องศา แนวทแยงนี้ตั้งตรงแนวตั้งพอดี
	float d = (UV.x + UV.y) / 2.0;
	
	// ตัดพิกเซลที่ยังไม่ถึงค่าชาร์จ
	if (1.0 - d > progress) {
		discard;
	}
	
	// HDR Glow: คูณสีด้วย glow_strength ให้ค่าสูงกว่า 1.0 เพื่อ trigger bloom จริงๆ
	vec3 hdr_color = tint.rgb * glow_strength;
	COLOR = vec4(tex_color.rgb * hdr_color, tex_color.a * tint.a);
}
