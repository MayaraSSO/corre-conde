extends KinematicBody

var estaca_molde = preload("res://Estaca.tscn")

# --- SONS DO PALADINO ---
var som_dano_paladino_res = preload("res://Sons/Dano no Paladino.wav")
var som_morte_paladino_res = preload("res://Sons/Morte do Paladino.mp3")
var som_disparo_estaca_res = preload("res://Sons/Disparo de Estaca.wav")

var player_dano_paladino : AudioStreamPlayer
var player_morte_paladino : AudioStreamPlayer
var player_disparo_estaca : AudioStreamPlayer

var desintegrando = false
export var saude_paladino = 1  # Configurável (Fase1=1, Fase2=3)
export var pedacos_necessarios = 2  # Quantos pedaços o Conde precisa antes de poder atacar
export var dano_estaca = 10.0
var temporizador_morte = 1.8
var material : SpatialMaterial
var conde_ref = null

# --- CONFIGURAÇÃO DE COMBATE DE PERTO (FASES 2 E 3) ---
export var pode_mover_e_bater = false
export var velocidade_movimento = 4.0
export var distancia_ataque_fisico = 4.5
export var dano_ataque_fisico = 15.0
export var cooldown_ataque_fisico = 1.5

var atacando_fisico = false
var tempo_ataque_fisico = 0.0
var timer_cooldown_fisico = 0.0

# --- NOVAS VARIÁVEIS DE SPRITE E ANIMAÇÃO ---
onready var sprite_node = $SpritePaladino

var sheet_idle = preload("res://Imagens/Paladino_Idle.png")
var sheet_attack = preload("res://Imagens/Paladino_Attack 1.png")
var sheet_dead = preload("res://Imagens/Paladino_Dead.png")
var sheet_run_attack = preload("res://Imagens/Paladino_Run+Attack.png")
var sheet_hurt = preload("res://Imagens/Paladino_Hurt.png")

var animacoes = {
	"idle": {
		"texture": sheet_idle,
		"hframes": 4,
		"frame_min": 0,
		"frame_max": 3,
		"fps": 6.0
	},
	"attack": {
		"texture": sheet_attack,
		"hframes": 5,
		"frame_min": 0,
		"frame_max": 4,
		"fps": 8.0
	},
	"run_attack": {
		"texture": sheet_run_attack,
		"hframes": 6,
		"frame_min": 0,
		"frame_max": 5,
		"fps": 8.0
	},
	"hurt": {
		"texture": sheet_hurt,
		"hframes": 2,
		"frame_min": 0,
		"frame_max": 1,
		"fps": 6.0
	},
	"dead": {
		"texture": sheet_dead,
		"hframes": 6,
		"frame_min": 0,
		"frame_max": 5,
		"fps": 3.5
	}
}

var estado_atual = "idle"
var estado_anterior = ""
var tempo_animacao = 0.0
var tempo_exibir_ataque = 0.0
var tempo_exibir_dano = 0.0

func _ready():
	# Pega o material do cilindro e duplica para manter compatibilidade, mas desativa visibilidade
	var mesh_inst = get_node_or_null("MeshInstance")
	if mesh_inst != null:
		mesh_inst.visible = false
		material = mesh_inst.get_surface_material(0)
		if material == null and mesh_inst.mesh != null:
			material = mesh_inst.mesh.surface_get_material(0)
		if material != null:
			material = material.duplicate()
			mesh_inst.set_surface_material(0, material)
			
	# Inicializa o sprite
	if sprite_node != null:
		sprite_node.texture = sheet_idle
		sprite_node.hframes = 4
		sprite_node.vframes = 1
		sprite_node.frame = 0
		print("PALADINO: Sprite de Paladino inicializado com sucesso!")
		
	# Aumenta o tempo entre tiros do Paladino para diminuir a dificuldade (menos estacas)
	var timer_tiro = get_node_or_null("TimerTiro")
	if timer_tiro != null:
		timer_tiro.wait_time = 5.0
		print("PALADINO: Frequência de tiros de estaca reduzida para 5.0s.")
	
	# --- INICIALIZAÇÃO DOS PLAYERS DE ÁUDIO ---
	player_dano_paladino = AudioStreamPlayer.new()
	player_dano_paladino.stream = som_dano_paladino_res
	add_child(player_dano_paladino)
	
	player_morte_paladino = AudioStreamPlayer.new()
	player_morte_paladino.stream = som_morte_paladino_res
	add_child(player_morte_paladino)
	
	player_disparo_estaca = AudioStreamPlayer.new()
	player_disparo_estaca.stream = som_disparo_estaca_res
	add_child(player_disparo_estaca)

