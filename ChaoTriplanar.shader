shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : hint_albedo;
uniform sampler2D normal_tex : hint_normal;
uniform vec3 uv1_scale = vec3(0.1, 0.1, 0.1);

varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power;

void vertex() {
	// Calcula a posição da textura usando coordenadas locais e escala
	uv1_triplanar_pos = VERTEX * uv1_scale;
	
	// Calcula os pesos triplanares baseados na normal local do vértice
	vec3 normal = abs(NORMAL);
	uv1_power = normal / (normal.x + normal.y + normal.z);
}

void fragment() {
	// Projeta as texturas usando fract() para forçar a repetição (tiling) matemática,
	// contornando qualquer configuração de importação de repeat desativada no Godot.
	vec4 albedo_x = texture(albedo_tex, fract(uv1_triplanar_pos.zy));
	vec4 albedo_y = texture(albedo_tex, fract(uv1_triplanar_pos.xz));
	vec4 albedo_z = texture(albedo_tex, fract(uv1_triplanar_pos.xy));
	
	// Combina o albedo baseado nos pesos das faces
	vec4 albedo_final = albedo_x * uv1_power.x + albedo_y * uv1_power.y + albedo_z * uv1_power.z;
	ALBEDO = albedo_final.rgb;
	
	// Projeta o mapa de normais
	vec4 normal_x = texture(normal_tex, fract(uv1_triplanar_pos.zy));
	vec4 normal_y = texture(normal_tex, fract(uv1_triplanar_pos.xz));
	vec4 normal_z = texture(normal_tex, fract(uv1_triplanar_pos.xy));
	
	// Combina o normal map baseado nos pesos
	vec3 normal_final = normal_x.rgb * uv1_power.x + normal_y.rgb * uv1_power.y + normal_z.rgb * uv1_power.z;
	NORMALMAP = normal_final;
	NORMALMAP_DEPTH = 1.0;
}
