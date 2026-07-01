extends Spatial

var arvore_cena = preload("res://ArvoreProtetora.tscn")
var tutorial_cena = preload("res://TutorialPanel.tscn")

# --- TRILHAS SONORAS (BGM) ---
var musica_bgm_misterio = preload("res://Sons/Trilha misteriosa todas as fases.mp3")
var musica_bgm_chefe = preload("res://Sons/batalha com chefe.mp3")
var player_bgm : AudioStreamPlayer
var bgm_atual = ""

func mostrar_tutorial(titulo: String, mensaje: String, botoes_fechamento = []):
	var panel = tutorial_cena.instance()
	panel.name = "TutorialPanelActive"
	add_child(panel)
	panel.inicializar(titulo, mensaje, botoes_fechamento)

func _ready():
	print("[Fase3] Inicializando as Catacumbas / Cemitério Ancestral...")
	
	# Reseta o cronômetro para esta fase
	DadosJogo.resetar_tempo_fase_atual()
	
	# Garante que o Conde comece com a vida cheia e configura HUD
	var conde = get_node_or_null("Conde")
	if conde != null:
		conde.energia_vital = 100.0
		var barra = conde.get_node_or_null("HUD/BarraVida")
		if barra != null:
			barra.value = conde.energia_vital
		var texto_hud = conde.get_node_or_null("HUD/TextoAnel")
		if texto_hud != null:
			texto_hud.text = "FALTAM 3 PEDAÇOS DO ANEL"
	
	# Configura a ZonaLuz na Fase 3 (sol super agressivo a 9.5 m/s)
	var zona = get_node_or_null("ZonaLuz")
	if zona != null:
		zona.velocidade_perseguicao = 9.5
		zona.perseguindo = false # Será ativado pelo Cam_Follow após a apresentação de varredura
		zona.tempo_espera = 2.0
	
	# Configura o Paladino Supremo da Fase 3
	var paladino = get_node_or_null("Paladino")
	if paladino != null:
		paladino.saude_paladino = 4        # Exige 4 espadadas para ser derrotado (clímax)
		paladino.pedacos_necessarios = 2    # Exige 2 pedaços recolhidos no mapa antes do boss
		paladino.dano_estaca = 10.0        # Estaca forte (10% dano)
		paladino.pode_mover_e_bater = true  # Habilita perseguição e golpe físico corpo a corpo
		paladino.velocidade_movimento = 4.0 # Perseguição desafiadora mas escapável
		paladino.dano_ataque_fisico = 12.0  # Golpe físico tira 12%
		paladino.cooldown_ataque_fisico = 2.0 # 2.0s entre golpes físicos
		var timer_tiro = paladino.get_node_or_null("TimerTiro")
		if timer_tiro != null:
			timer_tiro.wait_time = 3.5     # 3.5s entre tiros
		print("[Fase3] Paladino configurado: HP=4, TimerTiro=3.5s, Dano Estaca=10, Físico=12")
	
	# Configura os Lobos da Fase 3 (HP=3, Dano=15%, Vel=7.0)
	for lobo in get_tree().get_nodes_in_group("lobos_fase1"):
		lobo.saude = 3
		lobo.velocidade_perseguicao = 7.0
		lobo.dano_ao_conde = 15.0
		print("[Fase3] Lobo configurado: HP=3, Vel=7.0, Dano=15")
		
	# Configura os Crucifixos da Fase 3 (Dano=12%)
	for child in get_children():
		if "Crucifixo" in child.name:
			child.dano_cruz = 12.0
			print("[Fase3] Crucifixo configurado: Dano=12%")

	# Configura os Caixões Quebradiços da Fase 3 (Tremor=0.4s)
	for child in get_children():
		if "Caixao" in child.name:
			child.limite_tremor = 0.4
			print("[Fase3] Caixão configurado: Tremor=0.4s")
		
	# Configura a névoa das catacumbas (tom sepulcral roxo/escuro)
	var env_node = get_node_or_null("WorldEnvironment")
	if env_node != null and env_node.environment != null:
		var env = env_node.environment
		env.background_mode = 2 # BG_SKY
		env.background_color = Color(0.04, 0.02, 0.06) # Roxo sepulcral escuro
		env.ambient_light_color = Color(0.35, 0.3, 0.4)
		env.fog_enabled = true
		env.fog_color = Color(0.04, 0.02, 0.06)
		env.fog_depth_begin = 8.0
		env.fog_depth_end = 32.0
		
	# Configura a câmera de apresentação para varrer a Fase 3
	var cam = get_node_or_null("Conde/Cam_Follow")
	if cam != null:
		# Arena do chefe no final do mapa em X = 650
		cam.offset_fim_fase = Vector3(665.0, 8.0, 15.0)
		cam.offset_inicio_fase = Vector3(0.0, 8.0, 15.0)
		cam.estado = "apresentacao_ida" # Inicia varredura cinematográfica

	# --- CONFIGURAÇÃO DE BGM DINÂMICA ---
	player_bgm = AudioStreamPlayer.new()
	if musica_bgm_misterio is AudioStreamMP3:
		musica_bgm_misterio.loop = true
	if musica_bgm_chefe is AudioStreamMP3:
		musica_bgm_chefe.loop = true
	player_bgm.stream = musica_bgm_misterio
	add_child(player_bgm)
	player_bgm.play()
	bgm_atual = "misterio"

