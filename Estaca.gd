extends Area

# Velocidade agressiva do tiro da balestra
var velocidade_tiro = 30.0
export var dano_estaca = 10.0

func _physics_process(delta):
	# A estaca viaja como um míssil para a ESQUERDA (em direção contrária à corrida)
	translation.x -= velocidade_tiro * delta

func _on_Estaca_body_entered(body):
	# Se a estaca encostar no personagem principal (Conde)
	if body.name == "Conde":
		if body.temporizador_parry > 0.0:
			body.temporizador_parry = 0.0 # Consome o parry
			print("PARRY! O Conde bloqueou a estaca com a Capa de Hipnose.")
			queue_free()
			return
			
		# Arranca o dano parametrizado da energia vital
		body.ultimo_dano_recebido = "paladino"
		body.energia_vital -= dano_estaca
		
		# Atualiza a barra vermelha na tela na mesma hora
		var hud_barra = body.get_node_or_null("HUD/BarraVida")
		if hud_barra != null:
			hud_barra.value = body.energia_vital
		
		print("DANO: O Conde foi atingido por uma estaca! -10 Energia.")
		
		# Destrói a estaca do mapa instantaneamente após o impacto
		queue_free()
