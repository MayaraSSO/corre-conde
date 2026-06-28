extends Spatial

onready var arvore = $ArvoreProtetora

func _ready():
	print("[Fase2] Inicializando a Floresta Sombria...")
	# Inicializa a árvore invisível e inativa
	arvore.visible = false
	arvore.ativa = false
	
	# Garante que o Conde comece com a vida cheia e configura HUD
	var conde = get_node_or_null("Conde")
	if conde != null:
		conde.energia_vital = 100.0
		var barra = conde.get_node_or_null("HUD/BarraVida")
		if barra != null:
			barra.value = conde.energia_vital
		var texto_hud = conde.get_node_or_null("HUD/TextoAnel")
		if texto_hud != null:
			texto_hud.text = "ANEL INCOMPLETO (FASE 2)"
			
	# Configura a ZonaLuz na Fase 2
	var zona = get_node_or_null("ZonaLuz")
	if zona != null:
		# Calibração de Game Design: Conde corre a 8.0. Sol corre a 6.8 na Fase 2 (mais veloz que os 5.0 da Fase 1).
		zona.velocidade_perseguicao = 6.8
		zona.perseguindo = false # Será ativado pelo Cam_Follow após a apresentação de varredura
		zona.tempo_espera = 2.0
		
	# Configura a névoa claustrofóbica da floresta
	var env_node = get_node_or_null("WorldEnvironment")
	if env_node != null and env_node.environment != null:
		var env = env_node.environment
		env.background_mode = 1 # BG_COLOR
		env.background_color = Color(0.02, 0.05, 0.03) # Verde pantanoso escuro
		env.ambient_light_color = Color(0.3, 0.45, 0.35)
		env.fog_enabled = true
		env.fog_color = Color(0.02, 0.05, 0.03)
		env.fog_depth_begin = 6.0
		env.fog_depth_end = 28.0
		
	# Configura a câmera de apresentação para varrer a Fase 2
	var cam = get_node_or_null("Conde/Cam_Follow")
	if cam != null:
		# Arena do chefe e fim de fase em X = 580.0m
		cam.offset_fim_fase = Vector3(580.0, 8.0, 15.0)
		cam.offset_inicio_fase = Vector3(0.0, 8.0, 15.0)
		cam.estado = "apresentacao_ida" # Inicia varredura cinematográfica

func brotar_arvore(pos_x):
	if arvore != null:
		arvore.inicializar(pos_x)

func _process(delta):
	# Rotaciona o céu dinâmico estrelado de forma extremamente suave no eixo Y
	var env_node = get_node_or_null("WorldEnvironment")
	if env_node != null and env_node.environment != null:
		var env = env_node.environment
		if env.background_sky != null:
			env.background_sky_rotation_degrees.y += 3.5 * delta
