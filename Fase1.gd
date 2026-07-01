extends Spatial

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
	print("[Fase1] Inicializando o Castelo do Conde...")
	
	# Reseta o cronômetro para esta fase
	DadosJogo.resetar_tempo_fase_atual()
	
	# Configura a ZonaLuz na Fase 1
	var zona = get_node_or_null("ZonaLuz")
	if zona != null:
		zona.velocidade_perseguicao = 6.5
		zona.perseguindo = false # Será ativado pelo Cam_Follow após a apresentação de varredura
		zona.tempo_espera = 2.0

	# Configura os Lobos da Fase 1 (HP=1, Dano=8%, Vel=5.0)
	for child in get_children():
		if "Lobo" in child.name:
			child.saude = 1
			child.dano_ao_conde = 8.0
			child.velocidade_perseguicao = 5.0
			print("[Fase1] Lobo configurado: HP=1, Dano=8%, Vel=5.0")

	# Configura os Crucifixos da Fase 1 (Dano=8%)
	for child in get_children():
		if "Crucifixo" in child.name:
			child.dano_cruz = 8.0
			print("[Fase1] Crucifixo configurado: Dano=8%")

	# Configura o Paladino da Fase 1 (HP=1, CD Tiro=5.0s, Dano estaca=10%)
	var paladino = get_node_or_null("Paladino")
	if paladino != null:
		paladino.saude_paladino = 1
		paladino.pedacos_necessarios = 2
		paladino.dano_estaca = 10.0
		var timer_tiro = paladino.get_node_or_null("TimerTiro")
		if timer_tiro != null:
			timer_tiro.wait_time = 5.0
		print("[Fase1] Paladino configurado: HP=1, CD Tiro=5.0s, Dano Estaca=10%")

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
			if cam != null and cam.estado == "corrida" and conde.is_on_floor():
				
				# 1. Gatilho do Tutorial do Sol (ZonaLuz) - O Sol vem de trás, por isso é a primeira ameaça
				if not DadosJogo.tutor_sol_exibido:
					var sol = get_node_or_null("ZonaLuz")
					if sol != null:
						var dist = conde.translation.x - sol.translation.x
						if dist < 28.0:
							DadosJogo.tutor_sol_exibido = true
							mostrar_tutorial(
								"TUTORIAL: CORRA DO SOL!",
								"A parede de luz solar está se aproximando por trás!\n\nA luz é fatal para o Conde. [color=#ff4a4a]Corra rapidamente para a direita[/color] para se manter seguro na escuridão!\n\nSegure [b][SHIFT][/b] para correr mais rápido!"
							)
							return # Interrompe a execução para processar o fechamento antes de outros

				# 2. Gatilho do Tutorial de Movimento (após cair no bloco no início) - Logo após o do Sol
				if not DadosJogo.tutor_movimento_exibido:
					DadosJogo.tutor_movimento_exibido = true
					mostrar_tutorial(
						"TUTORIAL: MOVIMENTAÇÃO BÁSICA",
						"Use as teclas para se mover:\n\n- [b]SETAS DIREITA / ESQUERDA[/b]: Andar\n- [b]SETA PARA CIMA[/b]: Pular\n- [b]Teclas C ou Z[/b]: Usar capa protetora (deflete estacas)\n- [b]Teclado [SHIFT] (segurar)[/b]: Correr rápido",
						["ui_left", "ui_right", "ui_up", "combate_parry", "correr"]
					)
					return

				# 2.5 Gatilho do Tutorial de Ranking (após movimento)
				if not DadosJogo.tutor_ranking_exibido:
					DadosJogo.tutor_ranking_exibido = true
					mostrar_tutorial(
						"TUTORIAL: CRONÔMETRO E RANKING",
						"Seja rápido! O seu tempo de conclusão em cada fase está sendo cronometrado e será registrado.\n\nTermine o jogo rapidamente para gravar seu nome no [color=#ffdd00]Ranking dos Melhores Tempos[/color]!"
					)
					return

				# 3. Gatilho do Tutorial de Combate (Lobo1)
				if not DadosJogo.tutor_combate_exibido:
					var lobo1 = get_node_or_null("Lobo1")
					if lobo1 != null:
						var dist = abs(conde.translation.x - lobo1.translation.x)
						if dist < 18.0:
							DadosJogo.tutor_combate_exibido = true
							mostrar_tutorial(
								"TUTORIAL: COMBATE E ESPADA",
								"Um lobo selvagem bloqueia o caminho!\n\nPressione [b][ESPAÇO][/b] para golpear com sua espada e derrotar os monstros que te atacam."
							)
							return

				# 4. Gatilho do Tutorial do Objetivo (Coleta de Anel)
				if not DadosJogo.tutor_anel_exibido:
					if conde.pedacos_coletados > 0:
						DadosJogo.tutor_anel_exibido = true
						mostrar_tutorial(
							"TUTORIAL: PEDAÇOS DE ANEL",
							"Você recuperou um pedaço do Anel Ancestral!\n\nColete os [b]3 pedaços[/b] espalhados para restaurar seus poderes e abrir o portal no final."
						)
						return

				# 5. Gatilho do Tutorial do Paladino
				if not DadosJogo.tutor_paladino_exibido:
					paladino = get_node_or_null("Paladino")
					if paladino != null and not paladino.desintegrando:
						var dist = conde.translation.distance_to(paladino.translation)
						if dist < 61.0:
							DadosJogo.tutor_paladino_exibido = true
							mostrar_tutorial(
								"TUTORIAL: COMBATE COM O PALADINO",
								"Você alcançou o Paladino, o guardião do último fragmento!\n\nEle disparará estacas contra você. Use as teclas [b]C ou Z[/b] no tempo exato para usar a capa e refletir as estacas de volta a ele!\n\nPara derrotá-lo de vez, você deve acertá-lo [b]1 vez[/b] com um golpe de sua espada usando [b][ESPAÇO][/b]!"
							)
							return
