extends Spatial

var arvore_cena = preload("res://ArvoreProtetora.tscn")
var tutorial_cena = preload("res://TutorialPanel.tscn")

# --- TRILHAS SONORAS (BGM) ---
var musica_bgm_misterio = preload("res://Sons/Trilha misteriosa todas as fases.mp3")
var musica_bgm_chefe = preload("res://Sons/batalha com chefe.mp3")
var player_bgm : AudioStreamPlayer
var bgm_atual = ""

func mostrar_tutorial(titulo: String, mensagem: String, botoes_fechamento = []):
	var panel = tutorial_cena.instance()
	panel.name = "TutorialPanelActive"
	add_child(panel)
	panel.inicializar(titulo, mensagem, botoes_fechamento)

func _ready():
	print("[Fase2] Inicializando a Floresta Sombria...")
	
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
	
	# Configura a ZonaLuz na Fase 2 (sol mais rápido que na Fase 1)
	var zona = get_node_or_null("ZonaLuz")
	if zona != null:
		# Fase 1 = 6.5, Fase 2 = 8.5 (mais rápido que a velocidade de caminhada 8.0). Conde corre a 13.0.
		zona.velocidade_perseguicao = 8.5
		zona.perseguindo = false # Será ativado pelo Cam_Follow após a apresentação de varredura
		zona.tempo_espera = 2.0
	
	# Configura o Paladino da Fase 2 (mais forte que o da Fase 1)
	var paladino = get_node_or_null("Paladino")
	if paladino != null:
		paladino.saude_paladino = 3        # 3 espadadas para matar (vs 1 na Fase 1)
		paladino.pedacos_necessarios = 2    # Precisa de 2 pedaços antes de poder atacar
		paladino.dano_estaca = 8.0         # Estaca moderada (8% dano)
		paladino.pode_mover_e_bater = true  # Habilita perseguição e golpe físico corpo a corpo
		paladino.velocidade_movimento = 3.5 # Velocidade de perseguição moderada
		paladino.dano_ataque_fisico = 10.0  # Golpe físico tira 10%
		paladino.cooldown_ataque_fisico = 2.5 # 2.5s entre golpes físicos
		# Timer de tiro mais rápido
		var timer_tiro = paladino.get_node_or_null("TimerTiro")
		if timer_tiro != null:
			timer_tiro.wait_time = 4.0     # 4.0s entre tiros
		print("[Fase2] Paladino configurado: HP=3, TimerTiro=4.0s, Dano Estaca=8, Físico=10")
	
	# Configura os Lobos da Fase 2 (intermediários)
	for lobo in get_tree().get_nodes_in_group("lobos_fase1"):
		lobo.saude = 2                     # 2 espadadas para matar
		lobo.velocidade_perseguicao = 6.0  # Velocidade média
		lobo.dano_ao_conde = 12.0          # Dano médio
		print("[Fase2] Lobo configurado: HP=2, Vel=6.0, Dano=12")

	# Configura os Crucifixos da Fase 2 (Dano=10%)
	for child in get_children():
		if "Crucifixo" in child.name:
			child.dano_cruz = 10.0
			print("[Fase2] Crucifixo configurado: Dano=10%")
		
	# Configura a névoa claustrofóbica da floresta
	var env_node = get_node_or_null("WorldEnvironment")
	if env_node != null and env_node.environment != null:
		var env = env_node.environment
		env.background_mode = 2 # BG_SKY
		env.background_color = Color(0.02, 0.05, 0.03) # Verde pantanoso escuro
		env.ambient_light_color = Color(0.3, 0.45, 0.35)
		env.fog_enabled = true
		env.fog_color = Color(0.02, 0.05, 0.03)
		env.fog_depth_begin = 6.0
		env.fog_depth_end = 28.0
		
	# Configura a câmera de apresentação para varrer a Fase 2
	var cam = get_node_or_null("Conde/Cam_Follow")
	if cam != null:
		# Arena do chefe (Paladino) no final do mapa em X = 620
		cam.offset_fim_fase = Vector3(630.0, 8.0, 15.0)
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
	# Instancia uma NOVA árvore protetora a cada Pó Mágico coletado
	var nova_arvore = arvore_cena.instance()
	add_child(nova_arvore)
	nova_arvore.inicializar(pos_x, pos_y)
	print("[Fase2] Nova árvore protetora plantada em X=", pos_x, " Y=", pos_y)

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
				
				# Gatilho do Tutorial da Árvore Protetora (Semente)
				if not DadosJogo.tutor_arvore_exibido:
					# Dispara quando ele anda um pouquinho para a direita (perto da semente em X=20)
					if conde.translation.x > 5.0:
						DadosJogo.tutor_arvore_exibido = true
						mostrar_tutorial(
							"TUTORIAL: SEMENTE DE ÁRVORE PROTETORA",
							"Você encontrou um Pó Mágico! Ao coletá-lo, brotará instantaneamente uma Árvore Protetora gigante.\n\n- [b]Sombra Protetora[/b]: Fique sob a copa para se abrigar dos raios solares letais.\n- [b]Desaceleração do Sol[/b]: Enquanto estiver abrigado na sombra, a velocidade do Sol cai para apenas [color=#d9ad20]25%[/color], dando tempo para você respirar.\n- [b]Cura Instantânea[/b]: Entrar na sombra recupera na hora [color=#6cff6c]10% de sua vida[/color] (uma única cura por árvore plantada)."
						)
						return

				# Gatilho do Tutorial do Paladino Corpo a Corpo
				if not DadosJogo.tutor_paladino_fase2_exibido:
					paladino = get_node_or_null("Paladino")
					if paladino != null and not paladino.desintegrando:
						var dist = conde.translation.distance_to(paladino.translation)
						if dist < 61.0:
							DadosJogo.tutor_paladino_fase2_exibido = true
							mostrar_tutorial(
								"TUTORIAL: O PALADINO EVOLUIU",
								"O Paladino está mais furioso nesta floresta!\n\nAgora ele te perseguirá e fará ataques corpo a corpo, além das estacas.\n\nPara derrotá-lo desta vez, você precisará acertá-lo [b]3 vezes[/b] com a espada!"
							)
							return
