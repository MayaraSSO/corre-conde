extends KinematicBody

var velocidade = Vector3.ZERO
var forca_pulo = 15.0
var gravidade = 35.0
var velocidade_movimento = 8.0


# --- NOVAS VARIÁVEIS DE VIDA E PARRY ---
var energia_vital = 100.0
var vida_anterior = 100.0
var tempo_exibir_dano = 0.0
var tempo_animacao = 0.0
var temporizador_parry = 0.0
var imune_ao_sol = false
var ultimo_dano_recebido = "dano"
var tempo_fora_do_chao = 0.0
var sofrendo_dano_sol = false
var esta_morto = false
var motivo_morte = ""
var mostrando_frame_final_morte = false
var input_travado = false
var controles_travados = false

# --- VARIÁVEIS DE ATAQUE COM ESPADA ---
var atacando_espada = false
var tempo_ataque_espada = 0.0
var duracao_ataque = 0.4
var ja_acertou_ataque = false  # Evita múltiplos hits no mesmo ataque

# --- VARIÁVEIS DO ANEL ---
var pedacos_coletados = 0
var total_pedacos = 3

# --- CRONÔMETRO VISUAL NO HUD ---
var vbox_cronometro : VBoxContainer = null
var label_tempo_fase : Label = null
var label_tempo_geral : Label = null
var label_distancia_sol : Label = null

# --- TEXTURAS E NÓ DO SPRITE (NOVO SISTEMA DE SPRITESHEET) ---
onready var sprite_node = $SpriteConde
var grupo_anim_anterior = ""

var sheet_parado = preload("res://Imagens/Conde_Parado_Sheet.png")
var sheet_correndo = preload("res://Imagens/Conde_Correndo_Sheet.png")
var sheet_pulo = preload("res://Imagens/Conde_Pulo_Sheet.png")
var sheet_dano = preload("res://Imagens/Conde_Dano_Sheet.png")
var sheet_empurrando = preload("res://Imagens/Conde_Empurrando_Sheet.png")
var sheet_morte = preload("res://Imagens/Conde_Morte_Sheet.png")
var sheet_ataque = preload("res://Imagens/Conde_Attack_2.png")

# --- SONS DO CONDE ---
var som_ataque_res = preload("res://Sons/Ataque com Espada.wav")
var som_dano_res = preload("res://Sons/Dano Recebido.wav")
var som_morte_res = preload("res://Sons/Morte do Conde.wav")
var som_parry_res = preload("res://Sons/Parry (Bloqueio).mp3")
var som_pulo_res = preload("res://Sons/pulo.mp3")
var som_pouso_res = preload("res://Sons/Pouso.wav")
var som_andar_res = preload("res://Sons/dois passos andando.wav")
var som_correr_res = preload("res://Sons/dois passos correndo.wav")
var som_coleta_anel_res = preload("res://Sons/Coleta de Anel.mp3")
var som_luz_sol_res = preload("res://Sons/Luz do Sol (Dano do Sol).mp3")

var player_ataque : AudioStreamPlayer
var player_dano : AudioStreamPlayer
var player_morte : AudioStreamPlayer
var player_parry : AudioStreamPlayer
var player_pulo : AudioStreamPlayer
var player_pouso : AudioStreamPlayer
var player_andar : AudioStreamPlayer
var player_correr : AudioStreamPlayer
var player_coleta_anel : AudioStreamPlayer
var player_luz_sol : AudioStreamPlayer

var no_chao_anterior = true
var estado_movimento_anterior = "parado"


