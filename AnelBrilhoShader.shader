shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 cor_anel : hint_color = vec4(1.0, 0.9, 0.0, 1.0); // Amarelo Ouro
uniform vec4 cor_brilho : hint_color = vec4(1.0, 1.0, 0.7, 1.0); // Amarelo Claro Brilhante
uniform float velocidade_pulsacao : hint_range(0.1, 10.0) = 4.0;
uniform float intensidade_brilho : hint_range(0.5, 5.0) = 2.0;

void fragment() {
	// Pulsação temporal suave
	float pulso = sin(TIME * velocidade_pulsacao) * 0.2 + 0.8;
	
	// Efeito Fresnel para dar brilho de borda (glow 3D)
	// NORMAL e VIEW estão no espaço de visualização (View Space)
	float fresnel = 1.0 - dot(normalize(NORMAL), normalize(VIEW));
	fresnel = clamp(fresnel, 0.0, 1.0);
	float fresnel_power = pow(fresnel, 3.0); // Intensifica a transição para as bordas
	
	// Uma única grande onda de energia percorrendo a malha no sentido vertical
	float ondas = sin(UV.y * 3.0 - TIME * 3.0) * 0.25 + 0.75;
	
	// Mistura a cor do corpo do anel com a cor de brilho nas bordas
	vec3 cor_final = mix(cor_anel.rgb, cor_brilho.rgb, fresnel_power);
	
	// Aplica a modulação do pulso e das ondas de energia
	cor_final *= pulso * intensidade_brilho * ondas;
	
	ALBEDO = cor_final;
	
	// Opacidade levemente pulsante
	ALPHA = 0.9 + 0.1 * sin(TIME * 2.0);
}
