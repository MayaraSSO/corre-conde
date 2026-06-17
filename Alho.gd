extends Area

func _on_Alho_body_entered(body):
	# Verifica se quem bateu foi o jogador
	if body.name == "Conde":
		# Arranca 10 pontos de vida na mesma hora
		body.energia_vital -= 10.0
		
		# Atualiza a barra de vida na tela do jogador instantaneamente
		body.get_node("HUD/BarraVida").value = body.energia_vital
		
		print("DANO! O Conde pisou no Alho.")