# Configurações das animações (textura, hframes, frame_min, frame_max, fps, escala, offset_y)
var animacoes = {
	"parado": {
		"texture": sheet_parado,
		"hframes": 5,
		"frame_min": 0,
		"frame_max": 4,
		"fps": 6.0,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	},
	"caminhando": {
		"texture": sheet_correndo,
		"hframes": 8,
		"frame_min": 0,
		"frame_max": 7,
		"fps": 8.0,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	},
	"correndo": {
		"texture": sheet_correndo,
		"hframes": 8,
		"frame_min": 0,
		"frame_max": 7,
		"fps": 14.0,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	},
	"subindo": {
		"texture": sheet_pulo,
		"hframes": 7,
		"frame_min": 0,
		"frame_max": 3,
		"fps": 8.0,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	},
	"caindo": {
		"texture": sheet_pulo,
		"hframes": 7,
		"frame_min": 4,
		"frame_max": 5,
		"fps": 6.0,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	},
	"dano": {
		"texture": sheet_dano,
		"hframes": 2,
		"frame_min": 0,
		"frame_max": 1,
		"fps": 6.0,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	},
	"parry": {
		"texture": sheet_dano,
		"hframes": 2,
		"frame_min": 0,
		"frame_max": 1,
		"fps": 6.0,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	},
	"empurrando": {
		"texture": sheet_empurrando,
		"hframes": 8,
		"frame_min": 0,
		"frame_max": 7,
		"fps": 10.0,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	},
	"ataque": {
		"texture": sheet_ataque,
		"hframes": 3,
		"frame_min": 0,
		"frame_max": 2,
		"fps": 7.5,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	},
	"dano_sol": {
		"texture": sheet_morte,
		"hframes": 8,
		"frame_min": 0,
		"frame_max": 2,
		"fps": 6.0,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	},
	"morte": {
		"texture": sheet_morte,
		"hframes": 8,
		"frame_min": 0,
		"frame_max": 7,
		"fps": 3.0,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	},
	"morte_queda": {
		"texture": sheet_pulo,
		"hframes": 7,
		"frame_min": 3,
		"frame_max": 6,
		"fps": 10.0,
		"escala": Vector3(5.5, 5.5, 1.0),
		"offset_y": 2.45
	}
}



func _ready():
	if sprite_node != null:
		sprite_node.visible = true
		sprite_node.texture = sheet_parado
		sprite_node.hframes = 5
		sprite_node.vframes = 1
		sprite_node.frame = 0
		sprite_node.scale = Vector3(5.5, 5.5, 1.0)
		sprite_node.rotation_degrees = Vector3.ZERO # Garante que comece em pé
		
	# Configura o total de pedaços necessários dinamicamente
	if DadosJogo.fase_atual == 1:
		total_pedacos = 3
	elif DadosJogo.fase_atual == 2:
		total_pedacos = 3
	else:
		total_pedacos = 3
	print("[Conde] Pronto! Fase atual: ", DadosJogo.fase_atual, " | Pedaços de anel necessários: ", total_pedacos)
	_criar_indicador_anel()
	_atualizar_indicador_anel()
	_criar_cronometro_hud()

	# --- INICIALIZAÇÃO DOS PLAYERS DE ÁUDIO ---
	# Configura loop nos sons de passos (loop nativo com loop_end correto)
	_configurar_loop(som_andar_res, true)
	_configurar_loop(som_correr_res, true)
	# Sons one-shot (sem loop)
	_configurar_loop(som_ataque_res, false)
	_configurar_loop(som_dano_res, false)
	_configurar_loop(som_morte_res, false)
	_configurar_loop(som_parry_res, false)
	_configurar_loop(som_pulo_res, false)
	_configurar_loop(som_pouso_res, false)
	_configurar_loop(som_coleta_anel_res, false)
	_configurar_loop(som_luz_sol_res, false)
	
	# Debug: verifica se os sons de passos carregaram corretamente
	print("[Audio Debug] som_andar_res tipo: ", som_andar_res, " | é AudioStreamSample: ", som_andar_res is AudioStreamSample)
	print("[Audio Debug] som_correr_res tipo: ", som_correr_res, " | é AudioStreamSample: ", som_correr_res is AudioStreamSample)
	if som_andar_res is AudioStreamSample:
		print("[Audio Debug] Andar - loop_mode: ", som_andar_res.loop_mode, " | loop_begin: ", som_andar_res.loop_begin, " | loop_end: ", som_andar_res.loop_end, " | data size: ", som_andar_res.data.size())
	if som_correr_res is AudioStreamSample:
		print("[Audio Debug] Correr - loop_mode: ", som_correr_res.loop_mode, " | loop_begin: ", som_correr_res.loop_begin, " | loop_end: ", som_correr_res.loop_end, " | data size: ", som_correr_res.data.size())

	player_ataque = AudioStreamPlayer.new()
	player_ataque.stream = som_ataque_res
	add_child(player_ataque)

	player_dano = AudioStreamPlayer.new()
	player_dano.stream = som_dano_res
	add_child(player_dano)

	player_morte = AudioStreamPlayer.new()
	player_morte.stream = som_morte_res
	add_child(player_morte)

	player_parry = AudioStreamPlayer.new()
	player_parry.stream = som_parry_res
	add_child(player_parry)

	player_pulo = AudioStreamPlayer.new()
	player_pulo.stream = som_pulo_res
	add_child(player_pulo)

	player_pouso = AudioStreamPlayer.new()
	player_pouso.stream = som_pouso_res
	add_child(player_pouso)

	player_andar = AudioStreamPlayer.new()
	player_andar.stream = som_andar_res
	add_child(player_andar)

	player_correr = AudioStreamPlayer.new()
	player_correr.stream = som_correr_res
	add_child(player_correr)
	
	player_coleta_anel = AudioStreamPlayer.new()
	player_coleta_anel.stream = som_coleta_anel_res
	add_child(player_coleta_anel)
	
	player_luz_sol = AudioStreamPlayer.new()
	player_luz_sol.stream = som_luz_sol_res
	add_child(player_luz_sol)

