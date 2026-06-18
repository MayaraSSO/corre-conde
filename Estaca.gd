extends Area

# Velocidade agressiva do tiro da balestra
var velocidade_tiro = 30.0

func _physics_process(delta):
	# A estaca viaja como um míssil para a ESQUERDA (em direção contrária à corrida)
	translation.x -= velocidade_tiro * delta

func _on_Estaca_body_entered(body):
	# Se a estaca encostar no personagem principal (Conde)
	if body.name == "Conde":
		# Arranca 10 pontos da energia vital (10% do total)
		body.energia_vital -= 10.0
		
		# Atualiza a barra vermelha na tela na mesma hora
		body.get_node("HUD/BarraVida").value = body.energia_vital
		
		print("DANO: O Conde foi atingido por uma estaca! -10 Energia.")
		
		# Destrói a estaca do mapa instantaneamente após o impacto
		queue_free()
