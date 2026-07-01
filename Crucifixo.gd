extends Area

export var dano_cruz = 10.0

func _on_Crucifixo_body_entered(body):
	if body.name == "Conde":
		if body.temporizador_parry > 0.0:
			body.temporizador_parry = 0.0 # Consome o parry
			print("PARRY! O Conde bloqueou o Crucifixo com a capa.")
			queue_free()
			return
			
		body.ultimo_dano_recebido = "crucifixo"
		body.energia_vital -= dano_cruz
		body.tempo_exibir_dano = 0.35
		var barra = body.get_node_or_null("HUD/BarraVida")
		if barra != null:
			barra.value = body.energia_vital
		print("DANO! O Conde tocou no Crucifixo.")
		
		# Dispara o tutorial se for a primeira vez que toma dano no chão e o tutorial estiver ativo
		if not DadosJogo.tutor_cruz_exibido and DadosJogo.tutorial_ativo and body.is_on_floor():
			DadosJogo.tutor_cruz_exibido = true
			var fase = get_tree().current_scene
			if fase.has_method("mostrar_tutorial"):
				fase.mostrar_tutorial(
					"TUTORIAL: DANOS E DEFESA",
					"Os alhos e crucifixos sagrados queimam o sangue do Conde!\n\nUse pulos para desviar, ou ative a Capa de Hipnose pressionando [b][C] ou [Z][/b] no exato momento do impacto para realizar um [color=#d9ad20]Parry[/color] e anular todo o dano."
				)
				
		queue_free()