func _configurar_loop(stream, loop_ativo: bool):
	if stream == null:
		return
	if stream is AudioStreamSample:
		if loop_ativo:
			stream.loop_mode = AudioStreamSample.LOOP_FORWARD
			stream.loop_begin = 0
			# Calcula o loop_end baseado no tamanho dos dados de áudio
			# formato 16-bit stereo = 4 bytes por sample, 16-bit mono = 2 bytes por sample
			var bytes_por_sample = 2  # 16-bit
			if stream.format == AudioStreamSample.FORMAT_8_BITS:
				bytes_por_sample = 1
			elif stream.format == AudioStreamSample.FORMAT_IMA_ADPCM:
				bytes_por_sample = 1  # comprimido
			var canais = 2 if stream.stereo else 1
			var total_samples = stream.data.size() / (bytes_por_sample * canais)
			stream.loop_end = total_samples
			print("[Audio Config] Loop configurado: samples=", total_samples, " format=", stream.format, " stereo=", stream.stereo)
		else:
			stream.loop_mode = AudioStreamSample.LOOP_DISABLED
	else:
		stream.set("loop", loop_ativo)

func _physics_process(delta):
	# Trava o conde no ar durante a apresentação da câmera ou durante o teletransporte
	var cam = get_node_or_null("Cam_Follow")
	if (cam != null and cam.estado != "corrida") or input_travado:
		velocidade = Vector3.ZERO
		if player_andar != null and player_andar.playing:
			player_andar.stop()
		if player_correr != null and player_correr.playing:
			player_correr.stop()
		estado_movimento_anterior = "parado"
		_atualizar_visual_conde(delta, 0)
		return

	# Checagem centralizada de Morte
	if energia_vital <= 0.0 and not esta_morto:
		energia_vital = 0.0
		morrer(ultimo_dano_recebido)

	# Se o conde estiver morto, ele não deve fazer mais nada, apenas aplicar a gravidade e animar a morte
	if esta_morto:
		velocidade.x = 0
		velocidade.z = 0
		if player_andar != null and player_andar.playing:
			player_andar.stop()
		if player_correr != null and player_correr.playing:
			player_correr.stop()
		estado_movimento_anterior = "parado"
		if not is_on_floor():
			velocidade.y -= gravidade * delta
		velocidade = move_and_slide(velocidade, Vector3.UP)
		_atualizar_visual_conde(delta, 0)
		return

	# Ativação contínua do parry (Capa de Hipnose) enquanto segurar a tecla
	if Input.is_action_pressed("combate_parry"):
		temporizador_parry = 0.2 # Mantém ativo continuamente a cada frame enquanto pressionado
	else:
		# Encerra o escudo imediatamente ao soltar a tecla
		temporizador_parry = 0.0
		
	# Som de Parry
	if Input.is_action_just_pressed("combate_parry") and not esta_morto and not controles_travados:
		if player_parry != null:
			player_parry.play()
	
	# Ativação do ataque com espada (Espaço)
	if Input.is_action_just_pressed("combate_espada") and not atacando_espada:
		atacando_espada = true
		tempo_ataque_espada = 0.0
		ja_acertou_ataque = false
		print("[Conde] Ataque com espada!")
		if player_ataque != null:
			player_ataque.play()
		_executar_ataque_espada()
	
	# Atualiza o temporizador de ataque com espada
	if atacando_espada:
		tempo_ataque_espada += delta
		if tempo_ataque_espada >= duracao_ataque:
			atacando_espada = false
			tempo_ataque_espada = 0.0
	
	# 1. Aplicando a Gravidade (sempre aplicada para manter o is_on_floor estável no chão)
	velocidade.y -= gravidade * delta
		
	# 2. Movimentação Horizontal
	var direcao_x = 0
	
	if not controles_travados:
		if Input.is_action_pressed("ui_right"):
			direcao_x += 1
		if Input.is_action_pressed("ui_left"):
			direcao_x -= 1
		
	var esta_correndo = Input.is_action_pressed("correr") and direcao_x != 0
	var velocidade_atual = 13.0 if esta_correndo else velocidade_movimento
	velocidade.x = direcao_x * velocidade_atual
	
	# 3. O Salto
	if Input.is_action_pressed("ui_up") and is_on_floor() and not controles_travados:
		velocidade.y = forca_pulo
		if player_pulo != null:
			player_pulo.play()
		
	# 4. Trava de segurança do eixo Z
	velocidade.z = 0
	
	# 5. Executa a movimentação e colisão
	velocidade = move_and_slide(velocidade, Vector3.UP)
	
	# Detecção de Pouso (aterrissagem no chão)
	var no_chao_agora = is_on_floor()
	if no_chao_agora and not no_chao_anterior and velocidade.y <= 0 and not esta_morto:
		if player_pouso != null:
			player_pouso.play()
	no_chao_anterior = no_chao_agora

	# Controle dos sons de passos baseado em mudança de estado (State Machine de Som)
	var estado_movimento_atual = "parado"
	if no_chao_agora and direcao_x != 0 and not esta_morto and not controles_travados and not input_travado:
		if esta_correndo:
			estado_movimento_atual = "correndo"
		else:
			estado_movimento_atual = "andando"
	else:
		estado_movimento_atual = "parado"
		
	# 1. Tratamento das transições de estado (parando os outros players)
	if estado_movimento_atual != estado_movimento_anterior:
		if estado_movimento_atual == "parado":
			if player_andar != null:
				player_andar.stop()
			if player_correr != null:
				player_correr.stop()
			print("[Audio] Parando todos os passos (transição para parado)")
		elif estado_movimento_atual == "andando":
			if player_correr != null:
				player_correr.stop()
			if player_andar != null:
				player_andar.play()
			print("[Audio] Iniciando passos ANDANDO")
		elif estado_movimento_atual == "correndo":
			if player_andar != null:
				player_andar.stop()
			if player_correr != null:
				player_correr.play()
			print("[Audio] Iniciando passos CORRENDO")
		
		estado_movimento_anterior = estado_movimento_atual
	
	# Atualiza o temporizador de tolerância de chão para estabilizar as animações
	if is_on_floor():
		tempo_fora_do_chao = 0.0
	else:
		tempo_fora_do_chao += delta
	
	# 7. Máquina de Estados Visual das Sprites 2.5D
	_atualizar_visual_conde(delta, direcao_x)
	
	# Atualiza o painel do cronômetro no HUD
	if label_tempo_fase != null:
		label_tempo_fase.text = "FASE: " + DadosJogo.formatar_tempo(DadosJogo.tempo_fase_atual)
	
	if label_tempo_geral != null:
		label_tempo_geral.text = "TOTAL: " + DadosJogo.formatar_tempo(DadosJogo.obter_tempo_geral_atual())
		
	if label_distancia_sol != null:
		var sol = get_parent().get_node_or_null("ZonaLuz")
		if sol != null and sol.perseguindo:
			var dist = translation.x - sol.translation.x
			if dist <= 0.0:
				label_distancia_sol.text = "SOL: DENTRO DO SOL!"
				label_distancia_sol.add_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
			else:
				label_distancia_sol.text = "SOL: %.1fm" % dist
				if dist < 15.0:
					label_distancia_sol.text = "SOL PERIGO: %.1fm" % dist
					label_distancia_sol.add_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
				else:
					label_distancia_sol.add_color_override("font_color", Color(1.0, 0.6, 0.2, 0.95))
		else:
			label_distancia_sol.text = "SOL: AGUARDANDO..."
			label_distancia_sol.add_color_override("font_color", Color(0.6, 0.6, 0.6, 0.95))
	
	# Limpa a flag de dano do sol para o próximo frame
	sofrendo_dano_sol = false
	
	# 6. Se o Conde cair no abismo (passar de Y = -30), a fase recomeça com derrota por queda
	if translation.y < -30.0:
		morrer("queda")

