extends Control

func _on_BotaoIniciar_pressed():
	# Carrega a Fase 1 quando o jogador clica em Iniciar
	var _mudar = get_tree().change_scene("res://Fase1.tscn")
