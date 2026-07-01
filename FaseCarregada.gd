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
		
		# Se for modo editor, ajusta total_pedacos baseado nos pedaços reais da fase
		if DadosJogo.modo_editor:
			var n_aneis = 0
			for obj in level_loader.dados_fase.objetos:
				if obj.tipo == "pedaco_anel":
					n_aneis += 1
			if n_aneis > 0:
				conde.total_pedacos = n_aneis
			else:
				conde.total_pedacos = 3  # Padrão se não houver pedaços
			conde.pedacos_coletados = 0
			DadosJogo.pedacos_coletados = 0
			print("[FaseCarregada] Fase customizada: total_pedacos=%d" % n_aneis)
	
	# Configura ZonaLuz
	var zona = get_node_or_null("ZonaLuz")
	if zona:
		if DadosJogo.modo_editor:
			zona.perseguindo = true
			zona.set_process(true)
			zona.visible = true
		elif num_fase == 1:
			zona.perseguindo = false
		else:
			zona.set_process(false)
			zona.visible = false
	
	# Configura ambiente baseado no background_id da fase
	var env_node = get_node_or_null("WorldEnvironment")
	if env_node and env_node.environment:
		var bg_id = level_loader.dados_fase.background_id
		_aplicar_fundo(env_node.environment, bg_id)
	
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
			
			# Adiciona botão de voltar ao editor no HUD
			var btn = Button.new()
			btn.text = "VOLTAR AO EDITOR (Backspace)"
			btn.rect_position = Vector2(20, 110) # Fica posicionado no canto superior esquerdo abaixo do TextoAnel (Y=68)
			btn.rect_size = Vector2(240, 36)
			btn.focus_mode = Control.FOCUS_NONE # Evita roubar o foco dos inputs
			
			# Adiciona estilo de botão vermelho visível
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.8, 0.25, 0.25, 0.8)
			style.border_width_bottom = 2
			style.border_color = Color(0.5, 0.15, 0.15)
			btn.add_stylebox_override("normal", style)
			btn.connect("pressed", self, "_ao_clicar_voltar_editor")
			
			var hud = get_node_or_null("Conde/HUD")
			if hud:
				hud.add_child(btn)
				print("[FaseCarregada] Botão 'Voltar ao Editor' adicionado ao HUD.")
	
	print("[FaseCarregada] Fase %d pronta!" % num_fase)

func _process(_delta):
	# Verifica se Conde atingiu a saída
	var conde = get_node_or_null("Conde")
	if conde == null or level_loader == null:
		return
	
	var dist = conde.translation.distance_to(level_loader.saida_spawn_pos)
	if dist < 2.5:
		if DadosJogo.modo_editor:
			if DadosJogo.caminho_fase_custom == "user://editor_teste.lvl":
				print("[FaseCarregada] Fim do teste! Retornando ao Editor...")
				var _r = get_tree().change_scene("res://EditorFases.tscn")
			else:
				print("[FaseCarregada] Fim da fase customizada! Retornando ao Menu...")
				var _r = get_tree().change_scene("res://MenuFasesCustom.tscn")
		else:
			DadosJogo.avancar_fase()
			if DadosJogo.fase_atual > DadosJogo.total_fases:
				var _v = get_tree().change_scene("res://TelaVitoria.tscn")
			else:
				var _r = get_tree().change_scene("res://FaseCarregada.tscn")

# -----------------------------------------------------------------------
# Aplica preset de fundo (consistente com EditorFases.gd)
# -----------------------------------------------------------------------
func _aplicar_fundo(env: Environment, bg_id: int):
	env.background_mode = 2  # BG_SKY
	env.fog_enabled = true
	env.fog_depth_begin = 15.0
	env.fog_depth_end = 55.0
	
	var sky = PanoramaSky.new()
	var tex = null

	match bg_id:
		0:  # Noite Escura
			tex = load("res://Imagens/NightSkyHDRI014_1K_HDR.exr")
			env.ambient_light_color = Color(0.3, 0.3, 0.4)
			env.fog_color = Color(0.04, 0.04, 0.08)
		1:  # Castelo
			tex = load("res://Imagens/NightSkyHDRI014_1K_HDR.exr")
			env.ambient_light_color = Color(0.4, 0.35, 0.45)
			env.fog_color = Color(0.10, 0.06, 0.12)
		2:  # Floresta
			tex = load("res://Imagens/NightSkyHDRI014_1K_HDR.exr")
			env.ambient_light_color = Color(0.3, 0.45, 0.35)
			env.fog_color = Color(0.02, 0.05, 0.03)
		3:  # Cemitério
			tex = load("res://Imagens/NightSkyHDRI003_1K_HDR.exr")
			env.ambient_light_color = Color(0.35, 0.3, 0.4)
			env.fog_color = Color(0.04, 0.02, 0.06)
		4:  # Lua Cheia
			tex = load("res://Imagens/NightSkyHDRI014_1K_HDR.exr")
			env.ambient_light_color = Color(0.4, 0.4, 0.5)
			env.fog_color = Color(0.05, 0.05, 0.10)
		_:  # Fallback para Noite Escura
			tex = load("res://Imagens/NightSkyHDRI014_1K_HDR.exr")
			env.ambient_light_color = Color(0.3, 0.3, 0.4)
			env.fog_color = Color(0.04, 0.04, 0.08)
			
	if tex != null:
		sky.panorama = tex
		env.background_sky = sky
		env.ambient_light_sky_contribution = 0.5

	print("[FaseCarregada] Fundo aplicado: preset %d (Sky carregado)" % bg_id)

func _input(event):
	if DadosJogo.modo_editor:
		if event is InputEventKey and event.pressed and event.scancode == KEY_BACKSPACE:
			print("[FaseCarregada] Atalho acionado! Retornando ao Editor...")
			_ao_clicar_voltar_editor()

func _ao_clicar_voltar_editor():
	get_tree().paused = false
	if DadosJogo.caminho_fase_custom == "user://editor_teste.lvl" or DadosJogo.caminho_fase_custom == "":
		var _r = get_tree().change_scene("res://EditorFases.tscn")
	else:
		var _r = get_tree().change_scene("res://MenuFasesCustom.tscn")
