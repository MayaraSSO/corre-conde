extends Area

var ativado = false
var tempo = 0.0
var conde = null

# --- TEXTURAS DOS PORTAIS ---
var tex_purple = preload("res://Imagens/Purple Portal Sprite Sheet.png")
var tex_green = preload("res://Imagens/Green Portal Sprite Sheet.png")

# --- SOM DE TELETRANSPORTE ---
var som_teletransporte_res = preload("res://Sons/teletransporte de uma fase para outra.mp3")
var player_teletransporte : AudioStreamPlayer

# --- MÁQUINA DE ESTADOS DE ANIMAÇÃO ---
var estado_anim = "aparecendo"
var tempo_estado = 0.0
var fps_portal = 12.0

func _ready():
	# Começa invisível/minúsculo e expande
	scale = Vector3.ZERO
	var _err = connect("body_entered", self, "_on_body_entered")
	print("[Portal] Portal inicializado e pronto para receber o Conde.")

	# Configura a textura correta do Sprite3D do portal baseado na fase atual
	var sprite = get_node_or_null("Sprite3D")
	if sprite != null:
		if DadosJogo.fase_atual == 1:
			sprite.texture = tex_purple
			print("[Portal] Sprite definido para Purple (Fase 1).")
		else:
			sprite.texture = tex_green
			print("[Portal] Sprite definido para Green (Fase 2).")

	# Inicializa o player de áudio de teletransporte
	player_teletransporte = AudioStreamPlayer.new()
	player_teletransporte.stream = som_teletransporte_res
	add_child(player_teletransporte)

func _process(delta):
	# Animação de crescimento suave ao surgir
	if scale.x < 1.5 and not ativado:
		scale = scale.linear_interpolate(Vector3(1.5, 1.5, 1.5), 5.0 * delta)
		
	tempo_estado += delta
	var sprite = get_node_or_null("Sprite3D")
	
	# Máquina de Estados de Animação do Portal
	if estado_anim == "aparecendo":
		var frame_offset = int(tempo_estado * fps_portal)
		if frame_offset < 8:
			if sprite != null:
				sprite.frame = 8 + frame_offset
		else:
			estado_anim = "esperando"
			tempo_estado = 0.0
			if sprite != null:
				sprite.frame = 0
				
	elif estado_anim == "esperando":
		if sprite != null:
			sprite.frame = int(tempo_estado * fps_portal) % 8
			# Leve rotação contínua no eixo Z para profundidade visual
			sprite.rotation_degrees.z += 40.0 * delta
			
		# Redundância: Checa se o Conde já está dentro da área caso o sinal body_entered falhe
		if not ativado:
			for body in get_overlapping_bodies():
				if body.name == "Conde":
					_on_body_entered(body)
					break
					
	elif estado_anim == "fechando":
		var frame_offset = int(tempo_estado * fps_portal)
		if sprite != null:
			sprite.frame = 16 + min(frame_offset, 7)
			
		# Efeito de sucção do Conde ao centro do portal
		if conde != null and is_instance_valid(conde):
			conde.translation = conde.translation.linear_interpolate(translation, 6.0 * delta)
			conde.scale = conde.scale.linear_interpolate(Vector3.ZERO, 6.0 * delta)
			
			var conde_sprite = conde.get_node_or_null("SpriteConde")
			if conde_sprite != null:
				conde_sprite.rotation_degrees.z += 720.0 * delta # Gira o Conde rapidamente
				
		scale = scale.linear_interpolate(Vector3.ZERO, 4.0 * delta)
		
		tempo += delta
		if tempo >= 1.2:
			# Garante que o Conde não comece travado e despausa
			get_tree().paused = false
			
			if DadosJogo.modo_editor:
				if DadosJogo.caminho_fase_custom == "user://editor_teste.lvl":
					print("[Portal] Fim do teste! Retornando ao Editor...")
					var _r = get_tree().change_scene("res://EditorFases.tscn")
				else:
					print("[Portal] Fim da fase customizada! Retornando ao Menu...")
					var _r = get_tree().change_scene("res://MenuFasesCustom.tscn")
			else:
				# Campanha normal
				if DadosJogo.fase_atual == 1:
					DadosJogo.fase_atual = 2
					print("[Portal] Teletransportando para a Fase 2...")
					var _r = get_tree().change_scene("res://Fase2.tscn")
				elif DadosJogo.fase_atual == 2:
					DadosJogo.fase_atual = 3
					print("[Portal] Teletransportando para a Fase 3...")
					var _r = get_tree().change_scene("res://Fase3.tscn")
				else:
					print("[Portal] Jogo concluído! Teletransportando para a Cutscene do Castelo...")
					var _r = get_tree().change_scene("res://CutsceneEntradaCastelo.tscn")

func _on_body_entered(body):
	if body.name == "Conde" and not ativado:
		ativado = true
		conde = body
		body.input_travado = true # Trava os movimentos e velocidade do Conde
		body.velocidade = Vector3.ZERO
		
		# Faz o sprite do Conde sumir imediatamente
		var sprite_conde = body.get_node_or_null("SpriteConde")
		if sprite_conde != null:
			sprite_conde.visible = false
			print("[Portal] Sprite do Conde ocultado imediatamente.")
		
		# Muda o estado de animação para fechar
		estado_anim = "fechando"
		tempo_estado = 0.0
		
		# Para o cronômetro e salva o tempo da fase atual
		DadosJogo.salvar_tempo_fase_atual()
		
		print("[Portal] Conde entrou! Iniciando teletransporte...")
		
		# Toca o som de teletransporte
		if player_teletransporte != null:
			player_teletransporte.play()