func _process(delta):
	# Cooldown do golpe físico
	if timer_cooldown_fisico > 0.0:
		timer_cooldown_fisico -= delta

	# 1. Determina a máquina de estados visual
	var estado_desejado = "idle"
	
	if desintegrando:
		estado_desejado = "dead"
		temporizador_morte -= delta
		
		# Efeito visual de desvanecimento e piscar no sprite
		if sprite_node != null:
			var flash = sin(OS.get_ticks_msec() * 0.025) * 0.4 + 0.6
			sprite_node.modulate = Color(0.8, 0.8, 0.8, 0.3 + 0.7 * flash)
			
		if temporizador_morte <= 0.0:
			desintegrando = false
			print("PALADINO: Sucumbiu ao Conde! Instanciando o fragmento de anel final no chão.")
			
			# Destrava o Conde para que ele possa se mover e pegar o anel
			if is_instance_valid(conde_ref):
				conde_ref.controles_travados = false
				print("PALADINO: Conde destravado!")
			
			# Instancia o anel físico no chão
			var anel_cena = preload("res://PedacoAnel.tscn")
			var novo_anel = anel_cena.instance()
			novo_anel.translation = self.translation
			novo_anel.translation.y = 1.0 # Altura no chão
			novo_anel.translation.x += 3.0 # Ligeiramente à direita
			get_parent().add_child(novo_anel)
			
			# Destrói o Paladino
			queue_free()
			return
	elif tempo_exibir_dano > 0.0:
		tempo_exibir_dano -= delta
		estado_desejado = "hurt"
		if sprite_node != null:
			sprite_node.modulate = Color(1.0, 0.3, 0.3, 1.0) # Pisca em vermelho ao tomar dano
	elif atacando_fisico:
		tempo_ataque_fisico -= delta
		estado_desejado = "attack"
		if tempo_ataque_fisico <= 0.0:
			atacando_fisico = false
			timer_cooldown_fisico = cooldown_ataque_fisico
		if sprite_node != null:
			sprite_node.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif tempo_exibir_ataque > 0.0:
		tempo_exibir_ataque -= delta
		estado_desejado = "attack"
		if sprite_node != null:
			sprite_node.modulate = Color(1.0, 1.0, 1.0, 1.0) # Restaura cor normal
	else:
		estado_desejado = "idle"
		if sprite_node != null:
			sprite_node.modulate = Color(1.0, 1.0, 1.0, 1.0) # Restaura cor normal
			
	# 2. Atualiza e rotaciona o Paladino para sempre encarar o Conde
	var conde = get_tree().current_scene.get_node_or_null("Conde")
	if conde != null and not desintegrando:
		# Lógica de rotação horizontal (flip_h):
		# Se o Conde estiver à esquerda do Paladino (pos.x < pos.x), flip_h deve ser true.
		# Caso contrário, flip_h deve ser false.
		if sprite_node != null:
			if conde.translation.x < translation.x:
				sprite_node.flip_h = true   # Olha para a esquerda (textura original olha para a direita)
			else:
				sprite_node.flip_h = false  # Olha para a direita (textura original olha para a direita, sem flip)
				
		# --- MOVIMENTAÇÃO E ATAQUE FÍSICO (FASES 2 E 3) ---
		if pode_mover_e_bater and not conde.esta_morto:
			var distancia = translation.distance_to(conde.translation)
			if distancia <= 60.0:
				var dist_horizontal = conde.translation.x - translation.x
				var dir = sign(dist_horizontal)
				
				if atacando_fisico:
					# Se está golpeando fisicamente, não se move
					pass
				elif abs(dist_horizontal) <= distancia_ataque_fisico and abs(translation.y - conde.translation.y) < 2.5:
					# Se está muito perto e fora de cooldown, ataca fisicamente
					if timer_cooldown_fisico <= 0.0:
						atacando_fisico = true
						tempo_ataque_fisico = 0.625 # 5 frames / 8 fps = 0.625s
						_atacar_conde_fisico(conde)
				else:
					# Persegue o Conde horizontalmente apenas se houver chão seguro à frente
					var ponto_a_frente = translation.x + dir * 1.5
					if _esta_sobre_chao(ponto_a_frente):
						translation.x += dir * velocidade_movimento * delta
						estado_desejado = "run_attack"
					else:
						# Para na borda se houver abismo
						estado_desejado = "idle"
				
	# 3. Gerencia e atualiza a animação do sprite
	estado_atual = estado_desejado
	if estado_atual != estado_anterior:
		tempo_animacao = 0.0
		estado_anterior = estado_atual
		
		if sprite_node != null:
			var cfg = animacoes[estado_atual]
			sprite_node.texture = cfg["texture"]
			sprite_node.hframes = cfg["hframes"]
			sprite_node.vframes = 1
			sprite_node.frame = cfg["frame_min"]
			
	if sprite_node != null:
		var cfg = animacoes[estado_atual]
		tempo_animacao += delta * cfg["fps"]
		
		var total_frames = cfg["frame_max"] - cfg["frame_min"] + 1
		var frame_offset = 0
		
		if estado_atual == "dead":
			# Trava no último frame no chão na animação de morte
			frame_offset = int(tempo_animacao)
			if frame_offset >= total_frames:
				frame_offset = total_frames - 1
		else:
			frame_offset = int(tempo_animacao) % total_frames
			
		sprite_node.frame = cfg["frame_min"] + frame_offset

