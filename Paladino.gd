extends Area

var estaca_molde = preload("res://Estaca.tscn")

func _on_TimerTiro_timeout():
	# 1. O Paladino procura o Conde no mapa (Lógica de Radar)
	var conde = get_parent().get_node("Conde")
	
	# 2. Calcula a distância matemática entre os dois vetores 3D
	var distancia = translation.distance_to(conde.translation)
	
	# 3. Só atira se o Conde estiver a 60 metros ou menos (visível fora da névoa)
	if distancia <= 60.0:
		var nova_estaca = estaca_molde.instance()
		
		# Pega a posição do Paladino
		nova_estaca.translation = self.translation
		
		# FORÇA a estaca a descer para a altura do peito do Conde
		nova_estaca.translation.y = 1.0 
		nova_estaca.translation.x -= 2.0
		
		get_parent().add_child(nova_estaca)
		print("CHEFÃO: O Conde entrou no radar! Disparando estaca...")



func _on_Paladino_body_entered(body):
	# Se quem bateu no Paladino foi o Conde
	if body.name == "Conde":
		print("VITÓRIA! O Conde drenou o Paladino, pegou o ouro e 1/4 do Anel!")
		
		# 1. Drena o sangue: A vida do Conde volta para 100%!
		body.energia_vital = 100.0
		body.get_node("HUD/BarraVida").value = body.energia_vital
		
		# 2. Desliga o Tsunami de luz para ele não te engolir durante a vitória
		get_parent().get_node("ZonaLuz").set_process(false)
		
		# 3. O Paladino morre (some do mapa)
		queue_free()
