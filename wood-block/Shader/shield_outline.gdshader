shader_type spatial;
render_mode cull_front, unshaded; 

uniform vec4 outline_color : source_color = vec4(0.8, 0.4, 1.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 0.2) = 0.02;
uniform float outline_brightness : hint_range(0.0, 1.0) = 1.0; 

// 🌟 [เพิ่มบรรทัดนี้!] ตัวรับค่า "จุดศูนย์กลางโมเดล" จาก GDScript
uniform vec3 mesh_center = vec3(0.0, 0.0, 0.0);

void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	
	// 🌟 [แก้บรรทัดนี้!] เอา Vertex มาลบกับแกนกลางก่อน แล้วค่อยผลักออก 
	// (ทีนี้ไม่ว่าจุด Origin จะอยู่ตรงไหน ขอบก็จะพุ่งออก 4 ทิศทางเสมอ!)
	vec3 expand_dir = sign(VERTEX - mesh_center);
	VERTEX += expand_dir * (outline_thickness / scale);
}

void fragment() {
	ALBEDO = outline_color.rgb * outline_brightness;
}