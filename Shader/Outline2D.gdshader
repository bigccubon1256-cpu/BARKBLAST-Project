shader_type canvas_item;
// ============================================================
// Outline2D.gdshader — Post-Process Silhouette Dilation
// เทคนิคที่เกมส่วนใหญ่ใช้ (Unity outline asset, Roblox, ฯลฯ)
// รับ texture ของ silhouette จาก SubViewport → dilate → ลบส่วนกลางออก
// → ได้เส้น outline รอบตัวละครที่สวยงามสมบูรณ์แบบ
// ============================================================

uniform float outline_width : hint_range(1.0, 20.0) = 4.0;

void fragment() {
	vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
	
	// สี + alpha ของ pixel ปัจจุบัน (จาก SubViewport)
	vec4 orig = texture(TEXTURE, UV);
	float orig_alpha = orig.a;
	
	// ========== Dilation pass (8 directions circle) ==========
	// ค้นหา pixel ที่มี alpha สูงสุดในรัศมี outline_width รอบๆ
	float max_a    = orig_alpha;
	vec3  max_rgb  = orig.rgb;
	
	const int SAMPLES = 16; // ยิ่งมากยิ่งเนียน แต่เพิ่ม GPU cost เล็กน้อย
	for (int i = 0; i < SAMPLES; i++) {
		float angle  = float(i) * TAU / float(SAMPLES);
		vec2  offset = vec2(cos(angle), sin(angle)) * outline_width * pixel_size;
		vec4  s      = texture(TEXTURE, UV + offset);
		if (s.a > max_a) {
			max_a   = s.a;
			max_rgb = s.rgb;
		}
	}
	
	// ========== Extract outline ring ==========
	// outline = บริเวณที่ dilated เต็ม แต่ original ว่าง (= ขอบ)
	float ring_alpha = clamp(max_a - orig_alpha, 0.0, 1.0);
	
	// ========== Output: เฉพาะ ring (ไม่แสดงส่วนใน Silhouette) ==========
	COLOR = vec4(max_rgb, ring_alpha);
}
