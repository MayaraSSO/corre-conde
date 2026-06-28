shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;

uniform sampler2D textura_dia;

void fragment() {
	// O UV.x mapeia horizontalmente o plano de trás para a frente (0 a 1)
	// Fazemos a frente da onda (direita, UV.x = 1.0) ter um degradê de emenda suave
	float fade = 1.0 - smoothstep(0.99, 1.0, UV.x);
	
	// Mapeamos o UV.y para a metade superior da imagem HDRI (0.0 a 0.5) para exibir apenas o ceu azul e ocultar o solo
	vec2 uv_ceu = vec2(UV.x, UV.y * 0.5);
	vec4 col = texture(textura_dia, uv_ceu);
	ALBEDO = col.rgb;
	// Define a opacidade para misturar suavemente o dia com o céu estrelado da noite
	ALPHA = fade;
}
