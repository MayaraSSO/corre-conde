extends Camera

onready var posicao_original = translation
onready var fov_original = fov

var offset_batalha = Vector3(0, 3.5, 6.0)
var fov_batalha = 85.0

# --- LÓGICA DE VARREDURA (PERCORRER OS BLOCOS) ---
var estado = "apresentacao_ida"
var cronometro = 2.5

# Valores dinâmicos — ajustados pelo FaseCarregada ou Fase1
var offset_fim_fase = Vector3(450.0, 10.0, 15.0) 
var offset_inicio_fase = Vector3(0.0, 10.0, 15.0)

# Se true, pula a apresentação e vai direto para o modo corrida
var pular_apresentacao = false

func _ready():
	if pular_apresentacao:
		estado = "corrida"

func _process(delta):
	var paladino = get_node_or_null("../../Paladino")
	var conde = get_parent()
	var sol = get_node_or_null("../../ZonaLuz")
	
	# 1. A IDA: Câmera desliza por todos os blocos até o chefe
	if estado == "apresentacao_ida":
		translation = translation.linear_interpolate(posicao_original + offset_fim_fase, 1.2 * delta)
		cronometro -= delta
		
		if cronometro <= 0:
			estado = "apresentacao_volta"
			cronometro = 1.5
			
	# 2. A VOLTA: A Câmera recua deslizando de volta para o início
	elif estado == "apresentacao_volta":
		translation = translation.linear_interpolate(posicao_original + offset_inicio_fase, 2.0 * delta)
		cronometro -= delta
		
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
				translation = translation.linear_interpolate(posicao_original, 3.0 * delta)
				fov = lerp(fov, fov_original, 3.0 * delta)
		else:
			# Sem Paladino (fases carregadas do editor): câmera segue o Conde normalmente
			translation = translation.linear_interpolate(posicao_original, 3.0 * delta)
			fov = lerp(fov, fov_original, 3.0 * delta)
