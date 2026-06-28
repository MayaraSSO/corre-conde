extends Spatial

# ===========================================================================
# FaseCarregada.gd — Controlador que carrega fases .lvl e posiciona o Conde
# ===========================================================================

onready var level_loader = $LevelLoader

func _ready():
	var num_fase = DadosJogo.fase_atual
	var caminho = DadosJogo.obter_caminho_lvl(num_fase)
	
	print("[FaseCarregada] Carregando fase %d: '%s'" % [num_fase, caminho])
	
	# Carrega o nível
	var ok = level_loader.carregar_fase(caminho)
	if not ok:
		push_error("[FaseCarregada] Falha ao carregar!")
		return
	
	# Posiciona o Conde
	var conde = get_node_or_null("Conde")
	if conde:
		conde.translation = level_loader.player_spawn_pos
		conde.energia_vital = DadosJogo.energia_vital
		print("[FaseCarregada] Conde posicionado em ", conde.translation)
		
		# Atualiza HUD
		var barra = conde.get_node_or_null("HUD/BarraVida")
		if barra:
			barra.value = conde.energia_vital
	
	# Configura ZonaLuz
	var zona = get_node_or_null("ZonaLuz")
	if zona:
		if num_fase == 1:
			zona.perseguindo = false
		else:
			zona.set_process(false)
			zona.visible = false
	
	# Configura ambiente
	var env_node = get_node_or_null("WorldEnvironment")
	if env_node and env_node.environment:
		var env = env_node.environment
		env.background_mode = 1  # BG_COLOR
		env.background_color = Color(0.04, 0.04, 0.08)
		env.fog_enabled = true
		env.fog_color = Color(0.04, 0.04, 0.08)
		env.fog_depth_begin = 10.0
		env.fog_depth_end = 50.0
	
	# Configura câmera para o tamanho do mapa
	var cam = get_node_or_null("Conde/Cam_Follow")
	if cam and cam.has_method("_ready"):
		# Calcula o tamanho do mapa para a apresentação
		var max_x = 0.0
		for bloco in level_loader.dados_fase.blocos:
			if bloco.x > max_x:
				max_x = bloco.x
		var tamanho_mapa = (max_x / 60.0) * level_loader.ESCALA
		cam.offset_fim_fase = Vector3(tamanho_mapa, 8.0, 15.0)
		cam.offset_inicio_fase = Vector3(0.0, 8.0, 15.0)
		
		# Se for fase do editor, pula a apresentação
		if DadosJogo.modo_editor:
			cam.estado = "corrida"
	
	print("[FaseCarregada] Fase %d pronta!" % num_fase)

func _process(_delta):
	# Verifica se Conde atingiu a saída
	var conde = get_node_or_null("Conde")
	if conde == null or level_loader == null:
		return
	
	var dist = conde.translation.distance_to(level_loader.saida_spawn_pos)
	if dist < 2.5:
		DadosJogo.avancar_fase()
		if DadosJogo.fase_atual > DadosJogo.total_fases:
			var _v = get_tree().change_scene("res://TelaVitoria.tscn")
		else:
			var _r = get_tree().change_scene("res://FaseCarregada.tscn")
