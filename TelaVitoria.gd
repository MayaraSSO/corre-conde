extends Control

func _on_BotaoMenuPrincipal_pressed():
	# Volta para o menu principal
	var _voltar = get_tree().change_scene("res://MenuPrincipal.tscn")
