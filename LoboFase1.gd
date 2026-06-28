extends KinematicBody

# ===========================================================================
# LoboFase1.gd — Lobo da Fase 1 (morre rápido, 2 espadadas)
# Usa sprites 2D animados via Sprite3D
# ===========================================================================

var saude = 2  # Morre com 2 golpes de espada (fase 1 = fácil)
var morto = false
var levou_dano = false
var tempo_dano = 0.0
var tempo_morte = 0.0
var velocidade_perseguicao = 6.0
var gravidade = 35.0
var velocidade_y = 0.0
var distancia_ataque = 3.0
var atacando = false
var tempo_ataque = 0.0
var cooldown_ataque = 1.5
var timer_cooldown = 0.0
var dano_ao_conde = 10.0

# Temporizadores e flags para a IA de evitar buracos
var tempo_fuga_buraco = 0.0
var direcao_fuga_buraco = 0.0

# Sprite animado
onready var sprite_node = $SpriteLobo

# Spritesheets
var sheet_idle = preload("res://Imagens/Idle.png")
var sheet_run = preload("res://Imagens/Run.png")
var sheet_attack = preload("res://Imagens/Attack_3.png")
var sheet_hurt = preload("res://Imagens/Hurt.png")
var sheet_dead = preload("res://Imagens/Dead.png")

var animacoes = {
	"idle": {
		"texture": null,
		"hframes": 8,
		"frame_min": 0,
		"frame_max": 7,
		"fps": 8.0
	},
	"run": {
		"texture": null,
		"hframes": 9,
		"frame_min": 0,
		"frame_max": 8,
		"fps": 12.0
	},
	"attack": {
		"texture": null,
		"hframes": 5,
		"frame_min": 0,
		"frame_max": 4,
		"fps": 10.0
	},
	"hurt": {
		"texture": null,
		"hframes": 2,
		"frame_min": 0,
		"frame_max": 1,
		"fps": 6.0
	},
	"dead": {
		"texture": null,
		"hframes": 2,
		"frame_min": 0,
		"frame_max": 1,
		"fps": 3.0
	}
}

var estado_atual = "idle"
var estado_anterior = ""
var tempo_animacao = 0.0

func _ready():
	# Adiciona ao grupo para o Conde detectar
	add_to_group("lobos_fase1")
	
	# Força posição Z=0 (jogo 2.5D side-scroller)
	translation.z = 0.0
	
	# Atribui texturas ao dicionário (não pode ser feito na declaração com preload)
	animacoes["idle"]["texture"] = sheet_idle
	animacoes["run"]["texture"] = sheet_run
	animacoes["attack"]["texture"] = sheet_attack
	animacoes["hurt"]["texture"] = sheet_hurt
	animacoes["dead"]["texture"] = sheet_dead
	
	if sprite_node != null:
		sprite_node.texture = sheet_idle
		sprite_node.hframes = 8
		sprite_node.vframes = 1
		sprite_node.frame = 0
		print("[LoboFase1] Sprite configurado! Textura: ", sprite_node.texture, " Visível: ", sprite_node.visible)
	else:
		print("[LoboFase1] ERRO: SpriteLobo não encontrado!")
	
	print("[LoboFase1] Lobo posicionado em X=", translation.x, " Y=", translation.y, " Z=", translation.z)

func _esta_sobre_chao(x_pos):
	# O ciclo de blocos de chão se repete a cada 35 metros, de X=0 a X=500
	var mod = fmod(x_pos + 17.5, 35.0)
	if mod < 0.0:
		mod += 35.0
	
	# Cada bloco de chão tem 30 metros de largura, centralizado no ciclo.
	# Portanto, se estiver entre 2.5 e 32.5, há chão sob o lobo.
	return mod >= 2.5 and mod <= 32.5

func _obter_altura_chao_em(x_pos):
	# Retorna a altura Y correspondente a cada bloco de chão da Fase 1
	if x_pos >= 332.5 and x_pos < 367.5:
		return 2.0  # Chao11
	elif x_pos >= 367.5 and x_pos < 402.5:
		return 4.0  # Chao12
	elif x_pos >= 402.5 and x_pos < 437.5:
		return 2.0  # Chao13
	elif x_pos >= 437.5 and x_pos < 472.5:
		return -2.0 # Chao14
	elif x_pos >= 472.5:
		return 0.0  # Chao15
	else:
		return 0.0  # Chaos 1 a 10

func _mover_e_travar(movimento):
	var novo_mov = move_and_slide(movimento, Vector3.UP)
	
	# Trava de Y rígida e permanente baseada no bloco de chão atual (evita que o lobo caia do cenário e suma)
	var x_pos = translation.x
	var altura_chao = _obter_altura_chao_em(x_pos)
	if translation.y < (altura_chao + 0.1):
		translation.y = altura_chao + 0.1
		velocidade_y = 0.0
		
	# Trava o eixo Z rigidamente em 0 para manter o lobo no plano 2D
	translation.z = 0.0
	
	return novo_mov

