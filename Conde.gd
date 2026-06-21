extends KinematicBody

var velocidade = Vector3.ZERO
var forca_pulo = 15.0
var gravidade = 35.0
var velocidade_movimento = 8.0


# --- NOVAS VARIÁVEIS DE VIDA ---
var energia_vital = 100.0
var vida_anterior = 100.0
var tempo_exibir_dano = 0.0
var tempo_animacao = 0.0

# --- VARIÁVEIS DO ANEL ---
var pedacos_coletados = 0
var total_pedacos = 3

# --- TEXTURAS E NÓ DO SPRITE ---
onready var sprite_node = $SpriteConde
var grupo_anim_anterior = null

var sheet_parado = preload("res://Imagens/Conde_Parado_Sheet.png")
var sheet_correndo = preload("res://Imagens/Conde_Correndo_Sheet.png")
var sheet_pulo = preload("res://Imagens/Conde_Pulo_Sheet.png")
var sheet_queda = preload("res://Imagens/Conde_Queda_Sheet.png")
var sheet_dano = preload("res://Imagens/Conde_Dano_Sheet.png")



func _ready():
	if sprite_node != null:
		sprite_node.texture = sheet_parado
		sprite_node.hframes = 4
		sprite_node.vframes = 1
		sprite_node.frame = 0

func _physics_process(delta):
	
	# 1. Aplicando a Gravidade
	if not is_on_floor():
		velocidade.y -= gravidade * delta
		
	# 2. Movimentação Horizontal
	var direcao_x = 0
	
	if Input.is_action_pressed("ui_right"):
		direcao_x += 1
	if Input.is_action_pressed("ui_left"):
		direcao_x -= 1
		
	velocidade.x = direcao_x * velocidade_movimento
	
	# 3. O Salto
	if Input.is_action_pressed("ui_up") and is_on_floor():
		velocidade.y = forca_pulo
		
	# 4. Trava de segurança do eixo Z
	velocidade.z = 0
	
	# 5. Executa a movimentação e colisão
	velocidade = move_and_slide(velocidade, Vector3.UP)
	
	# 7. Máquina de Estados Visual das Sprites 2.5D
	_atualizar_visual_conde(delta, direcao_x)
	
	# 6. Se o Conde cair no abismo (passar de Y = -5), a fase recomeça com derrota por queda
	if translation.y < -5.0:
		var arquivo = File.new()
		var _erro = arquivo.open("user://motivo_morte.txt", File.WRITE)
		arquivo.store_string("queda")
		arquivo.close()
		var _reiniciar = get_tree().change_scene("res://GameOver.tscn")

func pegar_pedaco_anel():
	pedacos_coletados += 1
	var pedacos_restantes = total_pedacos - pedacos_coletados
	
	# Atualiza o texto na tela baseado na matemática exata
	if pedacos_restantes > 1:
		$HUD/TextoAnel.text = "FALTAM " + str(pedacos_restantes) + " PEDAÇOS DO ANEL"
	elif pedacos_restantes == 1:
		$HUD/TextoAnel.text = "FALTA 1 PEDAÇO DO ANEL"
	else:
		$HUD/TextoAnel.text = "ANEL COMPLETO!"
		print("VITÓRIA: O Conde juntou todos os pedaços!")
		# Aqui poderemos chamar a tela de vitória no futuro!

func _atualizar_visual_conde(delta, direcao_x):
	if sprite_node == null:
		return
		
	# A. Detecção de Dano (se a vida caiu em relação ao frame anterior)
	if energia_vital < vida_anterior:
		tempo_exibir_dano = 0.35 # Mostra o sprite de dano por 0.35 segundos
	vida_anterior = energia_vital
	
	var nova_sheet = sheet_parado
	var total_frames = 4
	var vel_anim = 4.0 # FPS padrão
	
	# Diminui o cronômetro do dano
	if tempo_exibir_dano > 0:
		tempo_exibir_dano -= delta
		nova_sheet = sheet_dano
		total_frames = 4
		vel_anim = 8.0 # Anima o dano a 8 FPS
		sprite_node.modulate = Color(1, 0.4, 0.4, 1) # Pisca em vermelho
	else:
		sprite_node.modulate = Color(1, 1, 1, 1) # Cor normal
		
		# B. Animação de Movimento (Pulo, Queda, Corrida, Parado)
		if not is_on_floor():
			# No ar
			if velocidade.y > 0:
				nova_sheet = sheet_pulo
				total_frames = 2
			else:
				nova_sheet = sheet_queda
				total_frames = 2
			vel_anim = 4.0 # Anima mais lento no ar (4 FPS)
		else:
			# No chão
			if direcao_x != 0:
				nova_sheet = sheet_correndo
				total_frames = 4
				vel_anim = 10.0 # Anima corrida a 10 FPS (mais rápido e dinâmico)
			else:
				nova_sheet = sheet_parado
				total_frames = 4
				vel_anim = 4.0 # Anima respiração parado a 4 FPS
				
	# Se mudou a spritesheet de animação, atualiza textura/hframes e reseta tempo
	if nova_sheet != grupo_anim_anterior:
		sprite_node.texture = nova_sheet
		sprite_node.hframes = total_frames
		sprite_node.vframes = 1
		tempo_animacao = 0.0
		grupo_anim_anterior = nova_sheet
		
	# Avança o tempo da animação
	tempo_animacao += delta * vel_anim
	
	# Calcula o índice do frame correspondente e atualiza na GPU via offset UV nativo
	var frame_idx = int(tempo_animacao) % total_frames
	if sprite_node.frame != frame_idx:
		sprite_node.frame = frame_idx
				
	# C. Orientação Horizontal (Inversão/Flip)
	if direcao_x < 0:
		sprite_node.flip_h = true
	elif direcao_x > 0:
		sprite_node.flip_h = false