func morrer(motivo):
	if esta_morto:
		return
	esta_morto = true
	motivo_morte = motivo
	velocidade = Vector3.ZERO
	# Para o cronômetro imediatamente ao morrer
	DadosJogo.cronometro_ativo = false
	print("[Conde] Morrendo! Motivo: ", motivo)
	
	# Para os sons de passos imediatamente
	if player_andar != null:
		player_andar.stop()
	if player_correr != null:
		player_correr.stop()
		
	# Toca o som de morte do Conde
	if player_morte != null:
		player_morte.play()
	
	# Salva o motivo da morte
	var arquivo = File.new()
	var _erro = arquivo.open("user://motivo_morte.txt", File.WRITE)
	arquivo.store_string(motivo)
	arquivo.close()
	
	# Determina o tempo da animação principal com base no motivo da morte
	var tempo_animacao_principal = 0.8 if motivo == "queda" else 1.6
	
	# Aguarda a animação principal antes de mudar de cena
	yield(get_tree().create_timer(tempo_animacao_principal), "timeout")
	
	# Mostra o frame final correspondente ao motivo da morte
	mostrando_frame_final_morte = true
	if sprite_node != null:
		if motivo == "queda":
			# Se caiu no abismo, fica invisível (não aparece flutuando no ar)
			sprite_node.visible = false
		elif motivo == "sol":
			# Se morreu pelo sol, fica deitado (frame 7) carbonizado (cinza escuro)
			sprite_node.texture = sheet_morte
			sprite_node.hframes = 8
			sprite_node.vframes = 1
			sprite_node.frame = 7
			sprite_node.modulate = Color(0.15, 0.15, 0.15, 1.0)
			sprite_node.scale = Vector3(5.5, 5.5, 1.0)
			sprite_node.translation.y = 2.45
		else: # "dano"
			# Se morreu por dano, fica deitado (frame 7) com cor normal
			sprite_node.texture = sheet_morte
			sprite_node.hframes = 8
			sprite_node.vframes = 1
			sprite_node.frame = 7
			sprite_node.modulate = Color(1, 1, 1, 1)
			sprite_node.scale = Vector3(5.5, 5.5, 1.0)
			sprite_node.translation.y = 2.45
		
	yield(get_tree().create_timer(0.2), "timeout")
	
	# Transiciona para GameOver
	var _reiniciar = get_tree().change_scene("res://GameOver.tscn")