func _on_TimerTiro_timeout():
	if desintegrando:
		return
		
	# 1. O Paladino procura o Conde no mapa (Lógica de Radar)
	var conde = get_tree().current_scene.get_node_or_null("Conde")
	if conde == null:
		return
		
	# 2. Calcula a distância matemática entre os dois vetores 3D
	var distancia = translation.distance_to(conde.translation)
	
	# 3. Só atira se o Conde estiver a 60 metros ou menos (visível fora da névoa)
	if distancia <= 60.0:
		var nova_estaca = estaca_molde.instance()
		
		# Pega a posição do Paladino
		nova_estaca.translation = self.translation
		
		# FORÇA a estaca a descer para a altura da cintura do Conde
		nova_estaca.translation.y = conde.translation.y 
		nova_estaca.translation.x -= 2.0
		
		nova_estaca.dano_estaca = dano_estaca
		get_parent().add_child(nova_estaca)
		print("CHEFÃO: O Conde entrou no radar! Disparando estaca...")
		
		# Toca o som de disparo de estaca
		if player_disparo_estaca != null:
			player_disparo_estaca.play()
		
		# 4. Ativa a animação de ataque
		tempo_exibir_ataque = 0.625 # 5 frames / 8 fps = 0.625 segundos de animação de ataque


func _is_custom_level() -> bool:
	var pai = get_parent()
	return pai != null and (pai.name.begins_with("LevelLoader") or pai.has_method("carregar_fase"))

func _esta_sobre_chao_custom(x_pos) -> bool:
	var pai = get_parent()
	if pai != null and "dados_fase" in pai and "blocos" in pai.dados_fase:
		var meia_largura = pai.ESCALA / 2.0
		for bloco in pai.dados_fase.blocos:
			var px = (bloco.x / pai.BLOCO_PX) * pai.ESCALA
			if abs(x_pos - px) <= meia_largura:
				return true
	return false

