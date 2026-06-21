extends Control

func _ready():
	var motivo_morte = "sol"
	var arquivo = File.new()
	if arquivo.file_exists("user://motivo_morte.txt"):
		var _erro = arquivo.open("user://motivo_morte.txt", File.READ)
		motivo_morte = arquivo.get_as_text().strip_edges()
		arquivo.close()
		
	if motivo_morte == "queda":
		$TituloGameOver.text = "O CONDE DESPENCOU!"
		$SubTitulo.text = "A queda no abismo foi fatal."
	elif motivo_morte == "paladino":
		$TituloGameOver.text = "O PALADINO VENCEU!"
		$SubTitulo.text = "Você foi derrotado pelo campeão da luz."
	else:
		$TituloGameOver.text = "O CONDE VIROU CINZAS!"
		$SubTitulo.text = "A luz do sol foi implacável..."

func _on_BotaoTentarNovamente_pressed():
	# Recarrega a Fase 1 para tentar de novo
	var _recarregar = get_tree().change_scene("res://Fase1.tscn")

func _on_BotaoMenuPrincipal_pressed():
	# Volta para o menu principal
	var _voltar = get_tree().change_scene("res://MenuPrincipal.tscn")
