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
	"correndo": {
		"texture": sheet_correndo,
		"hframes": 8,
		"frame_min": 0,
		"frame_max": 7,
		"fps": 12.0,
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
		total_pedacos = 1
	else:
		total_pedacos = 3
	print("[Conde] Pronto! Fase atual: ", DadosJogo.fase_atual, " | Pedaços de anel necessários: ", total_pedacos)
	_criar_indicador_anel()
	_atualizar_indicador_anel()

func _physics_process(delta):
	# Trava o conde no ar durante a apresentação da câmera ou durante o teletransporte
	var cam = get_node_or_null("Cam_Follow")
	if (cam != null and cam.estado != "corrida") or input_travado:
		velocidade = Vector3.ZERO
		_atualizar_visual_conde(delta, 0)
		return

	# Checagem centralizada de Morte
	if energia_vital <= 0.0 and not esta_morto:
		energia_vital = 0.0
		morrer("dano")

	# Se o conde estiver morto, ele não deve fazer mais nada, apenas aplicar a gravidade e animar a morte
	if esta_morto:
		velocidade.x = 0
		velocidade.z = 0
		if not is_on_floor():
			velocidade.y -= gravidade * delta
		velocidade = move_and_slide(velocidade, Vector3.UP)
		_atualizar_visual_conde(delta, 0)
		return

	# Decrementa o temporizador de parry
	if temporizador_parry > 0.0:
		temporizador_parry -= delta
		if temporizador_parry < 0.0:
			temporizador_parry = 0.0
			
	# Ativação do parry (Capa de Hipnose)
	if Input.is_action_just_pressed("combate_parry"):
		temporizador_parry = 0.8
		print("[Conde] Capa de Hipnose (Parry) ativada por 0.8s!")
	
	# Ativação do ataque com espada (Espaço)
	if Input.is_action_just_pressed("combate_espada") and not atacando_espada:
		atacando_espada = true
		tempo_ataque_espada = 0.0
		ja_acertou_ataque = false
		print("[Conde] Ataque com espada!")
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
		
	velocidade.x = direcao_x * velocidade_movimento
	
	# 3. O Salto
	if Input.is_action_pressed("ui_up") and is_on_floor() and not controles_travados:
		velocidade.y = forca_pulo
		
	# 4. Trava de segurança do eixo Z
	velocidade.z = 0
	
	# 5. Executa a movimentação e colisão
	velocidade = move_and_slide(velocidade, Vector3.UP)
	
	# Atualiza o temporizador de tolerância de chão para estabilizar as animações
	if is_on_floor():
		tempo_fora_do_chao = 0.0
	else:
		tempo_fora_do_chao += delta
	
	# 7. Máquina de Estados Visual das Sprites 2.5D
	_atualizar_visual_conde(delta, direcao_x)
	
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
	print("[Conde] Morrendo! Motivo: ", motivo)
	
	# Salva o motivo da morte
	var arquivo = File.new()
	var _erro = arquivo.open("user://motivo_morte.txt", File.WRITE)
	arquivo.store_string(motivo)
	arquivo.close()
	
	# Determina o tempo da animação principal com base no motivo da morte
	var tempo_animacao_principal = 0.8 if motivo == "queda" else 1.6
	
	# Aguarda a animação principal antes de mudar de cena
	yield(get_tree().create_timer(tempo_animacao_principal), "timeout")
	
	# Mostra o primeiro frame de Conde_Morte_Sheet antes de finalizar
	mostrando_frame_final_morte = true
	if sprite_node != null:
		sprite_node.texture = sheet_morte
		sprite_node.hframes = 8
		sprite_node.vframes = 1
		sprite_node.frame = 0
		sprite_node.modulate = Color(1, 1, 1, 1)
		sprite_node.scale = Vector3(5.5, 5.5, 1.0)
		sprite_node.translation.y = 2.45
		
	yield(get_tree().create_timer(0.2), "timeout")
	
	# Transiciona para GameOver
	var _reiniciar = get_tree().change_scene("res://GameOver.tscn")

func pegar_pedaco_anel():
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
			
		if DadosJogo.fase_atual == 1:
			# Instancia o Portal no cenário
			var portal_cena = preload("res://Portal.tscn")
			var portal = portal_cena.instance()
			# Spawna o portal exatamente onde o Conde está para captura imediata e segura
			portal.translation = translation
			portal.translation.y = 1.5 # altura do chão
			get_parent().add_child(portal)
			print("[Conde] Portal de vitória invocado exatamente na posição do Conde!")
		else:
			# Espera 1.5s e muda para a próxima fase ou tela de vitória
			yield(get_tree().create_timer(1.5), "timeout")
			if DadosJogo.modo_editor:
				DadosJogo.avancar_fase()
				if DadosJogo.fase_atual > DadosJogo.total_fases:
					var _v = get_tree().change_scene("res://TelaVitoria.tscn")
				else:
					var _r = get_tree().change_scene("res://FaseCarregada.tscn")
			else:
				# Campanha principal
				if DadosJogo.fase_atual == 2:
					DadosJogo.fase_atual = 3 # Fim da campanha
					var _v = get_tree().change_scene("res://TelaVitoria.tscn")

func _atualizar_visual_conde(delta, direcao_x):
	if sprite_node == null or mostrando_frame_final_morte or get_tree().paused:
		return
		
	# A. Detecção de Dano (se a vida caiu em relação ao frame anterior)
	if energia_vital < vida_anterior:
		tempo_exibir_dano = 0.35 # Mostra o sprite de dano por 0.35 segundos
	vida_anterior = energia_vital
	
	var estado_atual = "parado"
	
	if esta_morto:
		if motivo_morte == "queda":
			estado_atual = "morte_queda"
		else:
			estado_atual = "morte"
		sprite_node.modulate = Color(1, 1, 1, 1) # Cor normal na morte
	elif sofrendo_dano_sol:
		estado_atual = "dano_sol"
		sprite_node.modulate = Color(1, 0.4, 0.4, 1) # Pisca em vermelho
	elif tempo_exibir_dano > 0:
		tempo_exibir_dano -= delta
		estado_atual = "dano"
		sprite_node.modulate = Color(1, 0.4, 0.4, 1) # Pisca em vermelho
	elif atacando_espada:
		estado_atual = "ataque"
		sprite_node.modulate = Color(1, 1, 1, 1) # Cor normal (sem modulação amarela)
	elif temporizador_parry > 0.0:
		estado_atual = "parry"
		sprite_node.modulate = Color(0.0, 0.8, 1.0, 1) # Brilha em azul turquesa
	else:
		sprite_node.modulate = Color(1, 1, 1, 1) # Cor normal
		
		# C. Animação de Movimento (Pulo, Queda, Corrida, Parado)
		# Só ativa a animação de queda se estiver fora do chão por mais de 0.08 segundos de forma contínua,
		# ou se for um pulo voluntário ascendente (velocidade.y > 0)
		if tempo_fora_do_chao > 0.08 or (not is_on_floor() and velocidade.y > 0):
			# No ar
			if velocidade.y > 0:
				estado_atual = "subindo"
			else:
				estado_atual = "caindo"
		else:
			# No chão
			if direcao_x != 0:
				estado_atual = "correndo"
			else:
				estado_atual = "parado"
				
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
