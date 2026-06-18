extends Camera

# Carrega a posição original exata assim que o jogo começa
onready var posicao_original = translation
onready var fov_original = fov

# Configuração da câmera cinematográfica (Afastamento da Batalha)
var offset_batalha = Vector3(0, 3.5, 6.0) # Sobe 3.5 metros e afasta 6 metros para trás
var fov_batalha = 85.0 # Abre a lente para dar mais visão lateral das estacas

func _process(delta):
	# 1. Procura o Paladino subindo a hierarquia de pastas (Cam_Follow -> Conde -> Fase1 -> Paladino)
	var paladino = get_node_or_null("../../Paladino")
	var conde = get_parent()
	
	if paladino:
		# 2. Mede a distância vetorial exata até o chefe
		var distancia = conde.translation.distance_to(paladino.translation)
		
		# 3. Se estiver a 60 metros ou menos (início do combate e visão do radar)
		if distancia <= 60.0:
			# Puxa a câmera para trás e para cima de forma suave (lerp)
			translation = translation.linear_interpolate(posicao_original + offset_batalha, 2.0 * delta)
			fov = lerp(fov, fov_batalha, 2.0 * delta)
		else:
			# Se estiver longe, mantém a câmera focada na corrida de sobrevivência
			translation = translation.linear_interpolate(posicao_original, 2.0 * delta)
			fov = lerp(fov, fov_original, 2.0 * delta)
