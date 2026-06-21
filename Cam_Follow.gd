extends Camera

onready var posicao_original = translation
onready var fov_original = fov

var offset_batalha = Vector3(0, 3.5, 6.0)
var fov_batalha = 85.0

# --- LÓGICA DE VARREDURA (PERCORRER OS BLOCOS) ---
var estado = "apresentacao_ida"
var cronometro = 2.5 # 2.5 segundos deslizando até o chefe

# X=450 (Viaja pela fase inteira) | Y=10 (Altura para ver os buracos) | Z=15 (Afastamento lateral)
var offset_fim_fase = Vector3(450.0, 10.0, 15.0) 
var offset_inicio_fase = Vector3(0.0, 10.0, 15.0)

func _process(delta):
	var paladino = get_node_or_null("../../Paladino")
	var conde = get_parent()
	var sol = get_node_or_null("../../ZonaLuz")
	
	# 1. A IDAA Câmera desliza por todos os blocos até o Paladino
	if estado == "apresentacao_ida":
		translation = translation.linear_interpolate(posicao_original + offset_fim_fase, 1.2 * delta)
		cronometro -= delta
		
		# Quando der 3.5s, ela engata a marcha à ré
		if cronometro <= 0:
			estado = "apresentacao_volta"
			cronometro = 1.5 # 1.5 segundos para voltar rapidamente ao Conde
			
	# 2. A VOLTA: A Câmera recua deslizando de volta para o início
	elif estado == "apresentacao_volta":
		translation = translation.linear_interpolate(posicao_original + offset_inicio_fase, 2.0 * delta)
		cronometro -= delta
		
		# Terminou de voltar? Libera o Conde e destrava o Tsunami!
		if cronometro <= 0:
			estado = "corrida"
			if sol:
				sol.perseguindo = true 
				
	# 3. A CORRIDA: Jogo normal e câmera da Batalha Final
	elif estado == "corrida":
		if paladino:
			var distancia = conde.translation.distance_to(paladino.translation)
			if distancia <= 60.0:
				translation = translation.linear_interpolate(posicao_original + offset_batalha, 2.0 * delta)
				fov = lerp(fov, fov_batalha, 2.0 * delta)
			else:
				# 3.0 * delta faz a câmera "pousar" macio nas costas do Conde ao iniciar
				translation = translation.linear_interpolate(posicao_original, 3.0 * delta)
				fov = lerp(fov, fov_original, 3.0 * delta)
