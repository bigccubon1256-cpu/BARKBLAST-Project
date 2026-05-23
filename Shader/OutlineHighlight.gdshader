shader_type spatial;
render_mode cull_front, unshaded, blend_mix; 

uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 0.2) = 0.01; // ผมปรับให้ค่าน้อยลงเพื่อรองรับระบบใหม่
uniform float outline_brightness : hint_range(0.0, 5.0) = 1.0; 

uniform vec3 mesh_center = vec3(0.0, 0.0, 0.0);

void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 expand_dir = sign(VERTEX - mesh_center);
	
	// ==========================================
	// 🌟 [เวทมนตร์อยู่ตรงนี้!] คำนวณระยะห่างจากกล้อง
	// MODELVIEW_MATRIX จะแปลงพิกัดโมเดลเป็นมุมมองกล้อง (ความลึกคือแกน Z)
	// ==========================================
	float dist_to_camera = -(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
	
	// เอาความหนาเดิม ไปคูณกับระยะห่างกล้อง 
	// (ยิ่งไกล Shader จะยิ่งเบ่งพลังขยายเส้นให้ เพื่อให้บนหน้าจอดูหนาเท่าเดิมเป๊ะ!)
	// *คูณ 0.2 เพื่อให้ปรับค่า Slider ใน Inspector ได้ง่ายๆ ไม่พุ่งแรงเกินไป
	float screen_space_thickness = outline_thickness * dist_to_camera * 0.2;
	
	VERTEX += expand_dir * (screen_space_thickness / scale);
}

void fragment() {
	ALBEDO = outline_color.rgb * outline_brightness;
	ALPHA = outline_color.a; 
}