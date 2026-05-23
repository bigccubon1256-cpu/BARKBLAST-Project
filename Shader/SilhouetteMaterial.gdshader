shader_type spatial;
// ============================================================
// SilhouetteMaterial.gdshader
// เรนเดอร์ mesh เป็นสีทึบสำหรับ SubViewport (ไม่มีเงา ไม่มี lighting)
// ============================================================
render_mode blend_mix, unshaded, shadows_disabled, depth_draw_always;

uniform vec4 silhouette_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	ALBEDO = silhouette_color.rgb;
	ALPHA  = silhouette_color.a;
}
