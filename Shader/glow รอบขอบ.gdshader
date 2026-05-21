shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.0, 0.0);
uniform float glow_size : hint_range(0.0, 20.0) = 8.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    // วาด glow รอบขอบ
    float alpha = 0.0;
    for (float x = -glow_size; x <= glow_size; x += 1.0) {
        for (float y = -glow_size; y <= glow_size; y += 1.0) {
            vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
            alpha = max(alpha, texture(TEXTURE, UV + offset).a);
        }
    }
    
    vec4 glow = glow_color * alpha;
    COLOR = mix(glow, tex, tex.a);
}