func _esta_sobre_chao(x_pos):
	if _is_custom_level():
		return _esta_sobre_chao_custom(x_pos)
		
	# O ciclo de blocos de chão se repete a cada 35 metros
	var mod = fmod(x_pos + 17.5, 35.0)
	if mod < 0.0:
		mod += 35.0
	# Cada bloco de chão tem 30 metros de largura, centralizado no ciclo.
	# Portanto, se estiver entre 2.5 e 32.5, há chão sob o personagem.
	return mod >= 2.5 and mod <= 32.5

func _atacar_conde_fisico(conde):
	if conde.temporizador_parry > 0.0:
		conde.temporizador_parry = 0.0 # Consome o parry
		print("PARRY! O Conde bloqueou o golpe do Paladino com a capa.")
		# Repele o Paladino para trás
		var dir_repulsao = sign(translation.x - conde.translation.x)
		if dir_repulsao == 0:
			dir_repulsao = 1.0
		translation.x += dir_repulsao * 8.0
		return
		
	# Aplica o dano físico ao Conde
	conde.ultimo_dano_recebido = "paladino"
	conde.energia_vital -= dano_ataque_fisico
	conde.tempo_exibir_dano = 0.35
	
	var barra = conde.get_node_or_null("HUD/BarraVida")
	if barra != null:
		barra.value = conde.energia_vital
		
	# Repele o Conde levemente para trás
	var dir = sign(conde.translation.x - translation.x)
	if dir == 0:
		dir = -1.0
	conde.translation.x += dir * 4.0
	conde.velocidade.y = 8.0
	
	print("DANO: Paladino desferiu golpe físico no Conde! Dano: ", dano_ataque_fisico)
	
	if conde.energia_vital <= 0.0:
		conde.energia_vital = 0.0
		conde.morrer("paladino")

func receber_dano_espada():
	if desintegrando:
		return
		
	var conde = get_tree().current_scene.get_node_or_null("Conde")
	if conde == null:
		return
		
	# 1. Verifica se o Conde pegou os pedaços de anel necessários
	if conde.pedacos_coletados < pedacos_necessarios:
		print("CHEFÃO: Espadada inútil! Conde não tem as peças do anel!")
		
		# Mostra o aviso na tela do HUD
		var texto_anel = conde.get_node_or_null("HUD/TextoAnel")
		if texto_anel != null:
			texto_anel.text = "ANEL INCOMPLETO! COLETE OS PEDAÇOS!"
		return
		
	# 2. Paladino recebe o dano
	saude_paladino -= 1
	print("CHEFÃO: Paladino atingido por golpe de espada! HP restante: ", saude_paladino)
	
	# Toca o som de dano no Paladino
	if player_dano_paladino != null:
		player_dano_paladino.play()
			
	if saude_paladino <= 0:
		# Se tiver zerado a vida, inicia o processo de desintegração lenta!
		print("PALADINO: Sucumbiu ao Conde! Iniciando desintegração lenta de 1.8s...")
		desintegrando = true
		conde_ref = conde
		
		# Toca o som de morte do Paladino
		if player_morte_paladino != null:
			player_morte_paladino.play()
		
		# 1. Drena o sangue: A vida do Conde volta para 100% e ganha imunidade ao sol
		conde.energia_vital = 100.0
		conde.imune_ao_sol = true
		conde.controles_travados = true # Trava o movimento horizontal e pulo do Conde
		conde.velocidade.x = 0 # Para a inércia imediatamente
		var barra = conde.get_node_or_null("HUD/BarraVida")
		if barra != null:
			barra.value = conde.energia_vital
			
		# 2. Exibe texto "DESINTEGRANDO..." no HUD
		var texto_anel = conde.get_node_or_null("HUD/TextoAnel")
		if texto_anel != null:
			texto_anel.text = "DESINTEGRANDO..."
		
		# 3. Desliga o Tsunami de luz para ele não te engolir durante a vitória
		var zona = get_tree().current_scene.get_node_or_null("ZonaLuz")
		if zona != null:
			zona.set_process(false)
	else:
		# Se o Paladino ainda estiver vivo, inicia o estado de dano (Hurt)
		tempo_exibir_dano = 0.35

