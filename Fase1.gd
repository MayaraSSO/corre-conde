extends Spatial

var tutorial_cena = preload("res://TutorialPanel.tscn")

func mostrar_tutorial(titulo: String, mensagem: String, botoes_fechamento = []):
	var panel = tutorial_cena.instance()
	panel.name = "TutorialPanelActive"
	add_child(panel)
	panel.inicializar(titulo, mensagem, botoes_fechamento)

func _ready():
	print("[Fase1] Inicializando o Castelo do Conde...")
	# Garante que a ZonaLuz use a velocidade padrão da Fase 1 (5.0)
	var zona = get_node_or_null("ZonaLuz")
	if zona != null:
		zona.velocidade_perseguicao = 5.0
		zona.perseguindo = false # Será ativado pelo Cam_Follow após a apresentação de varredura
		zona.tempo_espera = 2.0

func _process(delta):
	# Rotaciona o céu dinâmico estrelado de forma extremamente suave no eixo Y
	var env_node = get_node_or_null("WorldEnvironment")
	if env_node != null and env_node.environment != null:
		var env = env_node.environment
		if env.background_sky != null:
			env.background_sky_rotation_degrees.y += 3.5 * delta

	# Gatilhos do tutorial (só se o tutorial estiver ativo)
	if DadosJogo.tutorial_ativo:
		# Se já existir um tutorial na tela, não processa novos gatilhos para não sobrepor
		if has_node("TutorialPanelActive"):
			return
			
		var conde = get_node_or_null("Conde")
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
								"A parede de luz solar está se aproximando por trás!\n\nA luz é fatal para o Conde. [color=#ff4a4a]Corra rapidamente para a direita[/color] para se manter seguro na escuridão!"
							)
							return # Interrompe a execução para processar o fechamento antes de outros

				# 2. Gatilho do Tutorial de Movimento (após cair no bloco no início) - Logo após o do Sol
				if not DadosJogo.tutor_movimento_exibido:
					DadosJogo.tutor_movimento_exibido = true
					mostrar_tutorial(
						"TUTORIAL: MOVIMENTAÇÃO BÁSICA",
						"Use as [b]SETAS[/b] do teclado para se mover:\n\n- [b]SETA ESQUERDA / DIREITA[/b]: Andar\n- [b]SETA PARA CIMA[/b]: Pular\n- [b]Teclas C ou Z[/b]: Usar capa protetora (deflete estacas)",
						["ui_left", "ui_right", "ui_up", "combate_parry"]
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
					var paladino = get_node_or_null("Paladino")
					if paladino != null and not paladino.desintegrando:
						var dist = conde.translation.distance_to(paladino.translation)
						if dist < 61.0:
							DadosJogo.tutor_paladino_exibido = true
							mostrar_tutorial(
								"TUTORIAL: COMBATE COM O PALADINO",
								"Você alcançou o Paladino, o guardião do último fragmento!\n\nEle disparará estacas contra você. Use as teclas [b]C ou Z[/b] no tempo exato para usar a capa e refletir as estacas de volta a ele!\n\nPara derrotá-lo de vez, você deve acertá-lo [b]1 vez[/b] com um golpe de sua espada usando [b][ESPAÇO][/b]!"
							)
							return
