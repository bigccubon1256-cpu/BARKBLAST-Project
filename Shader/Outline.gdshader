shader_type spatial;
render_mode cull_front, unshaded, depth_draw_always;

uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 10.0) = 2.5;
uniform float outline_brightness : hint_range(0.0, 5.0) = 1.5;

void vertex() {
	// ============================================================
	// Clip-Space Normal Expansion — เทคนิคมาตรฐาน AAA ที่ให้เส้นหนา
	// สม่ำเสมอ 100% ทุกระยะ ไม่มีบิดเบี้ยว ไม่มีลูกบาศก์เลย
	// ============================================================
	
	// 1. คำนวณตำแหน่ง Vertex ใน Clip Space
	vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	
	// 2. คำนวณทิศทาง Normal ใน Clip Space
	//    ใช้เฉพาะ xy เพื่อดัน Vertex ออกในระนาบหน้าจอ
	vec4 clip_normal = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(NORMAL, 0.0);
	vec2 screen_normal = normalize(clip_normal.xy);
	
	// 3. ดัน Vertex ออกตาม Screen Normal ด้วยขนาดที่ปรับตาม w
	//    (หาร w เพื่อให้ขนาดบนหน้าจอสม่ำเสมอทุกระยะ — NDC space)
	clip_pos.xy += screen_normal * outline_thickness * 0.001 * clip_pos.w;
	
	POSITION = clip_pos;
}

void fragment() {
	ALBEDO = outline_color.rgb * outline_brightness;
	ALPHA = outline_color.a;
}
