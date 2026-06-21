extends Area

func _on_PedacoAnel_body_entered(body):
	# Se quem encostou foi o Conde (o jogador)
	if body.name == "Conde":
		# Chama a função que já existe no Conde para contar o pedaço
		body.pegar_pedaco_anel()
		print("COLETOU! O Conde pegou um pedaço do Anel!")
		
		# Some do mapa instantaneamente
		queue_free()