func _physics_process(delta):
	# Gravidade
	if not is_on_floor():
		velocidade_y -= gravidade * delta
	else:
		velocidade_y = 0.0
	
	var movimento = Vector3.ZERO
	movimento.y = velocidade_y
	
	if morto:
		tempo_morte += delta
		_atualizar_sprite(delta)
		# Após 1.2s de animação de morte, remove o lobo
		if tempo_morte >= 1.2:
			queue_free()
		var _mov = _mover_e_travar(movimento)
		return
	
	if levou_dano:
		tempo_dano += delta
		if tempo_dano >= 0.4:
			levou_dano = false
			tempo_dano = 0.0
		_atualizar_sprite(delta)
		var _mov = _mover_e_travar(movimento)
		return
	
	# Cooldown de ataque
	if timer_cooldown > 0.0:
		timer_cooldown -= delta
		
	# Decrementa o temporizador de fuga de buraco
	if tempo_fuga_buraco > 0.0:
		tempo_fuga_buraco -= delta
	
	# Busca o Conde
	var conde = get_parent().get_node_or_null("Conde")
	if conde == null or conde.esta_morto:
		estado_atual = "idle"
		_atualizar_sprite(delta)
		var _mov = _mover_e_travar(movimento)
		return
	
	var dir = sign(conde.translation.x - translation.x)
	var dist = abs(translation.x - conde.translation.x)
	
	if atacando:
		tempo_ataque += delta
		estado_atual = "attack"
		if tempo_ataque >= 0.6:
			atacando = false
			tempo_ataque = 0.0
			timer_cooldown = cooldown_ataque
	elif dist <= distancia_ataque and abs(translation.y - conde.translation.y) < 2.5 and timer_cooldown <= 0.0:
		# Ataca o Conde
		atacando = true
		tempo_ataque = 0.0
		estado_atual = "attack"
		_atacar_conde(conde)
	elif dist > distancia_ataque:
		# Persegue o Conde
		estado_atual = "run"
		
		# Se estiver sob efeito da fuga de buraco, corre na direção oposta ao buraco
		if tempo_fuga_buraco > 0.0:
			movimento.x = direcao_fuga_buraco * velocidade_perseguicao
			if sprite_node != null:
				sprite_node.flip_h = direcao_fuga_buraco < 0
		else:
			# Verifica se há um buraco à frente (a 1.5 metros na direção do Conde)
			var ponto_a_frente = translation.x + dir * 1.5
			if not _esta_sobre_chao(ponto_a_frente):
				# Detectou o buraco! Dá meia-volta e corre na direção contrária por 1.0 segundo
				tempo_fuga_buraco = 1.0
				direcao_fuga_buraco = -dir
				movimento.x = direcao_fuga_buraco * velocidade_perseguicao
				if sprite_node != null:
					sprite_node.flip_h = direcao_fuga_buraco < 0
			else:
				# Movimento normal de perseguição e orientação
				movimento.x = dir * velocidade_perseguicao
				if sprite_node != null:
					sprite_node.flip_h = dir < 0
	else:
		estado_atual = "idle"
		if dir != 0 and sprite_node != null:
			sprite_node.flip_h = dir < 0
	
	movimento.z = 0.0
	var _mov = _mover_e_travar(movimento)
	_atualizar_sprite(delta)

func _atacar_conde(conde):
	if conde.temporizador_parry > 0.0:
		conde.temporizador_parry = 0.0 # Consome o parry
		print("PARRY! O Conde bloqueou o ataque do lobo com a capa.")
		# Repele o lobo para trás
		var dir_repulsao = sign(translation.x - conde.translation.x)
		if dir_repulsao == 0:
			dir_repulsao = -1.0
		translation.x += dir_repulsao * 6.0
		return
		
	# Aplica dano ao Conde
	conde.energia_vital -= dano_ao_conde
	conde.tempo_exibir_dano = 0.35
	
	var barra = conde.get_node_or_null("HUD/BarraVida")
	if barra != null:
		barra.value = conde.energia_vital
	
	# Repele levemente o conde
	var dir = sign(conde.translation.x - translation.x)
	conde.translation.x += dir * 3.0
	conde.velocidade.y = 8.0
	
	print("[LoboFase1] Atacou o Conde! HP Conde: ", conde.energia_vital)
	
	if conde.energia_vital <= 0.0:
		conde.energia_vital = 0.0
		conde.morrer("lobo")

func receber_dano_espada():
	"""Chamado quando o Conde acerta o lobo com a espada"""
	if morto:
		return
	
	saude -= 1
	print("[LoboFase1] Recebeu espadada! HP restante: ", saude)
	
	if saude <= 0:
		morto = true
		estado_atual = "dead"
		tempo_animacao = 0.0
		estado_anterior = ""
		print("[LoboFase1] Lobo morreu!")
	else:
		levou_dano = true
		tempo_dano = 0.0
		estado_atual = "hurt"
		tempo_animacao = 0.0
		estado_anterior = ""
		# Repele o lobo para trás
		var conde = get_parent().get_node_or_null("Conde")
		if conde != null:
			var dir = sign(translation.x - conde.translation.x)
			translation.x += dir * 5.0

func _atualizar_sprite(delta):
	if sprite_node == null:
		return
	
	# Se mudou de estado, reseta a animação
	if estado_atual != estado_anterior:
		tempo_animacao = 0.0
		estado_anterior = estado_atual
		
		var cfg = animacoes[estado_atual]
		sprite_node.texture = cfg["texture"]
		sprite_node.hframes = cfg["hframes"]
		sprite_node.vframes = 1
		sprite_node.frame = cfg["frame_min"]
	
	# Avança a animação
	var cfg = animacoes[estado_atual]
	tempo_animacao += delta * cfg["fps"]
	
	var total_frames = cfg["frame_max"] - cfg["frame_min"] + 1
	var frame_offset = 0
	
	if estado_atual == "dead":
		# Trava no último frame
		frame_offset = int(tempo_animacao)
		if frame_offset >= total_frames:
			frame_offset = total_frames - 1
	else:
		frame_offset = int(tempo_animacao) % total_frames
	
	sprite_node.frame = cfg["frame_min"] + frame_offset
