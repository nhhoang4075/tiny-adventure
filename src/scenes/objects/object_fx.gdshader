shader_type canvas_item;

// Shader hiệu ứng dùng CHUNG cho vật thể tương tác (cây, đá, crop, animal).
// Gộp nhiều hiệu ứng vào 1 material để tránh xung đột và tái sử dụng:
//   - RUNG (shake): lắc khi bị chặt/đập.
//   - HIGHLIGHT: phủ 1 lớp trắng lên toàn hình khi được target (mix về highlight_color
//     theo highlight_amount) — giống shader chuồng. Vì cùng 1 shader nên highlight
//     rung & mờ ĐỒNG BỘ với sprite, không loé trắng khi mờ (FadeComponent).

// --- rung ---
uniform float shake_intensity = 0.0;
uniform float shake_speed = 20.0;

// --- highlight (phủ trắng) ---
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float highlight_amount : hint_range(0.0, 1.0) = 0.0;   // 0 = tắt

// Bắt modulate ở vertex (COLOR ở đây = modulate, CHƯA kèm texture) để dùng lại ở
// fragment — vì built-in COLOR trong fragment đã = texture*modulate.
varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;
	if (VERTEX.y < 0.0) {
		VERTEX.x += sin(TIME * shake_speed + VERTEX.y) * shake_intensity;
	}
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Phủ trắng toàn hình theo highlight_amount, GIỮ NGUYÊN alpha (chỉ áp lên phần đặc).
	vec3 rgb = mix(tex.rgb, highlight_color.rgb, highlight_amount);
	// Nhân modulate (lấy từ vertex) để tôn trọng hiệu ứng mờ — KHÔNG nhân built-in
	// COLOR (đã = texture*modulate) vì sẽ bình phương màu (tối đi).
	COLOR = vec4(rgb, tex.a) * v_modulate;
}
