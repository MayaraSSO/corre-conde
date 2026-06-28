extends Area

var estaca_molde = preload("res://Estaca.tscn")

var desintegrando = false
var saude_paladino = 1
var temporizador_morte = 1.8
var material : SpatialMaterial
var conde_ref = null

# --- NOVAS VARIÁVEIS DE SPRITE E ANIMAÇÃO ---
onready var sprite_node = $SpritePaladino

var sheet_idle = preload("res://Imagens/Paladino_Idle.png")
var sheet_attack = preload("res://Imagens/Paladino_Attack 1.png")
var sheet_dead = preload("res://Imagens/Paladino_Dead.png")

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

func _process(delta):
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
	var conde = get_parent().get_node_or_null("Conde")
	if conde != null and not desintegrando:
		# Lógica de rotação horizontal (flip_h):
		# Se o Conde estiver à esquerda do Paladino (pos.x < pos.x), flip_h deve ser true.
		# Caso contrário, flip_h deve ser false.
		if sprite_node != null:
			if conde.translation.x < translation.x:
				sprite_node.flip_h = true  # Olha para a esquerda
			else:
				sprite_node.flip_h = false # Olha para a direita
				
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
	var conde = get_parent().get_node_or_null("Conde")
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
		
		get_parent().add_child(nova_estaca)
		print("CHEFÃO: O Conde entrou no radar! Disparando estaca...")
		
		# 4. Ativa a animação de ataque
		tempo_exibir_ataque = 0.625 # 5 frames / 8 fps = 0.625 segundos de animação de ataque

func _on_Paladino_body_entered(body):
	# Dano de contato removido para permitir aproximação do Conde para golpear com a espada
	pass

func receber_dano_espada():
	if desintegrando:
		return
		
	var conde = get_parent().get_node_or_null("Conde")
	if conde == null:
		return
		
	# 1. Verifica se o Conde pegou os 2 pedaços de anel espalhados pela fase
	if conde.pedacos_coletados < 2:
		print("CHEFÃO: Espadada inútil! Conde não tem as peças do anel!")
		
		# Mostra o aviso na tela do HUD
		var texto_anel = conde.get_node_or_null("HUD/TextoAnel")
		if texto_anel != null:
			texto_anel.text = "ANEL INCOMPLETO! COLETE OS PEDAÇOS!"
		return
		
	# 2. Paladino recebe o dano
	saude_paladino -= 1
	print("CHEFÃO: Paladino atingido por golpe de espada! HP restante: ", saude_paladino)
	
	# Efeito de piscar em vermelho ao tomar dano
	if sprite_node != null:
		sprite_node.modulate = Color(1.0, 0.3, 0.3, 1.0)
		yield(get_tree().create_timer(0.25), "timeout")
		if is_instance_valid(self) and not desintegrando:
			sprite_node.modulate = Color(1.0, 1.0, 1.0, 1.0)
			
	if saude_paladino <= 0:
		# Se tiver zerado a vida, inicia o processo de desintegração lenta!
		print("PALADINO: Sucumbiu ao Conde! Iniciando desintegração lenta de 1.8s...")
		desintegrando = true
		conde_ref = conde
		
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
		var zona = get_parent().get_node_or_null("ZonaLuz")
		if zona != null:
			zona.set_process(false)

