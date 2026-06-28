shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 core_color : hint_color = vec4(0.8, 0.2, 0.9, 1.0); // Roxo neon
uniform vec4 edge_color : hint_color = vec4(0.1, 0.8, 0.9, 1.0); // Ciano neon
uniform float speed : hint_range(0.1, 20.0) = 8.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	
	// Queda de opacidade nas bordas para formar um circulo suave
	float alpha = smoothstep(0.5, 0.08, dist);
	
	// Pulsação radial simulando ondas de energia cósmica
	float pulse = sin(dist * 20.0 - TIME * speed * 2.0) * 0.2 + 0.8;
	
	// Espiral helicoidal complexa (dist * 12.0 dá o efeito de distorção de redemoinho)
	float angle = atan(uv.y, uv.x);
	float spiral = sin(angle * 5.0 - TIME * speed + dist * 12.0) * 0.35 + 0.65;
	
	// Gradiente de cor do roxo para o ciano baseado no raio e modulado pela espiral
	vec3 color = mix(core_color.rgb, edge_color.rgb, dist * 2.0);
	color *= (spiral * pulse * 1.5); // Multiplica para dar mais brilho
	
	ALBEDO = color;
	ALPHA = alpha * (0.2 + 0.8 * spiral * pulse);
}
