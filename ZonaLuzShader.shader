shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, blend_add;

void fragment() {
	// O UV.x mapeia horizontalmente o bloco de sol de trás para a frente (0 a 1)
	// Fazemos a frente da onda solar (direita, UV.x = 1.0) ter um fade out suave
	float gradiente = 1.0 - smoothstep(0.98, 1.0, UV.x);
	
	// Cor dourada/solar quente e suave para o blend aditivo
	vec3 cor_sol = vec3(0.5, 0.4, 0.25);
	
	ALBEDO = cor_sol;
	// Opacidade aditiva muito suave que revela o ceu de dia de fundo
	ALPHA = 0.45 * gradiente;
}
