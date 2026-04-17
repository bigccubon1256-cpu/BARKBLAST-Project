shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;

// 🌟 ตัวแปรที่ GDScript จะส่งเข้ามา
uniform sampler2D glint_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 glint_color : source_color = vec4(0.9, 0.5, 1.0, 1.0);
uniform vec2 glint_scroll_speed = vec2(0.5, 0.5); 
uniform float glint_scale = 1.0; 
uniform float glint_intensity : hint_range(0.0, 10.0) = 2.0; 
uniform float emission_intensity : hint_range(0.0, 10.0) = 1.0; 

// ตัวแปรส่งค่าพิกัดแบบ 3D จากกล่องไปให้ระบบสี
varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
	// จับพิกัดและทิศทางแบบ 3D ของตัวกล่องมาใช้งาน
	local_pos = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	// --------------------------------------------------
	// 🧊 คาถา Triplanar Mapping: ฉายภาพ 3 ด้านให้ต่อกันเนียนๆ
	// --------------------------------------------------
	// คำนวณน้ำหนักว่าด้านไหนควรชัดสุด (แกน X, Y หรือ Z)
	vec3 blend_weights = abs(local_normal);
	blend_weights /= (blend_weights.x + blend_weights.y + blend_weights.z);

	// สั่งให้ลายเลื่อนตามเวลาและความเร็ว
	vec2 offset = TIME * glint_scroll_speed;

	// 1. ฉายภาพเข้าแกน X (ด้านข้าง)
	vec2 uv_x = local_pos.yz * glint_scale + offset;
	float tex_x = texture(glint_texture, uv_x).r;

	// 2. ฉายภาพเข้าแกน Y (ด้านบน/ล่าง)
	vec2 uv_y = local_pos.xz * glint_scale + offset;
	float tex_y = texture(glint_texture, uv_y).r;

	// 3. ฉายภาพเข้าแกน Z (ด้านหน้า/หลัง)
	vec2 uv_z = local_pos.xy * glint_scale + offset;
	float tex_z = texture(glint_texture, uv_z).r;

	// จับทั้ง 3 ด้านมาผสมกันตามน้ำหนัก จะได้ลายที่เนียนกริบไร้รอยต่อ!
	float texture_mask = (tex_x * blend_weights.x) + (tex_y * blend_weights.y) + (tex_z * blend_weights.z);

	// --------------------------------------------------
	// 🎨 ระบายสี
	vec3 final_glint = glint_color.rgb * texture_mask * glint_intensity;

	ALBEDO = final_glint;
	ALPHA = texture_mask * 0.4; 
	EMISSION = final_glint * emission_intensity;
}