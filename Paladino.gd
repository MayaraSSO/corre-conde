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
		# 1. Verifica se o Conde pegou os 2 pedaços de anel espalhados pela fase
		if body.pedacos_coletados < 2:
			print("CHEFÃO: Conde tentou enfrentar o paladino sem as peças do anel! Repelido...")
			
			# Conde toma dano por tentar encarar o paladino despreparado
			body.energia_vital -= 25.0
			body.get_node("HUD/BarraVida").value = body.energia_vital
			
			# Mostra o aviso na tela do HUD
			body.get_node("HUD/TextoAnel").text = "ANEL INCOMPLETO! COLETE OS PEDAÇOS!"
			
			# Se morrer para o Paladino
			if body.energia_vital <= 0:
				body.energia_vital = 0
				var arquivo = File.new()
				var _erro = arquivo.open("user://motivo_morte.txt", File.WRITE)
				arquivo.store_string("paladino")
				arquivo.close()
				var _morte = get_tree().change_scene("res://GameOver.tscn")
			else:
				# Repele o conde para trás (esquerda) para tirá-lo de cima da colisão
				body.translation.x -= 8.0
			return # Bloqueia a vitória!
			
		# Se tiver coletado os 2 pedaços, ele drena o Paladino e vence!
		print("VITÓRIA! O Conde drenou o Paladino, pegou o ouro e 1/4 do Anel!")
		
		# 1. Drena o sangue: A vida do Conde volta para 100%!
		body.energia_vital = 100.0
		body.get_node("HUD/BarraVida").value = body.energia_vital
		
		# 2. Desliga o Tsunami de luz para ele não te engolir durante a vitória
		get_parent().get_node("ZonaLuz").set_process(false)
		
		# 3. Dá o pedaço do anel ao Conde (completando 3)
		body.pegar_pedaco_anel()
		
		# 4. O Paladino morre (some do mapa)
		queue_free()
		
		# 5. Manda para a tela de vitória
		var _vitoria = get_tree().change_scene("res://TelaVitoria.tscn")