func pegar_pedaco_anel():
	# Toca o som de coleta de anel
	if player_coleta_anel != null:
		player_coleta_anel.play()
	pedacos_coletados += 1
	_atualizar_indicador_anel()
	var pedacos_restantes = total_pedacos - pedacos_coletados
	
	# Atualiza o texto na tela baseado na matemática exata
	if pedacos_restantes > 1:
		$HUD/TextoAnel.text = "FALTAM " + str(pedacos_restantes) + " PEDAÇOS DO ANEL"
	elif pedacos_restantes == 1:
		$HUD/TextoAnel.text = "FALTA 1 PEDAÇO DO ANEL"
	else:
		$HUD/TextoAnel.text = "ANEL COMPLETO!"
		print("VITÓRIA: O Conde juntou todos os pedaços!")
		imune_ao_sol = true # Ganha imunidade ao sol definitiva ao restaurar o anel
		
		# Desliga a parede de sol para não alcançar o jogador parado
		var zona = get_parent().get_node_or_null("ZonaLuz")
		if zona != null:
			zona.set_process(false)
			
		# Instancia o Portal no cenário (Fase 1 e 2 apenas)
		if DadosJogo.fase_atual < 3:
			var portal_cena = preload("res://Portal.tscn")
			var portal = portal_cena.instance()
			# Spawna o portal 6 metros à direita do Conde para que ele precise andar e entrar nele
			portal.translation = translation
			portal.translation.x += 6.0
			portal.translation.y = translation.y + 1.5 # altura do chão correspondente
			portal.rotation_degrees.y = -90.0 # Virado para o lado esquerdo (de onde o Conde chega)
			get_parent().add_child(portal)
			print("[Conde] Portal de transição invocado à direita e virado para a esquerda!")
		else:
			# Salva o tempo da Fase 3 e para o cronômetro imediatamente
			DadosJogo.salvar_tempo_fase_atual()
			
			# Se for Fase 3 (Catacumbas final), vai para a cutscene final após 3 segundos
			print("[Conde] Fase 3 concluída! Carregando cutscene final em 3 segundos...")
			yield(get_tree().create_timer(3.0), "timeout")
			var _r = get_tree().change_scene("res://CutsceneEntradaCastelo.tscn")