func brotar_arvore(pos_x, pos_y = 0.0):
	# Instancia uma nova árvore protetora a cada Pó Mágico coletado
	var nova_arvore = arvore_cena.instance()
	add_child(nova_arvore)
	nova_arvore.inicializar(pos_x, pos_y)
	print("[Fase3] Nova árvore protetora plantada em X=", pos_x, " Y=", pos_y)

func _process(delta):
	# Rotaciona o céu dinâmico estrelado de forma extremamente suave no eixo Y
	var env_node = get_node_or_null("WorldEnvironment")
	if env_node != null and env_node.environment != null:
		var env = env_node.environment
		if env.background_sky != null:
			env.background_sky_rotation_degrees.y += 3.5 * delta

	# --- CONTROLE DINÂMICO DE BGM (MISTÉRIO vs CHEFE) ---
	var conde = get_node_or_null("Conde")
	var paladino = get_node_or_null("Paladino")
	if conde != null and paladino != null and is_instance_valid(paladino) and not paladino.desintegrando:
		var dist = conde.translation.distance_to(paladino.translation)
		if dist <= 50.0:
			if bgm_atual != "chefe":
				player_bgm.stream = musica_bgm_chefe
				player_bgm.play()
				bgm_atual = "chefe"
		else:
			if bgm_atual != "misterio":
				player_bgm.stream = musica_bgm_misterio
				player_bgm.play()
				bgm_atual = "misterio"
	else:
		if bgm_atual != "misterio":
			player_bgm.stream = musica_bgm_misterio
			player_bgm.play()
			bgm_atual = "misterio"

	# Gatilhos do tutorial (só se o tutorial estiver ativo)
	if DadosJogo.tutorial_ativo:
		# Se já existir um tutorial na tela, não processa novos gatilhos para não sobrepor
		if has_node("TutorialPanelActive"):
			return
			
		conde = get_node_or_null("Conde")
		if conde != null:
			var cam = conde.get_node_or_null("Cam_Follow")
			# Só dispara os tutoriais após acabar a introdução de câmera e ele começar a correr
			if cam != null and cam.estado == "corrida" and conde.is_on_floor():
				
				# Gatilho do Tutorial dos Caixões
				if not DadosJogo.tutor_caixao_exibido:
					# Dispara quando ele avança um pouco na fase
					if conde.translation.x > 15.0:
						DadosJogo.tutor_caixao_exibido = true
						mostrar_tutorial(
							"TUTORIAL: CAIXÕES QUEBRADIÇOS",
							"Cuidado onde pisa!\n\nAlguns caixões nesta área estão muito velhos e instáveis. Se você ficar muito tempo em cima deles, eles começarão a tremer e [color=#ff4a4a]desabarão[/color]!"
						)
						return
				
				# Gatilho do Tutorial do Paladino Supremo
				if not DadosJogo.tutor_paladino_fase3_exibido:
					paladino = get_node_or_null("Paladino")
					if paladino != null and not paladino.desintegrando:
						var dist = conde.translation.distance_to(paladino.translation)
						if dist < 61.0:
							DadosJogo.tutor_paladino_fase3_exibido = true
							mostrar_tutorial(
								"TUTORIAL: BATALHA FINAL",
								"Este é o Paladino Supremo!\n\nEle está no auge de sua força e exigirá [b]4 golpes perfeitos[/b] de espada para ser derrotado.\n\nDesvie de seus golpes, use a sombra das árvores e recupere o último fragmento!"
							)
							return
