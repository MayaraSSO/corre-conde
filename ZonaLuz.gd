extends Area

export var velocidade_perseguicao = 5.0
var perseguindo = false
var tempo_espera = 2.0

func _process(delta):
	# 1. Movimento da Parede de Luz
	if perseguindo:
		if tempo_espera > 0:
			tempo_espera -= delta
		else:
			translation.x += velocidade_perseguicao * delta
			
	# 2. Sistema de Dano Contínuo da Luz Solar
	# Todo ponto à esquerda do limite da onda de luz está ensolarado
	var conde = get_parent().get_node_or_null("Conde")
	if conde != null:
		var limite_sol = translation.x # A frente física e visual está alinhada com a posição X
		if conde.translation.x < limite_sol:
			# O Conde está na luz solar!
			# Tiramos 25.0 de vida por segundo
			conde.energia_vital -= 25.0 * delta
			
			var hud_barra = conde.get_node_or_null("HUD/BarraVida")
			if hud_barra != null:
				hud_barra.value = conde.energia_vital
				
			# Se a energia acabou, manda para o Game Over de Sol
			if conde.energia_vital <= 0:
				conde.energia_vital = 0
				var arquivo = File.new()
				var _erro = arquivo.open("user://motivo_morte.txt", File.WRITE)
				arquivo.store_string("sol")
				arquivo.close()
				var _recarregar = get_tree().change_scene("res://GameOver.tscn")