func _atualizar_visual_conde(delta, direcao_x):
	if sprite_node == null or mostrando_frame_final_morte or get_tree().paused:
		return
		
	# A. Detecção de Dano (se a vida caiu em relação ao frame anterior)
	if energia_vital < vida_anterior:
		tempo_exibir_dano = 0.35 # Mostra o sprite de dano por 0.35 segundos
		if not esta_morto and player_dano != null:
			player_dano.play()
		# Toca o som de dano solar quando estiver na luz do sol
		if sofrendo_dano_sol and player_luz_sol != null and not player_luz_sol.playing:
			player_luz_sol.play()
	vida_anterior = energia_vital
	
	# Para o som de luz do sol quando não estiver mais sofrendo dano solar
	if not sofrendo_dano_sol and player_luz_sol != null and player_luz_sol.playing:
		player_luz_sol.stop()
	
	# B. Pré-calcula o estado normal de movimentação e combate ativo
	var estado_normal = "parado"
	if atacando_espada:
		estado_normal = "ataque"
	elif temporizador_parry > 0.0:
		estado_normal = "parry"
	elif tempo_fora_do_chao > 0.08 or (not is_on_floor() and velocidade.y > 0):
		# No ar
		if velocidade.y > 0:
			estado_normal = "subindo"
		else:
			estado_normal = "caindo"
	else:
		# No chão
		if direcao_x != 0:
			if Input.is_action_pressed("correr"):
				estado_normal = "correndo"
			else:
				estado_normal = "caminhando"
		else:
			estado_normal = "parado"
			
	# C. Máquina de Estados Final para decidir Animação e Cor (Modulate)
	var estado_atual = estado_normal
	
	if esta_morto:
		if motivo_morte == "queda":
			estado_atual = "morte_queda"
			sprite_node.modulate = Color(1, 1, 1, 1)
		elif motivo_morte == "sol":
			estado_atual = "morte"
			# Carboniza o Conde gradualmente ao morrer pelo sol (cinza escuro)
			sprite_node.modulate = Color(0.15, 0.15, 0.15, 1)
		else: # "dano"
			estado_atual = "morte"
			sprite_node.modulate = Color(1, 1, 1, 1)
	elif sofrendo_dano_sol:
		# Se estiver andando/correndo ou pulando/caindo, mantém a animação normal e pisca vermelho
		if direcao_x != 0 or tempo_fora_do_chao > 0.08:
			estado_atual = estado_normal
		else:
			# Se estiver parado no chão, exibe os sprites queimando (dano_sol)
			estado_atual = "dano_sol"
		sprite_node.modulate = Color(1, 0.4, 0.4, 1) # Pisca em vermelho
	elif tempo_exibir_dano > 0:
		tempo_exibir_dano -= delta
		estado_atual = "dano"
		sprite_node.modulate = Color(1, 0.4, 0.4, 1) # Pisca em vermelho
	elif atacando_espada:
		estado_atual = "ataque"
		sprite_node.modulate = Color(1, 1, 1, 1) # Cor normal
	elif temporizador_parry > 0.0:
		estado_atual = "parry"
		sprite_node.modulate = Color(0.0, 0.8, 1.0, 1) # Brilha em azul turquesa
	else:
		estado_atual = estado_normal
		sprite_node.modulate = Color(1, 1, 1, 1) # Cor normal
		
	# Se mudou o estado da animação, reseta o tempo de animação
	if estado_atual != grupo_anim_anterior:
		tempo_animacao = 0.0
		grupo_anim_anterior = estado_atual
		
		# Configura a textura, hframes, escala e offset correspondentes ao novo estado
		var cfg = animacoes[estado_atual]
		sprite_node.texture = cfg["texture"]
		sprite_node.hframes = cfg["hframes"]
		sprite_node.vframes = 1
		sprite_node.scale = cfg["escala"]
		sprite_node.frame = cfg["frame_min"]
		
	# Avança o tempo da animação
	var cfg = animacoes[estado_atual]
	tempo_animacao += delta * cfg["fps"]
	
	# Calcula o índice do frame correspondente
	var total_frames_estado = cfg["frame_max"] - cfg["frame_min"] + 1
	var frame_offset = 0
	if estado_atual == "morte":
		frame_offset = int(tempo_animacao)
		# Trava no último frame no chão
		if frame_offset >= total_frames_estado:
			frame_offset = total_frames_estado - 1
	elif estado_atual == "morte_queda":
		var total_frames_exibidos = int(tempo_animacao)
		if total_frames_exibidos >= 8:
			frame_offset = total_frames_estado - 1
		else:
			frame_offset = total_frames_exibidos % total_frames_estado
	else:
		frame_offset = int(tempo_animacao) % total_frames_estado
		
	sprite_node.frame = cfg["frame_min"] + frame_offset
				
	# C. Orientação Horizontal (Inversão/Flip)
	if direcao_x < 0:
		sprite_node.flip_h = true
	elif direcao_x > 0:
		sprite_node.flip_h = false
		
	# D. Offset do Sprite (Usa o offset_y dinâmico do estado atual)
	sprite_node.translation.x = 0.0
	sprite_node.translation.y = cfg["offset_y"]
	sprite_node.translation.z = 0.0

func _executar_ataque_espada():
	"""Detecta lobos ou o Paladino próximos e aplica dano com a espada"""
	if ja_acertou_ataque:
		return
	
	# Direção do ataque (baseada na orientação do sprite)
	var direcao_ataque = 1.0
	if sprite_node != null and sprite_node.flip_h:
		direcao_ataque = -1.0
		
	# 1. Verifica colisão com o Paladino
	var paladino = get_parent().get_node_or_null("Paladino")
	if paladino == null:
		var loader = get_parent().get_node_or_null("LevelLoader")
		if loader != null:
			paladino = loader.get_node_or_null("Paladino")
			
	if paladino != null and not paladino.desintegrando:
		var dist_paladino = paladino.translation - translation
		var dist_horizontal = dist_paladino.x
		var na_direcao = (direcao_ataque > 0 and dist_horizontal > -1.0 and dist_horizontal < 5.0) or \
						(direcao_ataque < 0 and dist_horizontal > -5.0 and dist_horizontal < 1.0)
		if na_direcao and abs(dist_horizontal) < 5.0 and abs(dist_paladino.y) < 3.0:
			paladino.receber_dano_espada()
			ja_acertou_ataque = true
			print("[Conde] Espada acertou o Paladino!")
			return # Evita acertar outros inimigos no mesmo ataque
	
	# 2. Busca todos os lobos na cena (LoboFase1)
	var lobos = get_tree().get_nodes_in_group("lobos_fase1")
	for lobo in lobos:
		if lobo.morto:
			continue
		var dist = lobo.translation - translation
		var dist_horizontal = dist.x
		
		# Verifica se o lobo está na direção do ataque e dentro do alcance
		var na_direcao = (direcao_ataque > 0 and dist_horizontal > -1.0 and dist_horizontal < 5.0) or \
						(direcao_ataque < 0 and dist_horizontal > -5.0 and dist_horizontal < 1.0)
		var dist_abs = abs(dist_horizontal)
		
		if na_direcao and dist_abs < 5.0 and abs(dist.y) < 3.0:
			lobo.receber_dano_espada()
			ja_acertou_ataque = true
			print("[Conde] Espada acertou o lobo!")
			break  # Só acerta um lobo por ataque

func _criar_indicador_anel():
	var hud = get_node_or_null("HUD")
	if hud == null:
		return
		
	# Limpa indicador anterior se houver
	var indicador_anterior = hud.get_node_or_null("IndicadorAnel")
	if indicador_anterior != null:
		indicador_anterior.queue_free()
		# Aguarda um frame para liberar o nó
		yield(get_tree(), "idle_frame")
		
	var container = HBoxContainer.new()
	container.name = "IndicadorAnel"
	# Posicionado abaixo da BarraVida (margin_top = 20, rect_min_size.y = 20 -> acaba em Y=40)
	# Colocamos em Y=48 com tamanho vertical de 12
	container.rect_position = Vector2(20, 48)
	container.rect_size = Vector2(300, 12)
	container.rect_min_size = Vector2(300, 12)
	
	var n_partes = total_pedacos
	if n_partes <= 0:
		n_partes = 3
		
	var separacao = 6
	container.set("custom_constants/separation", separacao)
	
	var largura_total = 300.0
	var largura_bloco = (largura_total - (separacao * (n_partes - 1))) / n_partes
	
	for i in range(n_partes):
		var rect = ColorRect.new()
		rect.name = "Parte_" + str(i + 1)
		rect.rect_min_size = Vector2(largura_bloco, 12)
		rect.color = Color(0.08, 0.08, 0.15, 0.6) # Cinza escuro translúcido
		container.add_child(rect)
		
	hud.add_child(container)
	
	# Ajusta a posição do TextoAnel para não ficar sobreposto ao indicador
	var texto_anel = hud.get_node_or_null("TextoAnel")
	if texto_anel != null:
		texto_anel.rect_position.y = 68.0
		
	print("[Conde] Indicador visual do anel com ", n_partes, " partes criado no HUD.")

func _criar_cronometro_hud():
	"""Cria dinamicamente um Painel vertical no canto superior direito do HUD para exibir tempos e distância."""
	var hud = get_node_or_null("HUD")
	if hud == null:
		return
	
	# Remove painel anterior se existir
	var painel_anterior = hud.get_node_or_null("PainelCronometro")
	if painel_anterior != null:
		painel_anterior.queue_free()
	
	vbox_cronometro = VBoxContainer.new()
	vbox_cronometro.name = "PainelCronometro"
	vbox_cronometro.anchor_left = 1.0
	vbox_cronometro.anchor_right = 1.0
	vbox_cronometro.anchor_top = 0.0
	vbox_cronometro.anchor_bottom = 0.0
	vbox_cronometro.margin_left = -250.0
	vbox_cronometro.margin_top = 20.0
	vbox_cronometro.margin_right = -20.0
	vbox_cronometro.margin_bottom = 120.0
	vbox_cronometro.set("custom_constants/separation", 2)
	
	# Estilo comum para as Labels
	var cor_texto = Color(1.0, 1.0, 1.0, 0.95)
	var cor_sombra = Color(0.0, 0.0, 0.0, 1.0)
	
	# 1. Label Tempo Fase
	label_tempo_fase = Label.new()
	label_tempo_fase.name = "LabelTempoFase"
	label_tempo_fase.text = "FASE: 00:00.00"
	label_tempo_fase.align = Label.ALIGN_RIGHT
	label_tempo_fase.add_color_override("font_color", cor_texto)
	label_tempo_fase.add_color_override("font_color_shadow", cor_sombra)
	label_tempo_fase.set("custom_constants/shadow_offset_x", 1)
	label_tempo_fase.set("custom_constants/shadow_offset_y", 1)
	vbox_cronometro.add_child(label_tempo_fase)
	
	# 2. Label Tempo Geral
	label_tempo_geral = Label.new()
	label_tempo_geral.name = "LabelTempoGeral"
	label_tempo_geral.text = "TOTAL: 00:00.00"
	label_tempo_geral.align = Label.ALIGN_RIGHT
	label_tempo_geral.add_color_override("font_color", Color(0.85, 0.75, 0.2, 0.95))
	label_tempo_geral.add_color_override("font_color_shadow", cor_sombra)
	label_tempo_geral.set("custom_constants/shadow_offset_x", 1)
	label_tempo_geral.set("custom_constants/shadow_offset_y", 1)
	vbox_cronometro.add_child(label_tempo_geral)
	
	# 3. Label Distância Sol
	label_distancia_sol = Label.new()
	label_distancia_sol.name = "LabelDistanciaSol"
	label_distancia_sol.text = "SOL: AGUARDANDO..."
	label_distancia_sol.align = Label.ALIGN_RIGHT
	label_distancia_sol.add_color_override("font_color", Color(0.6, 0.6, 0.6, 0.95))
	label_distancia_sol.add_color_override("font_color_shadow", cor_sombra)
	label_distancia_sol.set("custom_constants/shadow_offset_x", 1)
	label_distancia_sol.set("custom_constants/shadow_offset_y", 1)
	vbox_cronometro.add_child(label_distancia_sol)
	
	hud.add_child(vbox_cronometro)
	print("[Conde] Painel de Cronômetro/Sol HUD criado no canto superior direito.")

func _atualizar_indicador_anel():
	var hud = get_node_or_null("HUD")
	if hud != null:
		var indicador = hud.get_node_or_null("IndicadorAnel")
		if indicador != null:
			for i in range(total_pedacos):
				var rect = indicador.get_node_or_null("Parte_" + str(i + 1))
				if rect != null:
					if i < pedacos_coletados:
						rect.color = Color(0.9, 0.75, 0.15, 1.0) # Dourado rico e vibrante
					else:
						rect.color = Color(0.08, 0.08, 0.15, 0.6)
